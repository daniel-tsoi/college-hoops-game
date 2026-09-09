# College Hoops card game

The only openable Studio place is
`staged-implementation/CollegeHoops-UI-Trial-v3.rbxlx`. Use
`rojo serve default.project.json`, connect Studio, and save this same file.
Every future request continues this same game. Update the existing project and
documentation in place; do not create another place, version, or deliverable
document unless explicitly requested. The project-wide rules are in `AGENTS.md`.
Do not use Download a Copy or Save As to create a replacement place.
Historical builds are preserved under `staged-implementation/archive/` with the
non-openable `.rbxlx.archive` extension.

## Rolls, Shop, and ownership

Build Your Squad uses server-generated named players from `PlayerDatabase`.
Each position has consistent prospect numbers assigned by sorted card ID across
its eligible players: e.g. PG Prospect 750 resolves to an actual player, school,
season and rating. Numbers are identifiers, not prices or roll odds. Adding new
cards to the database may change the generated numbering.

The five candidates are server-generated rolls waiting to be accepted. Clicking
a candidate or pressing Roll adds that player to the saved collection and squad.
Unaccepted candidates do not count toward Collection or Best Team. Reroll spends a use to draw a different random school and year, new candidate
players, and a new rare wheel, without accepting a player or changing the squad. After accepting a player, press Roll for another team before
using Reroll again. Refresh redraws players within the current school and year and keeps the rare wheel.
Restart clears the current squad, keeps rolled ownership, and restores exactly
one free Reroll and one free Refresh. Unused quest Rerolls and Refreshes remain
on top of those free actions; free actions are spent first. Finish saves the completed draft. Reopening does
not reroll candidates. Studio profiles are disposable; live profiles save.

Shop buys permanent eligibility for that specific card, not ownership. Only
purchased HOF and non-college cards can appear in eligible position rolls.
Each positional draw uses mutually exclusive tickets out of 60,000:
HOF 75 (1/800), non-college 80 (1/750), All-Star 600 (1/100), ordinary 59,245.
These are tier odds; cards are selected uniformly among eligible cards in that
tier. If a special tier has no eligible cards for the position, that outcome
falls back to an ordinary college card. Ordinary and All-Star draws use the full
college database, not a currently selected school-season.

Legacy Shop-owned cards migrate to `shopUnlocked`; previous ownership/gold flags
are archived in `legacyShopOwned` / `legacyShopGold` without refunding or charging
cash. Their old equipped selection is cleared. Only subsequent rolled cards
enter Best Team. The leaderboard uses `HoopsRolledTeamOVR_v2` so old purchased
team scores do not appear. Eligible rolled teams register on next join.

## Squad chemistry

The active draft gives each player chemistry for matching schools and eras.
Era currently means the season printed on the card. Groups of 2/3/4/5 give
+1/+2/+3/+4 era OVR and +2/+4/+6/+7 school OVR. These stack on matching
players, after gold, without changing stored base ratings. Missing metadata
never forms a matching group. Team OVR averages the boosted lineup ratings.

Squad, candidate, and rare-hit cards show base OVR + chemistry. Hover or focus
a card to see the school/era breakdown and the projected team OVR, base change,
and chemistry change. Comparisons use the card's position and recalculate all
teammates; hovering never accepts a card. A filled regular slot is comparison
only; existing pick rules still apply. Collection Best Team remains its separate
highest-base-rating ownership summary.

## Gold, Collection, and Best Team

Every generated roll independently has 5% gold odds and a +5 OVR bonus, up to
115. Base database ratings stay unchanged. Gold is saved when accepting the roll.
A later gold roll upgrades an owned normal card; normal duplicates never remove
gold. A duplicate does not count as a new unique-player quest unlock.

Collection includes rolled cards; Gold Cards filters it to gold. Click to equip
a server-replicated overhead card. Best Team uses the five highest-rated unique
rolled players. A complete five-player team qualifies for the global top 50.
The current player's ranking row is highlighted. Studio rankings are local and
do not touch live data stores; global read caching refreshes every 30 seconds.

Playtime and activity quest cash, rerolls and refreshes remain saved. Only new
rolled ownership advances unique-player quests; eligibility purchases do not.

## Overhead titles

A colored title appears above each Roblox username: Top 1 gold, Top 2 silver,
Top 3 bronze, and Top 50 light blue for ranks 4–50. The same colored title
appears next to the player name in chat, e.g. `[Top 1] Player1`. Titles follow
the existing global best-team leaderboard and
refresh automatically even while the leaderboard panel is closed. Studio uses
session rankings only. Failed global reads preserve the last successful ranks.
Creator (purple), Admin (red), and Tester (green) override rank titles, in that
order. Configure numeric user IDs in `src/ServerScriptService/Config/TitleRoles.luau`;
the experience owner receives Creator automatically. These are cosmetic labels,
not administrative permissions. Equipped cards sit above the title and username.
The legacy server card renderer is replaced with cleanup; only the client renders
the card, preventing duplicate cards and broken server-side portraits.

## Verification and data

Run `python3 scripts/check_shop.py --luau /path/to/luau --compiler /path/to/luau-compile`
and `python3 scripts/check_player_database.py --luau /path/to/luau`.
Tests cover exact tier/gold ticket counts, eligibility gating, ownership migration,
roll saves, retries, positions, prospect IDs, bonuses, quests and leaderboard rules.
Live DataStore/cross-server validation remains separate from Studio tests.

Player data includes 25,393 college base cards, All-Star/HOF variants and four
non-college players. Ratings are estimates; preserve `research/THIRD_PARTY_NOTICES.md`
and see `research/PLAYER_DATABASE_RESEARCH.md` for sources and data limitations.
The separate disabled Robux product catalog is not the active cash eligibility shop.

## Card portraits

All card views share `CardPortrait` and `CardAppearance`: 3D block avatars with
a geometry smile, skin tones, styled hair and numbered team jerseys. The
existing prospect metadata supplies 3,000 player-season jersey records and 375
school colors. Missing details use deterministic stylized designs, not verified
likenesses. Special-player art is individually authored; Jordan has #23, a red
Bulls-inspired jersey, a bald head and a pulsing red energy aura.

HOF/non-college portraits use animated energy borders and hair details. Gold
cards retain their gold accent. A single visibility-aware client loop animates
auras and configures portrait cameras. Overhead cards render in each client’s
PlayerGui, attached to each character’s head, using replicated equipped-card
attributes. This lets Roblox render their ViewportFrame avatars correctly; cards
refresh on equipment changes and respawns and are removed when players leave. No external
face/hair assets or image uploads are required. Roll-card headers show only the
position; prospect numbers remain internal identifiers. Rebuild jersey metadata
with `python3 scripts/build_card_appearance.py`.
