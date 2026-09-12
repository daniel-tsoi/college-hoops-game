local Ranking = {}
function Ranking.score(overall, count)
	if (count ~= 5 and count ~= 6) or type(overall) ~= "number" or overall ~= overall or overall < 1 or overall > 128 then return nil end
	return math.floor(overall + 0.5)
end
function Ranking.top(entries)
	local sorted = table.clone(entries)
	table.sort(sorted, function(a, b)
		if a.overall ~= b.overall then return a.overall > b.overall end
		return a.userId < b.userId
	end)
	local rows = {}
	for rank = 1, math.min(50, #sorted) do
		local row = table.clone(sorted[rank])
		row.rank = rank
		table.insert(rows, row)
	end
	return rows
end
return Ranking
