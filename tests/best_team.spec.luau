local BestTeam = require("../src/ServerScriptService/Shop/BestTeam")
local Chemistry = require("../src/shared/TeamChemistry")
local Transactions = require("../src/ServerScriptService/Shop/Transactions")
local cards = {}
local positions = {"PG", "SG", "SF", "PF", "C"}
local function run(prefix, ratings, sixth)
 local squad = {}
 for i, pos in ipairs(positions) do
  local id = prefix .. pos
  cards[id] = {id=id, name=id, position=pos, overall=ratings[i], rarity="COMMON"}
  squad[pos] = {id=id, goldRoll=100}
 end
 if sixth then
  cards[prefix.."sixth"] = {id=prefix.."sixth", name="Bench", position="PG", overall=sixth, rarity="HOF"}
  squad.SIXTH = {id=prefix.."sixth", goldRoll=1}
 end
 return {squad=squad, finished=true}
end
local profile = Transactions.newProfile(0)
profile.owned.randomHighPlayer=true
assert(#BestTeam.select(profile).players==0, "Ownership alone never creates a team")
profile.rollDraft=run("first", {80,80,80,80,80})
profile.rollDraft.finished=false
assert(BestTeam.record(profile,cards,Chemistry)==profile, "Incomplete runs cannot qualify")
profile.rollDraft.finished=true
local first=BestTeam.record(profile,cards,Chemistry)
assert(BestTeam.select(first).overall==80 and #BestTeam.select(first).players==5)
assert(profile.bestCompletedTeam==nil, "Input profile is immutable")
local second=table.clone(first)
second.rollDraft=run("second", {100,70,70,70,70})
second=BestTeam.record(second,cards,Chemistry)
assert(second.bestCompletedTeam==first.bestCompletedTeam, "A stronger PG cannot replace a position from another run")
second.rollDraft=run("tie", {80,80,80,80,80})
assert(BestTeam.record(second,cards,Chemistry).bestCompletedTeam==first.bestCompletedTeam, "Ties keep the record")
second.rollDraft=run("winner", {81,81,81,81,81}, 100)
local winner=BestTeam.record(second,cards,Chemistry)
assert(winner.bestCompletedTeam.overall==85 and #winner.bestCompletedTeam.players==6)
assert(winner.bestCompletedTeam.players[6].slot=="SIXTH" and winner.bestCompletedTeam.players[6].overall==105)
for _,card in ipairs(winner.bestCompletedTeam.players) do assert(string.sub(card.id,1,6)=="winner") end
winner.goldOwned.winnerPG=true
cards.winnerPG.overall=110
assert(BestTeam.record(winner,cards,Chemistry)==winner, "Saved snapshots never change with later upgrades or catalog edits")
local restarted=Transactions.rollAction(winner,"RestartRoll",nil,{}, {})
assert(restarted.bestCompletedTeam==winner.bestCompletedTeam)
assert(Transactions.startSession(restarted,"rejoin").bestCompletedTeam==winner.bestCompletedTeam)
local optional=table.clone(first)
optional.rollDraft=table.clone(first.rollDraft)
optional.rollDraft.squad=table.clone(first.rollDraft.squad)
cards.bench={id="bench",name="Bench",position="C",overall=100,rarity="COMMON"}
optional.rollDraft.squad.SIXTH={id="bench",goldRoll=100}
local withSixth=BestTeam.record(optional,cards,Chemistry)
assert(withSixth.bestCompletedTeam.overall==83 and #withSixth.bestCompletedTeam.players==6)
local weakerSixth=table.clone(first)
weakerSixth.rollDraft=run("weakbench", {80,80,80,80,80}, 40)
assert(BestTeam.record(weakerSixth,cards,Chemistry).bestCompletedTeam==first.bestCompletedTeam, "A lower six-man OVR cannot replace a better five-man record")
local invalid=Transactions.newProfile(0)
invalid.rollDraft=run("invalid", {90,90,90,90,90})
invalid.rollDraft.squad.C=nil
assert(BestTeam.record(invalid,cards,Chemistry)==invalid, "Finished flag alone cannot qualify an incomplete squad")
local chemistry=Transactions.newProfile(0)
chemistry.rollDraft=run("chem", {80,80,80,80,80})
for _,entry in pairs(chemistry.rollDraft.squad) do cards[entry.id].school="Same"; cards[entry.id].season="2000" end
local chemTeam=BestTeam.record(chemistry,cards,Chemistry).bestCompletedTeam
assert(chemTeam.overall==91 and chemTeam.players[1].overall==91 and chemTeam.baseOverall==80)
print("Best team: complete single-run records, no mixing, ties, sixth man, gold, chemistry, immutable snapshots and persistence passed")
