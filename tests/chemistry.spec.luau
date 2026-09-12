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
assert(Chemistry.connection(card("Duke","2024-25"),card("Duke","2023-24")) == "School")
assert(Chemistry.connection(card("Duke","2024-25"),card("Kansas","2024-25")) == "Year")
assert(Chemistry.connection(card("Duke","2024-25"),card("duke","2024-25")) == "Both")
assert(Chemistry.connection(card("Duke","2024-25"),card("Kansas","2023-24")) == nil)
assert(Chemistry.connection(nil,card("Duke","2024-25")) == nil)
assert(Chemistry.connection(card(nil,nil),card(nil,nil)) == nil)
local Geometry = require("../src/shared/ChemistryLineGeometry")
local spans = Geometry.visible(0,0,100,0,{{x=-10,y=-10,w=20,h=20},{x=90,y=-10,w=20,h=20},{x=40,y=-10,w=20,h=20}})
assert(#spans == 2 and spans[1][1] == .1 and spans[1][2] == .4 and spans[2][1] == .6 and spans[2][2] == .9)
local vertical = Geometry.visible(0,0,0,100,{{x=-10,y=40,w=20,h=20}})
assert(#vertical == 2 and vertical[1][2] == .4 and vertical[2][1] == .6)
local diagonal = Geometry.visible(0,0,100,100,{{x=40,y=40,w=20,h=20}})
assert(#diagonal == 2 and diagonal[1][2] == .4 and diagonal[2][1] == .6)
assert(#Geometry.visible(0,0,100,100,{{x=-1,y=-1,w=102,h=102}}) == 0)
assert(#Geometry.visible(0,0,100,0,{{x=40,y=40,w=20,h=20}}) == 1)
print("Chemistry lines: all colors, missing cards, horizontal/vertical/diagonal clipping and intervening blockers passed")

local FullChem=require("../src/shared/TeamChemistry")
local connected={}
for i=1,5 do connected[i]={school="Duke",season="2025-26"} end
assert(FullChem.isFull(connected))
connected[5]=nil;assert(not FullChem.isFull(connected))
connected[5]={school="Kansas",season="2024-25"};assert(not FullChem.isFull(connected))
connected[5]={school="Kansas",season="2025-26"};assert(FullChem.isFull(connected))
print("Full-chem badge eligibility passed")
