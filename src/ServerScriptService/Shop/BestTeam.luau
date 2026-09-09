-- Highest-rated owned cards, with only one version of each player in the five.
local BestTeam = {}
function BestTeam.overall(card, isGold)
	return card.overall + (isGold and 5 or 0)
end
function BestTeam.select(owned, playersById, goldOwned)
	local candidates = {}
	for id, unlocked in pairs(owned) do
		if unlocked == true and playersById[id] then
			local card = table.clone(playersById[id])
			card.gold = goldOwned ~= nil and goldOwned[id] == true
			card.overall = BestTeam.overall(card, card.gold)
			table.insert(candidates, card)
		end
	end
	table.sort(candidates, function(a, b)
		if a.overall ~= b.overall then return a.overall > b.overall end
		return a.id < b.id
	end)
	local team, seen, total = {}, {}, 0
	for _, card in ipairs(candidates) do
		local identity = card.playerId or card.id
		if not seen[identity] then
			seen[identity] = true
			table.insert(team, { id = card.id, name = card.name, position = card.position,
				overall = card.overall, rarity = card.rarity, gold = card.gold, school = card.school, season = card.season })
			total += card.overall
			if #team == 5 then break end
		end
	end
	return { players = team, overall = #team > 0 and math.floor(total / #team + 0.5) or 0 }
end
return BestTeam
