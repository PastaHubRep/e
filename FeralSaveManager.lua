--[[
	FeralLib SaveManager (adapted from the Linoria SaveManager)

	Needs the patched FeralLib (controls register themselves in Library.Flags).

	  local SaveManager = loadstring(game:HttpGet("<url of FeralSaveManager.lua>"))()
	  SaveManager:SetLibrary(Library)
	  SaveManager:SetFolder("Feral/MyGame")            -- optional, default "FeralSettings"
	  SaveManager:SetIgnoreIndexes({ "Some/Flag" })    -- optional, flags that should not be saved
	  SaveManager:BuildConfigSection(Page)             -- adds a "Configuration" section to a Page
	                                                   -- (or pass a Section to fill an existing one)
	  SaveManager:LoadAutoloadConfig()                 -- call last, after all controls exist

	Toggles, sliders, boxes, dropdowns (single + multi) and binds are saved.
	Buttons and labels are not. A control's id is its `Flag` option, or
	"<page>/<section>/<title>" when no Flag was given.
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {} do
	SaveManager.Folder = "FeralSettings"
	SaveManager.Ignore = {}
	SaveManager.Library = nil

	----------------------------------------------------------------
	-- Parsers: how each control type is written to / read from a config
	----------------------------------------------------------------
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, obj)
				return { type = "Toggle", idx = idx, value = obj:Get() }
			end,
			Load = function(obj, data)
				if type(data.value) == "boolean" then obj:Set(data.value) end
			end,
		},
		Slider = {
			Save = function(idx, obj)
				return { type = "Slider", idx = idx, value = obj:Get() }
			end,
			Load = function(obj, data)
				local n = tonumber(data.value)
				if n then obj:Set(n) end
			end,
		},
		Box = {
			Save = function(idx, obj)
				return { type = "Box", idx = idx, text = obj:Get() }
			end,
			Load = function(obj, data)
				if type(data.text) == "string" then obj:Set(data.text, true) end
			end,
		},
		Dropdown = {
			Save = function(idx, obj)
				return { type = "Dropdown", idx = idx, value = obj:Get(), multi = obj.Multi }
			end,
			Load = function(obj, data)
				if data.value ~= nil then obj:Set(data.value, true) end
			end,
		},
		Bind = {
			Save = function(idx, obj)
				local k = obj:Get()
				local value = false -- false = no key bound
				if typeof(k) == "EnumItem" then
					value = { enum = (k.EnumType == Enum.KeyCode) and "KeyCode" or "UserInputType", name = k.Name }
				end
				return { type = "Bind", idx = idx, value = value }
			end,
			Load = function(obj, data)
				local v = data.value
				if v == false then
					obj:Set(nil)
				elseif type(v) == "table" and (v.enum == "KeyCode" or v.enum == "UserInputType") then
					local ok, item = pcall(function() return Enum[v.enum][v.name] end)
					if ok and item then obj:Set(item) end
				end
			end,
		},
	}

	----------------------------------------------------------------
	-- Setup
	----------------------------------------------------------------
	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function SaveManager:BuildFolderTree()
		-- create every level of the path ("Feral/MyGame" -> "Feral", "Feral/MyGame"), then the settings folder
		local function ensure(path)
			local built
			for part in string.gmatch(path, "[^/\\]+") do
				built = built and (built .. "/" .. part) or part
				if not isfolder(built) then makefolder(built) end
			end
		end
		ensure(self.Folder)
		ensure(self.Folder .. "/settings")
	end

	local function validName(name)
		return type(name) == "string" and name:gsub("%s", "") ~= "" and not name:find("[/\\]")
	end

	----------------------------------------------------------------
	-- Save / Load
	----------------------------------------------------------------
	function SaveManager:Save(name)
		if not name then return false, "no config file is selected" end
		if not validName(name) then return false, "invalid config name" end
		assert(self.Library, "Must call SaveManager:SetLibrary(Library) first")

		local data = { objects = {} }
		for idx, obj in next, self.Library.Flags do
			local parser = self.Parser[obj.Type]
			if parser and not self.Ignore[idx] then
				table.insert(data.objects, parser.Save(idx, obj))
			end
		end
		table.sort(data.objects, function(a, b) return a.idx < b.idx end)

		local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
		if not success then return false, "failed to encode data" end

		writefile(self.Folder .. "/settings/" .. name .. ".json", encoded)
		return true
	end

	function SaveManager:Load(name)
		if not name then return false, "no config file is selected" end
		if not validName(name) then return false, "invalid config name" end
		assert(self.Library, "Must call SaveManager:SetLibrary(Library) first")

		local file = self.Folder .. "/settings/" .. name .. ".json"
		if not isfile(file) then return false, "invalid file" end

		local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
		if not success or type(decoded) ~= "table" or type(decoded.objects) ~= "table" then
			return false, "decode error"
		end

		for _, entry in next, decoded.objects do
			local parser = self.Parser[entry.type]
			local obj = self.Library.Flags[entry.idx]
			-- only apply if the control still exists and is the same kind, and isn't ignored
			if parser and obj and obj.Type == entry.type and not self.Ignore[entry.idx] then
				-- task.spawn + pcall so one bad entry / callback can't stop the rest of the config loading
				task.spawn(pcall, parser.Load, obj, entry)
			end
		end

		return true
	end

	function SaveManager:Delete(name)
		if not name then return false, "no config file is selected" end
		if not validName(name) then return false, "invalid config name" end
		local file = self.Folder .. "/settings/" .. name .. ".json"
		if not isfile(file) then return false, "invalid file" end
		delfile(file)
		return true
	end

	function SaveManager:RefreshConfigList()
		local out = {}
		for _, file in ipairs(listfiles(self.Folder .. "/settings")) do
			local name = file:match("([^/\\]+)%.json$")
			if name then table.insert(out, name) end
		end
		table.sort(out)
		return out
	end

	function SaveManager:LoadAutoloadConfig()
		local path = self.Folder .. "/settings/autoload.txt"
		if isfile(path) then
			local name = readfile(path)
			local success, err = self:Load(name)
			if not success then
				return self.Library:CreateNoti({ Title = "Config", Desc = "Failed to load autoload config: " .. err, ShowTime = 4 })
			end
			self.Library:CreateNoti({ Title = "Config", Desc = string.format("Auto loaded config %q", name), ShowTime = 3 })
		end
	end

	----------------------------------------------------------------
	-- UI
	----------------------------------------------------------------
	-- `target` is a Page (a "Configuration" section is created on it) or an existing Section.
	function SaveManager:BuildConfigSection(target)
		local lib = self.Library
		assert(lib, "Must call SaveManager:SetLibrary(Library) first")

		local section = target.CreateSection and target:CreateSection("Configuration") or target

		local function notify(text)
			lib:CreateNoti({ Title = "Config", Desc = text, ShowTime = 3 })
		end

		local nameBox = section:CreateBox({ Title = "Config Name", Placeholder = "Enter config name", Flag = "SaveManager_ConfigName" })
		local configList = section:CreateDropdown({ Title = "Config List", Options = self:RefreshConfigList(), Flag = "SaveManager_ConfigList" })
		configList:Set(nil) -- start on "None" instead of the first config

		local autoloadLabel = section:CreateLabel({ Title = "Current autoload config: none" })
		local autoloadPath = self.Folder .. "/settings/autoload.txt"
		if isfile(autoloadPath) then
			autoloadLabel:SetText("Current autoload config: " .. readfile(autoloadPath))
		end

		local function refreshList()
			configList:Refresh(self:RefreshConfigList())
			configList:Set(nil)
		end

		section:CreateButton({ Title = "Create Config" }, function()
			local name = nameBox:Get()
			if not validName(name) then
				return notify("Invalid config name (empty or contains / \\)")
			end
			local success, err = self:Save(name)
			if not success then return notify("Failed to save config: " .. err) end
			notify(string.format("Created config %q", name))
			refreshList()
		end)

		section:CreateButton({ Title = "Load Config" }, function()
			local name = configList:Get()
			local success, err = self:Load(name)
			if not success then return notify("Failed to load config: " .. err) end
			notify(string.format("Loaded config %q", name))
		end)

		section:CreateButton({ Title = "Overwrite Config" }, function()
			local name = configList:Get()
			local success, err = self:Save(name)
			if not success then return notify("Failed to overwrite config: " .. err) end
			notify(string.format("Overwrote config %q", name))
		end)

		section:CreateButton({ Title = "Delete Config" }, function()
			local name = configList:Get()
			local success, err = self:Delete(name)
			if not success then return notify("Failed to delete config: " .. err) end
			if isfile(autoloadPath) and readfile(autoloadPath) == name then
				delfile(autoloadPath)
				autoloadLabel:SetText("Current autoload config: none")
			end
			notify(string.format("Deleted config %q", name))
			refreshList()
		end)

		section:CreateButton({ Title = "Refresh List" }, function()
			refreshList()
		end)

		section:CreateButton({ Title = "Set As Autoload" }, function()
			local name = configList:Get()
			if not name then return notify("Select a config first") end
			writefile(autoloadPath, name)
			autoloadLabel:SetText("Current autoload config: " .. name)
			notify(string.format("Set %q to auto load", name))
		end)

		self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
