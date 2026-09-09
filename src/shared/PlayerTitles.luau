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
function Titles.resolve(role, rank)
	if role == "Creator" or role == "Admin" or role == "Tester" then return role end
	return Titles.forRank(rank)
end
return Titles
