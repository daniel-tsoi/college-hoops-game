local Transactions = require("../src/ServerScriptService/Shop/Transactions")
local BestTeam = require("../src/ServerScriptService/Shop/BestTeam")
local Ranking = require("../src/ServerScriptService/Leaderboard/Ranking")
local hits = 0
for roll = 1, 100 do if Transactions.isGoldRoll(roll) then hits += 1 end end
assert(hits == 5, "Exactly five of 100 equally likely outcomes must be gold")
for _, invalid in ipairs({0, -1, 101, 1.5, "1"}) do assert(not Transactions.isGoldRoll(invalid)) end
local profile = Transactions.startSession(Transactions.newProfile(1000), "session")
local offer = { id = "card", price = 100 }
local purchased=Transactions.purchase(profile,offer)
assert(purchased.shopUnlocked.card and not purchased.owned.card and not purchased.goldOwned.card)
local gold, code = Transactions.unlock(purchased, "card", 5)
assert(code == "UNLOCKED" and gold.goldOwned.card and gold.balance == 900)
assert(not profile.owned.card and not profile.goldOwned.card)
local duplicate, duplicateCode = Transactions.unlock(gold, "card", 100)
assert(duplicateCode == "OWNED" and duplicate == gold and duplicate.goldOwned.card)
local normal = Transactions.unlock(purchased, "card", 6)
local upgraded = Transactions.unlock(normal, "card", 1)
assert(upgraded.goldOwned.card and upgraded.balance == 900)
assert(upgraded.sessionUnlocks == 1, "Gold upgrade is not a new unique player")
local replay = Transactions.unlock(purchased, "card", 5)
assert(replay.goldOwned.card and replay.balance == gold.balance)
local equipped = Transactions.equip(gold, "card")
local rejoined = Transactions.startSession(equipped, "next-session")
assert(rejoined.goldOwned.card and rejoined.equippedCardId == "card")
local migrated = Transactions.migrate({ owned = { old = true }, balance = 10 })
assert(not migrated.goldOwned.old and migrated.owned.old)
local college = Transactions.unlock(profile, "college-any-player", 1)
assert(college.goldOwned["college-any-player"], "Gold supports any card ID, not just shop offers")
local cards, owned = {}, {}
for i=1,6 do
 local id="c"..i
 cards[id]={id=id,playerId=id,overall=100+i,name=id,position="PG",rarity="HOF"}
 owned[id]=true
end
local before = BestTeam.select(owned, cards)
local after = BestTeam.select(owned, cards, { c1 = true })
assert(before.players[5].id == "c2" and after.players[1].id == "c1", "Bonus must affect top-five selection")
assert(after.players[1].gold and after.players[1].overall == 106 and cards.c1.overall == 101)
assert(after.overall == 105 and before.overall == 104)
assert(BestTeam.overall({overall=110}, true) == 115)
assert(Ranking.score(115,5)==115 and Ranking.score(116,5)==nil)
print("Gold cards: exact 5%, boundaries, purchases, retry safety, duplicate protection, migration, persistence, any-card unlock, boosted selection and 115 OVR passed")
