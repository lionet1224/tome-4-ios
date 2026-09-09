locale "zh_hant"
------------------------------------------------
section "mod-boot/class/Game.lua"

t("Welcome to T-Engine and the Tales of Maj'Eyal", "歡迎來到 T-Engine 和馬基·埃亞爾的傳說", "_t")
t([[#GOLD#"Tales of Maj'Eyal"#WHITE# is the main game, you can also install more addons or modules by going to https://te4.org/

When inside a module remember you can press Escape to bring up a menu to change keybindings, resolution and other module specific options.

Remember that in most roguelikes death is usually permanent so be careful!

Now go and have some fun!]], [[#GOLD#馬·基埃亞爾的傳說#WHITE# 是主遊戲，你也可以在 https://te4.org/ 下載到更多遊戲插件和遊戲模組。

在遊戲模組內，你可以按ESC鍵打開菜單，改變按鍵綁定，遊戲分辨率和其他和模組有關的設置。

請記住，在大部分Roguelike遊戲裏，角色的死亡都是永久的，請小心！

玩的開心！]], "_t")
t("Upgrade to 1.0.5", "升級到 v1.0.5 版本", "_t")
t([[The way the engine manages saving has been reworked for v1.0.5.

The background saves should no longer lag horribly and as such it is highly recommended that you use the option. The upgrade turned it on for you.

For the same reason the save per level option should not be used unless you have severe memory problems. The upgrade turned it off for you.
]], [[遊戲引擎管理遊戲存檔的方式在 v1.0.5 版本發生了變化

後臺存檔將不再會嚴重拖慢你的遊戲運行速率，強烈建議你開啓這一選項。這次更新會自動幫你打開這個選項。

與此同時，每層存檔的選項已經沒有必要使用，除非你有嚴重的內存問題。這次更新會自動幫你關閉這個選項。
]], "_t")
t("Safe Mode", "安全模式", "_t")
t([[Oops! Either you activated safe mode manually or the game detected it did not start correctly last time and thus you are in #LIGHT_GREEN#safe mode#WHITE#.
Safe Mode disabled all graphical options and sets a low FPS. It is not advisable to play this way (as it will be very painful and ugly).

Please go to the Video Options and try enabling/disabling options and then restarting until you do not get this message.
A usual problem is shaders and thus should be your first target to disable.]], [[糟糕！如果你不是手動開啓了安全模式的話，那麼說明，遊戲檢測到上一次啓動時發生錯誤，目前遊戲已進入#LIGHT_GREEN#安全模式#WHITE#。
在安全模式下，所有圖形選項都被關閉，FPS被設置爲很低。不建議在這種情況下進行遊戲(遊戲畫面會變得很難看)。

請你進入遊戲視頻選項，嘗試調整遊戲選項，直到你不再彈出此消息。
常見的問題一般是由着色器引發的，你可以先嚐試關閉這些選項。]], "_t")
t("Message", "消息", "_t")
t("Duplicate Addon", "重複的插件", "_t")
t([[Oops! It seems like you have the same addon/dlc installed twice.
This is unsupported and would make many things explode. Please remove one of the copies.

Addon name: #YELLOW#%s#LAST#

Check out the following folder on your computer:
%s
%s
]], [[糟糕！好像你安裝了多份同一個插件/DLC。
這種情況不被支持的，會引發很多BUG。請你移除掉多餘的文件。

插件名稱： #YELLOW#%s#LAST#

請你檢查你電腦裏的以下文件夾：
%s
%s
]], "_t")
t("Updating addon: #LIGHT_GREEN#%s", "正在更新插件: #LIGHT_GREEN#%s", "tformat")
t("Quit", "退出", "_t")
t("Really exit T-Engine/ToME?", "真的要退出 T-Engine/馬基·埃亞爾的傳說", "_t")
t("Continue", "繼續", "_t")
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
This is all optional, you are not forced to use this feature at all, but the developer would thank you if you did as it will make balancing easier.]], [[歡迎來到#LIGHT_GREEN#馬基·埃亞爾的傳說#LAST#！

在你開始嘗試這個遊戲裏無數有趣的死法之前，我們想問你一下有關在線遊戲的事情。

馬基·埃亞爾的傳說是一個#{bold}#單人遊戲#{normal}#，但也提供了豐富的在線功能，可以增強你的遊戲體驗，並讓你和遊戲社區建立聯繫：
* 在多臺電腦上游玩，而不需要複製遊戲解鎖和成就。
* 與其他玩家在遊戲內聊天，尋求建議，分享難忘的時刻…
* 記錄你的擊殺數量，死亡次數，以及最喜歡的職業…
* 統計你的遊戲數據，來記錄你的遊戲風格
* 在遊戲裏直接安裝官方擴展包和第三方插件，免去手動安裝的麻煩
* 如果你購買了遊戲或是在 https:/te4.org/ 上進行了捐助，你可以獲得獲得你的購買者/贊助者獨享權益
* 幫助遊戲開發者調整遊戲平衡，讓這個遊戲變得更好。

你也會在獲得一個 #LIGHT_BLUE#https:/te4.org/#LAST# 上的用戶頁面，可以用來向你的朋友炫耀。
這一切都是可選的，你可以自願使用或者關閉這些功能。開發者會根據你的用戶反饋來協助調整遊戲平衡。]], "_t")
t("Logging in...", "登錄中…", "_t")
t("Please wait...", "請等待…", "_t")
t("Profile logged in!", "賬戶登錄成功！", "_t")
t("Your online profile is now active. Have fun!", "你的在線賬戶已可用。玩得開心！", "_t")
t("Login failed!", "登陸失敗！", "_t")
t("Check your login and password or try again in in a few moments.", "請確認你的用戶名和密碼，或在幾分鐘後再試。", "_t")
t("Registering...", "正在註冊", "_t")
t("Registering on https://te4.org/, please wait...", "正在在 https://te4.org/ 上註冊，請稍候…", "_t")
t("Logged in!", "登陸成功！", "_t")
t("Profile created!", "賬戶創建成功！", "_t")
t("Profile creation failed!", "賬戶創建失敗！", "_t")
t("Creation failed: %s (you may also register on https://te4.org/)", "創建失敗: %s (你也可以在 https://te4.org/ 網站上註冊）", "tformat")
t("Try again in in a few moments, or try online at https://te4.org/", "請過幾分鐘後再試，或在 https://te4.org/ 網站上註冊", "_t")

------------------------------------------------
section "mod-boot/class/Player.lua"

t("%s available", "%s可用", "tformat")
t("#00ff00#Talent %s is ready to use.", "#00ff00#技能%s已經可以使用了。", "log")
t("LEVEL UP!", "升級了！", "_t")

------------------------------------------------
section "mod-boot/data/birth/descriptors.lua"

t("base", "基礎", "birth descriptor name")
t("Destroyer", "毀滅者", "birth descriptor name")
t("Acid-maniac", "狂酸使", "birth descriptor name")

------------------------------------------------
section "mod-boot/data/damage_types.lua"

t("Kill!", "擊殺!", "_t")

------------------------------------------------
section "mod-boot/data/general/grids/basic.lua"

t("floor", "地板", "entity type")
t("floor", "地板", "entity subtype")
t("floor", "地板", "entity name")
t("wall", "牆壁", "entity type")
t("wall", "牆壁", "entity name")
t("door", "門", "entity name")
t("open door", "敞開的門", "entity name")

------------------------------------------------
section "mod-boot/data/general/grids/forest.lua"

t("floor", "地板", "entity type")
t("grass", "草地", "entity subtype")
t("grass", "草地", "entity name")
t("wall", "牆壁", "entity type")
t("tree", "樹", "entity name")
t("flower", "花", "entity name")

------------------------------------------------
section "mod-boot/data/general/grids/underground.lua"

t("wall", "牆壁", "entity type")
t("underground", "地下", "entity subtype")
t("crystals", "水晶", "entity name")
t("floor", "地板", "entity type")
t("floor", "地板", "entity name")

------------------------------------------------
section "mod-boot/data/general/grids/water.lua"

t("floor", "地板", "entity type")
t("water", "水", "entity subtype")
t("deep water", "深水", "entity name")

------------------------------------------------
section "mod-boot/data/general/npcs/canine.lua"

t("animal", "動物", "entity type")
t("canine", "犬類", "entity subtype")
t("wolf", "狼", "entity name")
t("Lean, mean, and shaggy, it stares at you with hungry eyes.", "一頭瘦弱的、狡猾的皮毛蓬鬆的餓狼，它正用貪婪的眼神看着你。", "_t")
t("white wolf", "白狼", "entity name")
t("A large and muscled wolf from the northern wastes. Its breath is cold and icy and its fur coated in frost.", "一頭來自北部荒野的狼，它膘肥身健，體型勻稱。它的呼吸冰冷而急促且全身都凝結着冰霜。", "_t")
t("warg", "座狼", "entity name")
t("It is a large wolf with eyes full of cunning.", "這是一隻狡猾且體型巨大的狼。", "_t")
t("fox", "狐狸", "entity name")
t("The quick brown fox jumps over the lazy dog.", "這隻靈巧的棕色狐狸從一隻懶狗身上跳了過去。", "_t")

------------------------------------------------
section "mod-boot/data/general/npcs/skeleton.lua"

t("undead", "亡靈", "entity type")
t("skeleton", "骷髏", "entity subtype")
t("degenerated skeleton warrior", "腐化骷髏戰士", "entity name")
t("skeleton warrior", "骷髏戰士", "entity name")
t("skeleton mage", "骷髏法師", "entity name")
t("armoured skeleton warrior", "武裝骷髏戰士", "entity name")

------------------------------------------------
section "mod-boot/data/general/npcs/troll.lua"

t("giant", "巨人", "entity type")
t("troll", "巨魔", "entity subtype")
t("forest troll", "森林巨魔", "entity name")
t("Green-skinned and ugly, this massive humanoid glares at you, clenching wart-covered green fists.", "醜陋的綠皮生物正盯着你，同時它握緊了滿是肉瘤的綠色拳頭。", "_t")
t("stone troll", "岩石巨魔", "entity name")
t("A giant troll with scabrous black skin. With a shudder, you notice the belt of dwarf skulls around his massive waist.", "有着粗糙黑色皮膚的巨魔，一陣戰慄後，你驚訝的發現他的腰帶是用矮人頭骨製成。", "_t")
t("cave troll", "洞穴巨魔", "entity name")
t("This huge troll wields a massive spear and has a disturbingly intelligent look in its piggy eyes.", "這隻巨魔手握一根笨重的長矛，同時在它那貪婪的眼睛裏，你看出了一絲令人不安的信息。", "_t")
t("mountain troll", "山嶺巨魔", "entity name")
t("A large and athletic troll with an extremely tough and warty hide.", "一隻高大且強壯的巨魔，身披一張醜陋但異常堅硬的獸皮。", "_t")
t("mountain troll thunderer", "閃電山嶺巨魔", "entity name")

------------------------------------------------
section "mod-boot/data/talents.lua"

t("misc", "雜項", "talent category")
t("Kick", "踢", "talent name")
t("Acid Spray", "酸液噴吐", "talent name")
t("Manathrust", "奧術射線", "talent name")
t("Flame", "火球術", "talent name")
t("Fireflash", "爆裂火球", "talent name")
t("Lightning", "閃電術", "talent name")
t("Sunshield", "太陽護盾", "talent name")
t("Flameshock", "火焰衝擊", "talent name")

------------------------------------------------
section "mod-boot/data/timed_effects.lua"

t("Burning from acid", "酸液灼燒", "_t")
t("#Target# is covered in acid!", "#Target#被酸液覆蓋！", "_t")
t("+Acid", "+酸液", "_t")
t("#Target# is free from the acid.", "#Target#身上的酸液消失了。", "_t")
t("-Acid", "-酸液", "_t")
t("Sunshield", "太陽護盾", "_t")

------------------------------------------------
section "mod-boot/data/zones/dungeon/zone.lua"

t("Forest", "森林", "_t")

------------------------------------------------
section "mod-boot/dialogs/Addons.lua"

t("Configure Addons", "設置插件", "_t")
t("You can get new addons at #LIGHT_BLUE##{underline}#Te4.org Addons#{normal}#", "在以下位置可以獲得新的插件： #LIGHT_BLUE##{underline}#Te4.org 插件頁面#{normal}#", "_t")
t(" and #LIGHT_BLUE##{underline}#Te4.org DLCs#{normal}#", " 和 #LIGHT_BLUE##{underline}#Te4.org DLC頁面#{normal}#", "_t")
t("You can get new addons on #LIGHT_BLUE##{underline}#Steam Workshop#{normal}#", "在以下位置可以獲得新的插件： #LIGHT_BLUE##{underline}#Steam 創意工坊#{normal}# ", "_t")
t(", #LIGHT_BLUE##{underline}#Te4.org Addons#{normal}#", ", #LIGHT_BLUE##{underline}#Te4.org 插件頁面#{normal}#", "_t")
t("Show incompatible", "顯示不兼容版本", "_t")
t("Auto-update on start", "啓動時自動更新", "_t")
t("Game Module", "遊戲模組", "_t")
t("Version", "版本", "_t")
t("Addon", "插件", "_t")
t("Active", "啓動", "_t")
t("#GREY#Developer tool", "#GREY#開發者工具", "_t")
t("#LIGHT_RED#Donator Status: Disabled", "#LIGHT_RED#捐贈者狀態：禁用", "_t")
t("#LIGHT_GREEN#Manual: Active", "#LIGHT_GREEN#手動：啓動", "_t")
t("#LIGHT_RED#Manual: Disabled", "#LIGHT_RED#手動：禁用", "_t")
t("#LIGHT_GREEN#Auto: Active", "#LIGHT_GREEN#自動：啓動", "_t")
t("#LIGHT_RED#Auto: Incompatible", "#LIGHT_RED#自動：不兼容", "_t")
t("Addon Version", "插件版本", "_t")
t("Game Version", "遊戲版本", "_t")

------------------------------------------------
section "mod-boot/dialogs/Credits.lua"

t("Project Lead", "首席製作人", "_t")
t("Lead Coder", "領銜程序設計", "_t")
t("World Builders", "世界構建", "_t")
t("Graphic Artists", "視覺藝術", "_t")
t("Expert Shaders Design", "特效設計", "_t")
t("Soundtracks", "遊戲音樂", "_t")
t("Sound Designer", "音效設計", "_t")
t("Lore Creation and Writing", "劇情撰寫", "_t")
t("Code Heroes", "程序設計", "_t")
t("Community Managers", "社區經理", "_t")
t("Text Editors", "文本編輯", "_t")
t("Chinese Translation Lead", "漢化組組長", "_t")
t("Chinese Translators", "漢化組成員", "_t")
t("Korean Translation", "韓文翻譯組成員", "_t")
t("Japanese Translation", "日文翻譯組成員", "_t")
t("The Community", "遊戲社區", "_t")
t("Others", "其他", "_t")

------------------------------------------------
section "mod-boot/dialogs/FirstRun.lua"

t("Welcome to Tales of Maj'Eyal", "歡迎來到馬基埃亞爾的傳說", "_t")
t("Register now!", "現在註冊！", "_t")
t("Login existing account", "登錄已有賬戶", "_t")
t("Maybe later", "以後再說", "_t")
t("#RED#Disable all online features", "#RED#關閉所有聯網功能", "_t")
t("Disable all connectivity", "禁用所有網絡連接", "_t")
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

If you disable this option you can always re-activate it in the Online category of the Game Options menu later on.]], [[即將禁止所有網絡請求
包括但不僅限於:
- 用戶信息：不能登錄或者註冊。
- 角色備份：不能在te4.org上保存你的角色信息(用來給其他人分享你的炫酷角色)。
- 物品倉庫：不能訪問你的在線物品倉庫(包括存入和取回)。
- 遊戲內聊天：聊天要聯網, 謝謝。
- 氪金福利：聯網才能獲取你的氪金狀態。
- 擴展包&DLC：和氪金狀態一樣, 無法獲取DLC的購買狀態。
- 便捷的插件安裝：無法在遊戲內看見插件列表, 但是你還可以手動安裝插件。
- 插件版本更新：無法更新插件的版本。
- Steam：無法使用Steam相關的任何功能。
- Discord：無法同步到Discord的實時狀態。
- 遊戲內新聞：主菜單將不再顯示新聞。
注意這個設置隻影響遊戲本身。如果你使用遊戲啓動器，它的唯一目的就是確保遊戲是最新的，因此它仍然會連接網絡。
如果你不想這樣，直接運行遊戲即可。啓動器只是用來更新遊戲的。


#{bold}##CRIMSON#這是一個極端的選項。如果不是迫不得已, 推薦你不要打開它, 這會讓你失去很多好用的功能和一些遊戲體驗。#{normal}#
關閉後，可以通過遊戲設置菜單的在線選項卡打開。]], "_t")
t("Cancel", "取消", "_t")
t("#RED#Disable all!", "#RED#全部禁用！", "_t")

------------------------------------------------
section "mod-boot/dialogs/LoadGame.lua"

t("Load Game", "讀取遊戲", "_t")
t("Show older versions", "顯示舊版本", "_t")
t("Ignore unloadable addons", "忽略無法讀取的插件", "_t")
t("  Play!  ", "  遊玩！  ", "_t")
t("Delete", "刪除", "_t")
t([[#{bold}##GOLD#%s: %s#WHITE##{normal}#
Game version: %d.%d.%d
Requires addons: %s

%s]], [[#{bold}##GOLD#%s：%s#WHITE##{normal}#
遊戲版本： %d.%d.%d
需要的插件： %s

%s]], "tformat")
t("You can simply grab an older version of the game from where you downloaded it.", "你可以在下載這個遊戲的地方，下載到這個遊戲的舊版本。", "_t")
t("You can downgrade the version by selecting it in the Steam's \"Beta\" properties of the game.", "你可以在Steam中設置Beta版本屬性，來降級你的遊戲版本。", "_t")
t("Original game version not found", "未找到原遊戲版本", "_t")
t([[This savefile was created with game version %s. You can try loading it with the current version if you wish but it is recommended you play it with the old version to ensure compatibility
%s]], [[這個存檔是遊戲版本 %s 創建的。如果你願意，你可以嘗試使用當前版本強制讀檔，但是建議你使用舊版本遊戲進行遊玩，來確保兼容性。
%s]], "tformat")
t("Cancel", "取消", "_t")
t("Run with newer version", "運行新版本", "_t")
t("Developer Mode", "開發者模式", "_t")
t("#LIGHT_RED#WARNING: #LAST#Loading a savefile while in developer mode will permanently invalidate it. Proceed?", "#LIGHT_RED#警告： #LAST#在開發者模式下讀取一個存檔將會不可逆地將其標記爲作弊存檔。確定嗎？", "_t")
t("Load anyway", "仍然讀檔", "_t")
t("Delete savefile", "刪除存檔", "_t")
t("Really delete #{bold}##GOLD#%s#WHITE##{normal}#", "真的要刪除#{bold}##GOLD#%s#WHITE##{normal}#嗎", "tformat")
t("Old game data", "舊版遊戲數據", "_t")
t("No data available for this game version.", "沒有當前遊戲版本的數據。", "_t")
t("Downloading old game data: #LIGHT_GREEN#", "正在下載舊版遊戲數據： #LIGHT_GREEN#", "_t")
t("Old game data for %s correctly installed. You can now play.", " %s 的舊版遊戲數據已經安裝成功了。你可以現在遊玩了。", "tformat")
t("Failed to install.", "安裝失敗。", "_t")

------------------------------------------------
section "mod-boot/dialogs/MainMenu.lua"

t("Main Menu", "主菜單", "_t")
t("New Game", "新遊戲", "_t")
t("Load Game", "讀取遊戲", "_t")
t("Addons", "插件", "_t")
t("Options", "選項", "_t")
t("Game Options", "遊戲選項", "_t")
t("Credits", "製作人員名單", "_t")
t("Exit", "退出", "_t")
t("Reboot", "重啓遊戲", "_t")
t("Disable animated background", "關閉動態背景", "_t")
t("#{bold}##B9E100#T-Engine4 version: %d.%d.%d", "#{bold}##B9E100#T-Engine4 版本：%d.%d.%d", "tformat")
t([[#{bold}##GOLD#Ashes of Urh'Rok - Expansion#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#Many in Maj'Eyal have heard of "demons", sadistic creatures who appear seemingly from nowhere, leaving a trail of suffering and destruction wherever they go.#{normal}##LAST#

#{bold}#Features#{normal}#:
#LIGHT_UMBER#New class:#WHITE# Doombringers. These avatars of demonic destruction charge into battle with massive two-handed weapons, cutting swaths of firey devastation through hordes of opponents. Armed with flame magic and demonic strength, they delight in fighting against overwhelming odds
#LIGHT_UMBER#New class:#WHITE# Demonologists. Bearing a shield and the magic of the Spellblaze itself, these melee-fighting casters can grow demonic seeds from their fallen enemies. Imbue these seeds onto your items to gain a wide array of new talents and passive benefits, and summon the demons within them to fight!
#LIGHT_UMBER#New race:#WHITE# Doomelves. Shalore who've taken to the demonic alterations especially well, corrupting their typical abilities into a darker form.
#LIGHT_UMBER#New artifacts, lore, zones, events...#WHITE# For your demonic delight!

]], [[#{bold}##GOLD#烏魯洛克之燼 - 遊戲擴展包#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#很多馬基埃亞爾的居民都曾經聽說過“惡魔”的名字，它們是一羣似乎憑空出現的暴虐生物，無論走到哪裏都會帶來痛苦和毀滅。#{normal}##LAST#

#{bold}#擴展包特性#{normal}#:
#LIGHT_UMBER#新職業：#WHITE# 毀滅使者。 他們是惡魔毀滅力量的化身，手拿雙手武器加入戰鬥，將敵人化爲一片火海。他們的手中掌握着火焰的魔法和惡魔的力量，在與勢不可擋的敵人戰鬥中尋求歡愉。
#LIGHT_UMBER#新職業：#WHITE# 惡魔使者。 這些近戰施法者手拿盾牌，掌握魔法大爆炸本身的力量的魔法，可以在倒下的敵人的身上終止惡魔種子。將這些惡魔種子附魔到你的物品裏，可以獲得各種全新的技能和被動的能力，並召喚種子裏的惡魔來加入戰鬥！
#LIGHT_UMBER#新種族：#WHITE# 魔化精靈。 那些被惡魔的力量所改變的永恆精靈，他們的種族能力被腐化成了黑暗的形態。
#LIGHT_UMBER#更多新神器、新手札、新地圖、新事件……#WHITE# 體驗惡魔的歡愉吧！

]], "_t")
t("#LIGHT_GREEN#Installed", "#LIGHT_GREEN#已安裝", "_t")
t("#YELLOW#Not installed - Click to download / purchase", "#YELLOW#未安裝 - 點擊下載/購買", "_t")
t([[#{bold}##GOLD#Embers of Rage - Expansion#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#One year has passed since the one the Orcs call the "Scourge from the West" came and single-handedly crushed the Orc Prides of Grushnak, Vor, Gorbat, and Rak'Shor.  The Allied Kingdoms, now linked by farportal to their distant, long-lost Sunwall allies, have helped them conquer most of Var'Eyal.  The few remnants of the ravaged Prides are caged...  but one Pride remains.#{normal}##LAST#

#{bold}#Features#{normal}#:
#LIGHT_UMBER#A whole new campaign:#WHITE# Set one year after the events of the main game, the final destiny of the Orc Prides is up to you. Discover the Far East like you never knew it. 
#LIGHT_UMBER#New classes:#WHITE# Sawbutchers, Gunslingers, Psyshots, Annihilators and Technomanchers. Harness the power of steam to power deadly contraptions to lay waste to all those that oppose the Pride!  
#LIGHT_UMBER#New races:#WHITE# Orcs, Yetis, Whitehooves. Discover the orcs and their unlikely 'allies' as you try to save your Pride from the disasters caused by the one you call 'The Scourge from the West'.
#LIGHT_UMBER#Tinker system:#WHITE# Augment your items with powerful crafted tinkers. Attach rockets to your boots, gripping systems to your gloves and many more.
#LIGHT_UMBER#Salves:#WHITE# Bound to the tinker system, create powerful medical salves to inject into your skin, replacing the infusions§runes system.
#LIGHT_UMBER#A ton#WHITE# of artifacts, lore, zones, events... 

]], [[#{bold}##GOLD#餘燼怒火 - 遊戲擴展包#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#自從被獸人成爲“西方災星”的那個人，孤身一人粉碎了格魯希納克、沃爾、加伯特和拉克肖四大部落之後，已經過了一年的時間。聯合王國現在已經通過遠古傳送門，和他們失落已久的盟友太陽堡壘建立了聯繫，幫助他們征服了瓦·埃亞爾大陸的近乎全境。被戰火蹂躪的獸人部落的少數殘餘，現在都被聯軍關押在監獄裏……但是，還有一個部落存活了下來。#{normal}##LAST#

#{bold}#擴展包特性#{normal}#:
#LIGHT_UMBER#全新戰役：#WHITE# 這場戰役在主遊戲戰役以後，決定獸人部落的最終命運。探索全新的遠東大陸吧！
#LIGHT_UMBER#全新職業：#WHITE# 鏈鋸屠夫，槍手，念力射手，殲滅者和科技法師。掌握蒸汽的力量，驅動致命的裝置，用鋼鐵洪流粉碎那些膽敢反抗部落的人吧！
#LIGHT_UMBER#全新種族：#WHITE# 獸人，雪人，白蹄。瞭解獸人和他們那些奇特的“盟友”，團結起來，將獸人一族從“西方災星”帶來的災難中拯救出來。
#LIGHT_UMBER#插件系統：#WHITE# 合成強大的插件，用於強化你的物品。包括給你的靴子安裝火箭，給你的手套安裝抓取系統，乃至許多更多的插件。
#LIGHT_UMBER#藥劑系統：#WHITE# 在插件系統中，合成強大的醫療藥劑，用於注入你的皮膚，替代就有的紋身和符文系統。
#LIGHT_UMBER#大量#WHITE# 全新神器、手札、地圖和事件！

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

]], [[#{bold}##GOLD#禁忌邪教 - 遊戲擴展包#LAST##{normal}#
#{italic}##ANTIQUE_WHITE#不是所有的冒險者都在尋求財富，也不是所有保衛世界的人都心存善念。最近，恐魔在大陸上出現的次數急劇增加。不斷有人在偏僻的小路上失蹤，有時幾年後才被人發現，身體卻遭受了恐怖的變異，進入了瘋狂之中，也有時候再也無法尋到蹤跡。很明顯，在馬基·埃亞爾的大地深處，有某種東西正在暗中活動。那種東西——就是你。#{normal}##LAST#

#{bold}#擴展包特性#{normal}#:
#LIGHT_UMBER#新職業：#WHITE# 苦痛者。 它們被賦予了腐化的力量，最終將自己的身體轉化成了恐魔。它們可以召喚恐魔在戰鬥中協助自己，撕裂你的皮膚，融化你的臉龐，作爲攻擊敵人的武器。當你的手臂也被轉化成觸手之後，還有什麼敵人能阻擋你呢？
#LIGHT_UMBER#新職業：#WHITE# 熵教徒。 這種法師職業使用瘋狂的能力，掌控了熵的力量，顛覆了傳統的物理定律。它們可以將治療轉換成傷害，並召喚虛空的力量，將敵人粉碎爲塵土。
#LIGHT_UMBER#新種族：#WHITE# 德瑞姆。 他們是矮人的一支腐化分支，但是因爲某種原因，保持了一定程度的理性，而沒有完全孵化成爲沒有意識的恐魔。他們可以進入狂熱狀態，並學會召喚恐魔。
#LIGHT_UMBER#新種族：#WHITE# 克羅格。 他們是被本來應當殺死他們的那羣人轉化的食人魔。他們強大的攻擊可以震懾敵人，並且他們強壯的力量可以雙持任何單手武器。
#LIGHT_UMBER#大量全新地圖：#WHITE# 探索瘟疫之穴，在一隻巨大蠕蟲的身體內殺出一條血路(不要問我你是怎麼*進來*的)，探索神祕的出口，以及更多奇異的，充滿觸手的地圖！
#LIGHT_UMBER#新的恐魔：#WHITE# 你喜歡灼眼恐魔嗎？你一定會喜歡上灼熱恐魔的！還有虛空蠕蟲，還有熵之碎片，還有其他更多怪物！
#LIGHT_UMBER#厭倦了你自己的頭？#WHITE#  把它換成一個悠閒的寄生獸吧！
#LIGHT_UMBER#大量#WHITE# 全新神器、手札、事件……

]], "_t")
t("#GOLD#Online Profile", "#GOLD#在線賬戶", "_t")
t("Login", "登錄", "_t")
t("Register", "註冊", "_t")
t("Username: ", "用戶名：", "_t")
t("Password: ", "密碼：", "_t")
t("Login with Steam", "使用Steam登錄", "_t")
t("#GOLD#Online Profile#WHITE#", "#GOLD#在線賬戶#WHITE#", "_t")
t("#LIGHT_BLUE##{underline}#Logout", "#LIGHT_BLUE##{underline}#登出", "_t")
t("Username", "用戶名", "_t")
t("Your username is too short", "你的用戶名過短", "_t")
t("Password", "密碼", "_t")
t("Your password is too short", "你的密碼過短", "_t")
t("Login...", "登錄中…", "_t")
t("Logging in your account, please wait...", "正在登錄賬戶，請稍候…", "_t")
t("Steam client not found.", "找不到Steam客戶端", "_t")
-- untranslated text
--[==[
t("#LIGHT_BLUE##{underline}#%s#LAST##{normal}#", "#LIGHT_BLUE##{underline}#%s#LAST##{normal}#", "tformat")
--]==]


------------------------------------------------
section "mod-boot/dialogs/NewGame.lua"

t("New Game", "新遊戲", "_t")
t("Show all versions", "顯示所有版本", "_t")
t("Show incompatible", "顯示不兼容版本", "_t")
t([[You can get new games at
#LIGHT_BLUE##{underline}#https://te4.org/games#{normal}#]], [[你可以在這裏下載到最新遊戲
#LIGHT_BLUE##{underline}#https://te4.org/games#{normal}#]], "_t")
t("Game Module", "遊戲模組", "_t")
t("Version", "版本", "_t")
t("Enter your character's name", "輸入角色名稱", "_t")
t("Overwrite character?", "覆蓋角色？", "_t")
t("There is already a character with this name, do you want to overwrite it?", "已經有一個這個名稱的角色了，你要覆蓋這個角色嗎？", "_t")
t("No", "否", "_t")
t("Yes", "是", "_t")
t("This game is not compatible with your version of T-Engine, you can still try it but it might break.", "這個遊戲與你T-Engine的版本不兼容，你可以嘗試運行，但是遊戲可能崩潰。", "_t")

------------------------------------------------
section "mod-boot/dialogs/Profile.lua"

t("Player Profile", "玩家賬戶", "_t")
t("Logout", "登出", "_t")
t("You are logged in", "你已經登入了。", "_t")
t("Do you want to log out?", "你要登出嗎？", "_t")
t("Log out", "登出", "_t")
t("Cancel", "取消", "_t")
t("Login", "登錄", "_t")
t("Create Account", "創建賬戶", "_t")

------------------------------------------------
section "mod-boot/dialogs/ProfileLogin.lua"

t("Online profile ", "在線賬戶", "_t")
t("Username: ", "用戶名：", "_t")
t("Password: ", "密碼：", "_t")
t("Login", "登錄", "_t")
t("Cancel", "取消", "_t")
t("Password again: ", "重複密碼：", "_t")
t("Email: ", "郵箱", "_t")
t("Accept to receive #{bold}#very infrequent#{normal}# (a few per year) mails about important game events from us.", "允許我們#{bold}#偶爾#{normal}#向你發送有關遊戲重要新聞的郵件(每年最多隻會有幾封)", "_t")
t("You at least 16 years old, or have parental authorization to play the game.", "遊玩此遊戲時你已年滿16歲，或已得到了家長的許可。", "_t")
t("Create", "創建", "_t")
t("Privacy Policy (opens in browser)", "隱私政策(用瀏覽器打開)", "_t")
t("Password", "密碼", "_t")
t("Password mismatch!", "密碼不匹配！", "_t")
t("Username", "用戶名", "_t")
t("Your username is too short", "你的用戶名過短", "_t")
t("Your password is too short", "你的密碼過短", "_t")
t("Email", "郵箱", "_t")
t("Your email seems invalid", "郵箱地址無效", "_t")
t("Age Check", "年齡確認", "_t")
t("You need to be 16 years old or more or to have parental authorization to play this game.", "你需要年滿16歲以上，或者得到了家長的許可，纔可以遊玩本遊戲。", "_t")

------------------------------------------------
section "mod-boot/dialogs/ProfileSteamRegister.lua"

t("Steam User Account", "Steam用戶賬戶", "_t")
t([[Welcome to #GOLD#Tales of Maj'Eyal#LAST#.
To enjoy all the features the game has to offer it is #{bold}#highly#{normal}# recommended that you register your steam account.
Luckily this is very easy to do: you only require a profile name and optionally an email (we send very few email, maybe two a year at most).
]], [[歡迎來到#GOLD#馬基·埃亞爾的傳說#LAST#.
爲了享受遊戲的全部功能，我們#{bold}#強烈#{normal}#推薦你註冊你的Steam賬戶。
幸運的是，這非常容易：你只需要提供你的Steam用戶名，也可以提供你的郵箱。（我們基本上不會給你發送郵件，每年最多發送一兩份）
]], "_t")
t("Username: ", "用戶名：", "_t")
t("Email: ", "郵箱", "_t")
t("Accept to receive #{bold}#very infrequent#{normal}# (a few per year) mails about important game events from us.", "允許我們#{bold}#偶爾#{normal}#向你發送有關遊戲重要新聞的郵件(每年最多隻會有幾封)", "_t")
t("You at least 16 years old, or have parental authorization to play the game.", "遊玩此遊戲時你已年滿16歲，或已得到了家長的許可。", "_t")
t("Register", "註冊", "_t")
t("Cancel", "取消", "_t")
t("Privacy Policy (opens in browser)", "隱私政策(用瀏覽器打開)", "_t")
t("Username", "用戶名", "_t")
t("Your username is too short", "你的用戶名過短", "_t")
t("Email", "郵箱", "_t")
t("Your email does not look right.", "你的郵件地址有問題。", "_t")
t("Age Check", "年齡確認", "_t")
t("You need to be 16 years old or more or to have parental authorization to play this game.", "你需要年滿16歲以上，或者得到了家長的許可，纔可以遊玩本遊戲。", "_t")
t("Registering...", "正在註冊", "_t")
t("Registering on https://te4.org/, please wait...", "正在在 https://te4.org/ 上註冊，請稍候…", "_t")
t("Steam client not found.", "找不到Steam客戶端", "_t")
t("Error", "錯誤", "_t")
t("Username or Email already taken, please select an other one.", "用戶名或郵件地址已被使用，請選擇其他用戶名或郵件地址", "_t")

------------------------------------------------
section "mod-boot/dialogs/UpdateAll.lua"

t("Update all game modules", "更新所有遊戲模組", "_t")
t([[All those components will be updated:
]], [[所有需要更新的模組: 
]], "_t")
t("Component", "組件", "_t")
t("Version", "版本", "_t")
t("Nothing to update", "沒有需要更新的內容", "_t")
t("All your game modules are up to date.", "所有遊戲模組都處於最新版本。", "_t")
t("Game: #{bold}##GOLD#", "遊戲：#{bold}##GOLD#", "_t")
t("Engine: #{italic}##LIGHT_BLUE#", "遊戲引擎：#{italic}##LIGHT_BLUE#", "_t")
t("Error!", "錯誤！", "_t")
t([[There was an error while downloading:
]], [[下載時發生錯誤:
]], "_t")
t("Downloading: ", "正在下載：", "_t")
t("Update", "更新", "_t")
t("All updates installed, the game will now restart", "所有更新已安裝完畢，遊戲現在將會重新啓動", "_t")

------------------------------------------------
section "mod-boot/dialogs/ViewHighScores.lua"

t("View High Scores", "查看高分榜", "_t")
t("Game Module", "遊戲模組", "_t")
t("Version", "版本", "_t")
t("World", "世界", "_t")
t([[#{bold}##GOLD#%s#GREEN# High Scores#WHITE##{normal}#

]], [[#{bold}##GOLD#%s#GREEN# 高分榜 #WHITE##{normal}#

]], "tformat")
t([[#{bold}##GOLD#%s(%s)#GREEN# High Scores#WHITE##{normal}#

]], [[#{bold}##GOLD#%s(%s)#GREEN# 高分榜 #WHITE##{normal}#

]], "tformat")

------------------------------------------------
section "mod-boot/init.lua"

t("Tales of Maj'Eyal Main Menu", "馬基·埃亞爾的傳說 主菜單", "init.lua long_name")
t([[Bootmenu!
]], [[啓動菜單!
]], "init.lua description")

------------------------------------------------
section "mod-boot/load.lua"

t("Strength", "力量", "stat name")
t("str", "力量", "stat short_name")
t("Dexterity", "敏捷", "stat name")
t("dex", "敏捷", "stat short_name")
t("Constitution", "體質", "stat name")
t("con", "體質", "stat short_name")

