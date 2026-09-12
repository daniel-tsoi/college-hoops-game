local CardMotion = require(script.Parent:WaitForChild("CardMotion"))
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuFocus = require(script.Parent:WaitForChild("MenuFocus"))
local UserInputService = game:GetService("UserInputService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("HoopsBestTeamUI") then return end
local Portrait = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CardPortrait"))
local blue = Color3.fromRGB(104, 192, 255)
local white = Color3.fromRGB(246, 247, 250)
local muted = Color3.fromRGB(170, 182, 201)
local dark = Color3.fromRGB(9, 14, 22)
local function make(kind, parent, props)
	local object = Instance.new(kind)
	for key, value in pairs(props) do object[key] = value end
	object.Parent = parent
	return object
end
local function outline(object, color)
	make("UIStroke", object, { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color, Thickness = 2 })
end
local function label(parent, name, value, x, y, w, h, size, color)
	return make("TextLabel", parent, { Name = name, Text = value, Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, TextColor3 = color or white,
		Font = Enum.Font.GothamBold, TextSize = size, TextWrapped = true, BorderSizePixel = 0 })
end
local function button(parent, name, value, position, size)
	local object = make("TextButton", parent, { Name = name, Text = value, Position = position,
		Size = size, BackgroundColor3 = dark, TextColor3 = white, Font = Enum.Font.GothamBold,
		TextSize = 16, BorderSizePixel = 0, Selectable = true })
	outline(object, blue)
	return object
end
local gui = make("ScreenGui", playerGui, { Name = "HoopsBestTeamUI", ResetOnSpawn = false,
	DisplayOrder = 16, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets })
local entry = button(gui, "BestTeam", "BEST TEAM", UDim2.new(0, 24, 1, -112), UDim2.fromOffset(184, 52))
local page = make("Frame", gui, { Name = "BestTeamPage", Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = dark, BackgroundTransparency = 0.04, BorderSizePixel = 0, Visible = false, Active = true })
local canvas = make("Frame", page, { Name = "LineupCanvas", AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(900, 680), BackgroundTransparency = 1 })
local scale = make("UIScale", canvas, { Scale = 1 })
local function fit()
	scale.Scale = math.min(page.AbsoluteSize.X / 924, page.AbsoluteSize.Y / 704, 1.2)
end
page:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
label(canvas, "Title", "BEST TEAM", 24, 8, 360, 48, 32, blue).TextXAlignment = Enum.TextXAlignment.Left
local close = button(canvas, "Close", "X", UDim2.fromOffset(826, 12), UDim2.fromOffset(48, 44))
local status = label(canvas, "Status", "", 30, 624, 840, 44, 17, muted)
local points = { Vector2.new(450, 166), Vector2.new(725, 312), Vector2.new(690, 534),
	Vector2.new(210, 534), Vector2.new(175, 312), Vector2.new(450, 534) }
local overall = label(canvas, "TeamOverall", "—", 340, 300, 220, 72, 58, blue)
label(canvas, "OverallCaption", "TEAM OVR", 340, 373, 220, 28, 18, muted)
local count = label(canvas, "PlayerCount", "0 / 5 PLAYERS", 330, 405, 240, 26, 15, muted)
local slots = {}
for index, point in ipairs(points) do
	local card = make("Frame", canvas, { Name = "Player" .. index, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(point.X, point.Y), Size = UDim2.fromOffset(186, 160),
		BackgroundColor3 = Color3.fromRGB(22, 30, 44), BorderSizePixel = 0 })
	outline(card, blue)
	CardMotion.attach(card, false)
	local rating = label(card, "Overall", "—", 8, 3, 84, 26, 23, blue)
	local position = label(card, "Position", "", 116, 3, 60, 26, 18, blue)
	local name = label(card, "PlayerName", "EMPTY SLOT", 8, 110, 170, 28, 15)
	local rarity = label(card, "Rarity", "Roll a player", 8, 140, 170, 17, 10, muted)
	slots[index] = { frame = card, rating = rating, position = position, name = name, rarity = rarity }
end
local Lines = require(script.Parent:WaitForChild("ChemistryLines"))
local cardFrames = {}
for i, slot in ipairs(slots) do cardFrames[i] = slot.frame end
local connections = Lines.mount(canvas, cardFrames, {overall, canvas.OverallCaption, count})
Lines.legend(canvas, UDim2.fromOffset(520, 20), UDim2.fromOffset(285, 24))
local function render(team)
	local players = team and team.players or {}
	connections.render(players)
	overall.Text = #players > 0 and tostring(team.overall) or "—"
	count.Text = #players == 6 and "5 STARTERS + SIXTH MAN" or string.format("%d / 5 STARTERS", #players)
	for index, slot in ipairs(slots) do
		local card = players[index]
		slot.frame.Visible = index <= 5 or card ~= nil
		Portrait.mount(slot.frame, card, UDim2.new(0.5, 0, 0, 29), UDim2.fromOffset(94, 80))
		slot.rating.Text = card and tostring(card.overall) or "—"
		slot.position.Text = index == 6 and "6TH" or (card and card.position or "")
		slot.name.Text = card and card.name or "EMPTY SLOT"
		slot.rarity.Text = card and ((card.gold and "GOLD +5 · " or "") .. card.rarity) or "Roll a player"
		slot.rating.TextColor3 = card and card.gold and Color3.fromRGB(255, 207, 89) or blue
		slot.rarity.TextColor3 = card and card.gold and Color3.fromRGB(255, 207, 89) or muted
	end
end
local mainGui, mainWasEnabled
local generation = 0
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
	visibility()
	MenuFocus.select(entry)
end
entry.Activated:Connect(function()
	if playerGui:GetAttribute("HoopsPanel") then return end
	generation += 1
	local requestId = generation
	mainGui = playerGui:FindFirstChild("CollegeHoopsUI")
	if mainGui then mainWasEnabled = mainGui.Enabled; mainGui.Enabled = false end
	playerGui:SetAttribute("HoopsPanel", "BestTeam")
	page.Visible = true
	MenuFocus.select(close)
	render(nil)
	status.Text = "Loading your best completed team…"
	task.spawn(function()
		local ok, result = pcall(function()
			local remote = ReplicatedStorage:WaitForChild("HoopsShop", 10)
			if not remote then error("Roster unavailable") end
			local response
			for _ = 1, 3 do
				response = remote:InvokeServer("State")
				if response.code ~= "BUSY" then break end
				task.wait(0.5)
			end
			return response
		end)
		if generation ~= requestId then return end
		if not ok or type(result) ~= "table" or not result.ready or not result.bestTeam then
			status.Text = "Could not load your roster. Close and reopen Best Team to retry."
			return
		end
		render(result.bestTeam)
		local n = #result.bestTeam.players
		status.Text = n == 0 and "Finish all five positions in one run to set your first team record."
			or "Best complete run · Gold and chemistry included · Only a higher team OVR replaces it."
	end)
end)
close.Activated:Connect(closePage)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then closePage() end
end)
playerGui:GetAttributeChangedSignal("HoopsPanel"):Connect(visibility)
local function bindMain(object)
	if object.Name == "CollegeHoopsUI" then
		object:GetAttributeChangedSignal("PanelOpen"):Connect(visibility)
		visibility()
	end
end
playerGui.ChildAdded:Connect(bindMain)
for _, object in ipairs(playerGui:GetChildren()) do bindMain(object) end
visibility()
