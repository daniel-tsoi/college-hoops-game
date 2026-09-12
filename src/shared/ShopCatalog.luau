-- Shop prices are game-balance choices; ratings come from the existing catalog.
local data = script.Parent.PlayerData
local offers = {}
local byId = {}
local pricing = {
	-- College-season impact, with Shaq as the $400k anchor.
	["hof-magic-johnson-1978-79"] = { 375000, "32", Color3.fromRGB(35, 119, 83) }, -- Magic
	["hof-michael-jordan-1983-84"] = { 350000, "23", Color3.fromRGB(110, 186, 232) }, -- Jordan
	["hof-shaquille-oneal-1991-92"] = { 400000, "33", Color3.fromRGB(113, 67, 169) }, -- Shaq
	["hof-oscar-robertson-1959-60"] = { 450000, "12", Color3.fromRGB(197, 49, 67) }, -- Oscar
	["hof-pete-maravich-1969-70"] = { 425000, "23", Color3.fromRGB(113, 67, 169) }, -- Pete
	["hof-jayson-tatum-2016-17"] = { 175000, "0", Color3.fromRGB(54, 100, 215) }, -- Tatum
	["hof-derrick-rose-2007-08"] = { 225000, "23", Color3.fromRGB(63, 119, 218) }, -- Rose
	["hof-kyrie-irving-2010-11"] = { 150000, "1", Color3.fromRGB(54, 100, 215) }, -- Kyrie
	-- No college season: separately balanced premium unlocks.
	["non-college-kobe-bryant"] = { 425000, "24", Color3.fromRGB(128, 78, 195) },
	["non-college-lebron-james"] = { 450000, "23", Color3.fromRGB(199, 76, 87) },
	["non-college-luka-doncic"] = { 325000, "77", Color3.fromRGB(56, 132, 207) },
	["non-college-nikola-jokic"] = { 375000, "15", Color3.fromRGB(48, 108, 149) },
	["non-college-kevin-garnett"] = { 400000, "21", Color3.fromRGB(36, 104, 73) },
	["non-college-victor-wembanyama"] = { 425000, "1", Color3.fromRGB(150, 166, 177) },
	["non-college-dirk-nowitzki"] = { 375000, "41", Color3.fromRGB(0, 83, 140) },
	["non-college-giannis-antetokounmpo"] = { 425000, "34", Color3.fromRGB(0, 71, 27) },
}
for _, pool in ipairs({ require(data.GeneratedHOF001), require(data.GeneratedNonCollege001) }) do
	for _, player in ipairs(pool) do
		local price = assert(pricing[player.id], "Missing shop price: " .. player.id)
		local offer = table.freeze({
			id = player.id, player = player, price = price[1], number = price[2], color = price[3],
			group = player.sourceType == "NON_COLLEGE" and "NON-COLLEGE" or "HOF",
		})
		table.insert(offers, offer)
		byId[offer.id] = offer
	end
end
return table.freeze({ Offers = table.freeze(offers), ById = table.freeze(byId) })
