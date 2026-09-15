-- Ratings passed here already include gold. Never mutate stored card ratings.
local Chemistry = {}
Chemistry.Positions = { "PG", "SG", "SF", "PF", "C" }
Chemistry.SquadPositions = { "PG", "SG", "SF", "PF", "C", "SIXTH" }
local schoolPoints = { 0, 2, 4, 6, 7, 8 }
local eraPoints = { 0, 1, 2, 3, 4, 5 }
-- Per teammate, not per group: two rare cards of a tier are worth +2 to each,
-- and a HOF standing beside a non-college is worth +1 to each.
local rarityPoints = { HOF = 2, NonCollege = 2, Cross = 1 }
local function key(value)
	if type(value) ~= "string" or value == "" then return nil end
	local normalized = string.lower(value):match("^%s*(.-)%s*$")
	if normalized == "" or normalized == "non-college" or normalized == "n/a" then return nil end
	return normalized
end
function Chemistry.connection(a, b)
	if not a or not b then return nil end
	local school, era = key(a.school), key(a.era or a.season)
	local sameSchool = school ~= nil and school == key(b.school)
	local sameEra = era ~= nil and era == key(b.era or b.season)
	if sameSchool and sameEra then return "Both" end
	if sameSchool then return "School" end
	if sameEra then return "Year" end
	return nil
end
-- A card's rare tier, read from the fields the client card views actually carry:
-- non-college cards are identified by their ID prefix, HOF by rarity.
function Chemistry.tier(card)
	if not card then return nil end
	if string.sub(card.id or "", 1, 12) == "non-college-" then return "NonCollege" end
	if card.rarity == "HOF" then return "HOF" end
	return nil
end
-- Two rare cards link: matching tiers pair up, and a HOF beside a non-college
-- is a weaker crossover.
function Chemistry.rarityLink(a, b)
	local first, second = Chemistry.tier(a), Chemistry.tier(b)
	if not first or not second then return nil end
	if first == second then return first end
	return "Cross"
end
-- Every way a pair can connect. School and year keep precedence for the line
-- colour, so existing squads look exactly as they did; a rare link only fills
-- in pairs that had no line at all before.
function Chemistry.link(a, b)
	return Chemistry.connection(a, b) or Chemistry.rarityLink(a, b)
end
-- Full chemistry means all ten starter pairs connect, by any of those routes;
-- the sixth man is separate.
function Chemistry.isFull(players)
 for i=1,5 do
  if not players[i] then return false end
  for j=i+1,5 do if not Chemistry.link(players[i], players[j]) then return false end end
 end
 return true
end
function Chemistry.evaluate(squad)
	local schools, eras = {}, {}
	local tiers = { HOF = 0, NonCollege = 0 }
	for _, pos in ipairs(Chemistry.SquadPositions) do
		local card = squad[pos]
		if card then
			local school, era = key(card.school), key(card.era or card.season)
			if school then schools[school] = (schools[school] or 0) + 1 end
			if era then eras[era] = (eras[era] or 0) + 1 end
			local tier = Chemistry.tier(card)
			if tier then tiers[tier] += 1 end
		end
	end
	local result = { cards = {}, count = 0, baseOverall = 0, overall = 0, bonus = 0 }
	local baseTotal, total = 0, 0
	for _, pos in ipairs(Chemistry.SquadPositions) do
		local card = squad[pos]
		if card then
			local schoolCount = schools[key(card.school)] or 0
			local eraCount = eras[key(card.era or card.season)] or 0
			local schoolBonus, eraBonus = schoolPoints[schoolCount] or 0, eraPoints[eraCount] or 0
			-- Rare chemistry is counted per teammate, not by group size: +2 for
			-- every teammate of the same tier, +1 for every crossover.
			local tier = Chemistry.tier(card)
			local rarityBonus = 0
			if tier then
				local same = tiers[tier] - 1
				local other = tiers[tier == "HOF" and "NonCollege" or "HOF"]
				rarityBonus = same * rarityPoints[tier] + other * rarityPoints.Cross
			end
			local bonus = schoolBonus + eraBonus + rarityBonus
			result.cards[pos] = { baseOverall = card.overall, overall = card.overall + bonus,
				bonus = bonus, schoolBonus = schoolBonus, eraBonus = eraBonus,
				rarityBonus = rarityBonus, tier = tier,
				schoolCount = schoolCount, eraCount = eraCount }
			result.count += 1
			baseTotal += card.overall
			total += card.overall + bonus
		end
	end
	if result.count > 0 then
		result.baseOverall = math.floor(baseTotal / result.count + 0.5)
		result.overall = math.floor(total / result.count + 0.5)
		result.bonus = result.overall - result.baseOverall
	end
	return result
end
function Chemistry.preview(squad, position, candidate)
	local projected = table.clone(squad)
	projected[position] = candidate
	local before, after = Chemistry.evaluate(squad), Chemistry.evaluate(projected)
	return { before = before, after = after, delta = after.overall - before.overall,
		baseDelta = after.baseOverall - before.baseOverall, chemistryDelta = after.bonus - before.bonus }
end
return Chemistry
