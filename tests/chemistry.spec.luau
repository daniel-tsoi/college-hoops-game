local Chemistry = require("../src/shared/TeamChemistry")
local positions = Chemistry.Positions
local function card(school, season, overall)
 return {school=school, season=season, overall=overall or 80}
end
local squad = {}
local expectedSchool = {0,2,4,6,7}
for n,pos in ipairs(positions) do
 squad[pos] = card("Duke", "2024-25")
 local result = Chemistry.evaluate(squad)
 assert(result.overall == 80 + expectedSchool[n] + n-1)
 for _,rating in pairs(result.cards) do
  assert(rating.schoolBonus == expectedSchool[n] and rating.eraBonus == n-1)
 end
end
local replacement = Chemistry.preview(squad,"C",card("Kansas","2023-24",90))
assert(replacement.before.overall == 91)
assert(replacement.after.cards.PG.bonus == 9)
assert(replacement.after.cards.C.bonus == 0)
assert(replacement.after.overall == 89 and replacement.delta == -2)
assert(squad.C.school == "Duke" and squad.C.overall == 80)
local mixed = Chemistry.evaluate({PG=card("Duke","2024-25"),SG=card("Duke","2023-24"),SF=card("Kansas","2024-25")})
assert(mixed.cards.PG.bonus == 3 and mixed.cards.SG.bonus == 2 and mixed.cards.SF.bonus == 1)
assert(Chemistry.evaluate({}).overall == 0)
assert(Chemistry.evaluate({PG=card(nil,nil),C=card(nil,nil)}).bonus == 0)
assert(Chemistry.evaluate({PG=card("Non-college",nil),C=card("Non-college",nil)}).bonus == 0)
assert(Chemistry.evaluate({PG=card("Duke","2024-25",115),C=card("Duke","2024-25",115)}).overall == 118)
print("Chemistry: all thresholds, stacking, mixed groups, missing metadata, empty/sparse squads, gold and replacement losses passed")
