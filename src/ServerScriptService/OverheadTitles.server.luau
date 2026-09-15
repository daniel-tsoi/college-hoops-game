local Players = game:GetService("Players")
local Titles = require(game:GetService("ReplicatedStorage").Shared.PlayerTitles)
local Roles = require(script.Parent.Config.TitleRoles)

local function roleFor(player)
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then return "Creator" end
	for _, role in ipairs({ "Creator", "Admin", "Tester" }) do
		if Roles[role][player.UserId] then return role end
	end
	return nil
end
local function refresh(player)
	local role = roleFor(player)
	local title = Titles.resolve(role, player:GetAttribute("LeaderboardRank"))
	player:SetAttribute("HoopsTitle", title)
	-- Published so clients can show the role and the rank together; the
	-- nameplate below still shows only the single resolved title.
	player:SetAttribute("HoopsRole", role)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local gui = head and head:FindFirstChild("HoopsNameplate")
	if gui then
		gui.Title.Text = title or ""
		gui.Title.TextColor3 = Titles.Colors[title] or Color3.new(1, 1, 1)
	end
end
local function joined(player)
	local function characterAdded(character)
		local head = character:WaitForChild("Head", 10)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not head or not humanoid or player.Character ~= character or player.Parent ~= Players then return end
		local old = head:FindFirstChild("HoopsNameplate")
		if old then old:Destroy() end
		humanoid.NameDisplayDistance = 0
		local gui = Instance.new("BillboardGui")
		gui.Name = "HoopsNameplate"
		gui.Adornee = head
		gui.Size = UDim2.fromOffset(240, 64)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
		gui.MaxDistance = 80
		gui.LightInfluence = 0
		gui.AlwaysOnTop = false
		for index, name in ipairs({ "Title", "Username" }) do
			local label = Instance.new("TextLabel")
			label.Name = name
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(1, 0, 0, 30)
			label.Position = UDim2.fromOffset(0, (index - 1) * 30)
			label.Font = Enum.Font.GothamBold
			label.TextSize = index == 1 and 24 or 20
			label.TextColor3 = Color3.new(1, 1, 1)
			label.Text = index == 2 and player.Name or ""
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(24, 20, 34)
			stroke.Thickness = 2
			stroke.Parent = label
			label.Parent = gui
		end
		gui.Parent = head
		refresh(player)
	end
	player:GetAttributeChangedSignal("LeaderboardRank"):Connect(function() refresh(player) end)
	player.CharacterAdded:Connect(characterAdded)
	refresh(player)
	if player.Character then task.spawn(characterAdded, player.Character) end
end
Players.PlayerAdded:Connect(joined)
for _, player in ipairs(Players:GetPlayers()) do joined(player) end
