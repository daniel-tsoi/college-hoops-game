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

-- Rare-tier chemistry: purple between HOF, red between non-college, amber across.
local function hof(id, overall) return { id = "hof-" .. id, rarity = "HOF", overall = overall or 90 } end
local function nc(id, overall) return { id = "non-college-" .. id, overall = overall or 90 } end
local function plain(id, overall) return { id = "college-" .. id, overall = overall or 70 } end

assert(Chemistry.tier(hof("a")) == "HOF" and Chemistry.tier(nc("a")) == "NonCollege" and Chemistry.tier(plain("a")) == nil)
assert(Chemistry.tier(nil) == nil and Chemistry.tier({}) == nil, "A card with no id or rarity has no tier")
assert(Chemistry.rarityLink(hof("a"), hof("b")) == "HOF")
assert(Chemistry.rarityLink(nc("a"), nc("b")) == "NonCollege")
assert(Chemistry.rarityLink(hof("a"), nc("b")) == "Cross" and Chemistry.rarityLink(nc("a"), hof("b")) == "Cross")
assert(Chemistry.rarityLink(hof("a"), plain("b")) == nil, "A plain card never links by tier")
assert(Chemistry.rarityLink(plain("a"), plain("b")) == nil)

-- School and year keep precedence for the line colour; a rare link only fills
-- in a pair that had no connection at all.
local sameSchoolHOF = { id = "hof-x", rarity = "HOF", school = "Duke", season = "1990-91", overall = 90 }
local otherHOF = { id = "hof-y", rarity = "HOF", school = "Duke", season = "1999-00", overall = 90 }
assert(Chemistry.connection(sameSchoolHOF, otherHOF) == "School")
assert(Chemistry.link(sameSchoolHOF, otherHOF) == "School", "School still wins the line")
assert(Chemistry.link(hof("a"), hof("b")) == "HOF", "With no school or year, the tier draws the line")

-- +2 per same-tier teammate, +1 per crossover, stacking on school and year.
local two = Chemistry.evaluate({ PG = hof("a"), SG = hof("b") })
assert(two.cards.PG.rarityBonus == 2 and two.cards.SG.rarityBonus == 2, "One HOF teammate is +2")
local three = Chemistry.evaluate({ PG = hof("a"), SG = hof("b"), SF = hof("c") })
assert(three.cards.PG.rarityBonus == 4, "Two HOF teammates are +4")
local mixed = Chemistry.evaluate({ PG = hof("a"), SG = nc("b") })
assert(mixed.cards.PG.rarityBonus == 1 and mixed.cards.SG.rarityBonus == 1, "A crossover is +1 each")
local blend = Chemistry.evaluate({ PG = hof("a"), SG = hof("b"), SF = nc("c") })
assert(blend.cards.PG.rarityBonus == 3, "One HOF teammate plus one crossover is +3")
assert(blend.cards.SF.rarityBonus == 2, "The non-college card crosses over to two HOF cards")
local lone = Chemistry.evaluate({ PG = hof("a"), SG = plain("b") })
assert(lone.cards.PG.rarityBonus == 0, "A lone rare card gains nothing")
assert(lone.cards.SG.rarityBonus == 0 and lone.cards.SG.tier == nil)

-- The bonus reaches the card's overall and the team average.
assert(two.cards.PG.overall == two.cards.PG.baseOverall + 2)
assert(two.bonus == 2, "Two HOF cards raise the team average by 2")

-- Full chem now counts rare links, so an all-rare five is full without school or year.
local rareFive = { hof("a"), hof("b"), nc("c"), nc("d"), hof("e") }
assert(Chemistry.isFull(rareFive), "Every pair links by tier or crossover")
local broken = { hof("a"), hof("b"), nc("c"), nc("d"), plain("e") }
assert(not Chemistry.isFull(broken), "A plain card with no school or year breaks full chem")
print('Rare chemistry: tiers, links, school/year precedence, +2 same-tier and +1 crossover stacking, team average and full chem passed')

-- The badge replaces every line, and notes a sixth man when the run carries one.
-- Full chem must leave no connection lines behind, in the six-frame Best Team
-- canvas as well as the five-frame squad builder.
local full = { { school = "Duke", season = "1990-91" }, { school = "Duke", season = "1990-91" },
 { school = "Duke", season = "1990-91" }, { school = "Duke", season = "1990-91" },
 { school = "Duke", season = "1990-91" } }
assert(Chemistry.isFull(full), "Five identical school/season cards are full chem")
full[6] = { school = "Kansas", season = "2024-25" }
assert(Chemistry.isFull(full), "A sixth man never breaks the starters' full chem")
assert(full[6] ~= nil, "The sixth slot is what the badge reads for its +1 suffix")
full[6] = nil
assert(Chemistry.isFull(full) and full[6] == nil, "Without a sixth the badge stays plain")
print("Full-chem badge: starters-only rule, sixth-man tolerance and the +1 signal passed")
