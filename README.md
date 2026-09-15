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
enter Best Team. The leaderboard uses `HoopsCompletedTeamOVR_v3` so old purchased
or collection-composite scores do not appear. Saved complete-run teams register on next join.

## Squad chemistry

The active draft gives each player chemistry for matching schools and eras.
Era currently means the season printed on the card. Groups of 2/3/4/5 give
+1/+2/+3/+4 era OVR and +2/+4/+6/+7 school OVR. These stack on matching
players, after gold, without changing stored base ratings. Missing metadata
never forms a matching group. Team OVR averages the boosted lineup ratings.

Squad, candidate, and rare-hit cards show base OVR + chemistry. Hover or focus
a card to see only active bonuses as Year (+N) and Team (+N), plus the projected
team OVR. Zero-bonus categories are hidden. Comparisons use the card's position and recalculate all
teammates; hovering never accepts a card. A filled regular slot is comparison
only; existing pick rules still apply. Best Team uses the same gold and chemistry ratings as the completed squad.

Chemistry connections appear in the squad builder and Best Team view: green
means the same school, yellow means the same season/year, and blue means both.
Only players with chemistry connect; pairs without chemistry have no line. Five-pixel
straight segments stop before
card borders and skip any intervening card or central Best Team rating text.
Connections refresh when the displayed lineup changes; Best Team selection and
rating rules are unchanged by these visual connections.

## Gold, Collection, and Best Team

Every generated roll independently has 5% gold odds and a +5 OVR bonus, up to
115. Base database ratings stay unchanged. Gold is saved when accepting the roll.
A later gold roll upgrades an owned normal card; normal duplicates never remove
gold. A duplicate does not count as a new unique-player quest unlock.

Collection includes rolled cards; Gold Cards filters it to gold. Click to equip
a server-replicated overhead card. Best Team saves a whole completed run: five starters,
plus the optional sixth man when that lineup beats the record. It never combines
positions from separate runs or upgrades a record from later collection gold.
Only a strictly higher rounded team OVR replaces the saved lineup; ties retain it.
A five-player completion is eligible immediately; choosing a sixth evaluates the
complete six-player lineup, retaining the earlier five if its OVR was higher.
Gold and chemistry are included, with a maximum of 128 for a six-player team.
Existing completed drafts can seed a record; ownership alone cannot.
Complete five- or six-player records qualify for the global top 50.
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
block a new login's rewards.

### Testing persistence in Studio

Studio builds a disposable profile on each Play: no DataStore is read or
written, so progress cannot survive a rejoin and every session reports login #1
with no history. That is the default, not a fault, and "Enable Studio Access to
API Services" does not change it because the save path is skipped before that
setting would apply. Each server states its mode once at startup, so the output
window says plainly whether saving is live, opted-in, or disposable.

To verify persistence, set `enabled = true` in
`src/ServerScriptService/Config/StudioSaving.luau`. Studio then reads and writes
the real `CollegeHoopsShop_v1` and `HoopsPlayerSettings_v1` stores under the
`studio_` key prefix, so a Studio session can never read or overwrite a live
player's profile. Fresh Studio profiles start with the configured cash either
way. The global best-team leaderboard is deliberately excluded: its ordered
store is keyed by user ID with no room for a prefix, so Studio play would land
in the live rankings; Studio rankings stay session-local. The opt-in is
committed disabled and `lune run tests/studio_saving.spec.luau` fails if that
changes, along with checking Studio keys cannot collide with live ones.

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

Player data includes 25,393 college base cards, All-Star/HOF variants and eight
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
The silhouette is built from flat-topped fabric slabs capped by a rotated piping
chord, with the maths in `src/shared/JerseyGeometry.luau`. Each slab's top sits
on its chord's midpoint and the piping is at least as thick as a slab is wide,
which provably covers the fabric corners at every slope — including the steep
drop into each armhole, where the previous fixed 0.055 piping left them exposed
by 0.068 studs and read as a jagged strip. The piping is now one band per slab
wrapping the full torso depth, instead of two thinner ribbons floating 0.026
clear of the fabric, and the separate `ShoulderTrim` nubs are gone because they
sat at the same height as the shoulder-strap chord and shimmered against it.
Slabs overlap by 0.004 so their side faces never share a plane. This is 20
slabs rather than 48, which is 50 parts per avatar instead of 158. Run
`lune run tests/jersey_fit.spec.luau` to check coverage across torso shapes.

Sleeveless scoop-neck jerseys include contrasting neck/arm piping and matching
shorts with trimmed hems. The front shows a centered number; the back shows the
username and number. Server-built uniforms replicate and reapply on respawn
for R6 and R15 avatars. Uniform fitting waits for avatar appearance loading and rebuilds after body-size
changes. Classic clothing and torso/leg clothing accessories are hidden on the
in-game character so they cannot cover the uniform; hats, hair and shoes stay.
This does not change the player’s Roblox outfit. Unusual custom rigs still need
visual checks; this is a fitted geometric uniform rather than a skinned garment.
HOF and non-college VFX can be disabled independently for rare-pull celebrations
(including other players’ bursts); chat announcements and card art remain visible.
Five SFX bars control roll/refresh sound volume, with 0 for mute. Press Save changes
to apply. Live preferences save separately in HoopsPlayerSettings_v1; Studio
preferences last for the current play session. Failed saves can be retried.
Run `lune run tests/player_settings.spec.luau` for validation and compilation checks.

Non-college additions: Kevin Garnett (104 OVR, $400k), Victor Wembanyama
(104, $425k), Dirk Nowitzki (103, $375k), and Giannis Antetokounmpo (104, $425k).
All use the shared Shop, roll, collection, gold, and overhead card presentation.
Wembanyama has an intentionally extra-tall torso with his head above the portrait
crop. Draft year/pick appear in their Shop subtitles; these are metadata, not
college seasons for chemistry. Ratings are manual skill/potential appraisals.

For friends on separate computers, use Studio **Team Test** in the same
collaborative place; other collaborators join the active session with Play.
**Server & Clients** simulates multiple players locally and does not connect
independent tests on different computers. Check the server’s Players list to
confirm that both users are actually in the same session.

The squad builder includes an optional sixth man after the five starters auto-save. Three blank cards replace the lower-left prospect text; a fresh college team and season are rolled at random, both different from the final displayed prospect team and year. Each available card holds a distinct random player from that new roster, excluding the five displayed prospects and existing squad players. Chemistry uses the revealed player’s actual school and season; it does not inherit the final prospect roll’s chemistry. Picking one flips it with Casino Flip Card audio (Creator Store asset 77158612385089), saves it into the optional sixth slot and collection, and completes the squad again. Other cards stay hidden. Rosters with fewer than three eligible reserves disable the surplus cards. Restart discards unclaimed offers; leaving the menu preserves them. Sixth-man ownership uses the normal atomic save and retry rules. Team OVR averages all six cards when selected; six matching school/year cards receive +8 school and +5 year chemistry. Best Team records the complete five- or six-player lineup only when its team OVR exceeds the saved record. Run `lune run tests/sixth_man.spec.luau` for the optional-pick, exclusion, retry, ownership, restart, and chemistry checks.

The roll lineup shows only the five starters in a symmetric pentagon: PG at the top, SG/SF on the sides, and PF/C at the bottom. After the fifth pick, Roll becomes Finish. Finish opens a small “Do you want a 6th man?” prompt with Yes and No buttons. Yes returns to the builder with Roll enabled and three hidden sixth-man cards; Roll chooses an available hidden card at random, or the player can pick a card directly. No saves the decision to keep five and closes the builder. Revealing a sixth man changes Roll back to Finish, which returns to the game. Restart resets the draft. No full-screen validation or squad-summary page interrupts this flow.

Robux purchases use the four existing Developer Products in experience `10765724001`, configured in `src/ServerScriptService/Config/DeveloperProducts.luau`: Rerolls `3712333174` (49 Robux / 10), Refreshes `3712333240` (49 Robux / 10), ShopPlayer `3712333475` (400 Robux / one player eligibility unlock), and Sixth `3712334064` (29 Robux / one additional reveal). Each Shop card has equal-width cash and Robux buttons. Both payment methods unlock that specific player's roll eligibility; neither grants ownership nor guarantees a rare hit. The rare wheels use the normal independent 0.125% HOF / 0.13% Non-College odds, with the temporary 100% tests disabled. The custom purchase confirmation and chemistry-hover panels are removed; purchase buttons invoke Roblox's native purchase prompt directly.

The generic ShopPlayer product grants a durable unlock credit. After the receipt is saved, the Shop client automatically redeems that credit for the clicked player. If delivery is delayed past a disconnect or redemption fails, the credit stays saved and Shop buttons show USE UNLOCK; the player can redeem it without being charged again. Already-unlocked cards do not consume another credit. Receipt processing never infers a target card from a mutable last-selection variable: an old receipt cannot silently unlock a different player. The separate redemption endpoint validates the Shop catalog and never opens another payment prompt.

At zero total rerolls/refreshes, the corresponding button offers another pack of 10. Separate paid balances stack additively, persist across live server sessions, and survive squad restarts. Free and quest balances are consumed first. Receipt IDs and credits are committed atomically in the existing player profile; failed saves return NotProcessedYet, and duplicate receipts cannot duplicate rewards. Paid random-action eligibility is checked with PolicyService. The first sixth-man choice remains free; one 29 Robux credit reveals each additional card, up to all three. Each paid reveal rotates the selected card and replaces the active sixth man, unclaiming the outgoing reward from the collection. Copies owned before that pick are preserved. Previously tried cards show UNCLAIMED; only the current reward is kept. Occupied prospect positions show a large black X across the card.

Verification: `lune run tests/robux_rewards.spec.luau` covers distinct and duplicate receipts, stacked balances, two serialized save/rejoin cycles, free-before-paid consumption, restart preservation, Shop eligibility without ownership, no guarantee after paying, repeat redemption, and all three sixth-man reveals. The roll, rare-wheel, cash-Shop, quest, sixth-man, and completion tests also pass. Studio runtime checks confirmed 16 equal-width cash/Robux button pairs, no hover or custom confirmation panel, and the native 400 Robux prompt for the correct product (explicitly marked as a no-charge test purchase). Completing that simulated payment through the automation was blocked by CoreGui input restrictions; no real Robux were spent. An isolated real DataStore persistence check returned 403 because Studio API access is disabled; live DataStore rejoin testing remains unverified. Default Studio profiles are disposable, as documented in Config/StudioSaving; this does not reset live purchased balances.

The source changes are synced through the root Rojo project. Saving back to the canonical local file remains unverified: Studio has continued using a cloud document after the canonical local file was opened, and only offers Save to Roblox / Download a Copy. No alternate place file was created; source files are the durable copy until the canonical local save succeeds.


## Quest purchases, luck, and daily spins (September 12)

Every quest has a **2× NOW** purchase immediately left of Claim. A confirmed purchase immediately grants twice that quest's cash, rerolls, and refreshes, regardless of progress. It marks the quest claimed for this login. Each distinct paid receipt delivers its full bundle even after an earlier free or paid claim; duplicate receipt delivery does not grant twice. Progress counters are not fabricated. Wallet, receipt history, and claim flags are committed in the same UpdateAsync.

All eleven products below were created in Codeninjaexpert111's experience **10765724001** and their prices verified in Creator Dashboard. Managed pricing is disabled on these eleven offers to preserve the requested fixed prices. Existing products retain their settings.

| Product | Robux | Product ID |
|---|---:|---:|
| Instant 2×: Play 1 Hour | 49 | 3712570496 |
| Instant 2×: Play 2 Hours | 99 | 3712570593 |
| Instant 2×: Play 4 Hours | 199 | 3712570656 |
| Instant 2×: Unlock 5 Players | 49 | 3712570834 |
| Instant 2×: Unlock 10 Players | 99 | 3712570877 |
| Instant 2×: Use 100 Rerolls | 49 | 3712571010 |
| Instant 2×: Use 200 Rerolls | 99 | 3712571063 |
| Luck 1.5× | 149 | 3712570156 |
| Luck 2× | 399 | 3712570367 |
| Luck 2.5× | 799 | 3712570418 |
| Luck 3× | 1099 | 3712570467 |

The green horizontal thermometer starts at 1× and advances permanently in 0.5× steps. The next-tier cash prices are $250,000 / $1,000,000 / $5,000,000 / $10,000,000. Confirmed paid luck upgrades activate atomically during receipt saving, without needing a client event. Delayed higher-tier credits remain saved until their prerequisites are owned. Luck scales future All-Star tier tickets, independent eligible HOF/Non-College wheel tickets, and gold chances (5%, 7.5%, 10%, 12.5%, 15%). It does not redraw existing cards or unlock Shop eligibility. For restricted accounts only the cash-earned luck level applies.

Daily opens automatically once on every login, including while on cooldown, and can be reopened using a smaller **DAILY** button at the top right of the lobby. The green **SPIN** button shows availability via the wheel's 0/1 or 1/1 counter; **EXIT** dismisses it. A profile starts with one spin. Consuming it starts a saved 43,200-second cooldown. After 12 hours there is one spin available, never multiple accumulated spins. The server samples the outcome before the atomic wallet save, and the client animation lands on that saved outcome. The wheel rotates around its center beneath a fixed gold pointer, makes at least five clockwise turns, and eases to a stop at a random interior point of the server-awarded slice. The visual redesign uses one smooth, rounded disc with a conical gradient filling five colored pie wedges and five inset dividers instead of 360 strips. Each wedge runs from the shared center to the circular edge; the face rotates inside the stationary rim, with no offset orbit. The five distinct gold, red, green, blue, and purple fills use the same top-origin clockwise order as Geometry.target. Reward labels sit directly on their wedges instead of separate dark cards. Reward labels counter-rotate to stay upright with light text, muted percentages, and gold/red/green accents. A shaped gold diamond marks the landing edge and flicks on sector crossings. Layered rims, shadows, gradients, 2px borders, and SPIN hover/press feedback match the game panels. The persistent result card calls out the awarded reward; the two 2.5% player prizes receive a larger reveal and longer rim pulse. The 650×780 design canvas fits through UIScale without scrolling. These changes are client presentation only: the five-second Quart spin, Geometry.target contract, availability, odds, and server logic are unchanged. The wheel uses equal visual slices with explicit weighted probabilities:

| Daily outcome | Probability |
|---|---:|
| HOF player | 2.5% |
| Non-college player | 2.5% |
| $100,000 | 20% |
| $50,000 | 35% |
| $15,000 | 40% |

Daily odds are fixed and unaffected by purchased luck. Player prizes grant permanent card ownership directly, preferring unowned cards from the selected pool; if every player in that category is already owned, the prize becomes $1,000,000 instead. Ownership is checked inside the saved transaction; the wheel still lands on the original HOF/Non-College slice and the reveal shows the cash replacement. A missing reward pool keeps the spin available. Cash prizes also count toward the current login's earned cash.

Lobby controls expand to 276×78 on larger screens, with responsive widths and spacing; Build expands to 480×96. Roll is 240×132, and Reroll/Refresh/Restart/Exit are 240×75. Shop tabs, cash/Robux purchases, quest purchases, and luck purchases have taller hitboxes and larger text. Daily remains compact. Sixth-man cards use the normal card's large OVR above the portrait and separate player name below; the position header says SIXTH. Accepting a sixth-man choice disables Roll/Restart on client and server until selection or Keep Five. Full starting-five chemistry replaces the ten lines with a circled FULL CHEM badge.

Validation: all 224 source scripts compile. Spinner geometry tests cover centered strips, the circular rim, clockwise rotation, and safe landing within every awarded slice from every starting degree. Quest, instant-quest-purchase, luck, existing receipt, sixth-man, completion, and daily-spin tests pass. Daily tests exhaust all 1,000 outcome tickets and cover each reward, first-login availability, cooldown boundary, save retries, reconnects, a week away without accumulation, duplicate card ownership, and missing reward pools. Purchase tests cover zero-progress payout, post-claim purchases, duplicate receipts, serialized rejoining, exact prices, and immediate sequential luck activation.

**Studio integration remains pending.** The filled pie-wheel correction is saved in source. A read-only Studio check confirmed support for conical UIGradient rendering, but the active client still contains the old 460px wheel and earlier layout; the latest Studio check shows an active client play session with only a cloud place title, so the canonical local document still cannot be verified. The detected root Rojo server was stopped before this correction to prevent syncing to an unverified document. Root Rojo was stopped before editing; a newly started root-project server was later detected on port 34872, but its Studio connection has not been verified by this task. The canonical file picker still failed to open the selected local file; Finder also returned `cgWindowNotFound`. A stale canonical lock belonging to non-running PID 54627 was moved to a temporary backup, but this did not resolve opening. No alternate place, archive, cloud save, or publish was created. Source and product configuration are saved here; real purchase completion, daily-wheel rendering, and the canonical local save have not yet been verified. Open `staged-implementation/CollegeHoops-UI-Trial-v3.rbxlx`, run `rojo serve default.project.json --port 34872`, connect Rojo, and save to that same canonical local file.

The 100/200 activity quests now display **ROLL 100 TIMES** and **ROLL 200 TIMES**. Each successful Roll or Restart action contributes one toward both per-login milestones. Opening the builder, spending rerolls, refreshing, selecting a card, and rejected actions do not contribute. Existing saved quest progress is carried forward once; the new counter resets on the next login, and reward amounts and paid product IDs are unchanged.

## First-time tutorial

`src/StarterPlayer/StarterPlayerScripts/Tutorial.client.luau` owns a single `HoopsTutorialUI` ScreenGui at DisplayOrder **90**, below the rare-pull celebration at **100**. New profiles begin in the lobby and follow Build Your Squad, accepting a candidate, the three separate Reroll/Refresh/Restart explanations, chemistry, gold odds, a dedicated Shop eligibility explanation, and completion of the five-player run with the existing optional sixth-man flow. Daily spin, per-login quests, and luck each get one closing line. Gold is described as an independent **5% base chance**, with luck improving it, consistent with the existing luck system.

The lobby **Tutorial** button sits at the top left above the gear, with both positions and sizes owned by LobbyButtons. The Settings **Replay tutorial** button explicitly restarts the guide without clearing the profile flag or collection. **Skip tutorial** and the final **Let's play** button both call `CompleteTutorial`. The server allows that action and commits the pure `Transactions.completeTutorial` function through the existing atomic profile save. `Transactions.migrate` defaults `tutorialDone` to false; `startSession` never resets it. The response includes the flag, and failed completion saves display a retry instead of pretending completion was durable. Studio still uses disposable profiles, so every Play offers the tutorial again.

Highlights resolve real named instances and follow `AbsolutePosition` / `AbsoluteSize`, including ancestor scaling and safe-area offsets, on every rendered frame. The guide uses the same clamped 1280×720 reference scale as lobby controls and chooses a corner that avoids its current target. Controller selection uses MenuFocus. While active it owns `HoopsPanel = "Tutorial"`; if another panel owns the attribute, the guide and highlight pause until it closes. Daily's automatic login opening waits for first-time completion or skip. Confirmed RollController responses drive progress; rejected requests cannot count as accepted cards. Reopening the builder resumes the current run.

Validation: `lune run tests/tutorial.spec.luau` passes default-false, permanent session reset, JSON serde rejoin, pure completion, and duplicate completion commits with the online-time checkpoint. It also compile-checks the client and four integration scripts. The login-history fixture now fills `sessionRolls` to match the existing Roll/Restart quest change. Final full-suite result: **25 passed, 1 failed**. The expected `player_database.spec.luau` exception currently reports `src/shared/PlayerDatabase.luau:7: attempt to index nil with 'Parent'` under Lune; the separate Luau binary is unavailable here.

Studio integration is **blocked and unverified**. Both Open from File using the exact canonical path and the canonical recent-file entry returned to the cloud document. Its File menu offers Save to Roblox and Download a Copy, with no verified canonical local save. The root Rojo server was stopped before tutorial source edits to avoid syncing into that document. No place file was created, copied, rebuilt, or saved. Actual playthrough, controller navigation, mid-tutorial viewport resizing, and a rare celebration overlapping the guide still need verification after opening the canonical local file and connecting `rojo serve default.project.json`.

The tutorial now names the exact next control and draws an arrow to its live edge. Gameplay steps name the candidate position and player; available rare hits point directly to HOFResult or NonCollegeResult. Reading steps spotlight and point to Next, so players are not asked to spend rerolls or restart a squad just to learn. The three-part rare lesson explains HOF and non-college players, the Shop's cash/Robux eligibility purchase, random wheel hits, and clicking the result card to accept it. Purchases and rare hits are not required to complete the tutorial. Returning to the lobby prompts Build Your Squad again; only the actual completion flow can mark the run finished.

A Yes/No warning at DisplayOrder **95** appears only before Reroll or Restart when rare results are present (or a rare player is in the squad). Restart skips this warning once the squad is finished, with five players or a sixth man. It pauses the tutorial through HoopsPanel and stays below celebrations at 100. No, Escape and controller B cancel; No receives initial controller focus. Yes executes once, and changed draft snapshots invalidate old confirmations. Refresh and Roll do not show a confirmation. The existing server transaction preserves those results, their gold status and wheel serial on Refresh; Roll/Reroll/Restart replace the wheel results with a fresh random outcome. Already accepted collection ownership remains intact.

Additional failure tests in `tests/tutorial.spec.luau` cover offline exceptions, malformed replies, BUSY and stale-save responses, retry recovery, rejected candidate/rare picks, and Exit versus actual Finish. Arrow geometry tests cover moving/resizing targets and axis-aligned directions. `tests/rare_action_warning.spec.luau` covers both rare types, No/Yes, duplicate and stale confirmations, Refresh preservation across serde and subsequent acceptance, fresh-roll replacement, retained ownership, and failed Refresh without spending. The completion-flow test also verifies that a failed sixth-man decline cannot finish the tutorial. These are automated logic/geometry and compile checks; Studio visual verification remains blocked as described above.

Continued verification now executes `Tutorial.client.luau` itself in a simulated GUI/service environment, rather than only compiling it. Tests cover first-time startup, moving the real mocked target instance, HoopsPanel pause/resume, four failed Skip save attempts followed by successful Retry, no auto-guide for returning players, Settings replay without clearing completion, the full ordered lesson sequence, an HOF-result target, rejected rare acceptance, Exit/resume, and final completion acknowledgement. The full suite remains **25 passed, 1 expected player_database failure**. This does not replace an actual Studio visual/controller test.

The latest canonical-file attempt found an additional computer-use blocker: the file picker resolves the exact existing path, but Return and Escape reset its text to `/`, clipboard paste times out, and the resolved file's Open accessibility action does nothing. The active Studio connection still identifies the cloud place. Rojo was stopped again before continuing work. No canonical or alternate place was edited or saved during these attempts; manually opening the existing canonical local file remains necessary before Studio playtesting and saving can be verified.

The tutorial now uses a solid **white block arrow** matching the supplied reference (184px overall length, 30px shaft thickness, 80px triangular-head height at full scale), a thick white target outline, and a dark screen scrim with a live cutout around the required button. The guide has a drop shadow. All geometry follows the same clamped viewport scale and actual button bounds. The reading-step arrow approaches Next from below the guide to avoid crossing its text.

While the guide is active, `TutorialInputGate` makes every off-step GUI button non-interactable and non-selectable, including newly added buttons. The required step button and Skip tutorial remain available. Reading steps allow Next only; the first-run sixth-man prompt guides No to finish with five, matching its single allowed target. Required rare-action Yes/No confirmations and celebration controls at DisplayOrder 100 remain usable. The gate preserves changes made by the normal gameplay controller and restores button state when the tutorial is skipped, completed, destroyed, or paused for another menu. The dark screen regions also intercept pointer input outside the target. This uses Roblox's documented [Interactable behavior](https://create.roblox.com/docs/reference/engine/classes/GuiObject/GuiState), rather than only changing button appearance.

The actual-client harness now verifies off-step handler rejection, controller exclusion, allowed-target changes, rare-confirmation and celebration exceptions, Skip restoration, larger white arrow properties, and exact shade coverage around moved/clipped targets. Full suite: **25 passed, 1 expected player_database failure**. Studio visual verification remains pending the canonical local document connection; Rojo was stopped before these source edits.

The reference-arrow refinement replaces the separate outlined text glyph with a single joined geometric silhouette: a long rectangular white shaft and a broad filled triangular head. The arrow rotates around its exact tip and scales as one unit, preserving live target anchoring. No font outline, glyph padding, asset upload or new place is required.

Arrowhead visibility fix: replaced the half-pixel vertical strips with two-pixel horizontal rows. At the minimum 0.5 UI scale, each row remains at least one pixel in both dimensions, preventing the head from rounding away while the shaft stays visible. The triangle remains 40×80 at full scale, symmetric and joined to the shaft. Regression checks cover row visibility at 0.5, 0.65 and 1 scale and the apex reaching the target tip.

Tutorial shadow seam fix: reading/Next steps use one uninterrupted full-screen scrim behind the guide. Gameplay spotlights calculate all four shadow panels from shared whole-pixel boundaries, preventing fractional scaling from leaving bright gaps or overlapping dark bands. Zero-area panels are hidden. Fractional-coordinate coverage tests check exact single coverage outside the spotlight and no coverage inside it, including clipped viewport edges; completion checks no longer redefine the geometry helper.

Rare-result confirmations apply only to Restart and Reroll for HOF and non-college cards. Completed five- and six-player squads restart without confirmation. Refresh and Roll proceed without a confirmation; Refresh still preserves rare results. Both rare categories use the same gold rule: 5% at 1× luck, scaling through 7.5%, 10%, 12.5%, and 15%, with +5 OVR and gold ownership saved on acceptance. Exhaustive luck tests now cover both categories at every tier. These source updates still require a verified canonical local Studio connection and save; the unverified Rojo server was stopped before editing.

### Quest balances and within-team luck

Build Your Squad now observes the server-published `QuestRerolls` and `QuestRefreshes` balances, updating its buttons and purchase checks when another panel claims a quest. Both ordinary and paid quest rewards already share the durable profile wallet; unused rewards survive squad restarts and live rejoins and are consumed after the free actions. These are saved consumables, not an unlimited per-squad allowance. Studio's default disposable-profile setting remains unchanged.

Luck now also weights eligible players by base OVR within the selected college season and position, after rarity selection and refresh exclusions. At 1× each candidate is equally likely. At higher tiers the weakest candidate has 1,000 tickets, the strongest has `1,000 × luck`, and intermediate ratings interpolate between them. Equal OVRs remain equally likely. Team selection, distinct-player checks, and refresh team preservation remain intact. Gold still scales from 5% to 15%; HOF and non-college wheel hit tickets independently scale with luck and still require Shop eligibility.

Validation: 25 test files passed, with the existing `player_database.spec.luau` failure under Lune (`script.Parent` requires Roblox). Added tests exercise free and paid claims, immediate builder balance synchronization, free-before-quest spending, JSON save/rejoin and restart preservation, subscription cleanup, exact OVR weights at every luck tier, both rare-wheel ticket counts, and college/refresh gold boundaries. Studio integration remains blocked: opening the canonical path and its recent-file entry returned to the cloud document, whose File menu offers Save to Roblox and Download a Copy. No Rojo server was started and no place was modified or saved for this update. The source changes must still be synced and saved after opening the verified canonical local file.

Activity quests now award saved rerolls and refreshes as well as cash: Unlock 5 Players gives 2 of each; Unlock 10 gives 5 of each; Roll 100 Times gives 10 of each; Roll 200 gives 25 of each. These initial reward amounts scale from short unlock milestones to longer roll milestones, with a completion bonus for the harder tier. Claiming all four adds 42 rerolls and 42 refreshes. Hourly amounts remain 5/10/25 each. The shared quest UI displays all three rewards automatically, and 2× rewards double the new amounts. Existing claimed quests are not retroactively paid again; the new rewards apply to subsequent claims. Quest, double-reward, and receipt tests pass, including early/duplicate claim protection, serialized rejoin preservation, and re-earning in another login. Canonical Studio saving remains blocked as described above; this update is saved in source.

Additional permanent-balance verification exercises all seven quest claims through a simulated durable wallet with JSON serialization between commits. It confirms 82 rerolls + 82 refreshes and $310,000 after one complete set, unchanged balances through three rejoins and squad restarts, 164 of each after re-earning all quests on a later login, save-failure retry and duplicate-claim protection, and spending every action without regeneration or negative balances. Quest, double-reward, and paid-receipt suites pass. This verifies transaction behavior, not a real Roblox DataStore reconnect: canonical place integration is still blocked, and Studio's configured disposable profiles do not persist between Play sessions. Live server claims use UpdateAsync before publishing balances or reporting success.

### Creator account privileges

Codeninjaexpert111 (Roblox user ID **1123697419**, resolved through Roblox's username API) receives unlimited in-game cash spending and **50× luck**. The server reapplies these privileges using authenticated `Player.UserId` on profile load and before each transaction, and clears them for all other IDs. Display names, client attributes, and remote arguments cannot grant access. The existing numeric cash balance remains finite and intact; cash Shop purchases bypass affordability and deductions for this account. The wallet displays **∞ CASH**. This does not grant Robux or bypass Robux purchase prompts.

The creator's 50× multiplier applies to gold (capped naturally at 100%), HOF wheel hits (6.25%), non-college wheel hits (6.5%), and within-team OVR selection (strongest-to-weakest ticket ratio 50:1). Rare players still require Shop eligibility, which the creator can obtain with unlimited cash. Regular accounts retain the normal 1×–3× tiers. The luck panel displays **50× ACTIVE** and disables unnecessary upgrades, preserving existing purchased credits.

Validation: 26 test files pass; the existing player database test still requires Roblox's `script.Parent` runtime. Creator-specific tests cover exact user-ID isolation, 100 expensive purchases without cash deductions, JSON rejoin persistence, ordinary account affordability/deductions, saved credit preservation, exact 50× tier/rare/OVR ticket counts, 100% rare-card gold, and changed-script compilation. The unverified root Rojo server was stopped before editing. These changes remain source-only pending the verified canonical local Studio connection and save described above.

### Rare confirmation selection rules

Reroll now warns only for HOF/non-college wheel results whose player IDs are not already selected in the current squad. Accepted rare squad members alone do not trigger a Reroll warning. Refresh never warns because it preserves both the squad and wheel results. Restart warns for either an unselected rare result or a selected rare squad member, including completed five- and six-player squads; collection ownership remains saved. A second unselected rare result still triggers Reroll confirmation even when the other result was selected. Server response cards now include sourceType so non-college squad members are identified explicitly instead of assuming any missing school means a rare card. Rare-warning, tutorial, and squad-completion tests pass. These changes remain in source pending the canonical local Studio sync/save.

### Unlimited creator actions and Creator Gifts

User ID 1123697419 also receives unlimited rerolls and refreshes. Builder buttons display ∞; actions bypass resource deductions and pack purchase prompts while retaining normal selection/finished-squad rules. Saved quest and paid action balances remain intact. Other users retain normal consumption and policy checks.

The creator-only **Settings → Creator Gifts** panel sends cash, rerolls, and refreshes to an exact Roblox username currently in the same server. Each field accepts whole non-negative amounts (up to $1 trillion or 1 million of each action per gift), with at least one positive amount. The server authenticates the caller by UserId, resolves the recipient from connected Players, locks both profiles during the save, and uses the recipient's existing atomic commit path. Gifts add to balances without advancing quest activity. Saved request IDs prevent retries from awarding twice, including after rejoin. Failed/uncertain requests retain their original payload and ID for retry; invalid input remains editable. Recipient wallet/builder displays update via existing server-published attributes. No gifts are sent merely by opening the panel. Offline or other-server gifting is not supported. Studio disposable mode labels successful test gifts as unsaved.

Validation: 27 test files passed; the existing player database test still requires Roblox's script.Parent environment. New coverage includes unauthorized callers, malformed/negative/fractional/non-finite/excessive amounts, additive rewards, callback retries, duplicate delivery after serialized rejoin, separate stacked gifts, 100 consecutive free creator actions, normal account isolation, and integration-script compilation. Visual Studio verification and saving into the canonical local place remain pending due to the previously documented file-opening blocker.

### Rare results for occupied positions

An HOF or non-college result cannot replace a player already selected at its position. The server returns FILLED before granting ownership, gold or consuming the pending pick. The rare result displays POSITION TAKEN and is disabled. Roll stays disabled while a pick is pending, matching the server's CHOOSE_FIRST check; selecting a normal candidate in an open position lets the player continue. Rare results at open positions remain selectable. Reroll and Refresh retain their existing behavior. Tests cover both rare kinds, repeated rejected picks, serialized reload, unchanged ownership and squad, Roll rejection before normal selection and success afterward, and rare acceptance in an open position. The full suite has 28 passing files and the existing Studio-dependent player database failure. Canonical Studio synchronization and saving remain pending.

Codeninjaexpert111's HOF and non-college wheels now both have **100% hit probability**, overriding the previous 50×-derived 6.25%/6.5% hit rates only for authenticated user ID 1123697419. The server passes Player.UserId directly to the rare draw; no client parameter selects the override. Creator wheel labels show 100%, while other accounts keep their luck-based odds and global test flags remain disabled. Shop eligibility and occupied-position restrictions still apply, and an empty eligible pool cannot produce a card. Creator, rare-wheel and occupied-position tests pass, including exhaustive identity-scoped ticket checks. Source is updated; canonical local Studio sync/save remains pending.
