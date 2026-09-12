local CardMotion = require(script.Parent:WaitForChild("CardMotion"))
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuFocus = require(script.Parent:WaitForChild("MenuFocus"))
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("HoopsCollectionUI") then return end
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopCatalog"))
local Portrait = require(ReplicatedStorage.Shared.CardPortrait)
local blue, green = Color3.fromRGB(104, 192, 255), Color3.fromRGB(100, 239, 170)
local white, muted = Color3.fromRGB(246, 247, 250), Color3.fromRGB(170, 182, 201)
local gold = Color3.fromRGB(255, 207, 89)
local goldOnly = false
local dark = Color3.fromRGB(9, 14, 22)
local function make(kind, parent, props)
	local object = Instance.new(kind)
	for key, value in pairs(props) do object[key] = value end
	object.Parent = parent
	return object
end
local function label(parent, name, value, pos, size, fontSize, color)
	return make("TextLabel", parent, { Name = name, Text = value, Position = pos, Size = size,
		BackgroundTransparency = 1, TextColor3 = color or white, Font = Enum.Font.GothamBold,
		TextSize = fontSize, TextWrapped = true, BorderSizePixel = 0 })
end
local function button(parent, name, value, pos, size)
	local object = make("TextButton", parent, { Name = name, Text = value, Position = pos, Size = size,
		BackgroundColor3 = dark, TextColor3 = white, Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0, Selectable = true })
	make("UIStroke", object, { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = blue, Thickness = 2 })
	return object
end
local gui = make("ScreenGui", playerGui, { Name = "HoopsCollectionUI", ResetOnSpawn = false,
	DisplayOrder = 17, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets })
local entry = button(gui, "Collection", "COLLECTION", UDim2.new(0, 24, 1, -174), UDim2.fromOffset(184, 52))
local goldEntry = button(gui, "GoldCards", "GOLD CARDS", UDim2.new(1, -208, 1, -174), UDim2.fromOffset(184, 52))
goldEntry:FindFirstChildOfClass("UIStroke").Color = gold
goldEntry.TextColor3 = gold
local page = make("Frame", gui, { Name = "CollectionPage", Size = UDim2.fromScale(1, 1), BackgroundColor3 = dark,
	BackgroundTransparency = 0.04, Visible = false, Active = true, BorderSizePixel = 0 })
local title = label(page, "Title", "COLLECTION", UDim2.fromOffset(18, 12), UDim2.new(1, -90, 0, 44), 28, blue)
title.TextXAlignment = Enum.TextXAlignment.Left
local close = button(page, "Close", "X", UDim2.new(1, -62, 0, 12), UDim2.fromOffset(44, 44))
local count = label(page, "Count", "Your unlocked players", UDim2.fromOffset(18, 62), UDim2.new(1, -36, 0, 32), 16, muted)
local scroll = make("ScrollingFrame", page, { Name = "UnlockedPlayers", Position = UDim2.fromOffset(18, 106),
	Size = UDim2.new(1, -36, 1, -186), BackgroundTransparency = 1, BorderSizePixel = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 5 })
make("UIPadding", scroll, { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12) })
local grid = make("UIGridLayout", scroll, { CellPadding = UDim2.fromOffset(16, 16), CellSize = UDim2.fromOffset(230, 286), SortOrder = Enum.SortOrder.LayoutOrder })
local status = label(page, "Status", "", UDim2.new(0, 18, 1, -68), UDim2.new(1, -36, 0, 56), 16, muted)
local state, pending = { owned = {}, collection = {} }, false
local cards = {}
local request
-- Build tiles only for owned cards; the full database can contain thousands.
local function createCard(card)
	local offer = Catalog.ById[card.id] or { number = "★", color = blue }
	local tile = button(scroll, card.id, "", UDim2.new(), UDim2.fromOffset(230, 286))
	local rating = label(tile, "Overall", "", UDim2.fromOffset(10, 8), UDim2.new(0.65, -10, 0, 36), 23, blue)
	label(tile, "Position", card.position, UDim2.new(0.65, 0, 0, 8), UDim2.new(0.35, -10, 0, 36), 20, blue)
	Portrait.mount(tile, card, UDim2.new(0.5, 0, 0, 43), UDim2.fromOffset(132, 112))
	label(tile, "PlayerName", card.name, UDim2.fromOffset(10, 151), UDim2.new(1, -20, 0, 32), 18)
	label(tile, "School", card.school and (card.school .. " · " .. card.season) or "NON-COLLEGE", UDim2.fromOffset(10, 183), UDim2.new(1, -20, 0, 35), 13, muted)
	local badge = label(tile, "GoldBadge", "", UDim2.fromOffset(10, 218), UDim2.new(1, -20, 0, 22), 13, gold)
	local equip = label(tile, "Equip", "CLICK TO EQUIP", UDim2.fromOffset(10, 242), UDim2.new(1, -20, 0, 30), 16, blue)
	CardMotion.attach(tile, false)
	local item = { tile = tile, equip = equip, rating = rating, badge = badge }
	tile.Activated:Connect(function()
		if pending or state.owned[card.id] ~= true or state.equippedCardId == card.id then return end
		request("Equip", card.id)
	end)
	cards[card.id] = item
	return item
end
local function render()
	for _, item in pairs(cards) do item.tile.Visible = false end
	local total = 0
	for index, card in ipairs(state.collection or {}) do
		if state.owned[card.id] == true and (not goldOnly or card.gold) then
			local item = cards[card.id] or createCard(card)
			Portrait.mount(item.tile, card, UDim2.new(0.5, 0, 0, 43), UDim2.fromOffset(132, 112))
			item.tile.LayoutOrder = index
			item.tile.Visible = true
			item.tile.Active, item.tile.Selectable = not pending, not pending
			item.tile.BackgroundColor3 = card.gold and Color3.fromRGB(57, 43, 20) or Color3.fromRGB(22, 30, 44)
			item.tile:FindFirstChildOfClass("UIStroke").Color = card.gold and gold or blue
			item.rating.Text = tostring(card.overall) .. " OVR"
			item.rating.TextColor3 = card.gold and gold or blue
			item.badge.Text = card.gold and "★ GOLD · +5 OVR" or ""
			local equipped = state.equippedCardId == card.id
			item.equip.Text = equipped and "EQUIPPED ✓" or "CLICK TO EQUIP"
			item.equip.TextColor3 = equipped and green or (card.gold and gold or blue)
			total += 1
		end
	end
	count.Text = tostring(total) .. (goldOnly and " GOLD CARDS · +5 OVR · Click to equip" or " UNLOCKED · Select a player to display above your head")
	return total
end
local generation = 0
request = function(action, id)
	if pending then return end
	pending = true
	local requestId = generation
	status.Text = action == "Equip" and "Equipping player…" or "Loading collection…"
	render()
	local ok, result = pcall(function()
		local remote = ReplicatedStorage:WaitForChild("HoopsShop", 10)
		if not remote then error("Collection unavailable") end
		local response
		for _ = 1, 3 do
			response = remote:InvokeServer(action, id)
			if response.code ~= "BUSY" then break end
			task.wait(0.5)
		end
		return response
	end)
	pending = false
	if requestId ~= generation then
		if page.Visible then task.spawn(request, "State") end
		return
	end
	if ok and type(result) == "table" and result.ready then
		state = result
		local total = render()
		if result.code == "EQUIPPED" then
			status.Text = "Equipped! Your selected player card now appears above your head."
		elseif result.code == "READY" then
			status.Text = total == 0 and (goldOnly and "No gold cards yet. Every new unlock has a 5% gold chance." or "No players rolled yet. Open Build Your Squad to roll your first player.") or (goldOnly and "Gold cards keep their +5 OVR bonus when equipped or used in your best team." or "Click an unlocked player to equip their card.")
		else
			status.Text = "Could not complete that action. Please try again."
		end
	else
		status.Text = "Could not load your collection. Close and reopen to retry."
		render()
	end
end
local function fit()
	local width = math.max(1, scroll.AbsoluteSize.X - 16)
	local columns = math.clamp(math.floor((width + 16) / 236), 1, 5)
	grid.CellSize = UDim2.fromOffset(math.floor((width - (columns - 1) * 16) / columns), 286)
end
scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local mainGui, mainWasEnabled
local function visibility()
	local main = playerGui:FindFirstChild("CollegeHoopsUI")
	entry.Visible = not playerGui:GetAttribute("HoopsPanel") and not (main and main:GetAttribute("PanelOpen"))
	goldEntry.Visible = entry.Visible
end
local function closePage()
	if not page.Visible then return end
	generation += 1
	page.Visible = false
	if mainGui and mainGui.Parent then mainGui.Enabled = mainWasEnabled end
	playerGui:SetAttribute("HoopsPanel", nil)
	MenuFocus.select(goldOnly and goldEntry or entry)
end
local function openCollection(onlyGold)
	if playerGui:GetAttribute("HoopsPanel") then return end
	generation += 1
	goldOnly = onlyGold
	title.Text = goldOnly and "GOLD CARDS" or "COLLECTION"
	title.TextColor3 = goldOnly and gold or blue
	scroll.CanvasPosition = Vector2.zero
	render()
	mainGui = playerGui:FindFirstChild("CollegeHoopsUI")
	if mainGui then mainWasEnabled = mainGui.Enabled; mainGui.Enabled = false end
	playerGui:SetAttribute("HoopsPanel", goldOnly and "GoldCards" or "Collection")
	page.Visible = true
	MenuFocus.select(close)
	task.spawn(request, "State")
end
entry.Activated:Connect(function() openCollection(false) end)
goldEntry.Activated:Connect(function() openCollection(true) end)
close.Activated:Connect(closePage)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then closePage() end
end)
playerGui:GetAttributeChangedSignal("HoopsPanel"):Connect(visibility)
local function bindMain(object)
	if object.Name == "CollegeHoopsUI" then object:GetAttributeChangedSignal("PanelOpen"):Connect(visibility); visibility() end
end
playerGui.ChildAdded:Connect(bindMain)
for _, object in ipairs(playerGui:GetChildren()) do bindMain(object) end
player:GetAttributeChangedSignal("HoopsOwnedCount"):Connect(function()
	if page.Visible and not pending then task.spawn(request, "State") end
end)
visibility()
