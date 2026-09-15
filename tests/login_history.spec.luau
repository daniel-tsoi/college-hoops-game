-- Login counting, per-session activity history, and the guarantee that every
-- reward resets on each new connection.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local T = require("../src/ServerScriptService/Shop/Transactions")
local quests = require("../src/ReplicatedStorage/QuestConfig")

-- The Roblox-only scripts on this path cannot run here, but must still compile.
for _, path in
	{
		"src/ServerScriptService/ShopServer.server.luau",
		"src/ServerScriptService/Shop/Transactions.luau",
		"src/ReplicatedStorage/QuestConfig.luau",
		"src/StarterPlayer/StarterPlayerScripts/QuestsUI.client.luau",
	}
do
	luau.compile(fs.readFile(path))
end

-- A brand new profile's first login has no earlier session to archive.
local first = T.startSession(T.newProfile(0), "s1", 1000)
assert(first.logins == 1 and first.firstLoginAt == 1000 and first.lastLoginAt == 1000)
assert(first.sessionStartedAt == 1000 and #first.sessionHistory == 0)

-- Play the session: an hour on the clock, two cards, one reward claimed.
local played = T.advanceSession(first, "s1", 3600)
played = T.unlock(played, "cardA", 1)
played = T.unlock(played, "cardB", 9)
assert(played.sessionUnlocks == 2 and played.owned.cardA and played.goldOwned.cardA)
assert(not played.goldOwned.cardB, "A non-gold roll stays a normal card")
played = T.claim(played, quests[1])
assert(played.sessionCash == 10000 and played.balance == 10000 and played.rerolls == 5)

-- The next login archives exactly what happened in that session.
local second = T.startSession(played, "s2", 90000)
assert(second.logins == 2 and second.firstLoginAt == 1000 and second.lastLoginAt == 90000)
assert(second.sessionStartedAt == 90000 and #second.sessionHistory == 1)
local entry = second.sessionHistory[1]
assert(entry.startedAt == 1000 and entry.seconds == 3600 and entry.endedAt == 4600)
assert(entry.unlocks == 2 and entry.rerolls == 0 and entry.claims == 1 and entry.cash == 10000)

-- Every per-session counter clears, so all rewards are earnable again.
assert(second.sessionSeconds == 0 and second.sessionUnlocks == 0 and second.sessionRerolls == 0)
assert(second.sessionCash == 0 and next(second.sessionClaimed) == nil)

-- Ownership, cash and reward stock earned earlier all survive the reset.
assert(second.balance == 10000 and second.rerolls == 5 and second.refreshes == 5)
assert(second.owned.cardA and second.owned.cardB and second.goldOwned.cardA)
assert(second.playSeconds == 3600, "Lifetime playtime is kept as a statistic")

-- The loaded profile is never mutated in place.
assert(#played.sessionHistory == 0 and played.logins == 1, "startSession must not mutate its input")
assert(played.sessionCash == 10000 and played.sessionUnlocks == 2)

-- A retried UpdateAsync callback runs again on the same stored value, so the
-- login must be counted once, not once per attempt.
local attemptA = T.startSession(played, "s2", 90000)
local attemptB = T.startSession(played, "s2", 90000)
assert(attemptA.logins == attemptB.logins and attemptA.logins == 2)
assert(attemptA.lastLoginAt == attemptB.lastLoginAt)
assert(#attemptA.sessionHistory == #attemptB.sessionHistory and #attemptA.sessionHistory == 1)

-- Joining and leaving with nothing done is counted but not archived, so instant
-- rejoins cannot flush real sessions out of the bounded history.
local idle = T.startSession(T.newProfile(0), "i1", 10)
local afterIdle = T.startSession(idle, "i2", 20)
assert(afterIdle.logins == 2 and #afterIdle.sessionHistory == 0)

-- History is capped and ordered newest first.
local many = T.startSession(T.newProfile(0), "m1", 0)
for index = 1, 14 do
	many = T.advanceSession(many, "m" .. index, 60)
	many = T.startSession(many, "m" .. (index + 1), index * 1000)
end
assert(many.logins == 15, "Every login is counted even once history is full")
assert(#many.sessionHistory == 10, "Saved history stays bounded")
assert(many.sessionHistory[1].startedAt == 13000, "Newest session is first")
assert(many.sessionHistory[10].startedAt == 4000, "Oldest surviving session is last")
assert(many.playSeconds == 840, "All 14 played minutes still count toward lifetime playtime")

-- Every quest in the config is claimable in one session and resets on the next.
local full = T.startSession(T.newProfile(0), "f1", 1)
full = T.advanceSession(full, "f1", 14400)
full.sessionUnlocks, full.sessionRolls = 10, 200
local total = 0
for _, quest in ipairs(quests) do
	local claimed, code = T.claim(full, quest)
	assert(code == "REWARDED", quest.id .. " must be claimable within a single login")
	full, total = claimed, total + quest.cash
end
assert(total == 310000 and full.balance == total and full.sessionCash == total)
local fresh = T.startSession(full, "f2", 2)
for _, quest in ipairs(quests) do
	assert(not fresh.sessionClaimed[quest.id], quest.id .. " must reset on the next login")
end
assert(fresh.balance == total, "Cash already earned is never taken back")
assert(fresh.sessionCash == 0 and fresh.sessionHistory[1].cash == total)

-- Legacy profiles from before login tracking migrate without losing anything.
local legacy = T.migrate({ version = 1, balance = 500, owned = { shaq = true }, claimedQuests = { hour1 = true } })
assert(legacy.logins == 0 and legacy.sessionCash == 0 and #legacy.sessionHistory == 0)
assert(legacy.balance == 500 and legacy.owned.shaq and legacy.version == 6)
local revived = T.startSession(legacy, "old", 7000)
assert(revived.logins == 1 and revived.firstLoginAt == 7000 and revived.balance == 500)
assert(next(revived.sessionClaimed) == nil, "Old lifetime claims never block a new login's rewards")

print("Login history tests passed: four scripts compile; login counting, retry idempotence, archived session activity, bounded newest-first history, idle-rejoin exclusion, full reward reset, and legacy migration")
