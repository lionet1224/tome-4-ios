#!/usr/bin/env bash
# Compile T-Engine4 for the iOS SIMULATOR (arm64) and assemble ToME.app.
# Run tools/ios/build-deps.sh first. Produces tools/ios/out/ToME.app.
set -euo pipefail

# use a freshly installed Xcode even before xcode-select is switched to it
if ! xcrun --sdk iphonesimulator --show-sdk-path >/dev/null 2>&1 && [ -d /Applications/Xcode.app ]; then
	export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IOSDIR="$ROOT/tools/ios"
PLATFORM="${PLATFORM:-sim}"   # sim (simulator) or dev (device)
case "$PLATFORM" in
	sim) SDK=iphonesimulator; TRIPLE_SUFFIX="-simulator"; OUT="$IOSDIR/out";;
	dev) SDK=iphoneos; TRIPLE_SUFFIX=""; OUT="$IOSDIR/out-dev";;
	*) echo "PLATFORM must be sim or dev"; exit 1;;
esac
PREFIX="$IOSDIR/prefix-$PLATFORM"
OBJ="$OUT/obj"
APP="$OUT/ToME.app"
MIN_IOS=14.0
SDKPATH="$(xcrun --sdk $SDK --show-sdk-path)"
TARGET="-target arm64-apple-ios$MIN_IOS$TRIPLE_SUFFIX -isysroot $SDKPATH"

mkdir -p "$OBJ" "$APP"

DEFS=(-DTE4_IOS -DTE4_GLES1 -DTE4CORE_VERSION=17 -DPHYSFS_SUPPORTS_ZIP
      -DHAVE_MEMMOVE "-DTENGINE_HOME_PATH=\"Documents/t-engine\"")
INCS=(-I"$ROOT/src" -I"$ROOT/src/luasocket" -I"$ROOT/src/fov" -I"$ROOT/src/expat"
      -I"$ROOT/src/lxp" -I"$ROOT/src/libtcod_import" -I"$ROOT/src/physfs"
      -I"$ROOT/src/zlib" -I"$ROOT/src/bzip2" -I"$ROOT/tools/LuaJIT/src"
      -I"$PREFIX/include" -I"$PREFIX/include/SDL2")
WNO=(-Wno-implicit-function-declaration -Wno-deprecated-declarations
     -Wno-deprecated-non-prototype -Wno-incompatible-function-pointer-types
     -Wno-incompatible-pointer-types -Wno-int-conversion)
# TOUCH_LAYER=0 builds the bare port (no engine.TouchInput: fingers are mouse events)
CFLAGS=(-O2 $TARGET "${DEFS[@]}" "${INCS[@]}" "${WNO[@]}" -DTE4_TOUCH_LAYER=${TOUCH_LAYER:-1})

compile() { # src -> obj (skipped when up to date)
	local s="$1" o
	o="$OBJ/$(echo "${s#$ROOT/}" | tr '/' '_').o"
	if [ ! -f "$o" ] || [ "$s" -nt "$o" ]; then
		case "$s" in
			*.cpp) clang++ -std=c++11 "${CFLAGS[@]}" -c "$s" -o "$o" ;;
			*)     clang "${CFLAGS[@]}" -c "$s" -o "$o" ;;
		esac
	fi
	OBJS+=("$o")
}

OBJS=()

# engine core: all top-level src/*.c except the desktop GL loader
for s in "$ROOT"/src/*.c "$ROOT"/src/*.m; do
	case "$(basename "$s")" in
		glew.c) continue ;;
	esac
	compile "$s"
done

# vendored libraries (same sets as build/te4core.lua)
for s in "$ROOT"/src/physfs/*.c "$ROOT"/src/physfs/archivers/*.c \
         "$ROOT"/src/physfs/platform/unix.c "$ROOT"/src/physfs/platform/posix.c \
         "$ROOT"/src/zlib/*.c "$ROOT"/src/bzip2/*.c "$ROOT"/src/fov/*.c \
         "$ROOT"/src/lpeg/*.c "$ROOT"/src/luaprofiler/*.c \
         "$ROOT"/src/libtcod_import/*.c "$ROOT"/src/expat/*.c "$ROOT"/src/lxp/*.c \
         "$ROOT"/src/luamd5/*.c "$ROOT"/src/lzlib/*.c \
         "$ROOT"/src/utf8proc/utf8proc.c \
         "$ROOT"/src/luasocket/buffer.c \
         "$ROOT"/src/luasocket/except.c "$ROOT"/src/luasocket/inet.c \
         "$ROOT"/src/luasocket/io.c "$ROOT"/src/luasocket/luasocket.c \
         "$ROOT"/src/luasocket/options.c "$ROOT"/src/luasocket/select.c \
         "$ROOT"/src/luasocket/tcp.c "$ROOT"/src/luasocket/timeout.c \
         "$ROOT"/src/luasocket/udp.c "$ROOT"/src/luasocket/usocket.c \
         "$ROOT"/src/luasocket/mime.c; do
	compile "$s"
done
for s in "$ROOT"/src/wfc/*.cpp; do compile "$s"; done

echo "=== linking ==="
# Device: declare an iOS 18 SDK in the binary. SDL 2.30.9 does not adopt UIScene, and iOS 26+
# traps at launch (NoSceneLifecycleAdoption) for apps linked against a newer SDK.
LINK_SDK_COMPAT=()
[ "$PLATFORM" = dev ] && LINK_SDK_COMPAT=(-Xlinker -platform_version -Xlinker ios -Xlinker $MIN_IOS -Xlinker 18.0)
clang++ $TARGET "${LINK_SDK_COMPAT[@]}" -o "$APP/t-engine" "${OBJS[@]}" "$PREFIX/lib/libSDL2main.a" \
	"$PREFIX/lib/libSDL2.a" "$PREFIX/lib/libSDL2_image.a" "$PREFIX/lib/libSDL2_ttf.a" \
	"$PREFIX/lib/libpng16.a" "$PREFIX/lib/libvorbisfile.a" "$PREFIX/lib/libvorbis.a" \
	"$PREFIX/lib/libogg.a" "$PREFIX/lib/libluajit-$PLATFORM.a" \
	"$PREFIX/lib/libfreetype.a" \
	-lz -liconv \
	-framework ImageIO -framework CoreServices \
	-framework OpenGLES -framework OpenAL -framework UIKit -framework Foundation \
	-framework UserNotifications -framework AudioToolbox \
	-framework CoreGraphics -framework QuartzCore -framework AVFoundation \
	-framework GameController -framework CoreMotion -framework CoreHaptics \
	-framework Metal -framework CoreAudio -framework AudioToolbox \
	-framework CoreBluetooth

echo "=== bundling ==="
cat > "$APP/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>t-engine</string>
	<key>CFBundleIdentifier</key><string>org.te4.tome.dev</string>
	<key>CFBundleName</key><string>ToME</string>
	<key>CFBundleDisplayName</key><string>Tales of Maj'Eyal</string>
	<key>CFBundleIcons</key>
	<dict>
		<key>CFBundlePrimaryIcon</key>
		<dict>
			<key>CFBundleIconFiles</key>
			<array>
				<string>AppIcon20</string>
				<string>AppIcon29</string>
				<string>AppIcon40</string>
				<string>AppIcon58</string>
				<string>AppIcon60</string>
				<string>AppIcon76</string>
				<string>AppIcon80</string>
				<string>AppIcon87</string>
				<string>AppIcon120</string>
				<string>AppIcon152</string>
				<string>AppIcon167</string>
				<string>AppIcon180</string>
				<string>AppIcon1024</string>
			</array>
			<key>UIPrerenderedIcon</key><true/>
		</dict>
	</dict>
	<key>CFBundleVersion</key><string>1</string>
	<key>CFBundleShortVersionString</key><string>1.7.2</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>LSRequiresIPhoneOS</key><true/>
	<key>UILaunchScreen</key><dict/>
	<key>UIRequiresFullScreen</key><true/>
	<key>UIFileSharingEnabled</key><true/>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
		<string>UIInterfaceOrientationPortrait</string>
	</array>
	<key>UIApplicationSupportsIndirectInputEvents</key><true/>
	<key>CADisableMinimumFrameDurationOnPhone</key><true/>
</dict>
</plist>
EOF

# game data (rsync keeps rebuilds fast; ~1GB first time)
rsync -a --delete "$ROOT/bootstrap" "$APP/"
rsync -a --delete "$ROOT/game" "$APP/"
cp -f "$ROOT/tools/ios/icons"/AppIcon*.png "$APP/"   # app icon files (CFBundleIconFiles)

echo "OK: $APP"
du -sh "$APP"
