local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuFocus = require(script.Parent:WaitForChild("MenuFocus"))
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("HoopsQuestsUI") then return end
local Quests = require(ReplicatedStorage:WaitForChild("QuestConfig"))
local red = Color3.fromRGB(247, 111, 124)
local green = Color3.fromRGB(100, 239, 170)
local gold = Color3.fromRGB(255, 207, 89)
local muted = Color3.fromRGB(170, 182, 201)
local dark = Color3.fromRGB(9, 14, 22)
local function make(kind, parent, props)
	local object = Instance.new(kind)
	for key, value in pairs(props) do object[key] = value end
	object.Parent = parent
	return object
end
local function text(parent, value, pos, size, fontSize, color)
	return make("TextLabel", parent, { Text = value, Position = pos, Size = size,
		BackgroundTransparency = 1, TextColor3 = color or muted, Font = Enum.Font.GothamBold,
		TextSize = fontSize, TextWrapped = true })
end
local function outline(object, color)
	make("UIStroke", object, { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color, Thickness = 2 })
end
local function button(parent, name, value, pos, size, color)
	local object = make("TextButton", parent, { Name = name, Text = value, Position = pos, Size = size,
		BackgroundColor3 = dark, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
		TextSize = 16, BorderSizePixel = 0, Selectable = true })
	outline(object, color)
	return object
end
local function duration(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end
local function cash(amount)
	return "$" .. tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end
local gui = make("ScreenGui", playerGui, { Name = "HoopsQuestsUI", ResetOnSpawn = false,
	DisplayOrder = 16, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets })
local entry = button(gui, "Quests", "QUESTS", UDim2.new(1, -208, 1, -236), UDim2.fromOffset(184, 52), red)
local page = make("Frame", gui, { Name = "QuestsPage", Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = dark, BackgroundTransparency = 0.06, Visible = false, Active = true, BorderSizePixel = 0 })
text(page, "QUESTS", UDim2.fromOffset(18, 14), UDim2.new(1, -100, 0, 40), 25, red)
local close = button(page, "Close", "X", UDim2.new(1, -62, 0, 12), UDim2.fromOffset(44, 44), muted)
local timer = text(page, "Loading playtime…", UDim2.fromOffset(18, 61), UDim2.new(1, -36, 0, 27), 18, gold)
text(page, "Playtime: permanent milestones. Unlocks & rerolls: reset each login.", UDim2.fromOffset(18, 91), UDim2.new(1, -36, 0, 38), 13)
local balances = text(page, "", UDim2.fromOffset(18, 133), UDim2.new(1, -36, 0, 30), 14, green)
local scroll = make("ScrollingFrame", page, { Name = "Milestones", Position = UDim2.fromOffset(18, 176),
	Size = UDim2.new(1, -36, 1, -258), BackgroundTransparency = 1, BorderSizePixel = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 5,
	ScrollBarImageColor3 = red, ScrollingDirection = Enum.ScrollingDirection.Y })
make("UIPadding", scroll, { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8) })
make("UIListLayout", scroll, { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
local status = text(page, "Play to earn cash, rerolls, and refreshes.", UDim2.new(0, 18, 1, -70), UDim2.new(1, -36, 0, 58), 14)
local state = { ready = false, playSeconds = 0, claimedQuests = {}, rerolls = 0, refreshes = 0 }
local receivedAt, pending = os.clock(), false
local cards = {}
local request
local function render()
	local seconds = state.playSeconds + (state.ready and os.clock() - receivedAt or 0)
	timer.Text = state.ready and ("TIME PLAYED  " .. duration(seconds)) or "Loading playtime…"
	balances.Text = string.format("Quest rewards left: %d rerolls  ·  %d refreshes", state.rerolls, state.refreshes)
	for _, item in ipairs(cards) do
		local quest = item.quest
		local sessionQuest = quest.scope == "SESSION"
		local claimedFlags = sessionQuest and (state.sessionClaimed or {}) or state.claimedQuests
		local claimed = claimedFlags[quest.id] == true
		local progress = sessionQuest and (state[quest.metric] or 0) or seconds
		local target = sessionQuest and quest.target or quest.seconds
		local ready = state.ready and progress >= target
		item.fill.Size = UDim2.fromScale(math.clamp(progress / target, 0, 1), 1)
		local remaining = sessionQuest and string.format("%d / %d this login", math.min(progress, target), target)
			or (duration(target - progress) .. " remaining")
		item.progress.Text = claimed and "Reward collected" or (ready and "Ready to claim!" or remaining)
		item.claim.Text = claimed and "CLAIMED" or (ready and "CLAIM" or "LOCKED")
		item.claim.TextColor3 = (ready or claimed) and green or muted
		item.claim.Active = ready and not claimed and not pending
		item.claim.Selectable = item.claim.Active
		item.claim.AutoButtonColor = item.claim.Active
	end
end
for index, quest in ipairs(Quests) do
	local card = make("Frame", scroll, { Name = quest.id, LayoutOrder = index, Size = UDim2.new(1, 0, 0, 182),
		BackgroundColor3 = Color3.fromRGB(22, 30, 44), BorderSizePixel = 0 })
	outline(card, red)
	text(card, (quest.title or string.format("PLAY %d %s", quest.hours or 0, quest.hours == 1 and "HOUR" or "HOURS")), UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 30), 21, Color3.new(1, 1, 1))
	local rewards = quest.scope == "SESSION"
		and { cash(quest.cash) .. "\nCASH", "RESETS EACH\nLOGIN", "CLAIM ONCE\nPER LOGIN" }
		or { cash(quest.cash) .. "\nCASH", quest.rerolls .. "\nREROLLS", quest.refreshes .. "\nREFRESHES" }
	for col, reward in ipairs(rewards) do
		text(card, reward, UDim2.new((col - 1) / 3, 4, 0, 46), UDim2.new(1 / 3, -8, 0, 48), 16, col == 1 and gold or green)
	end
	local track = make("Frame", card, { Position = UDim2.new(0, 12, 0, 104), Size = UDim2.new(1, -24, 0, 8),
		BackgroundColor3 = Color3.fromRGB(47, 58, 74), BorderSizePixel = 0, ClipsDescendants = true })
	local fill = make("Frame", track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = green, BorderSizePixel = 0 })
	local progress = text(card, "", UDim2.fromOffset(12, 124), UDim2.new(1, -136, 0, 42), 13)
	local claim = button(card, "Claim", "LOCKED", UDim2.new(1, -116, 0, 126), UDim2.fromOffset(104, 38), green)
	table.insert(cards, { quest = quest, fill = fill, progress = progress, claim = claim })
	claim.Activated:Connect(function()
		if not claim.Active or pending then return end
		request("ClaimQuest", quest.id)
	end)
end
request = function(action, id)
	if pending then return end
	pending = true
	if action == "ClaimQuest" then status.Text = "Claiming rewards…" end
	render()
	local ok, result = pcall(function()
		local remote = ReplicatedStorage:WaitForChild("HoopsShop", 10)
		if not remote then error("Profile server unavailable") end
		return remote:InvokeServer(action, id)
	end)
	pending = false
	if ok and type(result) == "table" then
		state, receivedAt = result, os.clock()
		local messages = {
			READY = result.preview and "Studio trial: real-time timer; progress resets when Play stops." or "Playtime saves across visits. Activity quests start fresh each login.",
			REWARDED = "Reward claimed and added to your balance!",
			CLAIMED = "You already collected this reward.", NOT_READY = "Keep playing! This milestone is not ready yet.",
			STALE_SESSION = "A newer login is active. Rejoin to continue here.",
			BUSY = "Please wait a moment, then try again.", INVALID = "This quest is unavailable.",
			UNAVAILABLE = "Could not save rewards. Refreshing will check whether your claim was saved.",
		}
		if action ~= "State" or status.Text == "Loading…" or not result.ready then
			status.Text = messages[result.code] or "Please reopen Quests to refresh."
		end
	else
		state.ready = false
		status.Text = "Could not reach the server. Your progress will refresh shortly."
	end
	render()
end
-- Stack lobby controls on narrow screens so they do not cover Build or Shop.
local function fitLobby()
	entry.Position = UDim2.new(1, -208, 1, -236)
end
page:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitLobby)
fitLobby()
local mainGui, wasEnabled
local function visibility()
	local main = playerGui:FindFirstChild("CollegeHoopsUI")
	entry.Visible = not playerGui:GetAttribute("HoopsPanel") and not (main and main:GetAttribute("PanelOpen"))
end
local function bindMain(object)
	if object.Name == "CollegeHoopsUI" then object:GetAttributeChangedSignal("PanelOpen"):Connect(visibility) end
end
playerGui.ChildAdded:Connect(bindMain)
for _, object in ipairs(playerGui:GetChildren()) do bindMain(object) end
playerGui:GetAttributeChangedSignal("HoopsPanel"):Connect(visibility)
entry.Activated:Connect(function()
	mainGui = playerGui:FindFirstChild("CollegeHoopsUI")
	if mainGui then wasEnabled = mainGui.Enabled; mainGui.Enabled = false end
	page.Visible = true
	playerGui:SetAttribute("HoopsPanel", "Quests")
	status.Text = "Loading…"
	MenuFocus.select(close)
	task.spawn(request, "State")
end)
local function closePage()
	page.Visible = false
	if mainGui and mainGui.Parent then mainGui.Enabled = wasEnabled end
	playerGui:SetAttribute("HoopsPanel", nil)
	MenuFocus.select(entry)
end
close.Activated:Connect(closePage)
local input = UserInputService.InputBegan:Connect(function(key, processed)
	if not processed and page.Visible and (key.KeyCode == Enum.KeyCode.Escape or key.KeyCode == Enum.KeyCode.ButtonB) then closePage() end
end)
gui.Destroying:Connect(function() input:Disconnect() end)
visibility()
render()
task.spawn(function()
	local ticks = 0
	while gui.Parent do
		task.wait(1)
		if page.Visible then
			render()
			ticks += 1
			if ticks % 15 == 0 or not state.ready then task.spawn(request, "State") end
		end
	end
end)
