-- Pure transaction rules. Caller commits wallet and ownership together.
local Transactions = {}
-- Bounded so a long-lived profile cannot grow its saved history without limit.
local MAX_HISTORY = 10
function Transactions.newProfile(balance)
	return { version = 6, balance = balance, owned = {}, goldOwned = {}, shopUnlocked = {}, shopOwnershipMigrated = true,
		logins = 0, sessionHistory = {} }
end
-- Caller samples once before an UpdateAsync callback, never inside its retries.
function Transactions.isGoldRoll(roll)
	return type(roll) == "number" and roll % 1 == 0 and roll >= 1 and roll <= 5
end
-- Shared acquisition rule for any card ID; only trusted server services grant cards.
function Transactions.unlock(profile, id, roll)
	if profile.owned[id] then
		if Transactions.isGoldRoll(roll) and not (profile.goldOwned or {})[id] then
			local upgraded = table.clone(profile)
			upgraded.goldOwned = table.clone(profile.goldOwned or {})
			upgraded.goldOwned[id] = true
			return upgraded, "GOLD_UPGRADED"
		end
		return profile, "OWNED"
	end
	local updated = table.clone(profile)
	updated.owned = table.clone(profile.owned)
	updated.goldOwned = table.clone(profile.goldOwned or {})
	updated.owned[id] = true
	if Transactions.isGoldRoll(roll) then updated.goldOwned[id] = true end
	updated.sessionUnlocks = (profile.sessionUnlocks or 0) + 1
	return updated, "UNLOCKED"
end
function Transactions.purchase(profile, offer)
	if (profile.shopUnlocked or {})[offer.id] then return profile, "ELIGIBLE" end
	if profile.balance < offer.price then return profile, "INSUFFICIENT" end
	local updated = table.clone(profile)
	updated.shopUnlocked = table.clone(profile.shopUnlocked or {})
	updated.shopUnlocked[offer.id] = true
	updated.balance -= offer.price
	return updated, "PURCHASED"
end
-- One-time conversion: old Shop ownership becomes roll eligibility, not a rolled card.
-- Archive the previous flags for audit/recovery; preserve balance and rewards.
function Transactions.migrateShopOwnership(profile, offers)
	if profile.shopOwnershipMigrated then return profile end
	local updated = table.clone(profile)
	updated.owned = table.clone(profile.owned or {})
	updated.goldOwned = table.clone(profile.goldOwned or {})
	updated.shopUnlocked = table.clone(profile.shopUnlocked or {})
	updated.legacyShopOwned = table.clone(profile.legacyShopOwned or {})
	updated.legacyShopGold = table.clone(profile.legacyShopGold or {})
	for id in pairs(offers) do
		if updated.owned[id] then
			updated.shopUnlocked[id], updated.legacyShopOwned[id] = true, true
			updated.legacyShopGold[id] = updated.goldOwned[id]
			updated.owned[id], updated.goldOwned[id] = nil, nil
			if updated.equippedCardId == id then updated.equippedCardId = nil end
		end
	end
	updated.shopOwnershipMigrated = true
	return updated
end
-- Migration preserves existing cash and owned shop cards.
function Transactions.migrate(profile)
	local updated = table.clone(profile)
	updated.version = 6
	updated.shopUnlocked = table.clone(profile.shopUnlocked or {})
	updated.goldOwned = table.clone(profile.goldOwned or {})
	updated.playSeconds = profile.playSeconds or 0
	updated.rerolls = profile.rerolls or 0
	updated.refreshes = profile.refreshes or 0
	updated.claimedQuests = table.clone(profile.claimedQuests or {})
	updated.sessionClaimed = table.clone(profile.sessionClaimed or {})
	updated.sessionUnlocks = profile.sessionUnlocks or 0
	updated.sessionRerolls = profile.sessionRerolls or 0
	updated.previewFreeRerolls = profile.previewFreeRerolls or 0
	updated.freeRollRerolls = profile.freeRollRerolls == nil and 1 or profile.freeRollRerolls
	updated.freeRollRefreshes = profile.freeRollRefreshes == nil and 1 or profile.freeRollRefreshes
	updated.logins = profile.logins or 0
	updated.sessionCash = profile.sessionCash or 0
	updated.sessionHistory = table.clone(profile.sessionHistory or {})
	return updated
end
-- What the player did in the session that is ending, taken from the loaded
-- profile before the counters reset. A session with no time and no activity is
-- not recorded, so repeated instant rejoins cannot flush the bounded history.
local function summarize(profile)
	local claims = 0
	for _ in pairs(profile.sessionClaimed or {}) do claims += 1 end
	local seconds = profile.sessionSeconds or 0
	local unlocks = profile.sessionUnlocks or 0
	local rerolls = profile.sessionRerolls or 0
	local cash = profile.sessionCash or 0
	if seconds == 0 and unlocks == 0 and rerolls == 0 and cash == 0 and claims == 0 then return nil end
	local startedAt = profile.sessionStartedAt
	return { startedAt = startedAt, endedAt = startedAt and startedAt + seconds or nil,
		seconds = seconds, unlocks = unlocks, rerolls = rerolls, claims = claims, cash = cash }
end
-- Each login archives the previous session, counts the login, and clears every
-- per-session counter, so all rewards become earnable again. `at` is a UTC
-- timestamp the caller samples once before an UpdateAsync callback; every field
-- here derives from `profile` and `at`, so a retried callback recomputes the
-- same result rather than counting the login twice.
function Transactions.startSession(profile, sessionId, at)
	local updated = Transactions.migrate(profile)
	local previous = summarize(profile)
	if previous then
		table.insert(updated.sessionHistory, 1, previous)
		while #updated.sessionHistory > MAX_HISTORY do table.remove(updated.sessionHistory) end
	end
	updated.logins += 1
	updated.lastLoginAt = at
	updated.firstLoginAt = updated.firstLoginAt or at
	updated.sessionStartedAt = at
	updated.clockSession = sessionId
	updated.sessionSeconds = 0
	updated.sessionClaimed = {}
	updated.sessionUnlocks = 0
	updated.sessionRerolls = 0
	updated.sessionCash = 0
	updated.previewFreeRerolls = 1
	return updated
end
function Transactions.advanceSession(profile, sessionId, elapsed)
	local updated = Transactions.migrate(profile)
	-- A newer connection takes over time tracking. Old servers cannot double-count.
	if updated.clockSession ~= sessionId then return updated end
	local seconds = math.max(updated.sessionSeconds or 0, math.floor(elapsed))
	updated.playSeconds += seconds - (updated.sessionSeconds or 0)
	updated.sessionSeconds = seconds
	return updated
end
function Transactions.claim(profile, quest)
	local updated = Transactions.migrate(profile)
	local claimed = quest.scope == "SESSION" and updated.sessionClaimed or updated.claimedQuests
	local progress = quest.scope == "SESSION" and updated[quest.metric] or updated.playSeconds
	local target = quest.scope == "SESSION" and quest.target or quest.seconds
	if claimed[quest.id] then return updated, "CLAIMED" end
	if progress < target then return updated, "NOT_READY" end
	updated.balance += quest.cash
	updated.rerolls += quest.rerolls
	updated.refreshes += quest.refreshes
	updated.sessionCash += quest.cash
	claimed[quest.id] = true
	return updated, "REWARDED"
end
function Transactions.spend(profile, resource)
	local updated = Transactions.migrate(profile)
	if resource ~= "rerolls" and resource ~= "refreshes" then return updated, "INVALID" end
	if updated[resource] < 1 then return updated, "EMPTY" end
	updated[resource] -= 1
	if resource == "rerolls" then updated.sessionRerolls += 1 end
	return updated, "SPENT"
end
-- These two operations are exposed only in Studio while squad gameplay is a preview.
function Transactions.previewRestart(profile)
	local updated = Transactions.migrate(profile)
	updated.previewFreeRerolls = 1
	return updated, "RESET"
end
function Transactions.previewReroll(profile)
	local updated = Transactions.migrate(profile)
	if updated.previewFreeRerolls > 0 then
		updated.previewFreeRerolls -= 1
		updated.sessionRerolls += 1
		return updated, "SPENT"
	end
	return Transactions.spend(updated, "rerolls")
end
-- Ownership is checked again inside the atomic save callback.
function Transactions.equip(profile, id)
	if type(id) ~= "string" or profile.owned[id] ~= true then return profile, "LOCKED" end
	local updated = table.clone(profile)
	updated.equippedCardId = id
	return updated, "EQUIPPED"
end
-- Roll state and ownership are saved atomically. Draws are supplied by trusted server code.
local function finishIfFull(profile)
 for _,pos in ipairs({"PG","SG","SF","PF","C"}) do
  if not profile.rollDraft.squad[pos] then return profile,"ROLLED" end
 end
 profile.rollDraft.finished=true
 profile.rollDraft.pickAvailable=false
 return profile,"FINISHED"
end
function Transactions.rollAction(profile, action, position, draws, team, rare)
	local draft = profile.rollDraft
	if action == "RollState" and draft and draft.team then return profile, "READY" end
	if action == "RollState" or action == "RestartRoll" then
		local updated = table.clone(profile)
		if action == "RestartRoll" then
			updated.freeRollRerolls = 1
			updated.freeRollRefreshes = 1
		end
		updated.rollDraft = { rare = rare or {}, rareRoll = (draft and draft.rareRoll or 0) + 1, candidates = draws, squad = action == "RollState" and draft and table.clone(draft.squad) or {}, finished = action == "RollState" and draft and draft.finished or false, team = team, pickAvailable = true }
		return updated, "READY"
	end
	if not draft then return profile, "NOT_READY" end
	if action == "FinishRoll" then
		for _,pos in ipairs({"PG","SG","SF","PF","C"}) do if not draft.squad[pos] then return profile,"INCOMPLETE" end end
		local updated=table.clone(profile)
		updated.rollDraft=table.clone(draft)
		updated.rollDraft.finished=true
		return updated,"FINISHED"
	end
	if draft.finished then return profile,"FINISHED" end
	local updated=Transactions.migrate(profile)
	updated.rollDraft=table.clone(draft)
	updated.rollDraft.squad=table.clone(draft.squad)
	updated.rollDraft.candidates=table.clone(draft.candidates)
	if action=="NextRoll" then
  if draft.pickAvailable then return profile,"CHOOSE_FIRST" end
  for _,pos in ipairs({"PG","SG","SF","PF","C"}) do
   if not draft.squad[pos] then
    updated.rollDraft.candidates=draws
    updated.rollDraft.team=team
    updated.rollDraft.pickAvailable=true
    updated.rollDraft.rare=rare or {}
    updated.rollDraft.rareRoll=(draft.rareRoll or 0)+1
    return updated,"READY"
   end
  end
  return profile,"INCOMPLETE"
 end
 if action=="RefreshRoll" then
  if not draft.pickAvailable then return profile,"ROLL_REQUIRED" end
		if updated.freeRollRefreshes>0 then updated.freeRollRefreshes-=1
		elseif updated.refreshes>0 then updated.refreshes-=1 else return profile,"EMPTY" end
		updated.rollDraft.candidates=draws
		return updated,"REFRESHED"
	end
	if action=="ChooseRare" then
  if not draft.pickAvailable then return profile,"ROLL_REQUIRED" end
  local candidate=draft.rare and draft.rare[position]
  if not candidate then return profile,"INVALID" end
  if (profile.shopUnlocked or {})[candidate.id] ~= true then return profile,"LOCKED" end
  updated=Transactions.unlock(updated,candidate.id,candidate.goldRoll)
  updated.rollDraft.squad[candidate.position]=candidate
  updated.rollDraft.pickAvailable=false
  return finishIfFull(updated)
 end
 if action=="RerollPlayer" then
  if not draft.pickAvailable then return profile,"ROLL_REQUIRED" end
  if updated.freeRollRerolls>0 then updated.freeRollRerolls-=1
  elseif updated.rerolls>0 then updated.rerolls-=1 else return profile,"EMPTY" end
  updated.sessionRerolls+=1
  updated.rollDraft.candidates=draws
  updated.rollDraft.team=team
  updated.rollDraft.rare=rare or {}
  updated.rollDraft.rareRoll=(draft.rareRoll or 0)+1
  return updated,"REROLLED"
 end
 if action~="RollPlayer" or not draft.candidates[position] then return profile,"INVALID" end
 local candidate=draft.candidates[position]
 if draft.squad[position] then return profile,"FILLED" end
 if not draft.pickAvailable then return profile,"ROLL_REQUIRED" end
	updated = Transactions.unlock(updated,candidate.id,candidate.goldRoll)
	updated.rollDraft.squad[position]=candidate
 if action=="RollPlayer" then updated.rollDraft.pickAvailable=false end
	return finishIfFull(updated)
end
return Transactions
