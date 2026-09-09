--!strict
-- Shared enum, data shapes, and balance constants. No game actions.
export type Rarity = "Common" | "Rare" | "Epic" | "Legendary" | "All-Star" | "HOF"
export type Position = "PG" | "SG" | "SF" | "PF" | "C"
export type Attributes = { shooting: number, dribbling: number, defense: number, speed: number, stamina: number }
export type SourceStats = {
    gamesPlayed: number,
    gamesStarted: number?, minutes: number?, fgm: number?, fga: number?,
    threeMade: number?, threeAttempted: number?, ftm: number?, fta: number?,
    offensiveRebounds: number?, defensiveRebounds: number?, rebounds: number?,
    assists: number?, steals: number?, blocks: number?, turnovers: number?, fouls: number?, points: number?,
}
export type Player = {
    id: string, playerId: string, name: string, position: Position,
    rarity: Rarity, overall: number, attributes: Attributes, statMultiplier: number,
    sourceType: "COLLEGE" | "LEGACY_HOF" | "NON_COLLEGE",
    acquisition: "SCHOOL_SEASON" | "GLOBAL_HOF" | "DIRECT_PURCHASE",
    variant: "BASE" | "ALL_STAR_SEASON" | "HOF" | "NON_COLLEGE",
    ratingStatus: "DERIVED_ESTIMATE" | "MANUAL_ESTIMATE",
    ratingModelVersion: string, dataConfidence: "LOW" | "MEDIUM",
    positionConfidence: "SOURCE" | "ESTIMATED" | "LOW",
    speedBasis: "POSITION_PRIOR_NOT_MEASURED" | "MANUAL_ARCHETYPE_NOT_MEASURED",
    sourcePosition: string?, sourceId: string?, sourceUrls: { string }?, sourceStats: SourceStats?,
    schoolSeasonId: string?, school: string?, season: string?,
    eligiblePositions: { Position }, baseCardId: string?, eligibilityBasis: string?,
    defaultUnlocked: boolean?,
}
export type SchoolSeason = {
    id: string, school: string, teamName: string, season: string, sourceTeamId: string,
    recordedGames: number, rosterCardIds: { string }, allStarCardIds: { string },
    coverageStatus: "BOX_SCORES_IMPORTED_NOT_FULLY_AUDITED",
    hasLegalLineup: boolean, hasAllStarPool: boolean, releaseReady: boolean,
}
export type RatingRange = { min: number, max: number }
local Rarity: {
    Common: "Common", Rare: "Rare", Epic: "Epic", Legendary: "Legendary", AllStar: "All-Star", HOF: "HOF",
} = { Common = "Common", Rare = "Rare", Epic = "Epic", Legendary = "Legendary", AllStar = "All-Star", HOF = "HOF" }
table.freeze(Rarity)
local StatMultiplierByRarity: { [Rarity]: number } = table.freeze({
    [Rarity.Common] = 1, [Rarity.Rare] = 1.05, [Rarity.Epic] = 1.10,
    [Rarity.Legendary] = 1.15, [Rarity.AllStar] = 1.20, [Rarity.HOF] = 1.25,
})
-- These bands apply to Overall, not measured box scores or base attributes.
-- The shared endpoint 105 is intentional. Read rarity explicitly.
local OverallRangeByRarity: { [Rarity]: RatingRange } = {
    [Rarity.Common] = { min = 1, max = 64 }, [Rarity.Rare] = { min = 65, max = 79 },
    [Rarity.Epic] = { min = 80, max = 89 }, [Rarity.Legendary] = { min = 90, max = 99 },
    [Rarity.AllStar] = { min = 100, max = 105 }, [Rarity.HOF] = { min = 105, max = 110 },
}
for _, range in OverallRangeByRarity do table.freeze(range) end
table.freeze(OverallRangeByRarity)
return table.freeze({ Rarity = Rarity, StatMultiplierByRarity = StatMultiplierByRarity, OverallRangeByRarity = OverallRangeByRarity })
