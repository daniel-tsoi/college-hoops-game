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
local activityExpected = { { "sessionUnlocks", 5, 25000 }, { "sessionUnlocks", 10, 50000 }, { "sessionRerolls", 100, 50000 }, { "sessionRerolls", 200, 100000 } }
for i, expectedQuest in ipairs(activityExpected) do
	local quest = quests[i + 3]
	assert(quest.scope == "SESSION" and quest.metric == expectedQuest[1] and quest.target == expectedQuest[2] and quest.cash == expectedQuest[3])
	local before = T.startSession(T.newProfile(0), "login")
	before[quest.metric] = quest.target - 1
	local early, earlyCode = T.claim(before, quest)
	assert(earlyCode == "NOT_READY" and early.balance == 0)
	before[quest.metric] = quest.target
	local reward, rewardCode = T.claim(before, quest)
	assert(rewardCode == "REWARDED" and reward.balance == quest.cash and reward.sessionClaimed[quest.id])
	local duplicate, duplicateCode = T.claim(reward, quest)
	assert(duplicateCode == "CLAIMED" and duplicate.balance == quest.cash)
	local newLogin = T.startSession(reward, "next")
	assert(newLogin.balance == quest.cash and newLogin[quest.metric] == 0 and not newLogin.sessionClaimed[quest.id])
	local notReady, notReadyCode = T.claim(newLogin, quest)
	assert(notReadyCode == "NOT_READY" and notReady.balance == quest.cash)
	newLogin[quest.metric] = quest.target
	local earnedAgain = T.claim(newLogin, quest)
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
assert(rejoined.balance == activity.balance and rejoined.rerolls == 5 and rejoined.refreshes == 5)
assert(rejoined.sessionUnlocks == 0 and rejoined.sessionRerolls == 0 and next(rejoined.sessionClaimed) == nil)
print("Session quest tests passed: 5/10 unlocks, 100/200 rerolls, $225k stacked rewards, free/bonus counting, failed-action exclusion, repeat claims, squad restart, and login resets")
