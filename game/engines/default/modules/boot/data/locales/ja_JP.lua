locale "ja_JP"
------------------------------------------------
section "mod-boot/class/Game.lua"

t("Welcome to T-Engine and the Tales of Maj'Eyal", "T-engineとマイ・イヤルの世界にようこそ", "_t")
t([[#GOLD#"Tales of Maj'Eyal"#WHITE# is the main game, you can also install more addons or modules by going to https://te4.org/

When inside a module remember you can press Escape to bring up a menu to change keybindings, resolution and other module specific options.

Remember that in most roguelikes death is usually permanent so be careful!

Now go and have some fun!]], [[　#GOLD#Tales of Maj'Eyal#WHITE#はメインのゲームです。他にもアドオンやモジュールをhttps://te4.org/でインストールできます。
モジュール内ではEscキーでメニューを呼び出してキーコンフィグや解像度、その他特定のオプションを変更できます。ローグライクゲームでは大抵の場合、死ねば取り返しがつきません。お気をつけて！
ではゲームをお楽しみください！]], "_t")
t("Upgrade to 1.0.5", "１．０．５における改善点", "_t")
t([[The way the engine manages saving has been reworked for v1.0.5.

The background saves should no longer lag horribly and as such it is highly recommended that you use the option. The upgrade turned it on for you.

For the same reason the save per level option should not be used unless you have severe memory problems. The upgrade turned it off for you.
]], [[　T-engineのセーブ方法が１．０．５で変更されました。
　バックグラウンドセーブで発生していた酷いラグは解消されたため、現在はこの設定を有効にしておいてください。アップデートにより、デフォルトで有効となっています。
　同じく、階層毎セーブは非推奨となりました。メモリ関連で深刻な問題が発生する場合に限り有効にしてください。アップデートにより、こちらはデフォルトで無効になっています。
]], "_t")
t("Safe Mode", "セーフモード", "_t")
t([[Oops! Either you activated safe mode manually or the game detected it did not start correctly last time and thus you are in #LIGHT_GREEN#safe mode#WHITE#.
Safe Mode disabled all graphical options and sets a low FPS. It is not advisable to play this way (as it will be very painful and ugly).

Please go to the Video Options and try enabling/disabling options and then restarting until you do not get this message.
A usual problem is shaders and thus should be your first target to disable.]], [[　おおっと！　セーフモードを手動で起動したか、前回ゲームがちゃんと起動しませんでしたね。
　現在#LIGHT_GREEN#セーフモード#WHITE#になっています。セーフモード中はグラフィック関係のオプションが全て無効になり、低ＦＰＳに設定されています。この状態でのプレイはお勧めできません（鬱陶しくて見栄えが悪いですからね）
　
　ビデオオプションの項目を色々切り替えて再起動してみてください。このメッセージが表示されなくなれば原因は解消されています。
　大抵はシェーダー関係が原因です。まずはシェーダー関連の項目を無効にしてみてください。]], "_t")
t("Message", "メッセージ", "_t")
t("Duplicate Addon", "アドオン複製", "_t")
t([[Oops! It seems like you have the same addon/dlc installed twice.
This is unsupported and would make many things explode. Please remove one of the copies.

Addon name: #YELLOW#%s#LAST#

Check out the following folder on your computer:
%s
%s
]], [[　同じアドオンかＤＬＣを２回インストールしてしまったようです。
　こうした動作はサポートしておらず、様々な問題を引き起こしかねません。どちらかを削除してください。

　問題のアドオン：#YELLOW#%s#LAST#

　パソコンの以下のフォルダを開いてみて下さい。
%s
%s
]], "_t")
t("Updating addon: #LIGHT_GREEN#%s", "アドオンアップデート：#LIGHT_GREEN#%s", "tformat")
t("Quit", "出る", "_t")
t("Really exit T-Engine/ToME?", "T-Engine／ToMEを終了しますか？", "_t")
t("Continue", "続行", "_t")
t([[Welcome to #LIGHT_GREEN#Tales of Maj'Eyal#LAST#!

Before you can start dying in many innovative ways we need to ask you about online play.

This is a #{bold}#single player game#{normal}# but it also features many online features to enhance your gameplay and connect you to the community:
* Play from several computers without having to copy unlocks and achievements.
* Talk ingame to other fellow players, ask for advice, share your most memorable moments...
* Keep track of your kill count, deaths, most played classes...
* Cool statistics for to help sharpen your gameplay style
* Install official expansions and third-party addons directly from the game, hassle-free
* Access your purchaser / donator bonuses if you have bought the game or donated on https://te4.org/
* Help the game developers balance and refine the game

You will also have a user page on #LIGHT_BLUE#https://te4.org/#LAST# to show off to your friends.
This is all optional, you are not forced to use this feature at all, but the developer would thank you if you did as it will make balancing easier.]], [[　#LIGHT_GREEN#Tales of Maj'Eyal#LAST#の世界にようこそ！

　数々の独創的な死に様を遂げる前に、オンラインでのプレイをお勧めします。
　
　このゲームは#{bold}#一人用#{normal}#ですが、様々なオンライン要素が組み込まれています。ゲームプレイを盛り上げ、コミュニティに参加できます。
　
・アンロックや実績解除をコピーすることなく、別のパソコンでも遊べます。
・ゲーム中でお友達とチャットしたり、攻略を聞いたり、決定的瞬間をシェアしたり・・・
・キルカウント、死亡回数、お気に入りクラスなどの記録
・ゲームプレイスタイルの参考となるプレイ統計
・公式ＤＬＣやサードパーティーアドオンをゲーム内で楽々インストール
・購入者・寄付者特典にhttps://te4.org/でアクセス
・開発者へのフィードバックでゲームバランス向上に貢献

　#LIGHT_BLUE#https://te4.org/#LAST#にもユーザーページーがあり、お友達にキャラクターのお披露目も。
　あくまでも追加要素的なものですから、無理に利用しなくても構いません。ですが、開発者として使っていただけるとバランス調整が大変助かります。]], "_t")
t("Logging in...", "　ログイン中・・・", "_t")
t("Please wait...", "お待ちください・・・", "_t")
t("Profile logged in!", "プロフィールログイン！", "_t")
t("Your online profile is now active. Have fun!", "　オンラインプロフィールが有効になりました！　ゲームをお楽しみください！", "_t")
t("Login failed!", "ログイン失敗！", "_t")
t("Check your login and password or try again in in a few moments.", "　ユーザー名とパスワードが正しいか確認してください。もしくは少し待ってからまた試してください。", "_t")
t("Registering...", "登録中・・・", "_t")
t("Registering on https://te4.org/, please wait...", "https://te4.org/に登録中。お待ちください・・・", "_t")
t("Logged in!", "ログイン！", "_t")
t("Profile created!", "プロフィール作成！", "_t")
t("Profile creation failed!", "プロフィール作成失敗！", "_t")
t("Creation failed: %s (you may also register on https://te4.org/)", "　作成に失敗しました。: %s（https://te4.org/でも登録できます）", "tformat")
t("Try again in in a few moments, or try online at https://te4.org/", "　数分待ってまた試してみて下さい。https://te4.org/でも登録できます。", "_t")

------------------------------------------------
section "mod-boot/class/Player.lua"

t("%s available", "%s 使用可能", "tformat")
t("#00ff00#Talent %s is ready to use.", "#00ff00#%sが使えるようになった。", "log")
t("LEVEL UP!", "レベルアップ！", "_t")

------------------------------------------------
section "mod-boot/data/birth/descriptors.lua"

t("base", "ベース", "birth descriptor name")
t("Destroyer", "破壊者", "birth descriptor name")
t("Acid-maniac", "アシッドマニア", "birth descriptor name")

------------------------------------------------
section "mod-boot/data/damage_types.lua"

t("Kill!", "キル！", "_t")

------------------------------------------------
section "mod-boot/data/general/grids/basic.lua"

t("floor", "床", "entity type")
t("floor", "床", "entity subtype")
t("floor", "床", "entity name")
t("wall", "壁", "entity type")
t("wall", "壁", "entity name")
t("door", "扉", "entity name")
t("open door", "開いた扉", "entity name")

------------------------------------------------
section "mod-boot/data/general/grids/forest.lua"

t("floor", "床", "entity type")
t("grass", "草地", "entity subtype")
t("grass", "草地", "entity name")
t("wall", "壁", "entity type")
t("tree", "木", "entity name")
t("flower", "花", "entity name")

------------------------------------------------
section "mod-boot/data/general/grids/underground.lua"

t("wall", "壁", "entity type")
t("underground", "地底", "entity subtype")
t("crystals", "クリスタル", "entity name")
t("floor", "床", "entity type")
t("floor", "床", "entity name")

------------------------------------------------
section "mod-boot/data/general/grids/water.lua"

t("floor", "床", "entity type")
t("water", "水", "entity subtype")
t("deep water", "海底", "entity name")

------------------------------------------------
section "mod-boot/data/general/npcs/canine.lua"

t("animal", "動物", "entity type")
t("canine", "犬", "entity subtype")
t("wolf", "オオカミ", "entity name")
t("Lean, mean, and shaggy, it stares at you with hungry eyes.", "　痩せこけて、みすぼらしく毛羽立った狼だ。飢えた目でこちらを凝視している。", "_t")
t("white wolf", "白狼", "entity name")
t("A large and muscled wolf from the northern wastes. Its breath is cold and icy and its fur coated in frost.", "　がっしりと大柄な狼だ。北の荒れ地に生息している。吐く息は白く冷たく、毛皮は霜に覆われている。", "_t")
t("warg", "ワーグ", "entity name")
t("It is a large wolf with eyes full of cunning.", "　巨大な狼だ。非常に狡賢そうな目をしている。", "_t")
t("fox", "キツネ", "entity name")
t("The quick brown fox jumps over the lazy dog.", "　「すばしっこい茶色の狐はのろまな犬を飛び越える」", "_t")

------------------------------------------------
section "mod-boot/data/general/npcs/skeleton.lua"

t("undead", "不死者", "entity type")
t("skeleton", "スケルトン", "entity subtype")
t("degenerated skeleton warrior", "半壊スケルトン戦士", "entity name")
t("skeleton warrior", "スケルトン戦士", "entity name")
t("skeleton mage", "スケルトンメイジ", "entity name")
t("armoured skeleton warrior", "武装スケルトン戦士", "entity name")

------------------------------------------------
section "mod-boot/data/general/npcs/troll.lua"

t("giant", "ジャイアント", "entity type")
t("troll", "トロル", "entity subtype")
t("forest troll", "森トロル", "entity name")
t("Green-skinned and ugly, this massive humanoid glares at you, clenching wart-covered green fists.", "　緑色の肌をした醜い巨大な人型生物がこちらを見ている。肌と同じ色をしたイボだらけの拳を固く握り締めている。", "_t")
t("stone troll", "岩トロル", "entity name")
t("A giant troll with scabrous black skin. With a shudder, you notice the belt of dwarf skulls around his massive waist.", "　ざらざらとした黒い肌の巨大トロルだ。恐ろしいことに、その太い腰にはドワーフの頭蓋骨を繋いで作ったベルトが巻かれている。", "_t")
t("cave troll", "洞窟トロル", "entity name")
t("This huge troll wields a massive spear and has a disturbingly intelligent look in its piggy eyes.", "　大槍を持った巨大トロルだ。豚のような目にもどこか知性が窺える。", "_t")
t("mountain troll", "山トロル", "entity name")
t("A large and athletic troll with an extremely tough and warty hide.", "　巨大で頑健なトロルだ。並外れて打たれ強く、肌はイボだらけだ。", "_t")
t("mountain troll thunderer", "轟雷山トロル", "entity name")

------------------------------------------------
section "mod-boot/data/talents.lua"

t("misc", "雑具", "talent category")
t("Kick", "キック", "talent name")
t("Acid Spray", "アシッドスプレー", "talent name")
t("Manathrust", "マナスラスト", "talent name")
t("Flame", "フレイム", "talent name")
t("Fireflash", "ファイアフラッシュ", "talent name")
t("Lightning", "ライトニング", "talent name")
t("Sunshield", "サンシールド", "talent name")
t("Flameshock", "フレイムショック", "talent name")

------------------------------------------------
section "mod-boot/data/timed_effects.lua"

t("Burning from acid", "酸焼け", "_t")
t("#Target# is covered in acid!", "#Target#は酸を浴びた！", "_t")
t("+Acid", "+酸", "_t")
t("#Target# is free from the acid.", "#Target#から酸毒が消えた。", "_t")
t("-Acid", "-酸", "_t")
t("Sunshield", "サンシールド", "_t")

------------------------------------------------
section "mod-boot/data/zones/dungeon/zone.lua"

t("Forest", "森", "_t")

------------------------------------------------
section "mod-boot/dialogs/Addons.lua"

t("Configure Addons", "アドオン構成", "_t")
t("You can get new addons at #LIGHT_BLUE##{underline}#Te4.org Addons#{normal}#", "#LIGHT_BLUE##{underline}#Te4.org Addons#{normal}#で新たなアドオンを入手できます。", "_t")
t(" and #LIGHT_BLUE##{underline}#Te4.org DLCs#{normal}#", " and #LIGHT_BLUE##{underline}#Te4.orgのDLC#{normal}#", "_t")
t("You can get new addons on #LIGHT_BLUE##{underline}#Steam Workshop#{normal}#", "#LIGHT_BLUE##{underline}#Steam Workshop#{normal}#で新たなアドオンを入手できます。", "_t")
t(", #LIGHT_BLUE##{underline}#Te4.org Addons#{normal}#", ", #LIGHT_BLUE##{underline}#Te4.orgのアドオン#{normal}#", "_t")
t("Show incompatible", "互換性のないものを表示", "_t")
t("Auto-update on start", "スタート時に自動アップデート", "_t")
t("Game Module", "ゲームモジュール", "_t")
t("Version", "バージョン", "_t")
t("Addon", "アドオン", "_t")
t("Active", "状態", "_t")
t("#GREY#Developer tool", "#GREY#開発者ツール", "_t")
t("#LIGHT_RED#Donator Status: Disabled", "#LIGHT_RED#寄付者特典：無効", "_t")
t("#LIGHT_GREEN#Manual: Active", "#LIGHT_GREEN#手動：有効", "_t")
t("#LIGHT_RED#Manual: Disabled", "#LIGHT_RED#手動：無効", "_t")
t("#LIGHT_GREEN#Auto: Active", "#LIGHT_GREEN#自動：有効", "_t")
t("#LIGHT_RED#Auto: Incompatible", "#LIGHT_RED#自動：非互換", "_t")
t("Addon Version", "アドオンバージョン", "_t")
t("Game Version", "ゲームバージョン", "_t")

------------------------------------------------
section "mod-boot/dialogs/Credits.lua"

t("Project Lead", "プロジェクトリーダー", "_t")
t("Lead Coder", "プログラムリーダー", "_t")
t("World Builders", "マップ担当", "_t")
t("Graphic Artists", "グラフィックアーティスト", "_t")
t("Expert Shaders Design", "シェーダーデザイン", "_t")
t("Soundtracks", "サウンドトラック", "_t")
t("Sound Designer", "サウンドデザイナー", "_t")
t("Lore Creation and Writing", "ストーリー文書考案・作成", "_t")
t("Code Heroes", "プログラム関係でご協力頂いた方々", "_t")
t("Community Managers", "コミュニティ管理者", "_t")
t("Text Editors", "テキスト編集", "_t")
t("Chinese Translation Lead", "中国語訳担当リーダー", "_t")
t("Chinese Translators", "中国語訳スタッフ", "_t")
t("Korean Translation", "韓国語訳スタッフ", "_t")
t("Japanese Translation", "日本語訳スタッフ", "_t")
t("The Community", "コミュニティ", "_t")
t("Others", "そのほかご協力頂いた方々", "_t")

------------------------------------------------
section "mod-boot/dialogs/FirstRun.lua"

t("Welcome to Tales of Maj'Eyal", "Tales of Maj'Eyalにようこそ", "_t")
t("Register now!", "登録！", "_t")
t("Login existing account", "既存のアカウントでログイン", "_t")
t("Maybe later", "今はやめておく", "_t")
t("#RED#Disable all online features", "#RED#オンライン要素を全て無効化", "_t")
t("Disable all connectivity", "接続を全遮断", "_t")
t([[You are about to disable all connectivity to the network.
This includes, but is not limited to:
- Player profiles: You will not be able to login, register
- Characters vault: You will not be able to upload any character to the online vault to show your glory
- Item's Vault: You will not be able to access the online item's vault, this includes both storing and retrieving items.
- Ingame chat: The ingame chat requires to connect to the server to talk to other players, this will not be possible.
- Purchaser / Donator benefits: The base game being free, the only way to give donators their bonuses fairly is to check their online profile. This will thus be disabled.
- Easy addons downloading & installation: You will not be able to see ingame the list of available addons, nor to one-click install them. You may still do so manually.
- Version checks: Addons will not be checked for new versions.
- Discord: If you are a Discord user, Rich Presence integration will also be disabled by this setting.
- Ingame game news: The main menu will stop showing you info about new updates to the game.

#{bold}##CRIMSON#This is an extremely restrictive setting. It is recommended you only activate it if you have no other choice as it will remove many fun and acclaimed features.#{normal}#

If you disable this option you can always re-activate it in the Online category of the Game Options menu later on.]], [[　ネットワークへの接続を全て遮断しようとしています。
　これを実行すると以下の機能が無効になります（他にも無効化される機能があります）
　
・プレイヤープロフィール：ログインと登録ができなくなります。
・キャラクター展覧場：キャラクターをアップロードして栄光の軌跡を披露できません。
・オンライン保管庫：オンライン保管庫にアイテムを預けられません。引き出すのも無理です。
・ゲームチャット：サーバーに接続できませんから利用不可能です。
・購入者・寄付者特典：このゲームは基本無料で、寄付者がきちんと特典に与るにはオンラインプロフィールへのアクセスが必要です。これができなくなります。
・アドオンの手軽なＤＬ・インストール：ゲーム内の利用可能なアドオンリストが見られません。クリック一つでインストールするのも。ご自分でインストールする必要が出てくるでしょう。
・バージョンチェック：各アドオンのバージョンアップが確認されなくなります。
・Discord：Rich Presence機能がこの設定によって無効になります。
・ゲーム内ニュース：メインメニューでこのゲームのアップデート情報が表示されなくなります。

#{bold}##CRIMSON#　これは極めて制限のかかる設定です。他にどうしようもない時にだけ有効にしてください。大人気要素を大幅に削ぐことになります。#{normal}#
　この機能を無効しても、後からゲームオプションのオンライン項目でいつでも有効に戻せます。]], "_t")
t("Cancel", "キャンセル", "_t")
t("#RED#Disable all!", "#RED#無効にする！", "_t")

------------------------------------------------
section "mod-boot/dialogs/LoadGame.lua"

t("Load Game", "ロードゲーム", "_t")
t("Show older versions", "古いバージョン一覧", "_t")
t("Ignore unloadable addons", "ロード不可なアドオンを無視", "_t")
t("  Play!  ", "  プレイ！  ", "_t")
t("Delete", "削除", "_t")
t([[#{bold}##GOLD#%s: %s#WHITE##{normal}#
Game version: %d.%d.%d
Requires addons: %s

%s]], [[#{bold}##GOLD#%s: %s#WHITE##{normal}#
ゲームバージョン：%d.%d.%d
必要アドオン：%s

%s]], "tformat")
t("You can simply grab an older version of the game from where you downloaded it.", "　ダウンロード元から古いバージョンを持ってきても構いません。", "_t")
t("You can downgrade the version by selecting it in the Steam's \"Beta\" properties of the game.", "　Steamにおけるこのゲームの「ベータ版」を選択すればダウングレードできます。", "_t")
t("Original game version not found", "オリジナルのバージョンが見つかりませんでした。", "_t")
t([[This savefile was created with game version %s. You can try loading it with the current version if you wish but it is recommended you play it with the old version to ensure compatibility
%s]], [[　このセーブファイルはバージョン%sのものです。今のバージョンでロードしてみてもいいですが、互換性が保証されないため古いバージョンのデータをロードするのは非推奨です。
%s]], "tformat")
t("Cancel", "キャンセル", "_t")
t("Run with newer version", "新バージョンでロード", "_t")
t("Developer Mode", "開発者用モード", "_t")
t("#LIGHT_RED#WARNING: #LAST#Loading a savefile while in developer mode will permanently invalidate it. Proceed?", "#LIGHT_RED#WARNING: #LAST#開発者用モードでロードしたセーブデータは永久的に不正なデータとなります。それでもロードしますか？", "_t")
t("Load anyway", "とにかくロードする", "_t")
t("Delete savefile", "セーブファイル削除", "_t")
t("Really delete #{bold}##GOLD#%s#WHITE##{normal}#", "　本当に#{bold}##GOLD#%s#WHITE##{normal}#を削除しますか？", "tformat")
t("Old game data", "古いバージョン", "_t")
t("No data available for this game version.", "　このバージョンに対応するデータはありません。", "_t")
t("Downloading old game data: #LIGHT_GREEN#", "　古いバージョンのダウンロード：#LIGHT_GREEN#", "_t")
t("Old game data for %s correctly installed. You can now play.", "%sに対応するバージョンを問題なくインストールしました。これでプレイできます。", "tformat")
t("Failed to install.", "インストール失敗", "_t")

------------------------------------------------
section "mod-boot/dialogs/MainMenu.lua"

t("Main Menu", "メインメニューへ", "_t")
t("New Game", "ニューゲーム", "_t")
t("Load Game", "ロードゲーム", "_t")
t("Addons", "アドオン", "_t")
t("Options", "オプション", "_t")
t("Game Options", "ゲームオプション", "_t")
t("Credits", "クレジット", "_t")
t("Exit", "出る", "_t")
t("Reboot", "再起動", "_t")
t("Disable animated background", "背景のアニメを切る", "_t")
t("#{bold}##B9E100#T-Engine4 version: %d.%d.%d", "#{bold}##B9E100#T-Engine4のバージョン: %d.%d.%d", "tformat")
t([[#{bold}##GOLD#Ashes of Urh'Rok - Expansion#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#Many in Maj'Eyal have heard of "demons", sadistic creatures who appear seemingly from nowhere, leaving a trail of suffering and destruction wherever they go.#{normal}##LAST#

#{bold}#Features#{normal}#:
#LIGHT_UMBER#New class:#WHITE# Doombringers. These avatars of demonic destruction charge into battle with massive two-handed weapons, cutting swaths of firey devastation through hordes of opponents. Armed with flame magic and demonic strength, they delight in fighting against overwhelming odds
#LIGHT_UMBER#New class:#WHITE# Demonologists. Bearing a shield and the magic of the Spellblaze itself, these melee-fighting casters can grow demonic seeds from their fallen enemies. Imbue these seeds onto your items to gain a wide array of new talents and passive benefits, and summon the demons within them to fight!
#LIGHT_UMBER#New race:#WHITE# Doomelves. Shalore who've taken to the demonic alterations especially well, corrupting their typical abilities into a darker form.
#LIGHT_UMBER#New artifacts, lore, zones, events...#WHITE# For your demonic delight!

]], [[#{bold}##GOLD#ＤＬＣ・デーモンの贖罪#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#　マイ・イヤルでは誰もが「デーモン」の話を耳にします。凶悪な生物で、どこから来るのか判っていません。どこであろうと痛ましい破壊を繰り広げる存在です。#{normal}##LAST#

#{bold}#特色#{normal}#:
・#LIGHT_UMBER#新クラス：#WHITE#ドゥームブリンガー　デーモン達の破壊の化身たるこのクラスは巨大な両手武器を手に戦場に繰り出し、敵勢を炎で焼いて薙ぎ払います。火炎魔法と狂暴なパワーを有し、不利な戦いにも揚々と挑む戦士です。
・#LIGHT_UMBER#新クラス：#WHITE#デモノロジスト　盾を構え、かの魔法大禍の力を備えた近接系の魔法使いです。敵の死体を利用してデーモンの種子を育てます。そうして入手したデーモンシードを装備に埋め込んで、様々タレントやパッシブ効果を得られます。それにデーモン召喚も！
・#LIGHT_UMBER#新種族：#WHITE#ドゥームエルフ　彼らは完全にデーモン化したシャローレです。元来の能力が邪悪なものに変容しています。
・#LIGHT_UMBER#新アーティファクト、ストーリー文書、ゾーン、イベント・・・#WHITE#殺戮を楽しみましょう！

]], "_t")
t("#LIGHT_GREEN#Installed", "#LIGHT_GREEN#インストール済み", "_t")
t("#YELLOW#Not installed - Click to download / purchase", "#YELLOW#クリックでダウンロード／購入", "_t")
t([[#{bold}##GOLD#Embers of Rage - Expansion#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#One year has passed since the one the Orcs call the "Scourge from the West" came and single-handedly crushed the Orc Prides of Grushnak, Vor, Gorbat, and Rak'Shor.  The Allied Kingdoms, now linked by farportal to their distant, long-lost Sunwall allies, have helped them conquer most of Var'Eyal.  The few remnants of the ravaged Prides are caged...  but one Pride remains.#{normal}##LAST#

#{bold}#Features#{normal}#:
#LIGHT_UMBER#A whole new campaign:#WHITE# Set one year after the events of the main game, the final destiny of the Orc Prides is up to you. Discover the Far East like you never knew it. 
#LIGHT_UMBER#New classes:#WHITE# Sawbutchers, Gunslingers, Psyshots, Annihilators and Technomanchers. Harness the power of steam to power deadly contraptions to lay waste to all those that oppose the Pride!  
#LIGHT_UMBER#New races:#WHITE# Orcs, Yetis, Whitehooves. Discover the orcs and their unlikely 'allies' as you try to save your Pride from the disasters caused by the one you call 'The Scourge from the West'.
#LIGHT_UMBER#Tinker system:#WHITE# Augment your items with powerful crafted tinkers. Attach rockets to your boots, gripping systems to your gloves and many more.
#LIGHT_UMBER#Salves:#WHITE# Bound to the tinker system, create powerful medical salves to inject into your skin, replacing the infusions§runes system.
#LIGHT_UMBER#A ton#WHITE# of artifacts, lore, zones, events... 

]], [[#{bold}##GOLD#ＤＬＣ・憤怒の残火#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#　オークたちが「西の災厄」と呼ぶ者が単身で四部族を滅ぼしました。それから１年。連合王国は大ポータルを介して「太陽の壁」と交流しています。遥か昔に離れ離れとなった同胞が、ヴァル・イヤル全土を制圧するように力を貸しているのです。僅かに残ったオークの残党は捕虜になっています・・・ですがまだ部族が一つ、残っているのです。#{normal}##LAST#

#{bold}#特色#{normal}#:
#LIGHT_UMBER#完全新キャンペーン：#WHITE#メインキャンペーンの１年後の話となります。オークという種族の命運はあなたの背に。一新された東方世界を探索しましょう。 
#LIGHT_UMBER#新クラス：#WHITE#ブッチャー、ガンナー、サイコガンナー、アナイアレーター、魔工学士。蒸気の力を制御して強烈な兵器を操り、オークに仇為す者たちを殲滅！  
#LIGHT_UMBER#新種族：#WHITE#オーク、イエティ、白蹄族。「西の災厄」が引き起こした惨事より仲間たちを守りつつ、オークの数少ない「輩」を見出しましょう。
#LIGHT_UMBER#工士アイテム：#WHITE#強力な工士アイテムを作成して装備品を強化します。ブーツにロケット噴射装置を組み込んだり、グローブに拘束機能を追加したり、そのほかにもいろいろ。
#LIGHT_UMBER#軟膏：#WHITE#工士アイテムに関連します。強力な医療軟膏を作成して注射し、ハーブ物やルーンの代わりに活用します。
#LIGHT_UMBER#大量の#WHITE#アーティファクト、ストーリー文書、ゾーン、イベント・・・ 

]], "_t")
t([[#{bold}##GOLD#Forgotten Cults - Expansion#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#Not all adventurers seek fortune, not all that defend the world have good deeds in mind. Lately the number of sightings of horrors have grown tremendously. People wander off the beaten paths only to be found years later, horribly mutated and partly insane, if they are found at all. It is becoming evident something is stirring deep below Maj'Eyal. That something is you.#{normal}##LAST#

#{bold}#Features#{normal}#:
#LIGHT_UMBER#New class:#WHITE# Writhing Ones. Give in to the corrupting forces and turn yourself gradually into an horror, summon horrors to do your bidding, shed your skin and melt your face to assault your foes. With your arm already turned into a tentacle, what creature can stop you?
#LIGHT_UMBER#New class:#WHITE# Cultists of Entropy. Using its insanity and control of entropic forces to unravel the normal laws of physic this caster class can turn healing into attacks and call upon the forces of the void to reduce its foes to dust.
#LIGHT_UMBER#New race:#WHITE# Drems. A corrupt subrace of dwarves, that somehow managed to keep a shred of sanity to not fully devolve into mindless horrors. They can enter a frenzy and even learn to summon horrors.
#LIGHT_UMBER#New race:#WHITE# Krogs. Ogres transformed by the very thing that should kill them. Their powerful attacks can stun their foes and they are so strong they can dual wield any one handed weapons.
#LIGHT_UMBER#Many new zones:#WHITE# Explore the Scourge Pits, fight your way out of a giant worm (don't ask how you get *in*), discover the wonders of the Occult Egress and many more strange and tentacle-filled zones!
#LIGHT_UMBER#New horrors:#WHITE# You liked radiant horrors? You'll love searing horrors! And Nethergames. And Entropic Shards. And ... more
#LIGHT_UMBER#Sick of your own head:#WHITE#  Replace it with a nice cozy horror!
#LIGHT_UMBER#A ton#WHITE# of artifacts, lore, events... 

]], [[#{bold}##GOLD#ＤＬＣ・禁忌に触れしモノ達#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#　冒険者が皆、富を求めるわけではありません。同様に、世界を救う者が善良な人物とは限らないのです。近年、おぞましい怪物の目撃例が急増しています。人通りの無い場所に足を踏み入れた者は何年にも渡って行方知れずになり、見つかった時には変わり果てた姿で半ば正気を失っています。それもきちんと発見されればの話です。マイ・イヤルの地底で何かが暗躍しているようです。その「何か」とはつまりあなたのこと。#{normal}##LAST#

#{bold}#特色#{normal}#:
#LIGHT_UMBER#新クラス：#WHITE#ミュータント　悪しき力に身を任せ、怪物へと徐々に身を変じていきます。ホラーを召喚し、脱皮したり顔をグズグズに溶かしたりして敵を襲います。片腕は既に触手になっており、誰も貴方を止められません。 
#LIGHT_UMBER#新クラス：#WHITE#エントロピーカルト　狂気の力を利用してエントロピーを操作し、世の常なる物理法則を破壊します。このクラスは癒しの力を攻撃に転じ、虚空の力で敵を塵に変えます。
#LIGHT_UMBER#新種族：#WHITE#ドレム　変容したドワーフです。まともな意識は残っており、完全な怪物というわけではありません。クールダウンを無視できる他、化物を召喚できるようになります。
#LIGHT_UMBER#新種族：#WHITE#クログ　彼らは元はオーガでした。本来なら彼らを抹殺するであろう者たちがオーガを改造したのです。強力な攻撃で敵をスタンさせ、片手武器なら何でも二刀流できます。
#LIGHT_UMBER#新ゾーン：#WHITE#変異竜の巣窟を駆け、巨大ワームの体内から脱出（どうやって「入る」のかは聞かないで）「彼方への道」に隠された秘密を暴き、触手だらけのマップへ！
#LIGHT_UMBER#新ホラー：#WHITE#ラディアントホラーは気に入って頂けましたね？　ではシアリングホラーを好きになってくれるはず！　おまけにネザーゲートも！　さらにエントロピー断片！　もひとつおまけに・・・
#LIGHT_UMBER#そろそろこの顔にも飽きてきたなあ#WHITE#：体に馴染む素敵な寄生体に頭を挿げ替えましょう！
#LIGHT_UMBER#膨大な#WHITE#アーティファクト、ストーリー文書、イベント・・・ 

]], "_t")
t("#GOLD#Online Profile", "#GOLD#オンラインプロフィール", "_t")
t("Login", "ログイン", "_t")
t("Register", "登録", "_t")
t("Username: ", "ユーザー名： ", "_t")
t("Password: ", "パスワード：", "_t")
t("Login with Steam", "Steamでログイン", "_t")
t("#GOLD#Online Profile#WHITE#", "#GOLD#オンラインプロフィール#WHITE#", "_t")
t("#LIGHT_BLUE##{underline}#Logout", "#LIGHT_BLUE##{underline}#ログアウト", "_t")
t("Username", "ユーザー名", "_t")
t("Your username is too short", "ユーザー名が短すぎます", "_t")
t("Password", "パスワード", "_t")
t("Your password is too short", "パスワードが短すぎます", "_t")
t("Login...", "ログイン", "_t")
t("Logging in your account, please wait...", "　登録したアカウントにログインしています。しばらくお待ちください・・・", "_t")
t("Steam client not found.", "Steamのクライアントが見つかりません。", "_t")
-- untranslated text
--[==[
t("#LIGHT_BLUE##{underline}#%s#LAST##{normal}#", "#LIGHT_BLUE##{underline}#%s#LAST##{normal}#", "tformat")
--]==]


------------------------------------------------
section "mod-boot/dialogs/NewGame.lua"

t("New Game", "ニューゲーム", "_t")
t("Show all versions", "全バージョン表示", "_t")
t("Show incompatible", "互換性のないものを表示", "_t")
t([[You can get new games at
#LIGHT_BLUE##{underline}#https://te4.org/games#{normal}#]], "　#LIGHT_BLUE##{underline}#https://te4.org/games#{normal}#で最新のバージョンをＤＬできます。", "_t")
t("Game Module", "ゲームモジュール", "_t")
t("Version", "バージョン", "_t")
t("Enter your character's name", "キャラクター名を入力", "_t")
t("Overwrite character?", "上書きしますか？", "_t")
t("There is already a character with this name, do you want to overwrite it?", "　この名前のキャラクターはもういます。上書きしますか？", "_t")
t("No", "やめておく", "_t")
t("Yes", "実行する", "_t")
t("This game is not compatible with your version of T-Engine, you can still try it but it might break.", "　現行のT-Engineとバージョンが合いません。プレイしてもいいですが不具合が起こる可能性も。", "_t")

------------------------------------------------
section "mod-boot/dialogs/Profile.lua"

t("Player Profile", "プレイヤープロファイル", "_t")
t("Logout", "ログアウト", "_t")
t("You are logged in", "ログインしています", "_t")
t("Do you want to log out?", "ログアウトしますか？", "_t")
t("Log out", "ログアウト", "_t")
t("Cancel", "キャンセル", "_t")
t("Login", "ログイン", "_t")
t("Create Account", "アカウント作成", "_t")

------------------------------------------------
section "mod-boot/dialogs/ProfileLogin.lua"

t("Online profile ", "オンラインプロフィール ", "_t")
t("Username: ", "ユーザー名： ", "_t")
t("Password: ", "パスワード：", "_t")
t("Login", "ログイン", "_t")
t("Cancel", "キャンセル", "_t")
t("Password again: ", "パスワード確認： ", "_t")
t("Email: ", "Email：", "_t")
t("Accept to receive #{bold}#very infrequent#{normal}# (a few per year) mails about important game events from us.", "　#{bold}#たまに#{normal}#届く重要なゲームイベントについてのメールを受け取る（年に数回です）", "_t")
t("You at least 16 years old, or have parental authorization to play the game.", "　１６歳以上か、このゲームをプレイするのに保護者の同意を得ていますか？", "_t")
t("Create", "作成", "_t")
t("Privacy Policy (opens in browser)", "プライバシーポリシー（ブラウザで開きます）", "_t")
t("Password", "パスワード", "_t")
t("Password mismatch!", "パスワードが違っています！", "_t")
t("Username", "ユーザー名", "_t")
t("Your username is too short", "ユーザー名が短すぎます", "_t")
t("Your password is too short", "パスワードが短すぎます", "_t")
t("Email", "メール", "_t")
t("Your email seems invalid", "無効なメールアドレスです。", "_t")
t("Age Check", "年齢確認", "_t")
t("You need to be 16 years old or more or to have parental authorization to play this game.", "　１６歳以上か、このゲームをプレイするのに保護者の同意を得ていますか？", "_t")

------------------------------------------------
section "mod-boot/dialogs/ProfileSteamRegister.lua"

t("Steam User Account", "Steamユーザーアカウント", "_t")
t([[Welcome to #GOLD#Tales of Maj'Eyal#LAST#.
To enjoy all the features the game has to offer it is #{bold}#highly#{normal}# recommended that you register your steam account.
Luckily this is very easy to do: you only require a profile name and optionally an email (we send very few email, maybe two a year at most).
]], [[　#GOLD#Tales of Maj'Eyal#LAST#の世界にようこそ。
　このゲームの要素を遊び尽くすには、#{bold}#是非#{normal}#Steamのアカウントを登録を。幸いにもとても簡単な作業です。プロフィール名があれば良く、メールアドレスの登録は任意となっております（年にせいぜい２回程度メールを送ります）
]], "_t")
t("Username: ", "ユーザー名： ", "_t")
t("Email: ", "Email：", "_t")
t("Accept to receive #{bold}#very infrequent#{normal}# (a few per year) mails about important game events from us.", "　#{bold}#たまに#{normal}#届く重要なゲームイベントについてのメールを受け取る（年に数回です）", "_t")
t("You at least 16 years old, or have parental authorization to play the game.", "　１６歳以上か、このゲームをプレイするのに保護者の同意を得ていますか？", "_t")
t("Register", "登録", "_t")
t("Cancel", "キャンセル", "_t")
t("Privacy Policy (opens in browser)", "プライバシーポリシー（ブラウザで開きます）", "_t")
t("Username", "ユーザー名", "_t")
t("Your username is too short", "ユーザー名が短すぎます", "_t")
t("Email", "メール", "_t")
t("Your email does not look right.", "メールアドレスが正しくないようです。", "_t")
t("Age Check", "年齢確認", "_t")
t("You need to be 16 years old or more or to have parental authorization to play this game.", "　１６歳以上か、このゲームをプレイするのに保護者の同意を得ていますか？", "_t")
t("Registering...", "登録中・・・", "_t")
t("Registering on https://te4.org/, please wait...", "https://te4.org/に登録中。お待ちください・・・", "_t")
t("Steam client not found.", "Steamのクライアントが見つかりません。", "_t")
t("Error", "エラー", "_t")
t("Username or Email already taken, please select an other one.", "　ユーザー名かメールアドレスが既に使われているものです。別のを試してください。", "_t")

------------------------------------------------
section "mod-boot/dialogs/UpdateAll.lua"

t("Update all game modules", "全ゲームモジュールをアップデート", "_t")
t([[All those components will be updated:
]], [[　これらのコンポーネントを全てアップデートします：
]], "_t")
t("Component", "コンポーネント", "_t")
t("Version", "バージョン", "_t")
t("Nothing to update", "アップデート不要", "_t")
t("All your game modules are up to date.", "　ゲームモジュールは全て最新版です。", "_t")
t("Game: #{bold}##GOLD#", "ゲーム：#{bold}##GOLD#", "_t")
t("Engine: #{italic}##LIGHT_BLUE#", "エンジン：#{italic}##LIGHT_BLUE#", "_t")
t("Error!", "エラー発生！", "_t")
t([[There was an error while downloading:
]], [[　ダウンロード中にエラーが発生しました：
]], "_t")
t("Downloading: ", "ダウンロード：", "_t")
t("Update", "アップデート", "_t")
t("All updates installed, the game will now restart", "　アップデートが全て終了しました。ゲームを再起動します。", "_t")

------------------------------------------------
section "mod-boot/dialogs/ViewHighScores.lua"

t("View High Scores", "ハイスコア閲覧", "_t")
t("Game Module", "ゲームモジュール", "_t")
t("Version", "バージョン", "_t")
t("World", "ワールド", "_t")
t([[#{bold}##GOLD#%s#GREEN# High Scores#WHITE##{normal}#

]], [[#{bold}##GOLD#%s#GREEN#ハイスコア#WHITE##{normal}#

]], "tformat")
t([[#{bold}##GOLD#%s(%s)#GREEN# High Scores#WHITE##{normal}#

]], [[#{bold}##GOLD#%s(%s)#GREEN#ハイスコア#WHITE##{normal}#

]], "tformat")

------------------------------------------------
section "mod-boot/init.lua"

t("Tales of Maj'Eyal Main Menu", "メインメニュー", "init.lua long_name")
t([[Bootmenu!
]], [[　ブートメニュー！
]], "init.lua description")

------------------------------------------------
section "mod-boot/load.lua"

t("Strength", "腕力", "stat name")
t("str", "腕力", "stat short_name")
t("Dexterity", "機敏", "stat name")
t("dex", "機敏", "stat short_name")
t("Constitution", "耐久", "stat name")
t("con", "耐久", "stat short_name")

