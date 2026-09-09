-- Migration: replace the old server renderer saved in the canonical place.
-- ViewportFrame cards now render exclusively in each client's PlayerGui.
local Players = game:GetService("Players")
-- Rojo preserves unknown instances; an old same-named Script may survive sync.
for _, sibling in ipairs(script.Parent:GetChildren()) do
	if sibling ~= script and sibling:IsA("Script") and sibling.Name == "EquippedCard" then
		sibling.Enabled = false
		sibling:Destroy()
	end
end
local function characterAdded(character)
	local function removeLegacy(instance)
		if instance:IsA("BillboardGui") and instance.Name == "EquippedPlayerCard" then
			instance:Destroy()
		end
	end
	character.DescendantAdded:Connect(removeLegacy)
	for _, instance in ipairs(character:GetDescendants()) do removeLegacy(instance) end
end
local function joined(player)
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then characterAdded(player.Character) end
end
Players.PlayerAdded:Connect(joined)
for _, player in ipairs(Players:GetPlayers()) do joined(player) end
