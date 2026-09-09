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

Cash, rerolls and refreshes already earned remain saved. Only new
rolled ownership advances unique-player quests; eligibility purchases do not.

## Logins, saved progress, and reward resets

Logging in is itself a save. Joining runs one `UpdateAsync` that archives the
session that just ended, counts the login, and stamps `lastLoginAt`, so the
record of a session is written at the start of the next one rather than relying
on the player's disconnect. `firstLoginAt` is stamped once. The login timestamp
is sampled before the callback, and every field derives from the stored value, so
a retried save counts the login once.

Each archived entry records what the player did that session: when it started and
ended, seconds played, cards unlocked, rerolls used, rewards claimed, and cash
earned. `sessionHistory` keeps the ten most recent, newest first. A join with no
time and no activity counts as a login but is not archived, so repeated instant
rejoins cannot flush real sessions out of the record. The Quests panel shows the
login number, the current session's activity, and a RECENT LOGINS list.

Every quest reward resets on each new connection. The 1/2/4 hour milestones
measure the current session's clock, not lifetime `playSeconds`, so those hours
must be played again to re-earn the reward — reconnecting alone grants nothing.
Lifetime `playSeconds` is still accumulated and shown as an all-time statistic.
Cash, cards, gold and reward stock already earned are never taken back. Profiles
saved before login tracking migrate with `logins` at 0 and an empty history;
their old lifetime `claimedQuests` flags are kept for reference and no longer
block a new login's rewards. Studio builds a disposable profile on each Play, so
they always report login #1 with no history; only live profiles accumulate it.

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
Run `lune run tests/player_titles.spec.luau` for title boundaries, role priority,
chat prefixes, and title/card script compilation.
Run `lune run tests/login_history.spec.luau` for login counting, save-retry
idempotence, archived session activity, history bounding, and the full reward
reset. `lune` is declared in `aftman.toml`, so these run from the project root.
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

## Player jerseys and settings

The gear button opens a rounded two-column settings panel. Choose one of eight
jersey colors and a number from 00–99; the back uses the Roblox username.
Sleeveless scoop-neck jerseys include contrasting neck/arm piping and matching
shorts with trimmed hems. The front shows a centered number; the back shows the
username and number. Server-built uniforms replicate and reapply on respawn
for R6 and R15 avatars. Bulky layered clothing may cover the fitted torso shell.
HOF and non-college VFX can be disabled independently for rare-pull celebrations
(including other players’ bursts); chat announcements and card art remain visible.
Five SFX bars control roll/refresh sound volume, with 0 for mute. Press Save changes
to apply. Live preferences save separately in HoopsPlayerSettings_v1; Studio
preferences last for the current play session. Failed saves can be retried.
Run `lune run tests/player_settings.spec.luau` for validation and compilation checks.
