#!/usr/bin/env bash
# Build all T-Engine4 dependencies for the iOS SIMULATOR (arm64, static libs).
# Requires full Xcode (iphonesimulator SDK). Installs into tools/ios/prefix-sim.
# Idempotent: skips libs whose install artifacts already exist.
set -euo pipefail

# use a freshly installed Xcode even before xcode-select is switched to it
if ! xcrun --sdk iphonesimulator --show-sdk-path >/dev/null 2>&1 && [ -d /Applications/Xcode.app ]; then
	export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IOSDIR="$ROOT/tools/ios"
SRC="$IOSDIR/dep-src"
PREFIX="$IOSDIR/prefix-sim"
MIN_IOS=14.0
SDKPATH="$(xcrun --sdk iphonesimulator --show-sdk-path)" || {
	echo "ERROR: iphonesimulator SDK not found. Install full Xcode from the App Store,"
	echo "open it once to accept the license, then: sudo xcode-select -s /Applications/Xcode.app"
	exit 1
}
mkdir -p "$SRC" "$PREFIX"

CMFLAGS=(
	-DCMAKE_SYSTEM_NAME=iOS
	-DCMAKE_OSX_SYSROOT="$SDKPATH"
	-DCMAKE_OSX_ARCHITECTURES=arm64
	-DCMAKE_OSX_DEPLOYMENT_TARGET=$MIN_IOS
	-DCMAKE_INSTALL_PREFIX="$PREFIX"
	-DCMAKE_PREFIX_PATH="$PREFIX"
	-DBUILD_SHARED_LIBS=OFF
	-DCMAKE_C_FLAGS="-target arm64-apple-ios$MIN_IOS-simulator"
	-DCMAKE_BUILD_TYPE=Release
	-DCMAKE_POLICY_VERSION_MINIMUM=3.5
)

clone() { # name url tag
	[ -d "$SRC/$1" ] || git clone --depth 1 --branch "$3" "$2" "$SRC/$1"
}

cmbuild() { # name extra-flags...
	local name="$1"; shift
	echo "=== $name ==="
	cmake -S "$SRC/$name" -B "$SRC/$name/build-sim" "${CMFLAGS[@]}" "$@" >/dev/null
	cmake --build "$SRC/$name/build-sim" -j8 >/dev/null
	cmake --install "$SRC/$name/build-sim" >/dev/null
}

# ---- SDL2 + satellites ----
if [ ! -f "$PREFIX/lib/libSDL2.a" ]; then
	clone SDL https://github.com/libsdl-org/SDL.git release-2.30.9
	cmbuild SDL -DSDL_STATIC=ON -DSDL_SHARED=OFF -DSDL_TEST=OFF
fi
SDL2_HINTS=(-DSDL2_DIR="$PREFIX/lib/cmake/SDL2"
            -DSDL2_INCLUDE_DIR="$PREFIX/include/SDL2"
            -DSDL2_LIBRARY="$PREFIX/lib/libSDL2.a")
if [ ! -f "$PREFIX/lib/libSDL2_image.a" ]; then
	clone SDL_image https://github.com/libsdl-org/SDL_image.git release-2.8.2
	cmbuild SDL_image -DSDL2IMAGE_SAMPLES=OFF -DSDL2IMAGE_DEPS_SHARED=OFF "${SDL2_HINTS[@]}"
fi
if [ ! -f "$PREFIX/lib/libSDL2_ttf.a" ]; then
	clone SDL_ttf https://github.com/libsdl-org/SDL_ttf.git release-2.22.0
	(cd "$SRC/SDL_ttf" && git submodule update --init --depth 1 external/freetype)
	cmbuild SDL_ttf -DSDL2TTF_VENDORED=ON -DSDL2TTF_HARFBUZZ=OFF -DSDL2TTF_SAMPLES=OFF "${SDL2_HINTS[@]}"
fi

# ---- libpng (engine links it directly for PNG save/load) ----
if [ ! -f "$PREFIX/lib/libpng16.a" ]; then
	clone libpng https://github.com/pnggroup/libpng.git v1.6.43
	cmbuild libpng -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_TESTS=OFF -DPNG_TOOLS=OFF
fi

# ---- ogg + vorbis (music) ----
if [ ! -f "$PREFIX/lib/libogg.a" ]; then
	clone ogg https://github.com/xiph/ogg.git v1.3.5
	cmbuild ogg -DINSTALL_DOCS=OFF
fi
if [ ! -f "$PREFIX/lib/libvorbis.a" ]; then
	clone vorbis https://github.com/xiph/vorbis.git v1.3.7
	cmbuild vorbis -DOGG_LIBRARY="$PREFIX/lib/libogg.a" -DOGG_INCLUDE_DIR="$PREFIX/include"
fi

# ---- LuaJIT (interpreter-focused build for iOS; built out-of-tree copy so
#      the macOS build in tools/LuaJIT stays intact) ----
if [ ! -f "$PREFIX/lib/libluajit-sim.a" ]; then
	echo "=== LuaJIT (simulator) ==="
	rm -rf "$SRC/LuaJIT-sim"
	cp -r "$ROOT/tools/LuaJIT" "$SRC/LuaJIT-sim"
	export MACOSX_DEPLOYMENT_TARGET=12.0  # LuaJIT's Makefile insists, even cross-building
	make -C "$SRC/LuaJIT-sim" clean >/dev/null
	make -C "$SRC/LuaJIT-sim" -j8 DEFAULT_CC=clang \
		CROSS="$(dirname "$(xcrun --sdk iphonesimulator -f clang)")/" \
		TARGET_FLAGS="-isysroot $SDKPATH -target arm64-apple-ios$MIN_IOS-simulator" \
		TARGET_SYS=iOS amalg >/dev/null
	cp "$SRC/LuaJIT-sim/src/libluajit.a" "$PREFIX/lib/libluajit-sim.a"
fi

echo "OK: all simulator deps in $PREFIX"
ls "$PREFIX/lib"
