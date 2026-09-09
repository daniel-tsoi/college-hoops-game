local Players = game:GetService("Players")
local MenuFocus = require(script.Parent:WaitForChild("MenuFocus"))
local UserInputService = game:GetService("UserInputService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("HoopsLeaderboardUI") then return end
local pink, gold = Color3.fromRGB(235, 113, 203), Color3.fromRGB(255, 207, 89)
local white, muted, dark = Color3.fromRGB(246, 247, 250), Color3.fromRGB(170, 182, 201), Color3.fromRGB(9, 14, 22)
local function make(kind, parent, props)
	local object = Instance.new(kind)
	for key, value in pairs(props) do object[key] = value end
	object.Parent = parent
	return object
end
local function text(parent, value, pos, size, fontSize, color)
	return make("TextLabel", parent, { Text = value, Position = pos, Size = size, BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = fontSize, TextColor3 = color or white, TextWrapped = true, BorderSizePixel = 0 })
end
local function button(parent, name, value, pos, size)
	local object = make("TextButton", parent, { Name = name, Text = value, Position = pos, Size = size,
		BackgroundColor3 = dark, TextColor3 = white, Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0, Selectable = true })
	make("UIStroke", object, { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = pink, Thickness = 2 })
	return object
end
local gui = make("ScreenGui", playerGui, { Name = "HoopsLeaderboardUI", ResetOnSpawn = false, DisplayOrder = 18,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets })
local entry = button(gui, "Leaderboard", "LEADERBOARD", UDim2.new(1, -208, 1, -112), UDim2.fromOffset(184, 52))
local page = make("Frame", gui, { Name = "LeaderboardPage", Size = UDim2.fromScale(1, 1), BackgroundColor3 = dark,
	BackgroundTransparency = 0.03, BorderSizePixel = 0, Active = true, Visible = false })
text(page, "TOP 50 TEAMS", UDim2.fromOffset(18, 12), UDim2.new(1, -90, 0, 44), 28, pink).TextXAlignment = Enum.TextXAlignment.Left
local close = button(page, "Close", "X", UDim2.new(1, -62, 0, 12), UDim2.fromOffset(44, 44))
local subtitle = text(page, "Global rankings · Best five-player team OVR", UDim2.fromOffset(18, 62), UDim2.new(1, -36, 0, 38), 16, muted)
local header = make("Frame", page, { Position = UDim2.fromOffset(18, 110), Size = UDim2.new(1, -36, 0, 32), BackgroundTransparency = 1 })
text(header, "RANK", UDim2.new(), UDim2.new(0.17, 0, 1, 0), 13, muted)
text(header, "ROBLOX PLAYER", UDim2.fromScale(0.19, 0), UDim2.fromScale(0.57, 1), 13, muted).TextXAlignment = Enum.TextXAlignment.Left
text(header, "OVR", UDim2.fromScale(0.8, 0), UDim2.fromScale(0.18, 1), 13, gold)
local scroll = make("ScrollingFrame", page, { Name = "Rankings", Position = UDim2.fromOffset(18, 146), Size = UDim2.new(1, -36, 1, -240),
	BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5 })
make("UIListLayout", scroll, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
local status = text(page, "", UDim2.new(0, 18, 1, -86), UDim2.new(1, -150, 0, 70), 14, muted)
local refresh = button(page, "Refresh", "REFRESH", UDim2.new(1, -122, 1, -68), UDim2.fromOffset(104, 44))
local rows, generation, pending = {}, 0, false
local function render(entries)
	for _, row in ipairs(rows) do row:Destroy() end
	rows = {}
	for _, item in ipairs(entries) do
		local row = make("Frame", scroll, { Name = "Rank" .. item.rank, LayoutOrder = item.rank, Size = UDim2.new(1, -10, 0, 54),
			BackgroundColor3 = item.userId == Players.LocalPlayer.UserId and Color3.fromRGB(47, 34, 58) or Color3.fromRGB(22, 30, 44), BorderSizePixel = 0 })
		text(row, "#" .. item.rank, UDim2.new(), UDim2.fromScale(0.17, 1), 20, item.rank <= 3 and gold or muted)
		local name = text(row, item.username, UDim2.fromScale(0.19, 0), UDim2.fromScale(0.57, 1), 18)
		name.TextXAlignment = Enum.TextXAlignment.Left
		text(row, tostring(item.overall), UDim2.fromScale(0.8, 0), UDim2.fromScale(0.18, 1), 24, gold)
		table.insert(rows, row)
	end
end
local load
load = function()
	if pending then return end
	pending = true
	refresh.Active, refresh.Selectable = false, false
	status.Text = "Loading rankings…"
	local requestId = generation
	local ok, result = pcall(function()
		local remote = game:GetService("ReplicatedStorage"):WaitForChild("HoopsLeaderboard", 10)
		if not remote then error("Leaderboard unavailable") end
		return remote:InvokeServer()
	end)
	pending = false
	refresh.Active, refresh.Selectable = true, true
	if generation ~= requestId then
		if page.Visible then task.spawn(load) end
		return
	end
	if ok and result.rows then
		render(result.rows)
		subtitle.Text = result.preview and "Studio ranking · Players in this test session" or "Global rankings · Best five-player team OVR"
		status.Text = result.code == "STALE" and "Showing previous rankings. Refresh to try again."
			or (#result.rows == 0 and "No ranked teams yet. Unlock five unique players to qualify."
			or "Complete five-player teams · Rankings refresh every 30 seconds.")
	else
		status.Text = ok and result.code == "BUSY" and "Please wait a few seconds, then refresh." or "Rankings unavailable. Press Refresh to retry."
	end
end
local mainGui, mainWasEnabled
local function visibility()
	local main = playerGui:FindFirstChild("CollegeHoopsUI")
	entry.Visible = not playerGui:GetAttribute("HoopsPanel") and not (main and main:GetAttribute("PanelOpen"))
end
local function closePage()
	if not page.Visible then return end
	generation += 1
	page.Visible = false
	if mainGui and mainGui.Parent then mainGui.Enabled = mainWasEnabled end
	playerGui:SetAttribute("HoopsPanel", nil)
	MenuFocus.select(entry)
end
entry.Activated:Connect(function()
	if playerGui:GetAttribute("HoopsPanel") then return end
	generation += 1
	mainGui = playerGui:FindFirstChild("CollegeHoopsUI")
	if mainGui then mainWasEnabled = mainGui.Enabled; mainGui.Enabled = false end
	playerGui:SetAttribute("HoopsPanel", "Leaderboard")
	page.Visible = true
	MenuFocus.select(close)
	task.spawn(load)
end)
close.Activated:Connect(closePage)
refresh.Activated:Connect(load)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then closePage() end
end)
playerGui:GetAttributeChangedSignal("HoopsPanel"):Connect(visibility)
local function bindMain(object)
	if object.Name == "CollegeHoopsUI" then object:GetAttributeChangedSignal("PanelOpen"):Connect(visibility); visibility() end
end
playerGui.ChildAdded:Connect(bindMain)
for _, object in ipairs(playerGui:GetChildren()) do bindMain(object) end
visibility()
task.spawn(function()
	while gui.Parent do
		task.wait(30)
		if page.Visible then load() end
	end
end)
