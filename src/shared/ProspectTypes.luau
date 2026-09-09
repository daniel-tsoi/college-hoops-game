--!strict
-- College ratings are game-design estimates, not measured scouting grades.
export type Position = "PG" | "SG" | "SF" | "PF" | "C"
export type Rarity = "Common" | "Rare" | "Epic" | "Legendary"
export type Ratings = {
 midRange: number, threePoint: number, drivingDunk: number,
 perimeterDefense: number, ballHandle: number, speed: number, stamina: number,
}
export type Attributes = {
 shooting: number, dribbling: number, defense: number, speed: number, stamina: number,
}
export type Appearance = {
 jersey: string, teamColor: string, style: number,
 kind: "STYLIZED_NOT_VERIFIED_LIKENESS",
 height: string?, weight: string?,
}
export type Stats = {
 gamesPlayed: number, minutes: number, points: number, ppg: number,
 fgPercent: number?, threePercent: number?, freeThrowPercent: number?,
}
export type Prospect = {
 id: string, playerId: string, name: string, school: string, schoolId: string,
 season: string, year: number, position: Position, sourcePosition: string,
 overall: number, rarity: Rarity, ratings: Ratings, attributes: Attributes,
 appearance: Appearance, stats: Stats?,
 ratingStatus: "ESTIMATED" | "PROVISIONAL_NO_STATS", sourceId: string,
 rosterSourceUrl: string?,
}
local Rarity: {Common: "Common", Rare: "Rare", Epic: "Epic", Legendary: "Legendary"} = {
 Common = "Common", Rare = "Rare", Epic = "Epic", Legendary = "Legendary",
}
table.freeze(Rarity)
return table.freeze({Rarity = Rarity})
