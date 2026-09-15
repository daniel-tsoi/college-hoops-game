local T = require("../src/ServerScriptService/Shop/Transactions")
local quests = require("../src/ReplicatedStorage/QuestConfig")
assert(#quests == 7)
-- Playtime milestones are per-login: they measure the current session's seconds
-- and must be re-earned after every reconnect.
local expected = { { 3600, 10000, 5, 5 }, { 7200, 25000, 10, 10 }, { 14400, 50000, 25, 25 } }
for i = 1, 3 do
	local quest = quests[i]
	local e = expected[i]
	assert(quest.seconds == e[1] and quest.cash == e[2] and quest.rerolls == e[3] and quest.refreshes == e[4])
	assert(quest.scope == "SESSION" and quest.metric == "sessionSeconds" and quest.target == e[1])
	local profile = T.startSession(T.newProfile(0), "session", 1000)
	profile = T.advanceSession(profile, "session", quest.seconds - 1)
	local early, code = T.claim(profile, quest)
	assert(code == "NOT_READY" and early.balance == 0 and not early.sessionClaimed[quest.id])
	profile = T.advanceSession(profile, "session", quest.seconds)
	local claimed, claimCode = T.claim(profile, quest)
	assert(claimCode == "REWARDED" and claimed.balance == quest.cash)
	assert(claimed.rerolls == quest.rerolls and claimed.refreshes == quest.refreshes)
	assert(claimed.sessionCash == quest.cash, "Session cash tracks what was earned this login")
	assert(not profile.sessionClaimed[quest.id] and profile.balance == 0, "Claim must not mutate old state")
	local retry, retryCode = T.claim(claimed, quest)
	assert(retryCode == "CLAIMED" and retry.balance == claimed.balance and retry.rerolls == claimed.rerolls)
	-- A new login clears the claim flag but also the session clock behind it.
	local relogged = T.startSession(claimed, "again", 2000)
	assert(not relogged.sessionClaimed[quest.id] and relogged.sessionSeconds == 0)
	local unearned, unearnedCode = T.claim(relogged, quest)
	assert(unearnedCode == "NOT_READY" and unearned.balance == quest.cash,
		"Reconnecting must not hand out the reward again without replaying the hours")
	relogged = T.advanceSession(relogged, "again", quest.seconds)
	local secondTime, secondCode = T.claim(relogged, quest)
	assert(secondCode == "REWARDED" and secondTime.balance == 2 * quest.cash,
		"The same milestone is earnable again once the hours are replayed")
end
local legacy = { version = 1, balance = 123456, owned = { shaq = true } }
local migrated = T.migrate(legacy)
assert(migrated.balance == 123456 and migrated.owned.shaq and migrated.playSeconds == 0)
assert(migrated.rerolls == 0 and migrated.refreshes == 0 and legacy.version == 1)
local profile = T.startSession(T.newProfile(0), "first")
profile = T.advanceSession(profile, "first", 3500)
profile = T.advanceSession(profile, "first", 3500)
assert(profile.playSeconds == 3500, "Retried saves must not add playtime twice")
profile = T.advanceSession(profile, "first", 3400)
assert(profile.playSeconds == 3500, "Stale checkpoints cannot roll time back")
profile = T.startSession(profile, "second")
assert(profile.playSeconds == 3500, "Reconnect adds no offline time")
profile = T.advanceSession(profile, "first", 99999)
assert(profile.playSeconds == 3500, "An old session cannot count time after reconnect")
profile = T.advanceSession(profile, "second", 100)
assert(profile.playSeconds == 3600)
-- Lifetime playtime is now a statistic; claiming reads the session clock instead.
local sessionShort, sessionShortCode = T.claim(profile, quests[1])
assert(sessionShortCode == "NOT_READY" and sessionShort.balance == 0,
	"3600 lifetime seconds is not an hour played this login")
profile = T.advanceSession(profile, "second", 3600)
assert(profile.playSeconds == 7100, "Lifetime playtime keeps accumulating inside a session")
local awarded, code = T.claim(profile, quests[1])
assert(code == "REWARDED")
awarded = T.startSession(awarded, "third", 3000)
assert(awarded.balance == 10000 and awarded.rerolls == 5 and awarded.refreshes == 5,
	"Reconnect keeps rewards that were already banked")
assert(not awarded.sessionClaimed.hour1, "Reconnect clears the claim so it can be earned again")
awarded = T.advanceSession(awarded, "third", 10800)
local tooEarly, tooEarlyCode = T.claim(awarded, quests[3])
assert(tooEarlyCode == "NOT_READY" and tooEarly.balance == 10000, "Three hours does not reach the four-hour milestone")
awarded = T.claim(awarded, quests[2])
awarded = T.claim(awarded, quests[1])
assert(awarded.balance == 45000 and awarded.rerolls == 20 and awarded.refreshes == 20, "Milestones stack in any claim order")
assert(awarded.playSeconds == 17900, "Lifetime playtime still accumulates across logins")
local spent, spendCode = T.spend(awarded, "rerolls")
assert(spendCode == "SPENT" and spent.rerolls == 19 and spent.refreshes == 20 and awarded.rerolls == 20)
spent = T.spend(spent, "refreshes")
assert(spent.rerolls == 19 and spent.refreshes == 19)
local empty, emptyCode = T.spend(T.newProfile(0), "refreshes")
assert(emptyCode == "EMPTY" and empty.refreshes == 0)
local invalid, invalidCode = T.spend(awarded, "balance")
assert(invalidCode == "INVALID" and invalid.balance == 45000)
local bought = T.purchase(awarded, { id = "card", price = 40000 })
assert(bought.balance == 5000 and bought.shopUnlocked.card and not bought.owned.card and bought.sessionClaimed.hour2 and bought.rerolls == 20)
print("Quest tests passed: exact rewards, per-login playtime thresholds, re-earning after reconnect, duplicate claims, migration, save retries, offline exclusion, session takeover, stacked rewards, spending, and shop integration")

-- Per-login activity quests: exact thresholds, retries, and reset isolation.
local activityExpected = { { "sessionUnlocks", 5, 25000, 2 }, { "sessionUnlocks", 10, 50000, 5 }, { "sessionRolls", 100, 50000, 10 }, { "sessionRolls", 200, 100000, 25 } }
for i, expectedQuest in ipairs(activityExpected) do
	local quest = quests[i + 3]
	assert(quest.rerolls == expectedQuest[4] and quest.refreshes == expectedQuest[4])
	assert(quest.scope == "SESSION" and quest.metric == expectedQuest[1] and quest.target == expectedQuest[2] and quest.cash == expectedQuest[3])
	local before = T.startSession(T.newProfile(0), "login")
	before[quest.metric] = quest.target - 1
	local early, earlyCode = T.claim(before, quest)
	assert(earlyCode == "NOT_READY" and early.balance == 0 and early.rerolls == 0 and early.refreshes == 0)
	before[quest.metric] = quest.target
	local reward, rewardCode = T.claim(before, quest)
	assert(rewardCode == "REWARDED" and reward.balance == quest.cash and reward.sessionClaimed[quest.id])
	assert(reward.rerolls == quest.rerolls and reward.refreshes == quest.refreshes)
	local duplicate, duplicateCode = T.claim(reward, quest)
	assert(duplicateCode == "CLAIMED" and duplicate.balance == quest.cash and duplicate.rerolls == quest.rerolls and duplicate.refreshes == quest.refreshes)
	local serde = require("@lune/serde")
	local newLogin = T.startSession(serde.decode("json", serde.encode("json", reward)), "next")
	assert(newLogin.rerolls == quest.rerolls and newLogin.refreshes == quest.refreshes)
	assert(newLogin.balance == quest.cash and newLogin[quest.metric] == 0 and not newLogin.sessionClaimed[quest.id])
	local notReady, notReadyCode = T.claim(newLogin, quest)
	assert(notReadyCode == "NOT_READY" and notReady.balance == quest.cash)
	newLogin[quest.metric] = quest.target
	local earnedAgain = T.claim(newLogin, quest)
	assert(earnedAgain.rerolls == 2 * quest.rerolls and earnedAgain.refreshes == 2 * quest.refreshes)
	assert(earnedAgain.balance == 2 * quest.cash, "Must be earnable again after new progress in a new login")
end
local activity = T.startSession(T.newProfile(1000000), "activity")
for i = 1, 10 do
	activity = T.purchase(activity, { id = "player" .. i, price = 1000 })
	activity = T.unlock(activity,"player"..i,100)
end
assert(activity.sessionUnlocks == 10)
local duplicateBuy, duplicateBuyCode = T.purchase(activity, { id = "player1", price = 1000 })
assert(duplicateBuyCode == "ELIGIBLE" and duplicateBuy.sessionUnlocks == 10)
local failedBuy, failedBuyCode = T.purchase(activity, { id = "too-expensive", price = 2000000 })
assert(failedBuyCode == "INSUFFICIENT" and failedBuy.sessionUnlocks == 10)
activity = T.claim(activity, quests[4])
activity = T.claim(activity, quests[5])
assert(activity.balance == 1065000 and activity.sessionUnlocks == 10)
activity.rerolls = 199
activity = T.previewReroll(activity) -- free reroll counts too
assert(activity.sessionRerolls == 1 and activity.rerolls == 199 and activity.previewFreeRerolls == 0)
for _ = 1, 199 do activity = T.previewReroll(activity) end
assert(activity.sessionRerolls == 200 and activity.rerolls == 0)
local failedReroll, failedRerollCode = T.previewReroll(activity)
assert(failedRerollCode == "EMPTY" and failedReroll.sessionRerolls == 200)
activity.refreshes = 1
activity = T.spend(activity, "refreshes")
assert(activity.sessionRerolls == 200)
-- Spending rerolls does not advance the Roll + Restart quests.
assert(activity.sessionRolls == 0)
local draws={PG={id="player1",position="PG"}}
activity=T.rollAction(activity,"RollState",nil,draws,"team")
assert(activity.sessionRolls==0,"Opening the builder is not a button roll")
for _=1,100 do
 activity=T.rollAction(activity,"RestartRoll",nil,draws,"team")
 local before=activity.sessionRolls
 local blocked,code=T.rollAction(activity,"NextRoll",nil,draws,"team")
 assert(code=="CHOOSE_FIRST" and blocked.sessionRolls==before)
 activity=T.rollAction(activity,"RollPlayer","PG",draws,"team")
 activity=T.rollAction(activity,"NextRoll",nil,draws,"team")
 assert(activity.sessionRolls==before+1)
end
assert(activity.sessionRolls==200,"100 Restarts + 100 Rolls reach both quests")
local saved=activity
local retryA=T.rollAction(saved,"RestartRoll",nil,draws,"team")
local retryB=T.rollAction(saved,"RestartRoll",nil,draws,"team")
assert(retryA.sessionRolls==201 and retryB.sessionRolls==201 and saved.sessionRolls==200)
local locked=table.clone(activity)
locked.rollDraft=table.clone(activity.rollDraft)
locked.rollDraft.sixthAccepted=true
assert(select(2,T.rollAction(locked,"RestartRoll",nil,draws,"team"))=="CHOOSE_SIXTH")
assert(locked.sessionRolls==200)
activity = T.claim(activity, quests[6])
activity = T.claim(activity, quests[7])
assert(activity.balance == 1215000, "All four activity milestones award $225,000")
activity = T.previewRestart(activity)
assert(activity.sessionUnlocks == 10 and activity.sessionRerolls == 200 and activity.sessionClaimed.reroll200)
activity = T.advanceSession(activity, "activity", 3600)
activity = T.claim(activity, quests[1])
local rejoined = T.startSession(activity, "new-login", 9000)
assert(rejoined.playSeconds == 3600 and rejoined.owned.player1)
assert(not rejoined.sessionClaimed.hour1 and rejoined.sessionSeconds == 0, "Playtime milestones reset with the session clock")
assert(rejoined.balance == activity.balance and rejoined.rerolls == 40 and rejoined.refreshes == 40)
assert(rejoined.sessionUnlocks == 0 and rejoined.sessionRolls == 0 and rejoined.sessionRerolls == 0 and next(rejoined.sessionClaimed) == nil)
print("Session quest tests passed: 5/10 unlocks, 100/200 Roll + Restart actions, $225k stacked rewards, free/bonus counting, failed-action exclusion, repeat claims, squad restart, and login resets")

-- Actual claims flow through the builder, saved JSON, and fresh logins.
local serde=require('@lune/serde')
local Rewards=require('../src/ServerScriptService/Shop/RobuxRewards')
local Sync=require('../src/StarterPlayer/StarterPlayerScripts/QuestBalanceSync')
local function reload(profile) return serde.decode('json',serde.encode('json',profile)) end
local wallet=T.startSession(T.newProfile(0),'wallet',0)
wallet=T.rollAction(wallet,'RollState',nil,draws,{key='team'})
local view={rerolls=0,refreshes=0}
local listeners,attributes={},{}
local player={}
function player:GetAttribute(name) return attributes[name] end
function player:GetAttributeChangedSignal(name)
 return {Connect=function(_,callback)
  listeners[name]=callback
  return {Disconnect=function() listeners[name]=nil end}
 end}
end
local renders=0
local disconnect=Sync.bind(player,function() return view end,function() renders+=1 end)
local function publish(profile)
 attributes.QuestRerolls=profile.rerolls
 attributes.QuestRefreshes=profile.refreshes
 for _,callback in pairs(listeners) do callback() end
end
for i=1,3 do
 wallet=T.advanceSession(wallet,'wallet',quests[i].target)
 wallet=T.claim(wallet,quests[i])
end
publish(wallet)
assert(view.rerolls==40 and view.refreshes==40 and renders>0,'Claim updates the existing builder without reopening')
wallet=Rewards.grant(wallet,'paid-quest',{questId='hour1'},quests[1])
publish(wallet)
assert(view.rerolls==50 and view.refreshes==50,'Paid quest rewards stack with free claims')
wallet=T.rollAction(reload(wallet),'RestartRoll',nil,draws,{key='team'})
for _=1,2 do
 wallet=T.rollAction(wallet,'RerollPlayer',nil,draws,{key='team'})
 wallet=T.rollAction(wallet,'RefreshRoll',nil,draws,{key='team'})
end
publish(wallet)
assert(view.rerolls==49 and view.refreshes==49,'Free action first, then exactly one saved reward')
wallet=T.startSession(reload(wallet),'wallet-rejoin',20000)
wallet=T.rollAction(wallet,'RestartRoll',nil,draws,{key='team'})
assert(wallet.rerolls==49 and wallet.refreshes==49,'Restart and rejoin preserve unused rewards')
assert(wallet.balance==105000 and not next(wallet.sessionClaimed))
view=nil
publish(wallet) -- replication before the builder has loaded is safe
view={rerolls=0,refreshes=0}
publish(wallet)
assert(view.rerolls==49 and view.refreshes==49)
disconnect()
assert(next(listeners)==nil,'Destroyed builder releases balance subscriptions')
print('Quest balances: free + paid claims, live builder sync, spend order, serialized rejoin and restart passed')

-- Full wallet lifecycle: all seven quests, durable commit failure/retry,
-- disconnect/rejoin, another login's rewards, and spending down to zero.
local durable=reload(T.startSession(T.newProfile(0),'durable',0))
local function commitWallet(mutate, failSave)
 local base=reload(durable)
 local candidate,code=mutate(base)
 -- DataStore callback retries must recompute without accumulating rewards.
 local retried,retryCode=mutate(reload(durable))
 assert(candidate.rerolls==retried.rerolls and candidate.refreshes==retried.refreshes and code==retryCode)
 if failSave then return nil,'SAVE_FAILED' end
 durable=reload(retried)
 return reload(durable),code
end
local expectedActions,expectedCash=0,0
for _,quest in ipairs(quests) do
 durable[quest.metric]=quest.target
 local previous=reload(durable)
 local claim=function(profile) return T.claim(profile,quest) end
 local failed,code=commitWallet(claim,true)
 assert(failed==nil and code=='SAVE_FAILED')
 assert(durable.balance==previous.balance and durable.rerolls==previous.rerolls and durable.refreshes==previous.refreshes)
 assert(not durable.sessionClaimed[quest.id],'Failed save must leave the reward claimable')
 local saved,savedCode=commitWallet(claim)
 expectedActions+=quest.rerolls
 expectedCash+=quest.cash
 assert(savedCode=='REWARDED' and saved.rerolls==expectedActions and saved.refreshes==expectedActions and saved.balance==expectedCash)
 local duplicate,duplicateCode=commitWallet(claim)
 assert(duplicateCode=='CLAIMED' and duplicate.rerolls==expectedActions and duplicate.refreshes==expectedActions)
end
assert(expectedActions==82 and expectedCash==310000,'All seven quests stack to 82 of each action and $310,000')
for login=1,3 do
 durable=T.startSession(reload(durable),'durable-'..login,30000*login)
 durable=T.rollAction(durable,'RestartRoll',nil,draws,{key='team'})
 assert(durable.rerolls==82 and durable.refreshes==82 and durable.balance==310000,'Repeated joins and restarts cannot reset earned balances')
end
-- All seven can be earned again while the first login's unused balance stays.
for _,quest in ipairs(quests) do
 durable[quest.metric]=quest.target
 commitWallet(function(profile) return T.claim(profile,quest) end)
end
assert(durable.rerolls==164 and durable.refreshes==164 and durable.balance==620000)
for _=1,165 do -- one free action plus 164 saved actions
 local saved,code=commitWallet(function(profile) return T.rollAction(profile,'RerollPlayer',nil,draws,{key='team'}) end)
 assert(code=='REROLLED' and saved.rerolls>=0)
 saved,code=commitWallet(function(profile) return T.rollAction(profile,'RefreshRoll',nil,draws,{key='team'}) end)
 assert(code=='REFRESHED' and saved.refreshes>=0)
end
assert(durable.rerolls==0 and durable.refreshes==0 and durable.balance==620000)
for _,action in ipairs({'RerollPlayer','RefreshRoll'}) do
 local saved,code=commitWallet(function(profile) return T.rollAction(profile,action,nil,draws,{key='team'}) end)
 assert(code=='EMPTY' and saved.rerolls==0 and saved.refreshes==0)
end
durable=T.startSession(reload(durable),'spent-rejoin',120000)
assert(durable.rerolls==0 and durable.refreshes==0,'Spent rewards must not regenerate on rejoin')
print('All seven quest wallets: 82+82 saved actions, failed-save retry, duplicate protection, three rejoins, second-login stacking and full spend-down passed')
