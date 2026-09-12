--!strict
-- Real player-school-season data, generated from attributed box scores.
-- All game ratings are estimates. See research/PLAYER_DATABASE_RESEARCH.md.
-- Future stat consumers apply a multiplier ONCE to BASE attributes:
-- math.clamp(math.round(baseAttribute * player.statMultiplier), 1, 99).
-- Do not multiply Overall, which already defines the explicit card tier.
local Types = require(script.Parent.PlayerTypes)
local Data = require(script.Parent.PlayerDataIndex)
export type Rarity = Types.Rarity
export type Position = Types.Position
export type Attributes = Types.Attributes
export type Player = Types.Player
export type SourceStats = Types.SourceStats
export type RatingRange = Types.RatingRange
local ById: { [string]: Player } = {}
local function collect(shards: { { Player } }): { Player }
    local pool: { Player } = {}
    for _, shard in shards do
        for _, player in shard do
            assert(player.id ~= "" and ById[player.id] == nil, "Duplicate or empty card ID: " .. player.id)
            assert(player.name ~= "" and player.playerId ~= "", "Missing player identity")
            local range = Types.OverallRangeByRarity[player.rarity]
            assert(player.overall % 1 == 0 and player.overall >= range.min and player.overall <= range.max, "Invalid Overall: " .. player.id)
            assert(player.statMultiplier == Types.StatMultiplierByRarity[player.rarity], "Wrong multiplier")
            for _, value in { player.attributes.shooting, player.attributes.dribbling, player.attributes.defense, player.attributes.speed, player.attributes.stamina } do
                assert(value % 1 == 0 and value >= 1 and value <= 99, "Base attribute outside 1-99: " .. player.id)
            end
            if player.sourceType == "NON_COLLEGE" then
                assert(player.acquisition == "DIRECT_PURCHASE" and player.schoolSeasonId == nil and player.defaultUnlocked == false, "Non-college card must require purchase")
            else
                assert(player.schoolSeasonId ~= nil and player.school ~= nil and player.season ~= nil, "Missing historical school-season")
            end
            if player.sourceStats then table.freeze(player.sourceStats) end
            if player.sourceUrls then table.freeze(player.sourceUrls) end
            table.freeze(player.eligiblePositions)
            table.freeze(player.attributes)
            ById[player.id] = player
            table.insert(pool, player)
            table.freeze(player)
        end
        table.freeze(shard)
    end
    table.freeze(shards)
    return table.freeze(pool)
end
local Players = collect(Data.College)
local AllStarPlayers = collect(Data.AllStar)
local HOFPlayers = collect(Data.HOF)
local NonCollegePlayers = collect(Data.NonCollege)
assert(#HOFPlayers == 8 and #NonCollegePlayers == 8, "Special pools must contain exactly eight HOF and eight purchase cards")
for _, card in AllStarPlayers do
    local base = if card.baseCardId then ById[card.baseCardId] else nil
    assert(base ~= nil and base.sourceType == "COLLEGE" and base.variant == "BASE", "Missing All-Star base card")
    assert(base.playerId == card.playerId and base.schoolSeasonId == card.schoolSeasonId, "All-Star school-season mismatch")
end
table.freeze(ById)
return table.freeze({
    Rarity = Types.Rarity, StatMultiplierByRarity = Types.StatMultiplierByRarity,
    OverallRangeByRarity = Types.OverallRangeByRarity,
    Players = Players, AllStarPlayers = AllStarPlayers, HOFPlayers = HOFPlayers,
    NonCollegePlayers = NonCollegePlayers, ById = ById,
})
