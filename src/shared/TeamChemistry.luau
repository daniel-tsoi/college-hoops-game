-- Ratings passed here already include gold. Never mutate stored card ratings.
local Chemistry = {}
Chemistry.Positions = { "PG", "SG", "SF", "PF", "C" }
Chemistry.SquadPositions = { "PG", "SG", "SF", "PF", "C", "SIXTH" }
local schoolPoints = { 0, 2, 4, 6, 7, 8 }
local eraPoints = { 0, 1, 2, 3, 4, 5 }
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
-- Full chemistry means all ten starter pairs connect; the sixth man is separate.
function Chemistry.isFull(players)
 for i=1,5 do
  if not players[i] then return false end
  for j=i+1,5 do if not Chemistry.connection(players[i], players[j]) then return false end end
 end
 return true
end
function Chemistry.evaluate(squad)
	local schools, eras = {}, {}
	for _, pos in ipairs(Chemistry.SquadPositions) do
		local card = squad[pos]
		if card then
			local school, era = key(card.school), key(card.era or card.season)
			if school then schools[school] = (schools[school] or 0) + 1 end
			if era then eras[era] = (eras[era] or 0) + 1 end
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
			local bonus = schoolBonus + eraBonus
			result.cards[pos] = { baseOverall = card.overall, overall = card.overall + bonus,
				bonus = bonus, schoolBonus = schoolBonus, eraBonus = eraBonus,
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
