local Titles = {}
Titles.Colors = {
	["Top 1"] = Color3.fromRGB(255, 207, 89),
	["Top 2"] = Color3.fromRGB(210, 219, 230),
	["Top 3"] = Color3.fromRGB(205, 139, 82),
	["Top 50"] = Color3.fromRGB(128, 211, 255),
	Creator = Color3.fromRGB(185, 119, 255),
	Admin = Color3.fromRGB(255, 83, 91),
	Tester = Color3.fromRGB(103, 230, 139),
}
function Titles.forRank(rank)
	if type(rank) ~= "number" or rank ~= rank or rank % 1 ~= 0 or rank < 1 or rank > 50 then return nil end
	return rank <= 3 and ("Top " .. rank) or "Top 50"
end
function Titles.role(value)
	return (value == "Creator" or value == "Admin" or value == "Tester") and value or nil
end
-- The single title the overhead nameplate shows: the role outranks the board.
function Titles.resolve(role, rank)
	return Titles.role(role) or Titles.forRank(rank)
end
-- Every title a player holds, role first, for surfaces that can show more than
-- one. A Creator ranked first gets both, rather than the role hiding the rank.
function Titles.badges(role, rank)
	local list = {}
	local named = Titles.role(role)
	if named then table.insert(list, named) end
	local ranked = Titles.forRank(rank)
	if ranked then table.insert(list, ranked) end
	return list
end
return Titles
