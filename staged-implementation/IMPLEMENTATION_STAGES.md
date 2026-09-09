# Latest milestone: per-login activity quests

Added four session quests: unlock 5 new players → $25,000; unlock 10 → $50,000; complete 100 rerolls → $50,000; complete 200 → $100,000. Their progress and claims reset on each new login; permanent playtime rewards, money, inventory, and bonus actions remain saved. Current unlock progress comes from new Shop purchases. Trial: `CollegeHoops-Session-Quests-Trial.rbxlx`. See [QUESTS.md](QUESTS.md) for behavior and remaining gameplay integration. Tests and builds pass; Studio runtime testing is pending.

# Current quest milestone

The latest user request adds **1 / 2 / 4-hour quests** awarding **$10k + 5/5**, **$25k + 10/10**, and **$50k + 25/25** cash/rerolls/refreshes. This supersedes all earlier quest reward amounts in historical notes. Open `CollegeHoops-Quests-Trial.rbxlx` and see [QUESTS.md](QUESTS.md). Server time tracking, atomic claims, wallet integration, saved bonus actions, and their use in the squad preview are implemented locally. Studio/live verification remains pending.

# Current shop milestone

Open `CollegeHoops-Shop-Trial.rbxlx` in Studio and press **Play**, then **SHOP** in the lower-left lobby. See [SHOP.md](SHOP.md) for prices, behavior, and testing. The shop adds eight existing HOF cards and four non-college cards, using the current roster ratings and five attributes. Its standalone server saves live purchases atomically; Studio trials use disposable cash. Squad selection is still the earlier UI preview.

# Staged Roblox implementation

The latest user request authorizes the Shop feature in addition to the existing squad UI. Shop UI, cash purchases, and ownership saving are now implemented locally. Studio verification is still pending. Historical stage notes below describe earlier milestones.

## Latest interaction revision — supersedes earlier UI flow

User requested five selectable position-specific candidates, automatic acceptance, no Accept button, and Reroll becoming Finish when all five positions are chosen. The candidate pool is now PG, SG, SF, PF, C, replacing the earlier three-player mixed-position pool.

Interaction interpretation used after the user said continue: clicking a candidate immediately fills/replaces its matching squad slot; Reroll automatically replaces the selected player. The existing Roll button remains and fills the next empty position. These two details still need the user's Studio feedback because the clarification question did not receive a specific click-sequence answer.

Refresh replaces all five candidate previews while preserving the current squad. Reroll uses its free counter only for replacement; at 5/5 the same button is Finish and does not spend a Reroll. No separate Accept or Finish Squad button exists. Finish confirms ending the preview and saves nothing. Exit/Build preserves UI state. Restart discards unfinished preview progress with confirmation and assigns both counters to 1.

Randomized position-labeled prospects are UI test fixtures, not researched roster data, real ratings, or production roll odds. All previously planned server features remain deferred.

Test v3: Build → choose PG → Reroll (PG changes automatically) → choose SG, SF, PF, C → verify button reads Finish → Finish → confirm unsaved preview message. Also test Refresh preserves the squad, Exit/Build preserves state, and Restart clears all slots. Clicking a different position must fill that position, not the next slot by count. Trial file: CollegeHoops-UI-Trial-v3.rbxlx. Source formatting/parsing and built-source consistency checks passed; Studio runtime testing is pending.

## Checklist and script locations

SSS = ServerScriptService. RS = ReplicatedStorage. SPS = StarterPlayer > StarterPlayerScripts. Server ModuleScripts are loaded by the bootstrap Script. ScreenGuis are Instances created under PlayerGui by the client code.

| State | System / feature | Type | Planned Studio path |
|---|---|---|---|
| [x] | 1. Main screen, Roll/Reroll/Refresh/Restart/Accept/Finish Squad buttons, Exit to normal POV, bottom BUILD button, preview counters, confirmation dialogs, single-screen scaling and cross-device input | LocalScript | SPS/HoopsUI |
| [ ] | Server startup | Script | SSS/HoopsServer |
| [ ] | Shared types, rarity labels, positions, UI settings | ModuleScript | RS/HoopsShared/Types and PresentationConfig |
| [ ] | Recent five-season men's roster catalog, one-appearance eligibility, school identities | ModuleScript | SSS/HoopsData/CollegeCatalog |
| [ ] | Seven attributes, season appraisal, potential, positional weights | ModuleScript | SSS/HoopsData/Ratings |
| [ ] | Era calibration, comparative review, source confidence and model versions | ModuleScript + external research | SSS/HoopsData/RatingValidation; research outside Roblox |
| [ ] | Base, Breakout, Tournament, Award, All-Star and HOF variants | ModuleScript | SSS/HoopsData/Variants |
| [ ] | Eight HOF cards | ModuleScript | SSS/HoopsData/HofCatalog |
| [ ] | Four purchase-only non-college cards | ModuleScript | SSS/HoopsData/NonCollegeCatalog |
| [ ] | Start/Restart, school-season selection, run state, reset freebies to exactly 1 each | ModuleScript | SSS/HoopsServices/RunService |
| [ ] | Candidates, Refresh, individual Roll/Reroll | ModuleScript | SSS/HoopsServices/RollService |
| [ ] | Weighted odds, HOF 1/800, All-Star 1/100, no pity | ModuleScript | SSS/HoopsServices/OddsService |
| [ ] | Accept, five positions, swapping, 1–3 eligible positions, no duplicate person | ModuleScript + LocalScript | SSS/HoopsServices/LineupService; SPS/LineupController |
| [ ] | Average Team OVR and positional chemistry +0/+1/+2 | ModuleScript | SSS/HoopsServices/TeamRatingService |
| [ ] | Finish Team atomic commit and Restart discard | ModuleScript | SSS/HoopsServices/FinishTeamService |
| [ ] | Permanent inventory, saved best teams, owned editions, duplicate conversion on commit | ModuleScript | SSS/HoopsServices/InventoryService |
| [ ] | Card art, seven attributes, rarity frames, reveal effects, optional foil | ModuleScript + LocalScript | RS/HoopsUI/CardView; SPS/RevealController |
| [ ] | Collection, locked entries, era/season/variant filters, non-college tab | ModuleScript + LocalScript | SSS/HoopsServices/CollectionService; SPS/CollectionController |
| [ ] | Highest Team OVR and Players Collected leaderboards | ModuleScript + LocalScript | SSS/HoopsServices/LeaderboardService; SPS/LeaderboardController |
| [ ] | Money, action costs, spending and reward accounting | ModuleScript | SSS/HoopsServices/EconomyService |
| [ ] | 1/2/3-hour quests: 5,000 / 10,000 / 20,000; time tracking and claims | ModuleScript + LocalScript | SSS/HoopsServices/PlaytimeQuestService; SPS/QuestController |
| [ ] | Shop, direct purchases, permanent entitlements | ModuleScript + LocalScript | SSS/HoopsServices/PurchaseService; SPS/ShopController |
| [ ] | Paid random-item eligibility and odds display when applicable | ModuleScript + LocalScript | SSS/HoopsServices/PurchasePolicyService; SPS/OddsController |
| [ ] | Saving, reconnect recovery, migrations, receipt recovery, concurrent sessions | ModuleScript | SSS/HoopsServices/ProfileService |
| [ ] | Remotes, validation, request IDs, cooldowns, transaction audit | ModuleScript + LocalScript | SSS/HoopsServices/NetworkService; SPS/NetworkController; RemoteEvents in RS/HoopsRemotes |
| [ ] | Tutorial and settings | LocalScript + ModuleScript | SPS/OnboardingController and SettingsController; SSS/HoopsServices/SettingsService |
| [ ] | Analytics for onboarding, rolls, accepts, finishes, restarts, returns and purchases | ModuleScript | SSS/HoopsServices/AnalyticsService |
| [ ] | Featured pools, seasonal events and release batches | ModuleScript + LocalScript | SSS/HoopsData/ReleaseCatalog; SPS/EventController |
| [ ] | Historical teams and decade expansions | ModuleScript | SSS/HoopsData/HistoricalCatalog |
| [ ] | Original names/art/logos and research rights | No script; content workflow | Approved assets in RS/HoopsAssets; research records outside Roblox |
| [ ] | Soft launch, mobile/performance checks and economy validation | No standalone script; testing workflow | Studio Test / Device Emulator and Creator Analytics |

Earlier dynasty ideas are deferred pending confirmation that they belong in the current card game:

| State | Deferred feature | Type | Planned location if retained |
|---|---|---|---|
| [ ] | Recruiting, scouting and regions | ModuleScript + LocalScript | SSS/HoopsServices/RecruitingService; SPS/RecruitingController |
| [ ] | Training, XP, development, confidence, stamina and traits | ModuleScript + LocalScript | SSS/HoopsServices/DevelopmentService; SPS/TrainingController |
| [ ] | Class advancement, graduation, alumni and transfers | ModuleScript | SSS/HoopsServices/SeasonProgressionService |
| [ ] | Seasons, conference standings and rivalry games | ModuleScript + LocalScript | SSS/HoopsServices/SeasonService; SPS/SeasonController |
| [ ] | Match simulation, tournaments, upsets and match rewards | ModuleScript + LocalScript | SSS/HoopsServices/MatchService and TournamentService; SPS/MatchController |
| [ ] | Coaches, tempo, defense, timeouts, substitutions, foul trouble and final shot | ModuleScript + LocalScript | SSS/HoopsServices/CoachingService; SPS/CoachingController |
| [ ] | Archetype, school or region chemistry beyond position bonuses | ModuleScript | SSS/HoopsServices/AdvancedChemistryService |
| [ ] | Campus facilities, arenas, upgrades, trophies and banners | ModuleScript + LocalScript | SSS/HoopsServices/CampusService; SPS/CampusController |
| [ ] | All-time alumni mode | ModuleScript + LocalScript | SSS/HoopsServices/AlumniService; SPS/AlumniController |
| [ ] | Friend invites, private servers and equal-resource tournaments | ModuleScript + LocalScript | SSS/HoopsServices/SocialService; SPS/SocialController |
| [ ] | Optional uniforms, frames, animations, lineup-save slots, cosmetics and season pass | ModuleScript + LocalScript | SSS/HoopsServices/CosmeticService; SPS/CosmeticController |

Combat was not requested. Pity is explicitly excluded. Writing this plan does not complete the real roster research or appraisal work.

## Ambiguities before dependent implementation

Latest explicit clarification: Exit closes the page to reveal normal POV; bottom BUILD reopens it. Neither action resets preview state. Finish Squad is the requested UI label for the existing Finish Team concept. The screenshot’s source game, Auto Reveal behavior, and meaning of 2010 are unknown; those screenshot details are not new feature instructions.


1. Latest instructions specify three candidates and one revealed card, superseding the earlier five-position board. The UI follows the latest layout.
2. The user said Roll draws from the roster. The previous document narrowed it to the visible three, while Reroll draws from the whole roster. The actual sampling boundary needs confirmation.
3. The document fixes one school-season for a whole run, while the original fantasy includes mixed-school lineups. Does Accept advance to another school-season? Restart clearing the run is confirmed.
4. Normal Roll cost and how a free player reaches five accepts are unspecified. One free Reroll and Refresh per Restart is confirmed.
5. Candidate replenishment after Accept and the effect of Refresh on the revealed card are unspecified.
6. The previous assistant added a global HOF override. Confirm global specials versus historical school-season-only drops. A roster can lack All-Star candidates, conflicting with an unconditional 1/100 chance.
7. Excluding already accepted HOF players changes the individual-card probability from 1/6400. Define eligible-pool handling while preserving tier odds.
8. Illustrative Flagg ratings are not model-derived; a 96 Base card falls in a band named All-Star Potential. Clarify whether rarity follows OVR or variant. Ordinary draws must not create extra special-tier hits.
9. Strength and the broader Physical composite differ. Define Physical before enforcing comparative rankings.
10. Collection unlock on obtain versus Finish Team needs confirmation. No duplicate person in a lineup is confirmed; repeat collection conversion amount/resource is unspecified.
11. Quest amounts are confirmed. Daily reset, incremental payouts, active-time-only rules and timezone were earlier assistant proposals.
12. Purchase currency, prices, ratings, approved positions and leaderboard eligibility for the four store players remain open.
13. Purchased ownership persists through Restart. Whether completed collection cards may be reused in new teams is unspecified.
14. The document adds chemistry to Team OVR, permitting 112 with five 110 cards. Confirm whether chemistry is added to leaderboard OVR or displayed separately.
15. Specific launch schools, complete rated rosters and final fictional identities remain to be produced.

## Feature 1 installation

Full code: `src/StarterPlayer/StarterPlayerScripts/HoopsUI.client.luau`.

1. Open your place in Studio; show Explorer and Output.
2. Expand `StarterPlayer > StarterPlayerScripts`.
3. Insert a **LocalScript**, name it `HoopsUI`.
4. Replace its entire contents with the complete source file above.
5. Press **Play (F5)**, not Run, so a local player is created.
6. During Play the script builds `Players > YourPlayer > PlayerGui > CollegeHoopsUI`. No manual ScreenGui or other scripts are needed.

This folder has its own `default.project.json` for testing the UI separately. The root project also maps this same source file to StarterPlayerScripts. Use either Rojo sync or manual pasting, not duplicate copies.

### Current behavior

Feature 1 remains UI-only. Seven outlined buttons use the screenshot's dark, rectangular style, with separate Reroll and Refresh counts. Exit hides the page and reveals the normal game camera; bottom BUILD reopens the page without resetting its state. No camera override is installed.

In Studio, Roll creates a labeled test placeholder; Accept increments a disposable five-slot preview. Reroll requires a placeholder and spends its preview counter. Refresh spends its separate preview counter. Neither generates actual players. Finish Squad requires five preview slots and confirms ending the UI test; it does not save anything. Restart resets the preview and assigns both counters to exactly 1. It confirms only when unfinished accepted preview slots exist. Published places support Exit/BUILD but report that gameplay actions await the server stage.

### Studio verification gate

- UI appears once without Output errors; all seven action buttons are visible on the left without scrolling.
- Exit reveals normal POV and a bottom BUILD button. BUILD reopens the page with counters and preview slots preserved.
- Reroll before Roll spends nothing. Roll then Reroll uses exactly one free action; another Reroll does not go negative.
- Refresh uses its own counter and does not change the Reroll counter.
- Restart with zero accepted slots immediately resets counters to (1,1).
- Roll → Accept → Restart opens confirmation. Cancel preserves state. Confirm clears slots and resets counters to (1,1).
- Repeat Roll → Accept five times. Finish Squad opens a preview confirmation; Cancel preserves slots; confirmation reports explicitly that nothing was saved.
- After finishing, gameplay preview actions require Restart. Exit/BUILD still works.
- Dialog blocks background actions; Escape or controller B cancels; controller selection stays on dialog buttons.
- Respawning leaves exactly one UI and preserves its state. Stopping Play clears preview state.
- Resize the Studio viewport and test phone landscape/portrait: the entire 1120×680 design canvas scales to fit, with no scrolling. Portrait makes this wide layout smaller; check readability. Check dialog text and controller focus.

Stop after this feature and await user confirmation before implementing server gameplay.

### Local verification

Rojo built the staged place successfully. StyLua 2.0.2 parsed and formatted the Luau source. Lune 0.8.9 parsed the complete script and stopped at the first game:GetService call because standalone Lune has no Roblox game object. This is a syntax check, not a runtime pass. Actual Studio rendering and mouse/touch/controller behavior require the user's test. The assistant has not run this in Studio.

Research and behavior distinctions: [Button research](BUTTON_RESEARCH.md).

### Single-screen revision

Latest UI uses a transparent page, left action column, and right five-slot squad layout. Candidates and revealed card sit beneath the squad. The page starts closed; Build Your Squad opens it from normal POV. Accepted test placeholders now appear in the five cards, still without actual player generation or position validation. Trial file: CollegeHoops-UI-Trial-v2.rbxlx. Rojo build and source consistency checks passed; Studio visual verification remains pending.
