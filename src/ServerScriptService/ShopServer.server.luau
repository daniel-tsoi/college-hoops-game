local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local Products = require(script.Parent.Config.DeveloperProducts)
local Rewards = require(script.Parent.Shop.RobuxRewards)
local purchaseEvent = Instance.new("RemoteEvent")
purchaseEvent.Name = "HoopsPurchaseGranted"
purchaseEvent.Parent = game:GetService("ReplicatedStorage")
local paidAllowed = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Catalog = require(ReplicatedStorage.Shared.ShopCatalog)
local Quests = require(ReplicatedStorage.QuestConfig)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Daily = require(script.Parent.Shop.DailySpin)
local DailyConfig = require(ReplicatedStorage.Shared.DailySpinConfig)
local Transactions = require(script.Parent.Shop.Transactions)
local BestTeam = require(script.Parent.Shop.BestTeam)
local TeamChemistry = require(ReplicatedStorage.Shared.TeamChemistry)
local Database = require(ReplicatedStorage.Shared.PlayerDatabase)
local rosterById = Database.ById
local SixthMan = require(script.Parent.Roll.SixthMan)
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
local StudioSaving = require(script.Parent.Config.StudioSaving)
local inStudio = RunService:IsStudio()
-- Opting in makes Studio persist to a separate key namespace; see the config.
local studioSaving = inStudio and StudioSaving.enabled == true
-- `preview` means a disposable profile that is never read from or written to.
local preview = inStudio and not studioSaving
local store = not preview and DataStoreService:GetDataStore("CollegeHoopsShop_v1") or nil
-- Stated once at startup, because a silent disposable profile reads as lost progress.
print(preview and "[Hoops] Studio: disposable profile, progress will NOT be saved (see Config/StudioSaving)"
	or studioSaving and "[Hoops] Studio: saving to the real DataStore under key prefix '" .. StudioSaving.keyPrefix .. "'"
	or "[Hoops] Live: saving to CollegeHoopsShop_v1")
local profiles, busy, lastRequest, sessions = {}, {}, {}, {}
local remote = Instance.new("RemoteFunction")
remote.Name = "HoopsShop"
local questsById = {}
for _, quest in ipairs(Quests) do questsById[quest.id] = quest end
local function key(player) return (studioSaving and StudioSaving.keyPrefix or "") .. "player_" .. player.UserId end
-- Studio profiles start funded so features can be exercised without grinding.
local function startingBalance() return inStudio and StudioSaving.startingBalance or 0 end
local function elapsed(player)
	local session = sessions[player]
	return session and math.max(0, math.floor(os.clock() - session.started)) or 0
end
local function publish(player)
	local profile = profiles[player]
	if not profile or player.Parent ~= Players then return end
	local team = BestTeam.select(profile)
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
	local result = { sixthAccepted=draft.sixthAccepted, sixthAvailable={}, sixthRevealed={}, sixthDeclined=draft.sixthDeclined, sixthChoice=draft.sixthChoice, candidates={}, squad={}, rare={}, rareRoll=draft.rareRoll or 0, finished=draft.finished, team=draft.team, pickAvailable=draft.pickAvailable }
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
 for i=1,3 do
  local entry=(draft.sixthRevealed or {})[i] or (draft.sixthChoice==i and draft.squad.SIXTH)
  local card=entry and rosterById[entry.id]
  if card then
   local gold=Transactions.isGoldRoll(entry.goldRoll)
   result.sixthRevealed[i]={id=card.id,name=card.name,position=card.position,school=card.school,
    season=card.season,overall=BestTeam.overall(card,gold),gold=gold,rarity=card.rarity}
  end
  result.sixthAvailable[i]=draft.finished and not entry and (draft.sixthOffers or {})[i]~=nil
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
	local offers = {}
 if profile then
  for _,kind in ipairs({"Rerolls","Refreshes","Sixth"}) do
   local product=Products[kind]
   offers[kind]={id=product.id,price=product.price,available=paidAllowed[player]==true and Rewards.canOffer(profile,kind)}
  end
 end
 local level = profile and Luck.level(profile) or 1
 local nextLuck = Products["Luck_" .. (level + 1)]
 offers.Luck = nextLuck and { id=nextLuck.id, price=nextLuck.price } or nil
 offers.ShopPlayer={id=Products.ShopPlayer.id,price=Products.ShopPlayer.price}
 return { serverTime=os.time(), dailySpins=profile and Daily.available(profile,os.time()) and 1 or 0, nextDailySpinAt=profile and profile.nextDailySpinAt or 0, dailyReward=profile and profile.dailyReward or nil, luckLevel=level, luckMultiplier=profile and Luck.multiplier(profile,paidAllowed[player]) or 1, luckCredit=profile and (profile["luckCredit"..(level+1)] or 0) or 0, shopUnlockCredits=profile and profile.shopUnlockCredits or 0, products=offers, paidAllowed=paidAllowed[player]==true,
  sixthCredits=profile and profile.sixthCredits or 0,
  paidRerolls=profile and profile.paidRerolls or 0,paidRefreshes=profile and profile.paidRefreshes or 0, rollState = rollState(profile), freeRollRerolls = profile and profile.freeRollRerolls or 0, freeRollRefreshes = profile and profile.freeRollRefreshes or 0, shopUnlocked = profile and profile.shopUnlocked or {}, collection = collection(profile), goldOwned = profile and profile.goldOwned or {}, equippedCardId = profile and profile.equippedCardId or nil, code = code, ready = profile ~= nil, preview = preview,
		bestTeam = profile and BestTeam.select(profile) or nil,
		balance = profile and profile.balance or 0, owned = profile and profile.owned or {},
		playSeconds = profile and profile.playSeconds or 0,
		rerolls = profile and profile.rerolls or 0, refreshes = profile and profile.refreshes or 0,
		claimedQuests = profile and profile.claimedQuests or {},
		sessionClaimed = profile and profile.sessionClaimed or {},
		questDoubleCredits = profile and profile.questDoubleCredits or {},
		sessionDoubled = profile and profile.sessionDoubled or {},
		sessionUnlocks = profile and profile.sessionUnlocks or 0,
		sessionRerolls = profile and profile.sessionRerolls or 0,
		previewFreeRerolls = profile and profile.previewFreeRerolls or 0,
		sessionSeconds = profile and profile.sessionSeconds or 0,
		sessionCash = profile and profile.sessionCash or 0,
		logins = profile and profile.logins or 0,
		firstLoginAt = profile and profile.firstLoginAt or nil,
		lastLoginAt = profile and profile.lastLoginAt or nil,
		sessionHistory = profile and profile.sessionHistory or {} }
end
local function load(player)
	local policyOK, policy = pcall(function() return PolicyService:GetPolicyInfoForPlayerAsync(player) end)
 paidAllowed[player] = policyOK and policy.ArePaidRandomItemsRestricted == false
 local sessionId = HttpService:GenerateGUID(false)
	-- Sampled once here so a retried UpdateAsync callback stamps the same login time.
	local loginAt = os.time()
	local profile
	if preview then
		profile = Transactions.startSession(Transactions.newProfile(startingBalance()), sessionId, loginAt)
	else
		profile = store:UpdateAsync(key(player), function(current)
			return BestTeam.record(Transactions.startSession(Transactions.migrateShopOwnership(current or Transactions.newProfile(startingBalance()), Catalog.ById), sessionId, loginAt), rosterById, TeamChemistry)
		end)
	end
	profiles[player] = profile
	sessions[player] = { id = sessionId, started = os.clock(), startedAt = loginAt }
	publish(player)
end
-- Every wallet mutation includes the current online-time checkpoint in the same save.
-- Absolute per-session elapsed time makes retried UpdateAsync callbacks idempotent.
local function commit(player, mutate)
	local session = sessions[player]
	local seconds = elapsed(player)
	local startedAt = session.startedAt
	local code = "READY"
	local function transform(current)
		if current.clockSession ~= session.id then
			code = "STALE_SESSION"
			return current
		end
		local updated = BestTeam.record(Transactions.advanceSession(current, session.id, seconds), rosterById, TeamChemistry)
		if mutate then updated, code = mutate(updated) end
		return BestTeam.record(updated, rosterById, TeamChemistry)
	end
	if preview then
		profiles[player] = transform(profiles[player])
	else
		profiles[player] = store:UpdateAsync(key(player), function(current)
			return transform(current or Transactions.startSession(Transactions.newProfile(startingBalance()), session.id, startedAt))
		end)
	end
	publish(player)
	return code
end
local rollActions = { AcceptSixth=true, DeclineSixth=true, ChooseSixth=true, ChooseRare=true, NextRoll=true, RollState=true, RollPlayer=true, RerollPlayer=true, RefreshRoll=true, RestartRoll=true, FinishRoll=true }
local allowed = { DailySpin=true, UpgradeLuck=true, PurchaseLuck=true, PurchaseQuestDouble=true, PurchaseProduct=true, PurchaseShopPlayer=true, RedeemShopUnlock=true, Equip = true, State = true, Buy = true, ClaimQuest = true }
for action in pairs(rollActions) do allowed[action]=true end
remote.OnServerInvoke = function(player, action, id)
	if type(action) ~= "string" or not allowed[action] then return response(player, "INVALID") end
	if busy[player] or os.clock() - (lastRequest[player] or -math.huge) < 0.4 then return response(player, "BUSY") end
	lastRequest[player], busy[player] = os.clock(), true
	local ok, result = pcall(function()
		if not profiles[player] then load(player) end
		if action == "State" then return response(player, "READY") end
		local code
  if action=="DailySpin" then
   local now=os.time()
   if not Daily.available(profiles[player],now) then return response(player,"DAILY_COOLDOWN") end
   local index=Daily.index(rollRandom:NextInteger(1,DailyConfig.Denominator))
   local reward=DailyConfig.Rewards[index]
   local card
   if not reward.cash then
    local pool=rarePools[reward.id]
    local unowned={}
    for _,candidate in ipairs(pool) do if not profiles[player].owned[candidate.id] then table.insert(unowned,candidate) end end
    local choices=#unowned>0 and unowned or pool
    if #choices>0 then card=choices[rollRandom:NextInteger(1,#choices)] end
   end
   code=commit(player,function(profile) return Daily.grant(profile,now,reward,index,card) end)
  elseif action=="UpgradeLuck" or action=="PurchaseLuck" then
   local profile=profiles[player]
   local nextLevel=Luck.level(profile)+1
   local product=Products["Luck_"..nextLevel]
   if not product then return response(player,"LUCK_MAX") end
   local credit=(profile["luckCredit"..nextLevel] or 0)>0
   if (credit or action=="PurchaseLuck") and not paidAllowed[player] then return response(player,"PAID_RESTRICTED") end
   if action=="UpgradeLuck" or credit then
    code=commit(player,function(current) return Luck.upgrade(current,action=="UpgradeLuck" and "Cash" or "Credit") end)
   else
    if product.id<=0 then return response(player,"PRODUCT_UNCONFIGURED") end
    MarketplaceService:PromptProductPurchase(player,product.id)
    return response(player,"PURCHASE_PROMPTED")
   end
  elseif action=="PurchaseQuestDouble" then
   local quest=type(id)=="string" and questsById[id]
   local product=quest and Products["Quest_"..id]
   if not product then return response(player,"INVALID") end
   if product.id<=0 then return response(player,"PRODUCT_UNCONFIGURED") end
   MarketplaceService:PromptProductPurchase(player,product.id)
   return response(player,"PURCHASE_PROMPTED")
  elseif action=="PurchaseProduct" then
   local product=(id=="Rerolls" or id=="Refreshes" or id=="Sixth") and Products[id]
   if not product then return response(player,"INVALID") end
   if not paidAllowed[player] then return response(player,"PAID_RESTRICTED") end
   if not Rewards.canOffer(profiles[player],id) then return response(player,"NOT_ELIGIBLE") end
   if product.id<=0 then return response(player,"PRODUCT_UNCONFIGURED") end
   MarketplaceService:PromptProductPurchase(player,product.id)
   return response(player,"PURCHASE_PROMPTED")
  elseif action=="PurchaseShopPlayer" or action=="RedeemShopUnlock" then
   local offer=type(id)=="string" and Catalog.ById[id]
   if not offer then return response(player,"INVALID") end
   if profiles[player].shopUnlocked[id] then return response(player,"ELIGIBLE") end
   if action=="RedeemShopUnlock" or (profiles[player].shopUnlockCredits or 0)>0 then
    code=commit(player,function(profile) return Rewards.unlockPlayer(profile,id) end)
   else
    if Products.ShopPlayer.id<=0 then return response(player,"PRODUCT_UNCONFIGURED") end
    MarketplaceService:PromptProductPurchase(player,Products.ShopPlayer.id)
    return response(player,"PURCHASE_PROMPTED")
   end
  elseif rollActions[action] then
   local profile=profiles[player]
   if not paidAllowed[player] and (
    (action=="RerollPlayer" and profile.freeRollRerolls+profile.rerolls<=0 and (profile.paidRerolls or 0)>0)
    or (action=="RefreshRoll" and profile.freeRollRefreshes+profile.refreshes<=0 and (profile.paidRefreshes or 0)>0)
    or (action=="ChooseSixth" and profile.rollDraft and profile.rollDraft.squad.SIXTH)
   ) then return response(player,"PAID_RESTRICTED") end
			if action=="RollPlayer" and (type(id)~="string" or not validPositions[id]) then return response(player,"INVALID") end
			if action=="RollState" and profiles[player].rollDraft and profiles[player].rollDraft.team then return response(player,"READY") end
			local draws, team, rare
			if action=="RollState" or action=="RestartRoll" or action=="RefreshRoll" or action=="NextRoll" or action=="RerollPlayer" then
				local profile=profiles[player]
    local draft=profile.rollDraft
    draws,team=RollPool.drawTeam(pools,profile.shopUnlocked or {},rollRandom,SummonConfig,
     draft and draft.team and draft.team.key,action=="RefreshRoll",draft and draft.candidates,action=="RerollPlayer",Luck.multiplier(profile,paidAllowed[player]))
			end
			if action=="NextRoll" or action=="RestartRoll" or action=="RollState" or action=="RerollPlayer" then
    rare=RareWheel.draw(rarePools,rollRandom,profiles[player].shopUnlocked,Luck.multiplier(profile,paidAllowed[player]))
   end
   if action=="ChooseRare" and id~="HOF" and id~="NonCollege" then return response(player,"INVALID") end
   local beforeSerial=profiles[player].rollDraft and profiles[player].rollDraft.rareRoll or 0
   local sixthOffers
   if action=="RollPlayer" or action=="ChooseRare" then
    sixthOffers=SixthMan.draw(rosterById,profiles[player].rollDraft or {},rollRandom,Luck.multiplier(profile,paidAllowed[player]))
   end
   code=commit(player,function(profile) return Transactions.rollAction(profile,action,id,draws,team,rare,sixthOffers) end)
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
-- Only this callback grants purchases. Prompt closure is never proof of payment.
MarketplaceService.ProcessReceipt = function(receipt)
 local product
 for _,offer in pairs(Products) do if offer.id>0 and offer.id==receipt.ProductId then product=offer; break end end
 local player=Players:GetPlayerByUserId(receipt.PlayerId)
 if not product or not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
 while busy[player] and player.Parent==Players do task.wait(0.1) end
 if player.Parent~=Players then return Enum.ProductPurchaseDecision.NotProcessedYet end
 busy[player]=true
 local ok,code=pcall(function()
  if not profiles[player] then load(player) end
  return commit(player,function(profile)
   local updated, result=Rewards.grant(profile,tostring(receipt.PurchaseId),product,product.questId and questsById[product.questId])
   -- Apply paid luck in the same durable receipt save, without relying on a UI event.
   updated=Luck.redeemAvailable(updated)
   return updated,result
  end)
 end)
 busy[player]=nil
 if not ok or (code~="GRANTED" and code~="ALREADY_GRANTED") then
  return Enum.ProductPurchaseDecision.NotProcessedYet
 end
 if player.Parent==Players then purchaseEvent:FireClient(player,receipt.ProductId) end
 return Enum.ProductPurchaseDecision.PurchaseGranted
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
	profiles[player], lastRequest[player], sessions[player], paidAllowed[player] = nil, nil, nil, nil
end)
game:BindToClose(function()
	local remaining = 0
	for _, player in ipairs(Players:GetPlayers()) do
		remaining += 1
		task.spawn(function() flush(player); remaining -= 1 end)
	end
	while remaining > 0 do task.wait(0.05) end
end)
