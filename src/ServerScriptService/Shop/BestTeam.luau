-- A record is one complete rolled lineup, never a collection optimizer.
local BestTeam = {}
local positions = { "PG", "SG", "SF", "PF", "C", "SIXTH" }
function BestTeam.overall(card, isGold)
	return card.overall + (isGold and 5 or 0)
end
function BestTeam.select(profile)
	return profile.bestCompletedTeam or { players = {}, overall = 0 }
end
-- Called inside the profile save transaction. Snapshot the drawn gold version
-- and ratings so later collection upgrades cannot alter an earlier run.
function BestTeam.record(profile, playersById, chemistry)
	local draft = profile.rollDraft
	if not draft or not draft.finished then return profile end
	local size = draft.squad and draft.squad.SIXTH and 6 or 5
	if draft.bestTeamRecordedCount == size then return profile end
	local squad, players = {}, {}
	for index, position in ipairs(positions) do
		local entry = (draft.squad or {})[position]
		local source = entry and playersById[entry.id]
		if not source then
			if index <= 5 or entry then return profile end
		else
			local roll = entry.goldRoll
			local gold = type(roll) == "number" and roll % 1 == 0 and roll >= 1 and roll <= 5
			local card = { id = source.id, name = source.name, position = source.position,
				slot = position, overall = BestTeam.overall(source, gold), gold = gold,
				rarity = source.rarity, school = source.school, season = source.season, era = source.era }
			squad[position] = card
			table.insert(players, card)
		end
	end
	local rating = chemistry.evaluate(squad)
	local updated = table.clone(profile)
	updated.rollDraft = table.clone(draft)
	updated.rollDraft.bestTeamRecordedCount = #players
	if rating.overall <= BestTeam.select(profile).overall then return updated end
	for _, card in ipairs(players) do
		local stats = rating.cards[card.slot]
		card.baseOverall = card.overall
		card.overall = stats.overall
		card.chemistryBonus = stats.bonus
	end
	updated.bestCompletedTeam = { players = players, overall = rating.overall,
		baseOverall = rating.baseOverall, chemistryBonus = rating.bonus }
	return updated
end
return BestTeam
