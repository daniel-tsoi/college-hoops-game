-- Existing UI bootstrap; server-backed roll behavior lives in root RollController.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("CollegeHoopsUI") then
	return -- Prevent duplicate copies of this interface.
end
local preview = RunService:IsStudio()
local colors = {
	background = Color3.fromRGB(15, 20, 29),
	panel = Color3.fromRGB(25, 33, 46),
	button = Color3.fromRGB(43, 56, 74),
	accent = Color3.fromRGB(100, 229, 170),
	danger = Color3.fromRGB(242, 135, 135),
	text = Color3.fromRGB(241, 244, 249),
	muted = Color3.fromRGB(168, 181, 199),
}
local function create(className, parent, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties) do
		object[key] = value
	end
	object.Parent = parent
	return object
end
local function round(object)
	create("UICorner", object, { CornerRadius = UDim.new(0, 3) })
end
local gui = create("ScreenGui", playerGui, {
	Name = "CollegeHoopsUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
})
local background = create("Frame", gui, {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	BorderSizePixel = 0,
})
background:GetPropertyChangedSignal("Visible"):Connect(function()
	gui:SetAttribute("PanelOpen", background.Visible)
end)
local build = create("TextButton", gui, {
	Name = "Build",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.new(1, -32, 0, 64),
	Text = "Build Your Squad",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	BackgroundColor3 = Color3.fromRGB(8, 12, 12),
	TextColor3 = colors.text,
	BorderSizePixel = 0,
	Visible = true,
	Selectable = true,
})
round(build)
create("UISizeConstraint", build, { MaxSize = Vector2.new(320, 64) })
create("UIStroke", build, {
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	Thickness = 2,
	Color = Color3.fromRGB(83, 220, 133),
})
-- A fixed design canvas scales to the available safe area: no scrolling.
local canvas = create("Frame", background, {
	Name = "SquadCanvas",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(1120, 680),
	BackgroundTransparency = 1,
})
local canvasScale = create("UIScale", canvas, { Scale = 1 })
local function fitCanvas()
	local size = background.AbsoluteSize
	canvasScale.Scale = math.min(size.X / 1120, size.Y / 680)
end
local resizeConnection = background:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitCanvas)
fitCanvas()
local function textAt(parent, name, text, x, y, width, height, size, color)
	return create("TextLabel", parent, {
		Name = name,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size,
		TextColor3 = color or colors.text,
		Font = Enum.Font.GothamBold,
		TextWrapped = true,
		TextStrokeTransparency = 0.5,
	})
end
local function outline(object, color)
	create("UIStroke", object, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 2,
		Color = color or colors.accent,
	})
end
textAt(canvas, "Title", "BUILD YOUR\nSQUAD", 24, 18, 280, 100, 38)
textAt(canvas, "Mode", preview and "STUDIO TEST · DISPOSABLE SAVES" or "ROLL YOUR SQUAD", 24, 120, 280, 24, 14, colors.accent)
local counters = textAt(canvas, "Counters", "", 24, 147, 280, 40, 15)
local actions = create("Frame", canvas, {
	Name = "Actions",
	Position = UDim2.fromOffset(44, 202),
	Size = UDim2.fromOffset(240, 422),
	BackgroundTransparency = 1,
})
create("UIListLayout", actions, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
local buttons = {}
local actionNames = { "Roll", "Reroll", "Refresh", "Restart", "Exit" }
for index, name in ipairs(actionNames) do
	local button = create("TextButton", actions, {
		Name = name:gsub(" ", ""),
		LayoutOrder = index,
		Size = UDim2.fromOffset(240, 50),
		Text = name:upper(),
		BackgroundColor3 = Color3.fromRGB(8, 12, 12),
		BackgroundTransparency = 0.12,
		TextColor3 = colors.text,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Selectable = true,
	})
	round(button)
	outline(button, (name == "Restart" or name == "Exit") and colors.danger or colors.accent)
	buttons[name] = button
end
textAt(canvas, "Overall", "TEAM OVR: —", 340, 16, 748, 40, 26)
textAt(canvas, "SchoolSeason", "Named college prospects · Shop unlocks special roll eligibility", 340, 61, 748, 28, 16)
local court = create("Frame", canvas, {
	Name = "CurrentPlayers",
	Position = UDim2.fromOffset(340, 100),
	Size = UDim2.fromOffset(748, 366),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})
outline(court)
local lineup = textAt(court, "LineupCount", "", 12, 6, 724, 26, 17)
local positions = { "PG", "SG", "SF", "PF", "C" }
local slotLocations =
	{ Vector2.new(184, 44), Vector2.new(414, 44), Vector2.new(70, 204), Vector2.new(299, 204), Vector2.new(528, 204) }
local slots = {}
for index, position in ipairs(positions) do
	local point = slotLocations[index]
	local card = textAt(court, position, position .. "\n\nEMPTY", point.X, point.Y, 150, 140, 21)
	card.BackgroundColor3 = colors.panel
	card.BackgroundTransparency = 0.24
	card.BorderSizePixel = 0
	round(card)
	outline(card, colors.muted)
	slots[index] = card
end
textAt(canvas, "CandidatesTitle", "ROLL A PROSPECT  |  ONE PER POSITION", 340, 477, 748, 24, 16)
local candidateButtons = {}
for index, position in ipairs(positions) do
	local card = create("TextButton", canvas, {
		Name = "Candidate" .. position,
		Position = UDim2.fromOffset(340 + (index - 1) * 152, 509),
		Size = UDim2.fromOffset(140, 100),
		Text = position,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextWrapped = true,
		TextColor3 = colors.text,
		BackgroundColor3 = colors.panel,
		BackgroundTransparency = 0.16,
		BorderSizePixel = 0,
		Selectable = true,
		AutoButtonColor = true,
	})
	round(card)
	outline(card, colors.muted)
	candidateButtons[index] = card
end
local reveal = textAt(canvas, "SelectedPlayer", "Select a candidate", 24, 522, 280, 74, 16)
local status = textAt(
	canvas,
	"Status",
	"Loading named prospects…",
	340,
	622,
	748,
	46,
	16
)
status.BackgroundColor3 = colors.panel
status.BackgroundTransparency = 0.15
status.BorderSizePixel = 0

require(script.Parent:WaitForChild("RollController")).attach({
 gui=gui, background=background, build=build, buttons=buttons, slots=slots,
 candidates=candidateButtons, counters=counters, lineup=lineup, reveal=reveal,
 status=status, canvas=canvas, resizeConnection=resizeConnection,
})
