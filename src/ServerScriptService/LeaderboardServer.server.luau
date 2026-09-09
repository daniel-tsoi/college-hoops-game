local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Ranking = require(script.Parent.Leaderboard.Ranking)
local preview = RunService:IsStudio()
local store = not preview and game:GetService("DataStoreService"):GetOrderedDataStore("HoopsRolledTeamOVR_v2") or nil
local dirty, saving, submitted, names, lastRequest = {}, {}, {}, {}, {}
local cached, cachedAt, refreshing = nil, -math.huge, false
local function save(userId)
	if preview or saving[userId] or not dirty[userId] then return end
	saving[userId] = true
	local score = dirty[userId]
	local ok = pcall(function()
		store:UpdateAsync(tostring(userId), function(previous)
			-- Owned cards are permanent; a complete best five can only improve.
			return math.max(previous or 0, score)
		end)
	end)
	if ok and dirty[userId] == score then dirty[userId] = nil end
	saving[userId] = nil
end
local function observe(player)
	names[player.UserId] = player.Name
	local function update()
		local score = Ranking.score(player:GetAttribute("BestTeamOverall"), player:GetAttribute("BestTeamCount"))
		if score and submitted[player.UserId] ~= score then
			submitted[player.UserId] = score
			if not preview then dirty[player.UserId] = score; task.spawn(save, player.UserId) end
		end
	end
	player:GetAttributeChangedSignal("BestTeamOverall"):Connect(update)
	player:GetAttributeChangedSignal("BestTeamCount"):Connect(update)
	update()
end
Players.PlayerAdded:Connect(observe)
for _, player in ipairs(Players:GetPlayers()) do observe(player) end
Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
	task.spawn(save, player.UserId)
end)
task.spawn(function()
	while true do
		task.wait(30)
		for userId in pairs(dirty) do task.spawn(save, userId) end
	end
end)
game:BindToClose(function()
	if preview then return end
	local deadline = os.clock() + 25
	repeat
		for userId in pairs(dirty) do task.spawn(save, userId) end
		if not next(dirty) and not next(saving) then break end
		task.wait(1)
	until os.clock() >= deadline
end)
local function applyRanks(rows)
	local ranks = {}
	for _, row in ipairs(rows) do ranks[row.userId] = row.rank end
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("LeaderboardRank", ranks[player.UserId])
	end
end
local function getRows()
	if preview then
		local entries = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local score = Ranking.score(player:GetAttribute("BestTeamOverall"), player:GetAttribute("BestTeamCount"))
			if score then table.insert(entries, { userId = player.UserId, username = player.Name, overall = score }) end
		end
		local rows = Ranking.top(entries)
		applyRanks(rows)
		return { code = "READY", preview = true, rows = rows }
	end
	if os.clock() - cachedAt < 30 then applyRanks(cached); return { code = "READY", rows = cached } end
	if refreshing then return { code = cached and "STALE" or "BUSY", rows = cached } end
	refreshing = true
	local ok, rows = pcall(function()
		local page = store:GetSortedAsync(false, 50, 1):GetCurrentPage()
		local entries = {}
		for _, item in ipairs(page) do
			local userId = tonumber(item.key)
			if userId then
				local username = names[userId]
				if not username then
					local found, result = pcall(Players.GetNameFromUserIdAsync, Players, userId)
					if found then username = result; names[userId] = result end
				end
				table.insert(entries, { userId = userId, username = username or ("User " .. userId), overall = item.value })
			end
		end
		return Ranking.top(entries)
	end)
	refreshing = false
	if ok then cached, cachedAt = rows, os.clock(); applyRanks(rows) end
	return { code = ok and "READY" or (cached and "STALE" or "UNAVAILABLE"), rows = cached }
end
local remote = Instance.new("RemoteFunction")
remote.Name = "HoopsLeaderboard"
remote.OnServerInvoke = function(player)
	if os.clock() - (lastRequest[player] or -math.huge) < 3 then return { code = "BUSY" } end
	lastRequest[player] = os.clock()
	return getRows()
end
remote.Parent = ReplicatedStorage

-- Titles must update even when nobody opens the leaderboard panel.
Players.PlayerAdded:Connect(function() task.spawn(getRows) end)
task.spawn(function()
	while true do
		getRows()
		task.wait(preview and 3 or 30)
	end
end)
