-- Render every player’s overhead card in PlayerGui so ViewportFrame portraits display.
-- Equipped-card attributes still replicate from the server.
local Players = game:GetService("Players")
local Database = require(game:GetService("ReplicatedStorage").Shared.PlayerDatabase)
local Portrait = require(game:GetService("ReplicatedStorage").Shared.CardPortrait)
local function make(kind, parent, props)
	local object = Instance.new(kind)
	for key, value in pairs(props) do object[key] = value end
	object.Parent = parent
	return object
end
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local cards = {}
local connections = {}
local function clear(player)
	if cards[player] then cards[player]:Destroy(); cards[player] = nil end
end
local function render(player)
	clear(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local id = player:GetAttribute("EquippedCardId")
	local card = Database.ById[id]
	if not card then return end
	local isGold = player:GetAttribute("EquippedCardGold") == true
	local gui = make("BillboardGui", playerGui, { Name = "EquippedPlayerCard", Adornee = head, ResetOnSpawn = false,
		Size = UDim2.fromOffset(150, 180), StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0),
		MaxDistance = 80, AlwaysOnTop = false, LightInfluence = 0 })
	cards[player] = gui
	local frame = make("Frame", gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = isGold and Color3.fromRGB(255, 210, 82) or Color3.fromRGB(135, 207, 224), BorderSizePixel = 0 })
	make("UICorner", frame, { CornerRadius = UDim.new(0, 16) })
	make("UIStroke", frame, { Color = isGold and Color3.fromRGB(174, 115, 17) or Color3.fromRGB(39, 95, 122), Thickness = 3 })
	local function text(name, value, x, y, w, h, size)
		return make("TextLabel", frame, { Name = name, Text = value, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
			BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = size, TextColor3 = Color3.fromRGB(15, 43, 59), TextWrapped = true })
	end
	text("Overall", tostring(card.overall + (isGold and 5 or 0)), 5, 5, 65, 35, 29)
	if isGold then text("Gold", "GOLD +5", 36, 21, 78, 18, 10) end
	text("Position", card.position, 97, 10, 48, 26, 19)
	local display = table.clone(card)
	display.gold = isGold
	Portrait.mount(frame, display, UDim2.new(0.5, 0, 0, 35), UDim2.fromOffset(106, 92))
	text("PlayerName", card.name, 6, 126, 138, 46, 17)
end
local function joined(player)
	local function characterAdded(character)
		task.spawn(function()
			character:WaitForChild("Head", 10)
			if player.Parent == Players and player.Character == character then render(player) end
		end)
	end
	connections[player] = {
		player:GetAttributeChangedSignal("EquippedCardId"):Connect(function() render(player) end),
		player:GetAttributeChangedSignal("EquippedCardGold"):Connect(function() render(player) end),
		player.CharacterAdded:Connect(characterAdded),
		player.CharacterRemoving:Connect(function() clear(player) end),
	}
	if player.Character then characterAdded(player.Character) end
end
Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(player)
	clear(player)
	for _, connection in ipairs(connections[player] or {}) do connection:Disconnect() end
	connections[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do joined(player) end
