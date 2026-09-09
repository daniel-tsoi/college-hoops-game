local BestTeam = require("../src/ServerScriptService/Shop/BestTeam")
local cards, owned = {}, {}
for i = 1, 7 do
	local id = "card" .. i
	cards[id] = { id = id, playerId = "player" .. i, name = id, overall = 80 + i, position = "PG", rarity = "COMMON" }
	owned[id] = true
end
cards.variant = { id = "variant", playerId = "player7", name = "Variant", overall = 99, position = "PG", rarity = "HOF" }
owned.variant = true
owned.unknown = true
cards.locked = { id = "locked", overall = 110 }
local team = BestTeam.select(owned, cards)
assert(#team.players == 5)
assert(team.players[1].id == "variant")
assert(team.players[2].id == "card6")
assert(team.players[5].id == "card3")
assert(team.overall == 87)
assert(owned.variant and cards.card7.overall == 87, "Inputs must not change")
local empty = BestTeam.select({}, cards)
assert(#empty.players == 0 and empty.overall == 0)
local partial = BestTeam.select({ card1 = true, card2 = true, card3 = false }, cards)
assert(#partial.players == 2 and partial.overall == 82)
cards.card1.overall = 82
assert(BestTeam.select({ card1 = true, card2 = true }, cards).players[1].id == "card1")
print("Best team: top five, unique players, ownership, missing IDs, partial/empty roster, rounding and deterministic ties passed")
