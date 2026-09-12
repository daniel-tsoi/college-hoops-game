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
text(page, "Buy 2× to receive all doubled rewards instantly — no progress needed.", UDim2.fromOffset(18, 88), UDim2.new(1, -36, 0, 22), 13)
local balances = text(page, "", UDim2.fromOffset(18, 112), UDim2.new(1, -36, 0, 22), 14, green)
local summary = text(page, "", UDim2.fromOffset(18, 136), UDim2.new(1, -36, 0, 36), 13, gold)
local scroll = make("ScrollingFrame", page, { Name = "Milestones", Position = UDim2.fromOffset(18, 176),
	Size = UDim2.new(1, -36, 1, -258), BackgroundTransparency = 1, BorderSizePixel = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 5,
	ScrollBarImageColor3 = red, ScrollingDirection = Enum.ScrollingDirection.Y })
make("UIPadding", scroll, { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8) })
make("UIListLayout", scroll, { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
local status = text(page, "Play to earn cash, rerolls, and refreshes.", UDim2.new(0, 18, 1, -70), UDim2.new(1, -36, 0, 58), 14)
local state = { ready = false, playSeconds = 0, sessionSeconds = 0, claimedQuests = {}, rerolls = 0, refreshes = 0,
	logins = 0, sessionCash = 0, sessionHistory = {} }
local receivedAt, pending = os.clock(), false
local cards = {}
local request
local renderHistory
local function render()
	-- Both clocks tick locally between server checkpoints.
	local drift = state.ready and os.clock() - receivedAt or 0
	local seconds = state.playSeconds + drift
	local sessionSeconds = (state.sessionSeconds or 0) + drift
	timer.Text = state.ready and string.format("THIS LOGIN  %s   ·   ALL TIME  %s", duration(sessionSeconds), duration(seconds))
		or "Loading playtime…"
	balances.Text = string.format("Quest rewards left: %d rerolls  ·  %d refreshes", state.rerolls, state.refreshes)
	if state.ready then
		summary.Text = string.format("Login #%d  ·  this login: %s earned, %d cards, %d rerolls used",
			state.logins or 0, cash(state.sessionCash or 0), state.sessionUnlocks or 0, state.sessionRerolls or 0)
	else
		summary.Text = ""
	end
	renderHistory()
	for _, item in ipairs(cards) do
		local quest = item.quest
		-- Every quest is per-login now; time quests read the session clock.
		local timeQuest = quest.hours ~= nil
		local claimed = (state.sessionClaimed or {})[quest.id] == true
		local progress = timeQuest and sessionSeconds or (state[quest.metric] or 0)
		local target = quest.target
		local doubled = ((state.questDoubleCredits or {})[quest.id] or 0) > 0 or (state.sessionDoubled or {})[quest.id] == true
  local multiplier = doubled and 2 or 1
  item.rewardLabels[1].Text = cash(quest.cash * multiplier) .. "\nCASH"
  if quest.rerolls > 0 then
   item.rewardLabels[2].Text = quest.rerolls * multiplier .. "\nREROLLS"
   item.rewardLabels[3].Text = quest.refreshes * multiplier .. "\nREFRESHES"
  end
  item.double.Text = "2× NOW · " .. quest.doublePrice .. " Robux"
  item.double.Active = state.ready and not pending
  item.double.Selectable = item.double.Active
  item.double.AutoButtonColor = item.double.Active
  local ready = state.ready and progress >= target
		item.fill.Size = UDim2.fromScale(math.clamp(progress / target, 0, 1), 1)
		local remaining = timeQuest and (duration(math.max(0, target - progress)) .. " left this login")
			or string.format("%d / %d this login", math.min(progress, target), target)
		item.progress.Text = claimed and "Collected — resets next login" or (ready and "Ready to claim!" or remaining)
		item.claim.Text = claimed and "CLAIMED" or (ready and "CLAIM" or "LOCKED")
		item.claim.TextColor3 = (ready or claimed) and green or muted
		item.claim.Active = ready and not claimed and not pending
		item.claim.Selectable = item.claim.Active
		item.claim.AutoButtonColor = item.claim.Active
	end
end
for index, quest in ipairs(Quests) do
	local card = make("Frame", scroll, { Name = quest.id, LayoutOrder = index, Size = UDim2.new(1, 0, 0, 234),
		BackgroundColor3 = Color3.fromRGB(22, 30, 44), BorderSizePixel = 0 })
	outline(card, red)
	text(card, (quest.title or string.format("PLAY %d %s", quest.hours or 0, quest.hours == 1 and "HOUR" or "HOURS")), UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 30), 21, Color3.new(1, 1, 1))
	local rewards = quest.rerolls > 0
		and { cash(quest.cash) .. "\nCASH", quest.rerolls .. "\nREROLLS", quest.refreshes .. "\nREFRESHES" }
		or { cash(quest.cash) .. "\nCASH", "RESETS EACH\nLOGIN", "CLAIM ONCE\nPER LOGIN" }
	local rewardLabels = {}
	for col, reward in ipairs(rewards) do
		rewardLabels[col] = text(card, reward, UDim2.new((col - 1) / 3, 4, 0, 46), UDim2.new(1 / 3, -8, 0, 48), 16, col == 1 and gold or green)
	end
	local track = make("Frame", card, { Position = UDim2.new(0, 12, 0, 104), Size = UDim2.new(1, -24, 0, 8),
		BackgroundColor3 = Color3.fromRGB(47, 58, 74), BorderSizePixel = 0, ClipsDescendants = true })
	local fill = make("Frame", track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = green, BorderSizePixel = 0 })
	local progress = text(card, "", UDim2.fromOffset(12, 116), UDim2.new(1, -24, 0, 30), 13)
	local claim = button(card, "Claim", "LOCKED", UDim2.new(0.6, 6, 0, 154), UDim2.new(0.4, -18, 0, 57), green)
	local double = button(card, "DoubleRewards", "2× · " .. quest.doublePrice .. " Robux", UDim2.fromOffset(12, 154), UDim2.new(0.6, -18, 0, 57), gold)
 double.TextSize = 21
 claim.TextSize = 24
 for _,b in ipairs({double,claim}) do
  b.TextScaled = true
  local limit = make("UITextSizeConstraint", b, {MinTextSize=12,MaxTextSize=b.TextSize})
 end
 double.Activated:Connect(function()
  if double.Active and not pending then request("PurchaseQuestDouble", quest.id) end
 end)
 table.insert(cards, { quest = quest, fill = fill, progress = progress, claim = claim, double = double, rewardLabels = rewardLabels })
	claim.Activated:Connect(function()
		if not claim.Active or pending then return end
		request("ClaimQuest", quest.id)
	end)
end
-- The saved record of recent logins: what the player did in each past session.
local historyPanel = make("Frame", scroll, { Name = "History", LayoutOrder = 100,
	Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
make("UIListLayout", historyPanel, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
local historyTitle = text(historyPanel, "RECENT LOGINS", UDim2.new(), UDim2.new(1, 0, 0, 30), 18, red)
historyTitle.LayoutOrder = 1
historyTitle.TextXAlignment = Enum.TextXAlignment.Left
local historyRows, historySignature = {}, nil
local function historyRow(value, order, color)
	local row = text(historyPanel, value, UDim2.new(), UDim2.new(1, 0, 0, 26), 13, color)
	row.LayoutOrder = order
	row.TextXAlignment = Enum.TextXAlignment.Left
	-- Grow instead of clipping when the line wraps on a narrow screen.
	row.AutomaticSize = Enum.AutomaticSize.Y
	table.insert(historyRows, row)
end
-- Rebuilt only when the saved history actually changes, not every render tick.
renderHistory = function()
	local entries = state.sessionHistory or {}
	local signature = string.format("%d:%s:%s", #entries, tostring(entries[1] and entries[1].startedAt), tostring(state.logins))
	if signature == historySignature then return end
	historySignature = signature
	for _, row in ipairs(historyRows) do row:Destroy() end
	historyRows = {}
	if #entries == 0 then
		historyRow(state.ready and "No earlier sessions saved yet — this is your first login." or "", 2)
		return
	end
	for index, entry in ipairs(entries) do
		local when = entry.startedAt and os.date("!%b %d  %H:%M", entry.startedAt) or "earlier session"
		historyRow(string.format("%s   ·   %s played   ·   %d cards   ·   %d rerolls   ·   %s earned",
			when, duration(entry.seconds or 0), entry.unlocks or 0, entry.rerolls or 0, cash(entry.cash or 0)),
			index + 1, index == 1 and green or muted)
	end
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
			READY = result.preview and "Studio trial: real-time timer; progress resets when Play stops." or "Cards and cash are saved forever. Every reward resets each login.",
			REWARDED = "Reward claimed and added to your balance!",
   PURCHASE_PROMPTED = "Complete the Roblox purchase to receive all doubled rewards instantly.",
   DOUBLE_READY = "2× is ready. Complete this quest and claim all doubled rewards.",
   PRODUCT_UNCONFIGURED = "This 2× purchase is not available yet.",
			CLAIMED = "Already collected this login. Rejoin to earn it again.", NOT_READY = "Keep playing! This reward is not ready yet.",
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
local grantedConnection
 task.spawn(function()
  local event = ReplicatedStorage:WaitForChild("HoopsPurchaseGranted", 30)
  if not event or not gui.Parent then return end
  grantedConnection = event.OnClientEvent:Connect(function()
   task.wait(0.5)
   while pending and gui.Parent do task.wait(0.1) end
   if gui.Parent then request("State") end
  end)
 end)
 gui.Destroying:Connect(function() if grantedConnection then grantedConnection:Disconnect() end end)
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
