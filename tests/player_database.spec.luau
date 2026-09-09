--!strict
local db = require("../src/shared/PlayerDatabase")
local schools = require("../src/shared/SchoolSeasonDatabase")
local odds = require("../src/ServerScriptService/Config/SummonConfig")
local store = require("../src/ServerScriptService/Config/NonCollegeCatalog")
assert(#db.Players == 25393 and #schools.Entries == 1812)
assert(#db.HOFPlayers == 8 and #db.NonCollegePlayers == 4)
local tickets: { [string]: number } = { HOF = 0, NonCollege = 0, ["All-Star"] = 0, Ordinary = 0 }
for ticket = 1, odds.Denominator do
    local matches = 0
    for outcome, range in odds.Tickets do
        if ticket >= range.first and ticket <= range.last then
            tickets[outcome] += 1
            matches += 1
        end
    end
    assert(matches == 1, "Every ticket must have exactly one mutually exclusive outcome")
end
assert(tickets.HOF == 75 and tickets.NonCollege == 80 and tickets["All-Star"] == 600 and tickets.Ordinary == 59245)
assert(75 / odds.Denominator == odds.HOFChance)
assert(600 / odds.Denominator == odds.AllStarChance)
assert(80 / odds.Denominator == odds.NonCollegeChance)
assert(odds.HOFChance / #odds.HOFCardIds == 1 / 6400)
local expectedHOF = {
    ["Magic Johnson"] = true, ["Michael Jordan"] = true, ["Shaquille O'Neal"] = true,
    ["Oscar Robertson"] = true, ["Pete Maravich"] = true, ["Jayson Tatum"] = true,
    ["Derrick Rose"] = true, ["Kyrie Irving"] = true,
}
local foundHOF: { [string]: boolean } = {}
for _, id in odds.HOFCardIds do
    assert(not foundHOF[id], "Duplicate HOF whitelist entry")
    foundHOF[id] = true
    local card = db.ById[id]
    assert(card ~= nil and card.rarity == db.Rarity.HOF and expectedHOF[card.name])
    assert(card.sourceStats ~= nil and card.sourceUrls ~= nil)
end
local expectedPurchase = { ["Kobe Bryant"] = true, ["LeBron James"] = true, ["Luka Doncic"] = true, ["Nikola Jokic"] = true }
local purchaseIds: { [string]: boolean } = {}
for _, product in store.Products do
    local card = db.ById[product.cardId]
    assert(card ~= nil and expectedPurchase[card.name] and card.sourceType == "NON_COLLEGE")
    assert(not product.defaultUnlocked and not product.randomEligible and not product.enabled)
    assert(product.productId == nil and card.schoolSeasonId == nil)
    purchaseIds[product.cardId] = true
end
assert(#store.Products == 4 and store.RequireVerifiedServerEntitlement)
for _, pool in { db.Players, db.AllStarPlayers, db.HOFPlayers } do
    for _, card in pool do assert(not purchaseIds[card.id], "Purchase card leaked into a summon pool") end
end
local seasonCounts: { [string]: number } = {}
local seenRoster: { [string]: boolean } = {}
for _, school in schools.Entries do
    seasonCounts[school.season] = (seasonCounts[school.season] or 0) + 1
    assert(not school.releaseReady, "Unreviewed source data cannot claim release readiness")
    assert(school.hasAllStarPool == (#school.allStarCardIds > 0))
    for _, id in school.rosterCardIds do
        assert(not seenRoster[id]); seenRoster[id] = true
        local card = db.ById[id]
        assert(card.sourceType == "COLLEGE" and card.schoolSeasonId == school.id)
    end
end
assert(seasonCounts["2021-22"] == 358 and seasonCounts["2022-23"] == 363)
assert(seasonCounts["2023-24"] == 362 and seasonCounts["2024-25"] == 364 and seasonCounts["2025-26"] == 365)
local duke2022 = schools.ById["espn-150-2021-22"]
assert(#duke2022.rosterCardIds == 14, "Official Duke archive has 14 roster players")
local banchero = db.ById["college-4432573-150-2022"]
assert(banchero ~= nil and banchero.sourceStats ~= nil)
assert(banchero.sourceStats.points == 671 and banchero.sourceStats.gamesPlayed == 39)
local edey = db.ById["college-4600663-2509-2024"]
assert(edey ~= nil and edey.sourceStats ~= nil and edey.sourceStats.points == 983 and edey.sourceStats.rebounds == 474)
for _, card in db.Players do
    assert(seenRoster[card.id] and card.sourceStats ~= nil and card.sourceStats.gamesPlayed >= 1)
    assert(card.ratingStatus == "DERIVED_ESTIMATE" and card.overall <= 99)
    assert(table.isfrozen(card) and table.isfrozen(card.attributes))
end
assert(not pcall(function() db.Players[1].attributes.shooting = 1000 end))
print("PASS: 25,393 base cards, 1,812 school-seasons, exact 1/800 HOF, 1/750 non-college and 1/100 All-Star odds, eight HOF identities, four non-college identities, source spot checks, immutable data")
