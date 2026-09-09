--!strict
local Types = require(script.Parent.PlayerTypes)
local Players = require(script.Parent.PlayerDatabase)
export type SchoolSeason = Types.SchoolSeason
local shards: { { SchoolSeason } } = {
    require(script.Parent.PlayerData.GeneratedSchools2022),
    require(script.Parent.PlayerData.GeneratedSchools2023),
    require(script.Parent.PlayerData.GeneratedSchools2024),
    require(script.Parent.PlayerData.GeneratedSchools2025),
    require(script.Parent.PlayerData.GeneratedSchools2026),
}
local Entries: { SchoolSeason } = {}
local ById: { [string]: SchoolSeason } = {}
for _, shard in shards do
    for _, school in shard do
        assert(ById[school.id] == nil, "Duplicate school-season")
        for _, id in school.rosterCardIds do
            local card = Players.ById[id]
            assert(card ~= nil and card.schoolSeasonId == school.id and card.variant == "BASE", "Invalid roster card")
        end
        for _, id in school.allStarCardIds do
            local card = Players.ById[id]
            assert(card ~= nil and card.schoolSeasonId == school.id and card.variant == "ALL_STAR_SEASON", "Invalid All-Star roster card")
        end
        table.freeze(school.rosterCardIds)
        table.freeze(school.allStarCardIds)
        ById[school.id] = school
        table.insert(Entries, school)
        table.freeze(school)
    end
    table.freeze(shard)
end
return table.freeze({ Entries = table.freeze(Entries), ById = table.freeze(ById) })
