local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuFocus = require(script.Parent:WaitForChild("MenuFocus"))
local UserInputService = game:GetService("UserInputService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("HoopsShopUI") then return end
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopCatalog"))
local Portrait = require(ReplicatedStorage.Shared.CardPortrait)
local gold = Color3.fromRGB(255, 207, 89)
local blue = Color3.fromRGB(104, 192, 255)
local green = Color3.fromRGB(100, 239, 170)
local white = Color3.fromRGB(246, 247, 250)
local muted = Color3.fromRGB(170, 182, 201)
local dark = Color3.fromRGB(9, 14, 22)
local function make(kind, parent, props)
	local object = Instance.new(kind)
	for k, v in pairs(props) do object[k] = v end
	object.Parent = parent
	return object
end
local function stroke(object, color)
	return make("UIStroke", object, { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color, Thickness = 2 })
end
local function label(parent, name, text, pos, size, fontSize, color)
	return make("TextLabel", parent, { Name = name, Text = text, Position = pos, Size = size,
		BackgroundTransparency = 1, TextColor3 = color or white, Font = Enum.Font.GothamBold,
		TextSize = fontSize, TextWrapped = true, BorderSizePixel = 0 })
end
local function button(parent, name, text, pos, size, color)
	local object = make("TextButton", parent, { Name = name, Text = text, Position = pos, Size = size,
		BackgroundColor3 = dark, TextColor3 = white, Font = Enum.Font.GothamBold,
		TextSize = 16, BorderSizePixel = 0, Selectable = true })
	stroke(object, color)
	return object
end
local function money(value)
	local formatted = tostring(math.floor(value)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "$" .. formatted
end
local gui = make("ScreenGui", playerGui, { Name = "HoopsShopUI", ResetOnSpawn = false,
	DisplayOrder = 15, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets })
local entry = button(gui, "Shop", "SHOP", UDim2.new(0, 24, 1, -236), UDim2.fromOffset(184, 52), gold)
local lobbyMoney = label(gui, "Cash", "—", UDim2.new(0, 24, 1, -280), UDim2.fromOffset(184, 36), 27, gold)
local page = make("Frame", gui, { Name = "ShopPage", Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = dark, BackgroundTransparency = 0.06, Visible = false, BorderSizePixel = 0, Active = true })
label(page, "Title", "SHOP", UDim2.fromOffset(18, 12), UDim2.fromOffset(115, 44), 30, gold)
local wallet = label(page, "Wallet", "—", UDim2.new(1, -226, 0, 12), UDim2.fromOffset(150, 44), 21, gold)
local close = button(page, "Close", "X", UDim2.new(1, -62, 0, 12), UDim2.fromOffset(44, 44), muted)
local hofTab = button(page, "HOF", "HOF  ·  8", UDim2.fromOffset(18, 70), UDim2.new(0.5, -27, 0, 42), gold)
local nonTab = button(page, "NonCollege", "NON-COLLEGE  ·  4", UDim2.new(0.5, 9, 0, 70), UDim2.new(0.5, -27, 0, 42), blue)
local subtitle = label(page, "Subtitle", "", UDim2.fromOffset(18, 120), UDim2.new(1, -36, 0, 38), 14, muted)
local scroll = make("ScrollingFrame", page, { Name = "PlayerCards", Position = UDim2.fromOffset(18, 168),
	Size = UDim2.new(1, -36, 1, -246), BackgroundTransparency = 1, BorderSizePixel = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 5,
	ScrollBarImageColor3 = gold, ScrollingDirection = Enum.ScrollingDirection.Y })
make("UIPadding", scroll, { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12) })
local grid = make("UIGridLayout", scroll, { CellPadding = UDim2.fromOffset(16, 16),
	CellSize = UDim2.fromOffset(260, 408), SortOrder = Enum.SortOrder.LayoutOrder })
local status = label(page, "Status", "Loading wallet…", UDim2.new(0, 18, 1, -68), UDim2.new(1, -36, 0, 56), 15, muted)
local state = { ready = false, balance = 0, owned = {}, shopUnlocked = {}, preview = false }
local selectedGroup, pending = "HOF", false
local cards = {}
local request
local function render()
	wallet.Text = money(state.balance)
	lobbyMoney.Text = state.ready and money(state.balance) or "—"
	subtitle.Text = selectedGroup == "HOF" and "HOF roll eligibility · 1/800 tier chance for eligible positions" or "Non-college roll eligibility · 1/750 tier chance for eligible positions"
	hofTab.TextColor3 = selectedGroup == "HOF" and gold or muted
	nonTab.TextColor3 = selectedGroup == "NON-COLLEGE" and blue or muted
	for _, item in ipairs(cards) do
		local offer, buy = item.offer, item.buy
		item.frame.Visible = offer.group == selectedGroup
		local owned = state.shopUnlocked and state.shopUnlocked[offer.id] == true
		local enough = state.balance >= offer.price
		buy.Text = owned and "ROLL UNLOCKED" or ("BUY  ·  " .. money(offer.price))
		buy.TextColor3 = owned and green or (enough and gold or muted)
		buy.Active = state.ready and not pending and not owned and enough
		buy.Selectable = buy.Active
		buy.AutoButtonColor = buy.Active
		local isGold = state.owned[offer.id] == true and state.goldOwned and state.goldOwned[offer.id] == true
		item.frame.Overall.Text = tostring(offer.player.overall + (isGold and 5 or 0))
		item.lock.Text = isGold and "★ GOLD · +5 OVR" or (owned and "ELIGIBLE TO ROLL · NOT A CARD PURCHASE" or "BUY TO ADD TO ROLL POOL")
		item.lock.TextColor3 = owned and green or muted
	end
end
local attributes = { { "shooting", "SHOOTING" }, { "dribbling", "DRIBBLING" },
	{ "defense", "DEFENSE" }, { "speed", "SPEED" }, { "stamina", "STAMINA" } }
for index, offer in ipairs(Catalog.Offers) do
	local player = offer.player
	local accent = offer.group == "HOF" and gold or blue
	local frame = make("Frame", scroll, { Name = offer.id, LayoutOrder = index,
		BackgroundColor3 = Color3.fromRGB(22, 30, 44), BorderSizePixel = 0 })
	stroke(frame, accent)
	label(frame, "Overall", tostring(player.overall), UDim2.fromOffset(12, 8), UDim2.fromOffset(65, 36), 32, accent)
	label(frame, "OVR", "OVR", UDim2.fromOffset(12, 43), UDim2.fromOffset(65, 18), 12, muted)
	label(frame, "Position", player.position, UDim2.new(1, -70, 0, 12), UDim2.fromOffset(58, 28), 22, accent)
	Portrait.mount(frame, player, UDim2.new(0.5, 0, 0, 9), UDim2.fromOffset(124, 100))
	label(frame, "PlayerName", player.name, UDim2.fromOffset(8, 111), UDim2.new(1, -16, 0, 43), 20)
	label(frame, "SchoolSeason", player.school and (player.school .. " · " .. player.season) or "NON-COLLEGE EXCLUSIVE",
		UDim2.fromOffset(8, 157), UDim2.new(1, -16, 0, 26), 12, accent)
	for row, attribute in ipairs(attributes) do
		local y = 194 + (row - 1) * 27
		local statName = label(frame, attribute[1], attribute[2], UDim2.fromOffset(16, y), UDim2.new(1, -82, 0, 21), 13, muted)
		statName.TextXAlignment = Enum.TextXAlignment.Left
		label(frame, attribute[1] .. "Value", tostring(player.attributes[attribute[1]]),
			UDim2.new(1, -62, 0, y), UDim2.fromOffset(46, 21), 17)
	end
	local lock = label(frame, "Ownership", "LOCKED", UDim2.fromOffset(12, 331), UDim2.new(1, -24, 0, 19), 11, muted)
	local buy = button(frame, "Buy", "BUY", UDim2.new(0, 12, 1, -49), UDim2.new(1, -24, 0, 38), accent)
	table.insert(cards, { offer = offer, frame = frame, buy = buy, lock = lock })
	buy.Activated:Connect(function()
		if pending or not state.ready or (state.shopUnlocked and state.shopUnlocked[offer.id]) or state.balance < offer.price then return end
		request("Buy", offer.id, player.name)
	end)
end
request = function(action, id, name)
	if pending then return end
	pending = true
	status.Text = action == "Buy" and "Unlocking roll eligibility…" or "Loading wallet…"
	render()
	local ok, result = pcall(function()
		local remote = ReplicatedStorage:WaitForChild("HoopsShop", 10)
		if not remote then error("Shop server unavailable") end
		return remote:InvokeServer(action, id)
	end)
	pending = false
	if ok and type(result) == "table" then
		state = result
		local messages = {
			READY = result.preview and "Studio trial: $1,000,000 test money. Purchases reset when you stop Play." or "Buy roll eligibility with cash. Only rolled cards enter your collection.",
			PURCHASED = (name or "Player") .. " can now appear in rolls! Roll them to own their card.",
			ELIGIBLE = "This player is already eligible to roll. No money spent.",
			INSUFFICIENT = "Not enough cash. Save up to unlock this player.",
			BUSY = "Please wait a moment, then try again.",
			UNAVAILABLE = "Shop unavailable. Reopen the shop to check your balance and unlocks.",
			INVALID = "This player is unavailable.",
		}
		status.Text = messages[result.code] or "Reopen the shop to check your unlocks."
	else
		state.ready = false
		status.Text = "Could not reach the shop. Reopen it to check your balance and unlocks."
	end
	render()
end
local function fit()
	local width = math.max(1, scroll.AbsoluteSize.X - 16)
	local columns = math.clamp(math.floor((width + 16) / 256), 1, 4)
	grid.CellSize = UDim2.fromOffset(math.floor((width - (columns - 1) * 16) / columns), 408)
end
scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local mainGui, mainWasEnabled
local function closeShop()
	page.Visible = false
	playerGui:SetAttribute("HoopsPanel", nil)
	if mainGui and mainGui.Parent then mainGui.Enabled = mainWasEnabled end
	entry.Visible, lobbyMoney.Visible = true, true
	MenuFocus.select(entry)
end
entry.Activated:Connect(function()
	mainGui = playerGui:FindFirstChild("CollegeHoopsUI")
	if mainGui then mainWasEnabled = mainGui.Enabled; mainGui.Enabled = false end
	entry.Visible, lobbyMoney.Visible, page.Visible = false, false, true
	playerGui:SetAttribute("HoopsPanel", "Shop")
	MenuFocus.select(hofTab)
	task.spawn(request, "State")
end)
close.Activated:Connect(closeShop)
local function selectGroup(group)
	selectedGroup = group
	scroll.CanvasPosition = Vector2.zero
	render()
end
hofTab.Activated:Connect(function() selectGroup("HOF") end)
nonTab.Activated:Connect(function() selectGroup("NON-COLLEGE") end)
local input = UserInputService.InputBegan:Connect(function(key, processed)
	if not processed and page.Visible and (key.KeyCode == Enum.KeyCode.Escape or key.KeyCode == Enum.KeyCode.ButtonB) then closeShop() end
end)
-- Keep the lobby's Shop button out of the squad-building screen.
local function bindMain(object)
	if object.Name ~= "CollegeHoopsUI" then return end
	local function visibility()
		local inSquad = object:GetAttribute("PanelOpen") == true
		entry.Visible = not playerGui:GetAttribute("HoopsPanel") and not inSquad
		lobbyMoney.Visible = entry.Visible
	end
	object:GetAttributeChangedSignal("PanelOpen"):Connect(visibility)
	playerGui:GetAttributeChangedSignal("HoopsPanel"):Connect(visibility)
	visibility()
end
playerGui.ChildAdded:Connect(bindMain)
for _, object in ipairs(playerGui:GetChildren()) do bindMain(object) end
gui.Destroying:Connect(function() input:Disconnect() end)
Players.LocalPlayer:GetAttributeChangedSignal("HoopsCash"):Connect(function()
	state.balance = Players.LocalPlayer:GetAttribute("HoopsCash") or state.balance
	render()
end)
render()
task.spawn(request, "State")
