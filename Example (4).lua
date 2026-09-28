-- FeralLib example UI: every page / section / control from the original Feral script.
-- VISUAL ONLY: callbacks just print. Hook your own logic into the callbacks.
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/PastaHubRep/e/refs/heads/main/FeralLib.lua"))()
-- Host FeralSaveManager.lua next to FeralLib.lua and put its raw url here.
-- NOTE: the hosted FeralLib.lua must be the patched one (it provides Library.Flags).
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/PastaHubRep/e/refs/heads/main/FeralSaveManager.lua"))()
-- Roblox Studio: local Library = require(path.to.FeralLib)

local Window = Library:CreateMain({
	Title = "Grand Piece Online",
	Desc = "v1.0",
	Brand = "Feral",
	ToggleKey = Enum.KeyCode.RightShift,
})

local function log(name)
	return function(...) print(name, ...) end
end

-- Pages (same order as the original)
local Main   = Window:CreatePage("Main", "Main Tab")
local Esp    = Window:CreatePage("Esp", "ESP Tab")
local Combat = Window:CreatePage("Combat", "Combat Tab")
local Farm   = Window:CreatePage("Farm", "Farm Tab")
local Misc   = Window:CreatePage("Misc", "Misc Tab")
local Config = Window:CreatePage("Config", "Config Tab")

local Rarities = { "Mythical", "Legendary", "Rare", "Epic", "Common", "Uncommon" }
local Webhook = "https://discord.com/api/webhooks/..."

--------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------
local ps = Main:CreateSection("Private Server")
ps:CreateToggle({ Title = "Auto Join PS", Description = "Enable whether to auto join ps or not", Default = false }, log("Auto Join PS"))
ps:CreateToggle({ Title = "Auto Rejoin", Description = "Auto Rejoins When Kicked", Default = false }, log("Auto Rejoin"))
ps:CreateBox({ Title = "Private Server Code", Placeholder = "Enter code...", Default = "" }, log("PS code"))
ps:CreateDropdown({ Title = "Teleport Sea", Options = { "First Sea", "Second Sea" }, Default = "First Sea" }, log("Sea"))

local speed = Main:CreateSection("Speed")
speed:CreateToggle({ Title = "Speed", Description = "Increases your velocity", Default = false }, log("Speed"))
speed:CreateSlider({ Title = "Speed Boost", Min = 0, Max = 250, Default = 50 }, log("Speed Boost"))

--------------------------------------------------------------------
-- ESP
--------------------------------------------------------------------
local chest = Esp:CreateSection("Chest Esp")
chest:CreateToggle({ Title = "Chest Esp", Description = "Enable or disable Chest Esp", Default = false }, log("Chest Esp"))
chest:CreateSlider({ Title = "Max Distance", Min = 0, Max = 10000, Default = 2500 }, log("Chest distance"))
chest:CreateDropdown({
	Title = "Enabled Chests",
	Options = { "Common", "Uncommon", "Rare", "Legendary", "Mythic" },
	Default = { "Common", "Uncommon", "Rare", "Legendary", "Mythic" },
	Multi = true,
}, log("Enabled Chests"))

local medal = Esp:CreateSection("Medal Esp")
medal:CreateToggle({ Title = "Medal Esp", Description = "Enable or disable Medal Esp", Default = false }, log("Medal Esp"))
medal:CreateSlider({ Title = "Max Distance", Min = 0, Max = 10000, Default = 2500 }, log("Medal distance"))

local pesp = Esp:CreateSection("Player Esp")
pesp:CreateToggle({ Title = "Enable Player Esp", Description = "Enables player visuals", Default = false }, log("Player Esp"))
pesp:CreateToggle({ Title = "Enable Name", Description = "Enables showing name for esp", Default = true }, log("Name"))
pesp:CreateToggle({ Title = "Enable Box", Description = "Enables Boxes for esp", Default = true }, log("Box"))
pesp:CreateToggle({ Title = "Enable Devil Fruit", Description = "Enables Devil Fruit for esp", Default = true }, log("Devil Fruit"))
pesp:CreateToggle({ Title = "Enable HealthBar", Description = "Enables Healthbar for esp", Default = true }, log("HealthBar"))

--------------------------------------------------------------------
-- COMBAT
--------------------------------------------------------------------
local pc = Combat:CreateSection("Player Combat")
pc:CreateToggle({ Title = "Tp Behind Player", Description = "Teleports behind the closest player", Default = false }, log("Tp Behind Player"))
pc:CreateBind({ Title = "Tp Behind Player Key", Default = Enum.KeyCode.N }, log("Tp key"))

--------------------------------------------------------------------
-- FARM
--------------------------------------------------------------------
local lvl = Farm:CreateSection("Level Farm")
lvl:CreateToggle({ Title = "Level Farm Unpatched (Beta)", Description = "Level farm 0-625 lvl", Default = false }, log("Level Farm"))

local hw = Farm:CreateSection("Halloween Farm")
hw:CreateToggle({ Title = "Auto Farm Halloween", Description = "Auto Knocks on doors to farm candy (fully automatic)", Default = false }, log("Auto Farm Halloween"))
hw:CreateToggle({ Title = "Auto Buy Halloween", Description = "Automaticlaly purchases selected items with candy", Default = false }, log("Auto Buy Halloween"))
hw:CreateDropdown({
	Title = "Buyables",
	Options = { "Race Reroll x5", "Legendary Fruit Chest Blueprint", "Mummy Wrappings", "Custom Spirit Color",
		"Devil Fruit Journal", "Devil Fruit Remover", "Joker Costume", "Blood Scythe", "Plague Doctor Costume",
		"Trading Sign", "SP Reset Essence", "Fruit Bag", "Ghost Face Costume", "Rare Fruit Chest" },
	Default = {},
	Multi = true,
}, log("Halloween buyables"))

local juzo = Farm:CreateSection("Juzo")
juzo:CreateToggle({ Title = "Auto Juzo", Description = "Enable or disable Auto Juzo Farm", Default = false }, log("Auto Juzo"))
juzo:CreateToggle({ Title = "Auto Juzo (Rifle)", Description = "Enable or disable Auto Juzo Farm (Rifle)", Default = false }, log("Auto Juzo Rifle"))
juzo:CreateToggle({ Title = "Auto Rejoin Juzo", Description = "Enable or disable Auto Rejoin On Juzo Farm", Default = true }, log("Auto Rejoin Juzo"))
juzo:CreateBox({ Title = "Webhook", Placeholder = "Webhook URL...", Default = "" }, log("Juzo webhook"))

local santa = Farm:CreateSection("Santa")
santa:CreateToggle({ Title = "Auto Santa", Description = "Farms Santa", Default = false }, log("Auto Santa"))
santa:CreateToggle({ Title = "Open Gifts/Presents", Description = "Toggles wether to open presents", Default = false }, log("Open Presents"))
santa:CreateToggle({ Title = "Attack Santa", Description = "Toggles wether to attack big boy santa", Default = true }, log("Attack Santa"))
santa:CreateSlider({ Title = "Open At X Presents", Min = 1, Max = 50, Default = 5 }, log("Open at"))
santa:CreateBox({ Title = "Webhook", Placeholder = Webhook, Default = "" }, log("Santa webhook"))
santa:CreateDropdown({
	Title = "Drops",
	Options = { "SP Reset Essence", "Dark Root", "Festive Merry Dress", "Frosty Festive Dress", "Iceborn Daggers",
		"Iceborn Rapier", "Iceborn Blade", "Candy Cane" },
	Default = {},
	Multi = true,
}, log("Santa drops"))

local impel = Farm:CreateSection("Impel")
impel:CreateToggle({ Title = "Auto Impel Down", Description = "Farms Impel Down", Default = false }, log("Auto Impel Down"))

local ship = Farm:CreateSection("Ship Farm")
ship:CreateToggle({ Title = "Ship Bounty Farm", Description = "Does ship farming for you!", Default = false }, log("Ship Bounty Farm"))
ship:CreateToggle({ Title = "Kill Cannoneers", Description = "Targets ships subordinates when no captains.", Default = false }, log("Kill Cannoneers"))

local baal = Farm:CreateSection("Baal Farm")
baal:CreateToggle({ Title = "Baal Farm (Suna)", Description = "Auto Farm True Demon Ba'al & Resurrected Ba'al Using Suna!", Default = false }, log("Baal Farm"))
baal:CreateBox({ Title = "Webhook", Placeholder = "Webhook URL...", Default = "" }, log("Baal webhook"))

local pica = Farm:CreateSection("Pica Farm")
pica:CreateToggle({ Title = "Farm Pica (SUNA)", Description = "so its real?", Default = false }, log("Pica Suna"))
pica:CreateToggle({ Title = "Farm Pica (MEGAPOW)", Description = "so its real?", Default = false }, log("Pica Megapow"))
pica:CreateBox({ Title = "Webhook", Placeholder = "Webhook URL...", Default = "" }, log("Pica webhook"))

local gkk = Farm:CreateSection("Gkk Stack")
gkk:CreateToggle({ Title = "Gkk Farm", Description = "chat this might be the one", Default = false }, log("Gkk Farm"))
gkk:CreateToggle({ Title = "Lure Account", Description = "Enable this if ur a lure account", Default = false }, log("Lure Account"))
gkk:CreateDropdown({ Title = "Kill Method", Options = { "Mega-Pow" }, Default = "Mega-Pow" }, log("Kill Method"))

local stats = Farm:CreateSection("Auto Stats")
-- Original builds these from the in-game Statistics GUI; names below are the usual GPO stats.
for _, stat in ipairs({ "Strength", "Defense", "Sword", "Gun", "Devil Fruit" }) do
	stats:CreateToggle({ Title = "Auto " .. stat .. " Stat", Description = "Automatically Puts Stat Points Into " .. stat, Default = false }, log("Auto " .. stat))
	stats:CreateBox({ Title = stat .. " Max Stat", Placeholder = "Max Stat", Default = "800" }, log(stat .. " max"))
end
stats:CreateSlider({ Title = "Stat Amount", Min = 1, Max = 100, Default = 1 }, log("Stat Amount"))

local fishMain = Farm:CreateSection("Fish Kaitun - Main")
fishMain:CreateToggle({ Title = "Fish Kaitun Enabled", Description = "Enable fish kaitun farming or disable", Default = false }, log("Fish Kaitun"))
fishMain:CreateToggle({ Title = "Auto Sell Fish", Description = "Enable whether to sell fish or not.", Default = true }, log("Auto Sell Fish"))
fishMain:CreateToggle({ Title = "Auto Equip Titles", Description = "Enables wether to equip titles or not.", Default = true }, log("Auto Equip Titles"))
fishMain:CreateToggle({ Title = "Auto Set Spawn", Description = "Sets spawn at Shell's Town", Default = false }, log("Auto Set Spawn"))
fishMain:CreateDropdown({ Title = "Bait", Options = { "Best", "Legendary Fish Bait", "Rare Fish Bait", "Common Fish Bait" }, Default = "Best" }, log("Bait"))
fishMain:CreateDropdown({ Title = "Sell Rarities", Options = Rarities, Default = Rarities, Multi = true }, log("Sell Rarities"))

local fishBait = Farm:CreateSection("Fish Kaitun - Bait & Crafting")
fishBait:CreateToggle({ Title = "Auto Craft Legendary Bait", Description = "Auto Crafts Legendary Bait When You Have Legendary Fish", Default = false }, log("Craft Legendary Bait"))
fishBait:CreateToggle({ Title = "Auto Craft Rare Bait", Description = "Auto Crafts Rare Bait When You Have Rare Fish", Default = false }, log("Craft Rare Bait"))
fishBait:CreateBox({ Title = "Buy Bait Amount (Common)", Placeholder = "50", Default = "50" }, log("Bait amount"))

local fishMerch = Farm:CreateSection("Fish Kaitun - Merchant & Items")
fishMerch:CreateToggle({ Title = "Auto Buy From Merchant", Description = "Auto buys from the merchant when available", Default = false }, log("Auto Buy Merchant"))
fishMerch:CreateToggle({ Title = "Auto Store Fruits", Description = "Enable whether to store fruits or not.", Default = true }, log("Auto Store Fruits"))
fishMerch:CreateToggle({ Title = "Connect Websocket", Description = "Connectes you to the websocket server", Default = false }, log("Websocket"))
fishMerch:CreateBox({ Title = "Webhook", Placeholder = Webhook, Default = "" }, log("Fish webhook"))
fishMerch:CreateDropdown({ Title = "Drop Fruit Rarities", Options = Rarities, Default = Rarities, Multi = true }, log("Drop Fruit Rarities"))
fishMerch:CreateDropdown({ Title = "Webhook Fruit Rarities", Options = Rarities, Default = Rarities, Multi = true }, log("Webhook Fruit Rarities"))
fishMerch:CreateDropdown({ Title = "Buyables", Options = { "Merchant items" }, Default = {}, Multi = true }, log("Merchant buyables")) -- list is built at runtime in the original

--------------------------------------------------------------------
-- MISC
--------------------------------------------------------------------
local move = Misc:CreateSection("Movement")
move:CreateToggle({ Title = "No Stun", Description = "Removes stun when attacked", Default = false }, log("No Stun"))
move:CreateToggle({ Title = "Infinite Jump", Description = "Lets you jump forever", Default = false }, log("Infinite Jump"))
move:CreateToggle({ Title = "Geppo Loop", Description = "Helps bypass some speed checks", Default = false }, log("Geppo Loop"))

local qol = Misc:CreateSection("Quality Of Life")
qol:CreateToggle({ Title = "Auto Enable Buso", Description = "Enables Buso For You When At 100%", Default = false }, log("Auto Buso"))
qol:CreateToggle({ Title = "Auto Second Sea", Description = "Auto Gets Scroll And Goes To Second Sea", Default = false }, log("Auto Second Sea"))
qol:CreateToggle({ Title = "Reveal Fruits", Description = "Reveals Fruits In HotBar And Inventory", Default = false }, log("Reveal Fruits"))
qol:CreateToggle({ Title = "Auto Watch Xp Ads", Description = "Watches Ads When You Don't Have The Boost.", Default = false }, log("Xp Ads"))
qol:CreateToggle({ Title = "Auto Watch Drop Rate Ads", Description = "Watches Ads When You Don't Have The Boost.", Default = false }, log("Drop Rate Ads"))

local island = Misc:CreateSection("Island")
island:CreateDropdown({
	Title = "Island Tp",
	Options = { "Town of Beginnings", "Shell's Town", "Sandora", "Orange Town", "Restaurant Baratie", "Logue Town",
		"Roca Island", "Shark Park", "Reverse Mountain", "Sphinx Island", "World Scroll", "Mysterious Cliff",
		"Kori Island", "A rock", "Coco Island", "Fishman Cave", "Fishman Island", "Marine Fort F-1",
		"Marine Base G-1", "Spooksville", "Colosseum", "Land of the Sky", "Island Of Zou", "Transylvania", "Hell" },
	Default = "Coco Island",
	Search = true,
}, log("Island"))
island:CreateButton({ Title = "Teleport" }, function() print("Teleport") end)

local market = Misc:CreateSection("Market")
market:CreateDropdown({ Title = "Select Value", Options = { "skyWalkTrainer", "Cyborg", "Vampire", "Rokushiki" }, Default = "skyWalkTrainer" }, log("Market"))
market:CreateButton({ Title = "Purchase" }, function() print("Purchase") end)

local lp = Misc:CreateSection("Local Player")
lp:CreateToggle({ Title = "Auto Use/Buy Fruit Bag", Description = "Uses/Buys Spare Fruit Bag When Available", Default = false }, log("Fruit Bag"))
lp:CreateToggle({ Title = "No Dash Take Stamina", Description = "Prevents the game from taking your stamina on dash", Default = false }, log("No Dash Stamina"))
lp:CreateToggle({ Title = "Fake Geppo", Description = "Gives you fake geppo (Anticheat still can flag you)", Default = false }, log("Fake Geppo"))
lp:CreateToggle({ Title = "Streamer Mode", Description = "Replaces usernames", Default = false }, log("Streamer Mode"))
lp:CreateToggle({ Title = "Optimize Game", Description = "Applies optimizations :)", Default = false }, log("Optimize Game"))
lp:CreateToggle({ Title = "Hide Accounts", Description = "Hides other accounts (this can't be undone)", Default = false }, log("Hide Accounts"))
lp:CreateButton({ Title = "Remove Fog + Fix Lightning" }, function() print("Remove Fog") end)
lp:CreateButton({ Title = "Desync" }, function() print("Desync") end)

local gs = Misc:CreateSection("Global Settings")
gs:CreateDropdown({ Title = "Fighting Style", Options = { "Auto", "Melee", "Sword" }, Default = "Auto" }, log("Fighting Style"))
gs:CreateSlider({ Title = "Tween Speed (multiplier)", Min = 0.1, Max = 1, Default = 1, Decimals = 1 }, log("Tween Speed"))

--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------
-- Real config system: Config Name / Config List / Create / Load / Overwrite / Delete / Refresh / Set As Autoload
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("Feral/GrandPieceOnline")
SaveManager:BuildConfigSection(Config)

local other = Config:CreateSection("Other")
other:CreateBind({ Title = "Toggle UI", Default = Enum.KeyCode.RightShift }, log("Toggle UI"))
other:CreateLabel({ Title = "Account Table [PS]" })
other:CreateBox({ Title = "Account (username:password)", Placeholder = "Add account...", Default = "" }, log("Account"))
other:CreateButton({ Title = "Unload UI" }, function() Window:Destroy() end)

local rejoin = Config:CreateSection("Auto Rejoin")
rejoin:CreateToggle({ Title = "Auto Rejoin", Description = "Rejoins based on servertime", Default = false }, log("Timed Auto Rejoin"))
rejoin:CreateSlider({ Title = "Rejoin Time (In Seconds)", Min = 0, Max = 10000, Default = 1200 }, log("Rejoin Time"))

Main:Select()

-- Load the config marked "Set As Autoload" (call this after every control exists)
SaveManager:LoadAutoloadConfig()
