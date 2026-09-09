local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Catalog = require(ReplicatedStorage.Shared.ShopCatalog)
local Quests = require(ReplicatedStorage.QuestConfig)
local Transactions = require(script.Parent.Shop.Transactions)
local BestTeam = require(script.Parent.Shop.BestTeam)
local TeamChemistry = require(ReplicatedStorage.Shared.TeamChemistry)
local Database = require(ReplicatedStorage.Shared.PlayerDatabase)
local rosterById = Database.ById
local RollPool = require(script.Parent.Roll.Pool)
local SummonConfig = require(script.Parent.Config.SummonConfig)
local pools = RollPool.build(Database, SummonConfig)
local RareWheel = require(script.Parent.Roll.RareWheel)
local rarePools = RareWheel.build(Database)
local RareReveal = require(script.Parent.Roll.RareReveal)
local revealEvent = Instance.new("RemoteEvent")
revealEvent.Name = "HoopsRareReveal"
revealEvent.Parent = ReplicatedStorage
local rollRandom = Random.new()
local validPositions = { PG=true, SG=true, SF=true, PF=true, C=true }
local preview = RunService:IsStudio()
local store = not preview and DataStoreService:GetDataStore("CollegeHoopsShop_v1") or nil
local profiles, busy, lastRequest, sessions = {}, {}, {}, {}
local remote = Instance.new("RemoteFunction")
remote.Name = "HoopsShop"
local questsById = {}
for _, quest in ipairs(Quests) do questsById[quest.id] = quest end
local function key(player) return "player_" .. player.UserId end
local function elapsed(player)
	local session = sessions[player]
	return session and math.max(0, math.floor(os.clock() - session.started)) or 0
end
local function publish(player)
	local profile = profiles[player]
	if not profile or player.Parent ~= Players then return end
	local team = BestTeam.select(profile.owned, rosterById, profile.goldOwned)
	player:SetAttribute("BestTeamOverall", team.overall)
	player:SetAttribute("BestTeamCount", #team.players)
	local equipped = profile.equippedCardId
	player:SetAttribute("EquippedCardGold", equipped ~= nil and profile.owned[equipped] == true and profile.goldOwned[equipped] == true)
	player:SetAttribute("EquippedCardId", equipped and profile.owned[equipped] == true and rosterById[equipped] and equipped or nil)
	local ownedCount = 0
	for _, unlocked in pairs(profile.owned) do if unlocked == true then ownedCount += 1 end end
	player:SetAttribute("HoopsOwnedCount", ownedCount)
	player:SetAttribute("HoopsCash", profile.balance)
	player:SetAttribute("QuestRerolls", profile.rerolls)
	player:SetAttribute("QuestRefreshes", profile.refreshes)
end
local function collection(profile)
	local cards = {}
	if not profile then return cards end
	for id, owned in pairs(profile.owned) do
		local card = owned == true and rosterById[id]
		if card then
			local gold = profile.goldOwned[id] == true
			table.insert(cards, { id = id, name = card.name, position = card.position,
				school = card.school, season = card.season, rarity = card.rarity,
				overall = BestTeam.overall(card, gold), gold = gold })
		end
	end
	table.sort(cards, function(a, b)
		if a.overall ~= b.overall then return a.overall > b.overall end
		return a.id < b.id
	end)
	return cards
end
local function rollState(profile)
	local draft = profile and profile.rollDraft
	if not draft then return nil end
	local result = { candidates={}, squad={}, rare={}, rareRoll=draft.rareRoll or 0, finished=draft.finished, team=draft.team, pickAvailable=draft.pickAvailable }
	for _,field in ipairs({"candidates","squad","rare"}) do
		for pos,entry in pairs(draft[field] or {}) do
			local card=rosterById[entry.id]
			if card and (field ~= "rare" or (profile.shopUnlocked or {})[card.id] == true) then
				local gold=Transactions.isGoldRoll(entry.goldRoll)
				result[field][pos]={id=card.id,prospectNumber=entry.prospectNumber,name=card.name,position=card.position,school=card.school,
					season=card.season,overall=BestTeam.overall(card,gold),gold=gold,rarity=card.rarity}
			end
		end
	end
	result.chemistry = TeamChemistry.evaluate(result.squad)
	return result
end
local function response(player, code)
	local profile = profiles[player]
	local session = sessions[player]
	if profile and session then
		profile = Transactions.advanceSession(profile, session.id, elapsed(player))
	end
	return { rollState = rollState(profile), freeRollRerolls = profile and profile.freeRollRerolls or 0, freeRollRefreshes = profile and profile.freeRollRefreshes or 0, shopUnlocked = profile and profile.shopUnlocked or {}, collection = collection(profile), goldOwned = profile and profile.goldOwned or {}, equippedCardId = profile and profile.equippedCardId or nil, code = code, ready = profile ~= nil, preview = preview,
		bestTeam = profile and BestTeam.select(profile.owned, rosterById, profile.goldOwned) or nil,
		balance = profile and profile.balance or 0, owned = profile and profile.owned or {},
		playSeconds = profile and profile.playSeconds or 0,
		rerolls = profile and profile.rerolls or 0, refreshes = profile and profile.refreshes or 0,
		claimedQuests = profile and profile.claimedQuests or {},
		sessionClaimed = profile and profile.sessionClaimed or {},
		sessionUnlocks = profile and profile.sessionUnlocks or 0,
		sessionRerolls = profile and profile.sessionRerolls or 0,
		previewFreeRerolls = profile and profile.previewFreeRerolls or 0 }
end
local function load(player)
	local sessionId = HttpService:GenerateGUID(false)
	local profile
	if preview then
		profile = Transactions.startSession(Transactions.newProfile(1000000), sessionId)
	else
		profile = store:UpdateAsync(key(player), function(current)
			return Transactions.startSession(Transactions.migrateShopOwnership(current or Transactions.newProfile(0), Catalog.ById), sessionId)
		end)
	end
	profiles[player] = profile
	sessions[player] = { id = sessionId, started = os.clock() }
	publish(player)
end
-- Every wallet mutation includes the current online-time checkpoint in the same save.
-- Absolute per-session elapsed time makes retried UpdateAsync callbacks idempotent.
local function commit(player, mutate)
	local session = sessions[player]
	local seconds = elapsed(player)
	local code = "READY"
	local function transform(current)
		if current.clockSession ~= session.id then
			code = "STALE_SESSION"
			return current
		end
		local updated = Transactions.advanceSession(current, session.id, seconds)
		if mutate then updated, code = mutate(updated) end
		return updated
	end
	if preview then
		profiles[player] = transform(profiles[player])
	else
		profiles[player] = store:UpdateAsync(key(player), function(current)
			return transform(current or Transactions.startSession(Transactions.newProfile(0), session.id))
		end)
	end
	publish(player)
	return code
end
local rollActions = { ChooseRare=true, NextRoll=true, RollState=true, RollPlayer=true, RerollPlayer=true, RefreshRoll=true, RestartRoll=true, FinishRoll=true }
local allowed = { Equip = true, State = true, Buy = true, ClaimQuest = true }
for action in pairs(rollActions) do allowed[action]=true end
remote.OnServerInvoke = function(player, action, id)
	if type(action) ~= "string" or not allowed[action] then return response(player, "INVALID") end
	if busy[player] or os.clock() - (lastRequest[player] or -math.huge) < 0.4 then return response(player, "BUSY") end
	lastRequest[player], busy[player] = os.clock(), true
	local ok, result = pcall(function()
		if not profiles[player] then load(player) end
		if action == "State" then return response(player, "READY") end
		local code
		if rollActions[action] then
			if action=="RollPlayer" and (type(id)~="string" or not validPositions[id]) then return response(player,"INVALID") end
			if action=="RollState" and profiles[player].rollDraft and profiles[player].rollDraft.team then return response(player,"READY") end
			local draws, team, rare
			if action=="RollState" or action=="RestartRoll" or action=="RefreshRoll" or action=="NextRoll" or action=="RerollPlayer" then
				local profile=profiles[player]
    local draft=profile.rollDraft
    draws,team=RollPool.drawTeam(pools,profile.shopUnlocked or {},rollRandom,SummonConfig,
     draft and draft.team and draft.team.key,action=="RefreshRoll",draft and draft.candidates,action=="RerollPlayer")
			end
			if action=="NextRoll" or action=="RestartRoll" or action=="RollState" or action=="RerollPlayer" then
    rare=RareWheel.draw(rarePools,rollRandom,profiles[player].shopUnlocked)
   end
   if action=="ChooseRare" and id~="HOF" and id~="NonCollege" then return response(player,"INVALID") end
   local beforeSerial=profiles[player].rollDraft and profiles[player].rollDraft.rareRoll or 0
   code=commit(player,function(profile) return Transactions.rollAction(profile,action,id,draws,team,rare) end)
   for _,hit in ipairs(RareReveal.events(beforeSerial,profiles[player],rosterById)) do
    hit.userId=player.UserId
    hit.playerName=player.DisplayName
    revealEvent:FireAllClients(hit)
   end
		elseif action == "Equip" then
			if type(id) ~= "string" or not rosterById[id] then return response(player, "INVALID") end
			code = commit(player, function(profile) return Transactions.equip(profile, id) end)
		elseif action == "Buy" then
			local offer = type(id) == "string" and Catalog.ById[id]
			if not offer then return response(player, "INVALID") end
			code = commit(player, function(profile) return Transactions.purchase(profile, offer) end)
		elseif action == "ClaimQuest" then
			local quest = type(id) == "string" and questsById[id]
			if not quest then return response(player, "INVALID") end
			code = commit(player, function(profile) return Transactions.claim(profile, quest) end)
		end
		return response(player, code)
	end)
	busy[player] = nil
	if not ok then
		warn("Hoops profile request failed for user", player.UserId)
		return response(player, "UNAVAILABLE")
	end
	return result
end
remote.Parent = ReplicatedStorage
local function joined(player)
	if busy[player] or profiles[player] then return end
	busy[player] = true
	local ok = pcall(load, player)
	busy[player] = nil
	if not ok then warn("Hoops profile load will retry for user", player.UserId) end
end
Players.PlayerAdded:Connect(joined)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(joined, player) end
-- Save online playtime even when the player never opens a menu.
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				if busy[player] then return end
				busy[player] = true
				local ok = pcall(function()
					if not profiles[player] then load(player) else commit(player) end
				end)
				busy[player] = nil
				if not ok then warn("Playtime checkpoint will retry for user", player.UserId) end
			end)
		end
	end
end)
local function flush(player)
	while busy[player] do task.wait(0.05) end
	busy[player] = true
	local ok = true
	if profiles[player] then
		for attempt = 1, 3 do
			ok = pcall(commit, player)
			if ok then break end
			task.wait(attempt)
		end
	end
	busy[player] = nil
	return ok
end
Players.PlayerRemoving:Connect(function(player)
	if not flush(player) then warn("Final playtime checkpoint failed for user", player.UserId) end
	profiles[player], lastRequest[player], sessions[player] = nil, nil, nil
end)
game:BindToClose(function()
	local remaining = 0
	for _, player in ipairs(Players:GetPlayers()) do
		remaining += 1
		task.spawn(function() flush(player); remaining -= 1 end)
	end
	while remaining > 0 do task.wait(0.05) end
end)
