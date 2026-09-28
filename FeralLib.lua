--[[
	Feral UI Library
	Layout values taken from the original Feral script (629x359 window, 180px sidebar,
	435x325 pages, Gotham fonts, blue accent).

	API
	  local Library = loadstring(...)()
	  local Window  = Library:CreateMain({ Title = "My Hub", Desc = "v1", Brand = "Feral", ToggleKey = Enum.KeyCode.RightShift })
	  local Page    = Window:CreatePage("Main", "Main Tab")
	  local Section = Page:CreateSection("Section name")

	  Section:CreateToggle  ({ Title, Description, Default }, callback(bool))          -> { Set, Get }
	  Section:CreateButton  ({ Title }, callback())
	  Section:CreateLabel   ({ Title })                                                -> { SetText, SetColor }
	  Section:CreateBox     ({ Title, Default, Placeholder }, callback(text))          -> { Set, Get }
	  Section:CreateSlider  ({ Title, Min, Max, Default, Decimals }, callback(number)) -> { Set, Get }
	  Section:CreateDropdown({ Title, Options, Default }, callback(choice))            -> { Set, Get, Refresh }
	  Section:CreateBind    ({ Title, Default = Enum.KeyCode.X }, callback())          -> { Set, Get }

	  Library:CreateNoti({ Title, Desc, ShowTime })
	  Library:SetAccent(Color3)
	  Window:Toggle() / Window:Destroy() / Page:Select()
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local Library = {
	Theme = {
		Border      = Color3.fromRGB(40, 40, 40),
		Bg1         = Color3.fromRGB(30, 30, 30),
		Bg2         = Color3.fromRGB(45, 45, 45),
		Bg3         = Color3.fromRGB(24, 24, 24),
		Accent      = Color3.fromRGB(90, 160, 255),
		Text        = Color3.fromRGB(220, 220, 220),
		Placeholder = Color3.fromRGB(150, 150, 150),
		Desc        = Color3.fromRGB(180, 180, 180),
		Icon        = Color3.fromRGB(200, 200, 200),
		SliderLine  = Color3.fromRGB(60, 60, 60),
		T1 = 0.25, T2 = 0.5, T3 = 0.1,
	},
	Assets = {
		Slice    = "rbxassetid://8068653048",
		Logo     = "rbxassetid://9327507243",
		Gear     = "rbxassetid://7397332215",
		Search   = "rbxassetid://8154282545",
		Checkbox = "rbxassetid://4552505888",
		Check    = "rbxassetid://4555411759",
		Arrow    = "rbxassetid://6954383209",
	},
	Windows = {},
}

local T = Library.Theme
local A = Library.Assets

--------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------
local function getParent()
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	local ok2 = pcall(function() return game:GetService("CoreGui").Name end)
	if ok2 then return game:GetService("CoreGui") end
	return player:WaitForChild("PlayerGui")
end

local function new(class, props, kids)
	local i = Instance.new(class)
	for k, v in pairs(props or {}) do i[k] = v end
	for _, c in ipairs(kids or {}) do c.Parent = i end
	return i
end

local function corner(r) return new("UICorner", {CornerRadius = UDim.new(0, r)}) end

local function tween(o, props, t)
	TweenService:Create(o, TweenInfo.new(t or T.T1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function rgbTag(c)
	return string.format("rgb(%d,%d,%d)", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

local function draggable(handle, target)
	local dragging, start, startPos
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, start, startPos = true, i.Position, target.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

local function keyName(k)
	if not k then return "None" end
	local s = tostring(k):gsub("Enum%.KeyCode%.", ""):gsub("Enum%.UserInputType%.", "")
	s = s:gsub("MouseButton", "MB")
	return s
end

-- accent color registry (so Library:SetAccent recolors everything live)
local accentFns = {}
local function onAccent(fn)
	table.insert(accentFns, fn)
	fn(T.Accent)
end
local function accent(inst, prop)
	onAccent(function(c) inst[prop] = c end)
end

function Library:SetAccent(color)
	T.Accent = color
	for _, fn in ipairs(accentFns) do pcall(fn, color) end
end

--------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------
local notiGui, notiHolder
local function ensureNoti()
	if notiGui and notiGui.Parent then return end
	local parent = getParent()
	if parent:FindFirstChild("Feral Notification") then parent["Feral Notification"]:Destroy() end
	notiGui = new("ScreenGui", {Name = "Feral Notification", ResetOnSpawn = false, DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parent})
	notiHolder = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.new(0, 260, 1, -20),
		BackgroundTransparency = 1, Parent = notiGui},
		{new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})})
end

function Library:CreateNoti(cfg)
	cfg = cfg or {}
	ensureNoti()
	local showTime = cfg.ShowTime or 5

	local outer = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		ClipsDescendants = true, Parent = notiHolder})
	local card = new("Frame", {Position = UDim2.new(1, 20, 0, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Bg3, BorderSizePixel = 0, Parent = outer},
		{corner(4), new("UIStroke", {Color = T.Border, Thickness = 1.5}),
		 new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})

	local head = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 1, Parent = card})
	new("ImageLabel", {Position = UDim2.fromOffset(6, 2), Size = UDim2.fromOffset(25, 25), BackgroundTransparency = 1, Image = A.Logo, Parent = head})
	local title = new("TextLabel", {Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 14, RichText = true, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = head})
	onAccent(function(c)
		title.Text = string.format('<font color="%s">%s</font>', rgbTag(c), tostring(cfg.Title or "Feral"))
	end)
	local close = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "x", TextSize = 16, TextColor3 = T.Icon, Parent = head})
	close.MouseEnter:Connect(function() tween(close, {TextColor3 = T.Accent}, T.T3) end)
	close.MouseLeave:Connect(function() tween(close, {TextColor3 = T.Icon}, T.T3) end)

	new("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2,
		Font = Enum.Font.GothamBold, TextSize = 14, TextWrapped = true, TextColor3 = T.Desc, TextXAlignment = Enum.TextXAlignment.Left,
		Text = tostring(cfg.Desc or ""), Parent = card},
		{new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})})

	tween(card, {Position = UDim2.new(0, 0, 0, 0)}, T.T1)

	local closed = false
	local function dismiss()
		if closed then return end
		closed = true
		tween(card, {Position = UDim2.new(1, 20, 0, 0)}, T.T1)
		task.wait(T.T1)
		outer:Destroy()
	end
	close.MouseButton1Click:Connect(dismiss)
	task.delay(showTime, dismiss)
	return {Close = dismiss}
end

--------------------------------------------------------------------
-- Window
--------------------------------------------------------------------
function Library:CreateMain(cfg)
	cfg = cfg or {}
	local parent = getParent()
	if parent:FindFirstChild("Feral GUI") then parent["Feral GUI"]:Destroy() end

	local gui = new("ScreenGui", {Name = "Feral GUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parent})

	local main = new("Frame", {Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(629, 359), BackgroundTransparency = 1, Parent = gui})

	local glow = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 30, 1, 30),
		BackgroundTransparency = 1, Image = A.Slice, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(15, 15, 175, 175),
		SliceScale = 1.3, ZIndex = 0, Parent = main})
	accent(glow, "ImageColor3")

	local body = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Bg3, BorderSizePixel = 0, ZIndex = 1,
		Parent = main}, {corner(4)})

	-- top bar
	local top = new("Frame", {Name = "TopMain", Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Parent = body})
	draggable(top, main)
	new("ImageLabel", {Position = UDim2.fromOffset(5, 0), Size = UDim2.fromOffset(25, 25), BackgroundTransparency = 1, Image = A.Logo, Parent = top})
	local titleLabel = new("TextLabel", {Position = UDim2.fromOffset(35, 0), Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, RichText = true, TextSize = 16, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = top})
	onAccent(function(c)
		titleLabel.Text = string.format('<font color="%s">%s</font> %s', rgbTag(c), tostring(cfg.Brand or "Feral"), tostring(cfg.Desc or ""))
	end)

	if cfg.OnSettings then
		local settings = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(30, 30),
			BackgroundTransparency = 1, Parent = top})
		local gear = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -10, 1, -10),
			BackgroundTransparency = 1, Image = A.Gear, ImageColor3 = T.Icon, Parent = settings})
		local sb = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = settings})
		sb.MouseEnter:Connect(function() tween(gear, {ImageColor3 = T.Accent}, T.T3) end)
		sb.MouseLeave:Connect(function() tween(gear, {ImageColor3 = T.Icon}, T.T3) end)
		sb.MouseButton1Click:Connect(function() task.spawn(cfg.OnSettings) end)
	end

	local cont = new("Frame", {Name = "Container", Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -30), BackgroundTransparency = 1, Parent = body})

	-- sidebar
	local side = new("Frame", {Name = "Sidebar", Position = UDim2.fromOffset(5, 0), Size = UDim2.fromOffset(180, 325), BackgroundColor3 = T.Bg1,
		BorderSizePixel = 0, Parent = cont}, {corner(4), new("UIStroke", {Color = T.Border, Thickness = 1.5})})
	new("TextLabel", {Position = UDim2.fromOffset(5, 0), Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
		TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = cfg.Title or "Feral", Parent = side})
	local tabScroll = new("ScrollingFrame", {Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, -5, 1, -30), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 5, Active = true, CanvasSize = UDim2.new(), Parent = side})
	local tabLayout = new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = tabScroll})
	tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabScroll.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 5)
	end)

	-- page area
	local pageArea = new("Frame", {Name = "Pages", Position = UDim2.fromOffset(190, 0), Size = UDim2.fromOffset(435, 325), BackgroundTransparency = 1,
		ClipsDescendants = true, Parent = cont})
	local pageLayout = new("UIPageLayout", {FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder,
		EasingStyle = Enum.EasingStyle.Quart, TweenTime = T.T1, Padding = UDim.new(0, 10), ScrollWheelInputEnabled = false,
		TouchInputEnabled = false, GamepadInputEnabled = false, Parent = pageArea})

	local Window = {Gui = gui, Main = main, Pages = {}, Selected = nil}
	local order = 0
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift

	local keyConn = UIS.InputBegan:Connect(function(i, gp)
		if not gp and i.KeyCode == toggleKey then gui.Enabled = not gui.Enabled end
	end)

	function Window:Toggle(state)
		if state == nil then state = not gui.Enabled end
		gui.Enabled = state
	end
	function Window:SetToggleKey(k) toggleKey = k end
	function Window:Destroy()
		keyConn:Disconnect()
		gui:Destroy()
	end

	----------------------------------------------------------------
	-- Page
	----------------------------------------------------------------
	function Window:CreatePage(name, title)
		order += 1
		local myOrder = order

		local row = new("Frame", {Name = name .. "_Tab", Size = UDim2.new(1, -10, 0, 25), BackgroundTransparency = 1, LayoutOrder = myOrder, Parent = tabScroll})
		local inner = new("Frame", {Position = UDim2.fromOffset(5, 0), Size = UDim2.new(1, -5, 1, 0), BackgroundTransparency = 1, Parent = row})
		local line = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 14, 1, 0),
			BackgroundTransparency = 1, Parent = inner})
		local bar = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(1, -10, 0, 0),
			BorderSizePixel = 0, Parent = line}, {corner(2)})
		accent(bar, "BackgroundColor3")
		new("TextLabel", {Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -15, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
			Text = name, TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = inner})
		local btn = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = inner})

		local page = new("Frame", {Name = "Page_" .. name, Size = UDim2.fromOffset(435, 325), BackgroundColor3 = T.Bg1, BorderSizePixel = 0,
			LayoutOrder = myOrder, Parent = pageArea}, {corner(4)})
		new("TextLabel", {Position = UDim2.fromOffset(5, 0), Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
			Text = title or (name .. " Tab"), TextSize = 16, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = page})
		local list = new("ScrollingFrame", {Position = UDim2.fromOffset(5, 30), Size = UDim2.new(1, -10, 1, -30), BackgroundTransparency = 1,
			BorderSizePixel = 0, ScrollBarThickness = 5, Active = true, CanvasSize = UDim2.new(), Parent = page})
		local listLayout = new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = list})
		listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			list.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 5)
		end)

		-- search box
		local sbox = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -5, 0, 5), Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = T.Bg2, BorderSizePixel = 0, ClipsDescendants = true, Parent = page}, {corner(2)})
		local sicon = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1, Image = A.Search, ImageColor3 = T.Icon, Parent = sbox})
		local sbtn = new("TextButton", {Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Text = "", Parent = sbox})
		local sinput = new("TextBox", {Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold, Text = "", TextSize = 14, PlaceholderText = "Search Section name", PlaceholderColor3 = T.Placeholder,
			TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = sbox})
		local searchOpen = false
		sbtn.MouseEnter:Connect(function() tween(sicon, {ImageColor3 = T.Accent}, T.T3) end)
		sbtn.MouseLeave:Connect(function() tween(sicon, {ImageColor3 = T.Icon}, T.T3) end)
		sbtn.MouseButton1Click:Connect(function()
			searchOpen = not searchOpen
			tween(sbox, {Size = searchOpen and UDim2.fromOffset(190, 20) or UDim2.fromOffset(20, 20)}, T.T2)
			if searchOpen then sinput:CaptureFocus() else sinput.Text = "" end
		end)

		local Page = {Sections = {}}

		local function setSelected(on)
			tween(bar, on and {Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5)}
				or {Size = UDim2.new(1, -10, 0, 0), Position = UDim2.fromScale(0.5, 1), AnchorPoint = Vector2.new(0.5, 1)})
		end
		Page._deselect = function() setSelected(false) end
		function Page:Select()
			if Window.Selected and Window.Selected ~= Page then Window.Selected._deselect() end
			Window.Selected = Page
			setSelected(true)
			pageLayout:JumpTo(page)
		end
		btn.MouseButton1Click:Connect(function() Page:Select() end)

		sinput:GetPropertyChangedSignal("Text"):Connect(function()
			local q = sinput.Text:lower()
			for _, s in ipairs(Page.Sections) do
				s.Frame.Visible = q == "" or s.Name:lower():find(q, 1, true) ~= nil
			end
		end)

		----------------------------------------------------------------
		-- Section
		----------------------------------------------------------------
		function Page:CreateSection(secName)
			local sec = new("Frame", {Name = secName .. "_Section", Size = UDim2.new(1, -5, 0, 100), BackgroundColor3 = T.Bg3, BorderSizePixel = 0,
				LayoutOrder = #Page.Sections + 1, Parent = list}, {corner(4)})
			local secLayout = new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = sec})
			secLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				sec.Size = UDim2.new(1, -5, 0, secLayout.AbsoluteContentSize.Y + 5)
			end)

			local topsec = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 0, Parent = sec})
			local stitle = new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = secName,
				TextSize = 14, TextColor3 = T.Text, Parent = topsec})
			accent(stitle, "TextColor3")
			local uline = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, -10, 0, 2),
				BorderSizePixel = 0, Parent = topsec},
				{new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(0.51, 0.02), NumberSequenceKeypoint.new(1, 1)})})})
			accent(uline, "BackgroundColor3")
			table.insert(Page.Sections, {Name = secName, Frame = sec})

			local Section = {}
			local n = 0
			local function nextOrder() n += 1 return n end
			local function noop() end

			-- shared: a Bg1 row with a title, sized `h`
			local function makeRow(h, name)
				local frame = new("Frame", {Name = name, Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = sec})
				local bg = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -10, 1, 0),
					BackgroundColor3 = T.Bg1, BorderSizePixel = 0, Parent = frame}, {corner(4)})
				return frame, bg
			end

			----------------------------------------------------------------
			-- Toggle
			----------------------------------------------------------------
			function Section:CreateToggle(opts, callback)
				callback = callback or opts.Callback or noop
				local state = opts.Default or false
				local frame = new("Frame", {Name = "Toggle", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
					LayoutOrder = nextOrder(), Parent = sec}, {new("UIPadding", {PaddingBottom = UDim.new(0, 6)})})
				local tf = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, -10, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = frame})
				new("Frame", {Size = UDim2.new(1, 0, 1, 6), BackgroundColor3 = T.Bg1, BorderSizePixel = 0, Parent = tf}, {corner(4)})
				local hasDesc = opts.Description and opts.Description ~= ""
				new("TextLabel", {Position = UDim2.fromOffset(10, hasDesc and 0 or 5), Size = UDim2.new(1, -50, 0, 20), AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = opts.Title, TextSize = 14, TextColor3 = T.Text,
					TextXAlignment = Enum.TextXAlignment.Left, Parent = tf})
				if hasDesc then
					new("TextLabel", {Position = UDim2.fromOffset(15, 20), Size = UDim2.new(1, -50, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = opts.Description, TextSize = 13, TextWrapped = true,
						TextColor3 = T.Desc, TextXAlignment = Enum.TextXAlignment.Left, Parent = tf})
				end
				local checkbox = new("ImageLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 3), Size = UDim2.fromOffset(25, 25),
					BackgroundTransparency = 1, Image = A.Checkbox, ZIndex = 3, Parent = tf})
				accent(checkbox, "ImageColor3")
				local check = new("ImageLabel", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(), BackgroundTransparency = 1,
					Image = A.Check, ImageColor3 = T.Text, ZIndex = 3, Parent = checkbox})
				local click = new("TextButton", {Size = UDim2.new(1, 0, 1, 6), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = tf})

				local function apply(v, silent)
					tween(check, v and {Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5)}
						or {Size = UDim2.new(), Position = UDim2.fromScale(0, 1), AnchorPoint = Vector2.new(0, 1)})
					if not silent then task.spawn(callback, v) end
				end
				click.MouseButton1Click:Connect(function() state = not state apply(state) end)
				if state then apply(true) end
				return {
					Set = function(_, v) state = not not v apply(state) end,
					Get = function() return state end,
				}
			end

			----------------------------------------------------------------
			-- Button
			----------------------------------------------------------------
			function Section:CreateButton(opts, callback)
				callback = callback or opts.Callback or noop
				local frame = new("Frame", {Name = "Button", Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = sec})
				local bg = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -10, 1, 0),
					BorderSizePixel = 0, Parent = frame}, {corner(4)})
				accent(bg, "BackgroundColor3")
				new("TextLabel", {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -10, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack,
					Text = opts.Title, TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = bg})
				local b = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = bg})
				local flash = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
					BorderSizePixel = 0, ZIndex = 2, Parent = bg}, {corner(4)})
				b.MouseButton1Click:Connect(function()
					flash.BackgroundTransparency = 0.7
					tween(flash, {BackgroundTransparency = 1}, T.T1)
					task.spawn(callback)
				end)
				return {Fire = function() task.spawn(callback) end}
			end

			----------------------------------------------------------------
			-- Label
			----------------------------------------------------------------
			function Section:CreateLabel(opts)
				local frame = new("Frame", {Name = "Label", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
					LayoutOrder = nextOrder(), Parent = sec}, {new("UIPadding", {PaddingBottom = UDim.new(0, 6)})})
				local bg = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, -10, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Bg1, BorderSizePixel = 0, Parent = frame}, {corner(4)})
				local text = new("TextLabel", {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = tostring(opts.Title or opts), TextSize = 14, TextWrapped = true,
					TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = bg},
					{new("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5)})})
				return {
					SetText = function(_, s) text.Text = tostring(s) end,
					SetColor = function(_, c) text.TextColor3 = c end,
				}
			end

			----------------------------------------------------------------
			-- Box (text input)
			----------------------------------------------------------------
			function Section:CreateBox(opts, callback)
				callback = callback or opts.Callback or noop
				local _, bg1 = makeRow(60, "Box")
				new("TextLabel", {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -10, 0.5, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack,
					Text = opts.Title, TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = bg1})
				local bg2 = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0, 40), Size = UDim2.new(1, -10, 0, 25),
					BackgroundColor3 = T.Bg2, BorderSizePixel = 0, ClipsDescendants = true, Parent = bg1}, {corner(4)})
				local input = new("TextBox", {Position = UDim2.fromOffset(5, 0), Size = UDim2.new(1, -10, 1, 0), BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold, Text = opts.Default or "", PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = T.Placeholder,
					TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = bg2})
				local hl = new("Frame", {Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = bg2})
				accent(hl, "BackgroundColor3")
				input.Focused:Connect(function() tween(hl, {BackgroundTransparency = 0}) end)
				input.FocusLost:Connect(function()
					tween(hl, {BackgroundTransparency = 1})
					task.spawn(callback, input.Text)
				end)
				return {
					Set = function(_, v) input.Text = tostring(v) end,
					Get = function() return input.Text end,
				}
			end

			----------------------------------------------------------------
			-- Slider
			----------------------------------------------------------------
			function Section:CreateSlider(opts, callback)
				callback = callback or opts.Callback or noop
				local min, max = opts.Min or 0, opts.Max or 100
				local decimals = opts.Decimals or (opts.Precise and 1) or 0
				local mult = 10 ^ decimals
				local function round(v) return math.floor(v * mult + 0.5) / mult end
				local value = math.clamp(round(opts.Default or min), min, max)

				local _, bg = makeRow(50, "Slider")
				new("TextLabel", {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -90, 0, 25), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack,
					Text = opts.Title, TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = bg})
				local vbox = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -5, 0, 3), Size = UDim2.fromOffset(70, 20),
					BackgroundColor3 = T.Bg2, BorderSizePixel = 0, Parent = bg}, {corner(4)})
				local vinput = new("TextBox", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "",
					TextSize = 14, TextColor3 = T.Text, ClearTextOnFocus = false, Parent = vbox})
				local track = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 34), Size = UDim2.new(1, -20, 0, 6),
					BackgroundColor3 = T.SliderLine, BorderSizePixel = 0, Parent = bg}, {corner(3)})
				local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track}, {corner(3)})
				accent(fill, "BackgroundColor3")
				local hit = new("TextButton", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1, Text = "", Parent = track})

				local function render(animate)
					local a = (max == min) and 0 or (value - min) / (max - min)
					if animate then tween(fill, {Size = UDim2.fromScale(a, 1)}, T.T3) else fill.Size = UDim2.fromScale(a, 1) end
					vinput.Text = tostring(value)
				end
				local function setValue(v, silent, animate)
					v = math.clamp(round(v), min, max)
					local changed = v ~= value
					value = v
					render(animate)
					if changed and not silent then task.spawn(callback, value) end
				end
				local function fromMouse()
					local x = UIS:GetMouseLocation().X
					local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
					setValue(min + (max - min) * a)
				end

				local dragging = false
				hit.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						fromMouse()
					end
				end)
				UIS.InputChanged:Connect(function(i)
					if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromMouse() end
				end)
				UIS.InputEnded:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
				end)
				vinput.FocusLost:Connect(function()
					local n = tonumber(vinput.Text)
					if n then setValue(n) else render() end
				end)

				render()
				return {
					Set = function(_, v) setValue(v, false, true) end,
					Get = function() return value end,
				}
			end

			----------------------------------------------------------------
			-- Dropdown
			----------------------------------------------------------------
			function Section:CreateDropdown(opts, callback)
				callback = callback or opts.Callback or noop
				local options = opts.Options or {}
				local cur = opts.Default or options[1]
				local open = false

				local frame = new("Frame", {Name = "Dropdown", Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = sec})
				local bg1 = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -10, 1, 0),
					BackgroundColor3 = T.Bg1, BorderSizePixel = 0, ClipsDescendants = true, Parent = frame}, {corner(4)})
				local head = new("Frame", {Size = UDim2.new(1, 0, 0, 25), BackgroundColor3 = T.Bg2, BorderSizePixel = 0, ZIndex = 2, Parent = bg1}, {corner(4)})
				local label = new("TextLabel", {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1,
					Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = head})
				local arrow = new("ImageLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(15, 15),
					BackgroundTransparency = 1, Image = A.Arrow, ImageColor3 = T.Icon, ZIndex = 2, Parent = head})
				local dbtn = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3, Parent = head})
				local holder = new("Frame", {Position = UDim2.fromOffset(0, 25), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, Parent = bg1})
				local scroll = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true,
					ScrollBarThickness = 5, CanvasSize = UDim2.new(), Parent = holder})
				local scont = new("Frame", {Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -15, 1, -5), BackgroundTransparency = 1, Parent = scroll})
				local lay = new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = scont})
				lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					scroll.CanvasSize = UDim2.fromOffset(0, lay.AbsoluteContentSize.Y + 10)
				end)

				local items = {}
				local function refresh()
					label.Text = opts.Title .. ": " .. tostring(cur)
					for name, it in pairs(items) do tween(it.bar, {BackgroundTransparency = (name == cur) and 0 or 1}) end
				end
				local function rebuild()
					for _, c in ipairs(scont:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
					items = {}
					for i, name in ipairs(options) do
						local it = new("Frame", {Name = tostring(name), Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, LayoutOrder = i, Parent = scont})
						local ln = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 14, 1, 0),
							BackgroundTransparency = 1, Parent = it})
						local b = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -10, 1, -10),
							BackgroundTransparency = 1, BorderSizePixel = 0, Parent = ln}, {corner(4)})
						accent(b, "BackgroundColor3")
						new("TextLabel", {Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -15, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
							Text = tostring(name), TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = it})
						local click = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = it})
						items[name] = {bar = b}
						click.MouseButton1Click:Connect(function()
							cur = name
							refresh()
							task.spawn(callback, cur)
						end)
					end
					refresh()
				end
				rebuild()

				dbtn.MouseButton1Click:Connect(function()
					open = not open
					local listH = math.min(#options * 25 + 10, 170)
					tween(holder, {Size = UDim2.new(1, 0, 0, open and listH or 0)}, T.T2)
					tween(frame, {Size = UDim2.new(1, 0, 0, open and (25 + listH) or 25)}, T.T2)
					tween(arrow, {Rotation = open and 90 or 0}, T.T2)
				end)

				return {
					Set = function(_, v) cur = v refresh() end,
					Get = function() return cur end,
					Refresh = function(_, newOptions, keep)
						options = newOptions
						if not keep or not table.find(options, cur) then cur = options[1] end
						rebuild()
					end,
				}
			end

			----------------------------------------------------------------
			-- Bind (keybind)
			----------------------------------------------------------------
			function Section:CreateBind(opts, callback)
				callback = callback or opts.Callback or noop
				local key = opts.Default
				local listening = false

				local _, bg = makeRow(35, "Bind")
				new("TextLabel", {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack,
					Text = opts.Title, TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = bg})
				local kb = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.fromOffset(80, 25),
					BackgroundColor3 = T.Bg2, BorderSizePixel = 0, Parent = bg}, {corner(4)})
				local btn = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = keyName(key),
					TextSize = 14, TextColor3 = T.Text, Parent = kb})

				btn.MouseButton1Click:Connect(function()
					if listening then return end
					listening = true
					btn.Text = "..."
					task.wait(0.1)
					local conn
					conn = UIS.InputBegan:Connect(function(i)
						local picked
						if i.UserInputType == Enum.UserInputType.Keyboard then
							if i.KeyCode == Enum.KeyCode.Escape then picked = false
							elseif i.KeyCode == Enum.KeyCode.Backspace then picked = "clear"
							else picked = i.KeyCode end
						elseif i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2
							or i.UserInputType == Enum.UserInputType.MouseButton3 then
							picked = i.UserInputType
						end
						if picked == nil then return end
						conn:Disconnect()
						task.defer(function() listening = false end)
						if picked == "clear" then key = nil elseif picked ~= false then key = picked end
						btn.Text = keyName(key)
					end)
				end)

				UIS.InputBegan:Connect(function(i, gp)
					if listening or gp or not key then return end
					if i.KeyCode == key or i.UserInputType == key then task.spawn(callback, key) end
				end)

				return {
					Set = function(_, k) key = k btn.Text = keyName(key) end,
					Get = function() return key end,
				}
			end

			return Section
		end

		table.insert(Window.Pages, Page)
		return Page
	end

	table.insert(Library.Windows, Window)
	return Window
end

return Library
