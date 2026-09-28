-- Example usage of FeralLib
-- Host FeralLib.lua somewhere (or paste it into a ModuleScript / use loadstring) and load it:
local Library = loadstring(game:HttpGet("https://YOUR-HOST/FeralLib.lua"))()
-- Roblox Studio: local Library = require(path.to.FeralLib)

local Window = Library:CreateMain({
	Title = "Grand Piece Online", -- sidebar title
	Desc = "v1.0",                -- shown next to the brand in the top bar
	Brand = "Feral",              -- blue word in the top bar
	ToggleKey = Enum.KeyCode.RightShift,
})

-- Pages (sidebar tabs)
local Main   = Window:CreatePage("Main", "Main Tab")
local Combat = Window:CreatePage("Combat", "Combat Tab")
local Misc   = Window:CreatePage("Misc", "Misc Tab")

--------------------------------------------------------------------
-- Main page
--------------------------------------------------------------------
local ps = Main:CreateSection("Private Server")

ps:CreateToggle({ Title = "Auto Join PS", Description = "Enable whether to auto join ps or not", Default = true }, function(v)
	print("Auto Join PS:", v)
end)

ps:CreateToggle({ Title = "Auto Rejoin", Description = "Auto Rejoins When Kicked", Default = true }, function(v)
	print("Auto Rejoin:", v)
end)

ps:CreateBox({ Title = "Private Server Code", Default = "M66w8qDIcG", Placeholder = "Enter code..." }, function(text)
	print("PS code:", text)
end)

ps:CreateDropdown({ Title = "Teleport Sea", Options = { "First Sea", "Second Sea", "Third Sea" }, Default = "Second Sea" }, function(choice)
	print("Sea:", choice)
end)

local speed = Main:CreateSection("Speed")

local speedToggle = speed:CreateToggle({ Title = "Speed Hack", Description = "Walk faster" }, function(v)
	print("Speed hack:", v)
end)

speed:CreateSlider({ Title = "Walk Speed", Min = 16, Max = 200, Default = 16 }, function(v)
	print("Walk speed:", v)
end)

speed:CreateSlider({ Title = "Jump Multiplier", Min = 0, Max = 5, Default = 1, Decimals = 1 }, function(v)
	print("Jump multiplier:", v)
end)

--------------------------------------------------------------------
-- Combat page
--------------------------------------------------------------------
local aim = Combat:CreateSection("Aim")

aim:CreateBind({ Title = "Aim Key", Default = Enum.KeyCode.E }, function(key)
	print("Aim key pressed:", key)
end)

aim:CreateButton({ Title = "Test Notification" }, function()
	Library:CreateNoti({ Title = "Feral", Desc = "This is a notification that closes itself.", ShowTime = 4 })
end)

--------------------------------------------------------------------
-- Misc page
--------------------------------------------------------------------
local info = Misc:CreateSection("Info")

local status = info:CreateLabel({ Title = "Status: idle" })

info:CreateButton({ Title = "Change Label" }, function()
	status:SetText("Status: clicked at " .. os.date("%X"))
end)

info:CreateButton({ Title = "Random Accent Color" }, function()
	Library:SetAccent(Color3.fromHSV(math.random(), 0.6, 1))
end)

info:CreateButton({ Title = "Unload UI" }, function()
	Window:Destroy()
end)

-- Controls return objects, so you can read/change them from your own code:
--   speedToggle:Get()  /  speedToggle:Set(true)

Main:Select()
