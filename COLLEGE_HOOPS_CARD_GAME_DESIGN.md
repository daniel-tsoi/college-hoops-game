# Build a College Hoops Dynasty — Game Design and Data Specification

Status: concept specification for later implementation  
Platform: Roblox  
Research snapshot: September 4, 2026  
Working title: **Build a College Hoops Dynasty**

## 1. Product vision

Build a College Hoops Dynasty is a card-rolling and team-building game in which a player:

1. Starts a run and receives a random men's Division I school-season.
2. Rolls player cards from that exact school-season roster.
3. Refreshes the currently available player choices without changing the school-season.
4. Hunts for rare versions of those players, including high-potential and special-season cards.
5. Fills a five-player lineup and improves its Overall and chemistry.
6. Completes the run to bank its final cards, or presses Restart to scratch the current run and receive a new school-season.
7. Saves the best lineup, completes collections, and eventually enters tournament modes.

The immediate fantasy is: **“What player did I pull?”**

The long-term fantasy is: **“Can I assemble the greatest college lineup across eras?”**

The distinguishing promise is that cards are not assigned arbitrary ratings by hand. Their Season Appraisal and attributes come from a documented, repeatable model using the player's performance in that college season. Potential variants use information about the prospect's ceiling, kept separate from actual college production.

## 2. Important scope and legal constraint

The launch scope is the latest **five completed men's Division I seasons**, not every season since 2000. This keeps the initial roster research, balance review, and content production achievable. Older tournament teams, major historical seasons, decade collections, and eventually broader historical coverage can be released in later batches.

There is no official current 2K database of college ratings covering this population. NBA 2K ratings describe professional-game rosters, and College Hoops 2K ratings ended with the older college series. Therefore this game must create its **own appraisal system inspired by the readability of sports-game ratings**, not claim that its values are official or “the real 2K ratings.” Do not use `2K` in the game title, marketing, rating label, or card art.

Using real current or historical athletes, photographs, likenesses, university marks, uniforms, NCAA marks, conference marks, or tournament branding can require separate permissions. A disclaimer does not grant those rights. Slight spelling changes or recognizable variations of real athlete and team names are not a reliable legal workaround when the surrounding appearance, biography, school, season, or statistics still identifies the original person or organization.

Selected prototype/release direction:

- Use fully original fictional player identities rather than near-copies of real names.
- Use original fictional school and team names that are not confusingly similar to real programs.
- Use original logos, colors, uniforms, conferences, event marks, and card artwork.
- Do not imitate the NCAA or March Madness logos. Use original names such as `National College Tournament` or `Championship Bracket` unless rights are secured.
- Use researched statistics to inform balanced fictional archetypes and appraisal ranges, with enough transformation and grouping that the game is not presenting a disguised one-to-one likeness.

Before public release, keep these routes available:

- **Selected/safest:** fictional schools, fully original athletes, original uniforms, and statistically informed archetypes.
- **Licensed athlete route:** obtain appropriate athlete NIL/publicity permissions and separate school/brand permissions.
- **Prototype-only route:** use placeholder names and original silhouettes while validating gameplay, then resolve licensing before release.

Do not publish real or recognizably altered player names, headshots, school names/logos, copied uniforms, or recognizable card photographs until a qualified attorney or licensing partner confirms the rights.

## 3. Terminology

### School-season

A specific team in a specific basketball season, such as `Duke 2024-25`. A season should always be stored as its starting year (`2024`) and displayed as `2024-25`.

### Season Appraisal

A rating of what the player accomplished **during that specific college season**. It uses only information available from that season and is normalized against players from the same era and positional group.

### Potential

A separate evaluation of the player's projected ceiling. It may use recruiting information, age/class, role, contemporary scouting information, and draft outlook when those sources are licensed or permitted.

### Variant

A version of a player-season card. One athlete can have a Base card and one or more eligible special variants.

### Rarity

The presentation and collection tier of the final card. Rarity is derived primarily from the card's final Overall, with special eligibility rules for the top potential tiers.

## 4. Core interaction: Restart, Refresh, and Roll

Confirmed interaction model:

- **Restart** scratches the active team-building run and selects a new random school-season. Example: `Duke 2024-25` may become `Houston 2022-23`.
- **Refresh** preserves the current school-season and replaces a visible three-player candidate pool using eligible players from that roster. The three candidates may contain any mix of positions.
- **Roll** normally selects one of the three visible candidates and reveals his full card and variant. A fixed HOF or All-Star special-tier hit can override the ordinary candidate result as described in Section 11.
- **Reroll** replaces only the currently revealed individual and repeats the same rarity process; it does not refresh all three candidates.
- **Accept** places the currently revealed card into an open or chosen lineup position.
- **Finish Team** permanently commits the completed five and its collection discoveries.
- **Restart before completion** destroys the entire temporary five and all other provisional run state.

This produces a clear loop:

```text
Start or Restart → receive a new school-season
        ↓
Refresh the visible three-player candidate pool (optional)
        ↓
Roll one random player, then inspect the revealed card
        ↓
Accept that player or Reroll only that individual
        ↓
Complete and bank the five, or Restart and scratch the run
```

Example:

1. Start or Restart selects `Duke 2024-25`.
2. The screen displays a three-player candidate pool drawn from that roster; it may contain any mix of positions.
3. Refresh replaces all three visible candidates but does not change Duke or the season.
4. Roll runs the special-tier check; if neither special tier hits, it randomly chooses one of the three visible candidates and reveals his full card and variant.
5. Reroll replaces only that revealed individual; it does not replace all three visible candidates.
6. Accept places the revealed player into the temporary lineup.
7. Cooper Flagg is not guaranteed merely because that school-season appeared.
8. If Cooper Flagg is selected, the Base card remains much more likely than an eligible special or All-Star Potential version. He is not one of the eight HOF Potential cards.
9. The school-season remains `Duke 2024-25` until the player completes the team or presses Restart.

The UI must use two visually distinct run resources:

- `Rerolls`: spent to replace only the currently revealed player.
- `Refreshes`: spent to replace the full three-player candidate pool while preserving the current school-season.

### Free actions on every Restart

Every committed Restart initializes the new run with:

- `1` free Reroll
- `1` free Refresh

Restart performs an unconditional assignment:

```lua
newRun.freeRerollsRemaining = 1
newRun.freeRefreshesRemaining = 1
```

It does not inspect, preserve, refund, or add to the previous run's values.

| Before Restart | After Restart |
|---|---|
| 1 free Reroll, 1 free Refresh | 1 free Reroll, 1 free Refresh |
| 0 free Rerolls, 0 free Refreshes | 1 free Reroll, 1 free Refresh |
| 1 free Reroll, 0 free Refreshes | 1 free Reroll, 1 free Refresh |
| 0 free Rerolls, 1 free Refresh | 1 free Reroll, 1 free Refresh |

These free actions are **run-bound**:

- Restart sets each free-action balance to exactly `1`; it does not add one to an account balance.
- An unused free action is forfeited when Restart is pressed.
- Free actions cannot be traded, banked, converted, or carried into another run.
- The UI spends the free action before spending permanent or purchased currency.
- There is no pity counter in this design.

This prevents an infinite-currency exploit in which a player repeatedly restarts to accumulate free resources.

### What Restart scratches

Restart clears only the **active, uncompleted run**:

- Current school-season
- Current player offer pool
- Current three-player candidate pool and revealed/unaccepted card
- All temporary players placed in the active five
- Run-specific chemistry, OVR, progress, and free actions

Cards from an incomplete run are provisional and are not added to the permanent collection. Completing all five positions and confirming `FINISH TEAM` commits the final five cards and collection discoveries in one server transaction.

Restart does **not** delete:

- Previously completed teams
- Previously banked collection cards
- Saved best lineup
- Permanent currencies or purchases
- Account settings and achievements

Because Restart discards progress, it requires a confirmation modal whenever the active run contains at least one accepted player. The modal must say exactly what will be lost. There should be no confirmation when the run is empty.

## 5. Card anatomy

Every visible card should contain:

- Player display name
- School display name or licensed/original mark
- Season (`2024-25`)
- Primary position and optional secondary position
- Full eligible-position list of one to three positions
- Year/class (`Fr.`, `So.`, `Jr.`, `Sr.`)
- Height and weight, if sourced and permitted
- Card variant
- Rarity color/frame
- Overall (OVR)
- Finishing
- Playmaking
- Shooting
- Defense
- Physical
- Handles
- Rebounding
- Source/version identifier for auditability

Optional later additions:

- Archetype
- Handedness
- Badges/traits
- Games played and minutes
- Collection number
- Foil/shiny treatment
- Award icon

### 5.1 Multi-position lineup rules

Every player has one primary position and may have up to two additional eligible positions. Eligibility must come from the player's actual role, size, responsibilities, and official/credible roster context rather than being added solely to make a card stronger.

Examples:

- Traditional point guard: `PG`
- Combo guard: `PG/SG`
- Wing: `SG/SF`
- Versatile forward such as the proposed Cooper Flagg card: `SF/PF`
- Exceptional three-position player: for example `SG/SF/PF` or `SF/PF/C`, only when supported by how he played

Players can drag or select cards to switch lineup slots at any time before `FINISH TEAM`. A card is considered in position when its current slot appears anywhere in its eligible-position list. Moving a player out of position is permitted but loses that player's position-match contribution.

The same underlying player cannot occupy two slots in one active team, even when the cards have different variants, seasons, or eligible positions. The server validates uniqueness by stable `playerId`, not display name or `cardId`.

### 5.2 Chemistry

Chemistry rewards cards placed in one of their eligible positions:

| Players correctly positioned | Chemistry bonus |
|---:|---:|
| 0–2 | +0 |
| 3–4 | +1 |
| 5 | +2 |

“Correctly positioned” means the occupied slot is included in that card's eligible-position list. A `SF/PF` card earns the position match in either SF or PF.

Chemistry is calculated only after all five lineup slots are occupied. The UI should show which players count, the current matched-player count, and the exact bonus.

### 5.3 Team Overall

Base Team Overall is the arithmetic mean of the five card Overall ratings:

```text
baseTeamOverall = (PG + SG + SF + PF + C) / 5
finalTeamOverall = baseTeamOverall + chemistryBonus
```

Store the unrounded mean at high precision. Display one decimal place in the lineup UI and use the unrounded value for leaderboard ordering. Chemistry makes the final displayed result at most two points higher.

To keep elite Team Overall difficult to obtain:

- Do not round each player before averaging; use stored card Overall values.
- Do not use the sum of all attributes as Team Overall.
- Keep 100+ player cards limited to properly eligible special variants.
- Require five strong cards rather than allowing one exceptional card to carry the average.
- Do not add other hidden OVR bonuses at launch.
- Balance ratings by season, position, era, and role before assigning rarity.

Leaderboard ties are broken by, in order: higher unrounded Final Team Overall, more correctly positioned players, higher lowest-card OVR, then earlier valid submission time.

## 6. Rating scale

Use a game-owned scale from **40 to 110**. Ratings over 99 are reserved for exceptional special or potential variants so that they feel categorically different without making ordinary cards unreadable.

| Final OVR | Visible rarity | Purpose |
|---:|---|---|
| 40–64 | Common | Deep reserves, low-minute players, developmental cards |
| 65–74 | Uncommon | Rotation players and situational contributors |
| 75–84 | Rare | Reliable starters and strong specialists |
| 85–94 | Epic | High-level starters, stars, and major award candidates |
| 95–100 | All-Star Potential | Elite prospects or exceptional season variants |
| 101–110 | HOF Potential | Extremely scarce ceiling cards for historically exceptional prospects |

These labels are game-language and do **not** predict that a real person will actually become an All-Star or Hall of Fame player. Consider renaming them before release to `Elite Potential` and `Generational Potential` if legal or reputational review finds the claims too strong.

### Two values that must never be confused

- `seasonAppraisalOverall`: the player's demonstrated value in that season.
- `potentialCeilingOverall`: a modelled, uncertain ceiling used only on eligible potential variants.

A player can therefore have:

- Base Season card: 88 OVR Epic
- Breakout card: 94 OVR Epic
- All-Star Potential card: 99 OVR All-Star Potential
- HOF Potential card: 106 OVR HOF Potential

This is intentional. Potential is a collectible “what could this player become?” variant, not a rewrite of historical college performance.

## 7. Attribute definitions

All seven attributes are rated on the same 40–110 display scale. Base attributes should normally cap at 99; special variants may exceed 99.

### Finishing

Measures scoring at or near the basket.

Preferred inputs:

- Two-point percentage and volume
- Free-throw attempt rate as a contact-pressure proxy
- Assisted versus unassisted rim attempts, if legally available
- Position and size adjustment
- Sample-size reliability

Historical fallback: derive two-point makes and attempts from total field goals minus three-point field goals. This does not distinguish rim attempts from midrange attempts, so the data-confidence flag must be lower.

### Playmaking

Measures creation for teammates and decision quality.

Preferred inputs:

- Assist percentage
- Assists per 40 minutes
- Assist-to-turnover ratio
- Usage-adjusted creation
- Team role/possession share

### Shooting

Measures perimeter and free-throw shooting with volume considered.

Preferred inputs:

- Three-point percentage
- Three-point attempts per 40 minutes
- Free-throw percentage
- Effective field-goal percentage
- Shot-location data when permitted
- Bayesian/sample-size regression so one make does not create a 99 rating

### Defense

Measures defensive events and estimated team impact.

Preferred inputs:

- Steal percentage
- Block percentage
- Defensive rebound percentage
- Foul rate
- Team defensive performance with role/context adjustments
- Play-by-play or possession impact if available

Box-score defense is incomplete. This attribute should display a confidence level and must not pretend to measure unrecorded positioning perfectly.

### Physical

Measures functional size, athletic workload, and durability—not simply body weight.

Preferred inputs:

- Height and weight relative to position
- Games/minutes availability
- Foul endurance
- Transition/rim pressure proxies
- Verified combine measurements, if permitted

Do not infer sensitive medical information or fabricate combine results.

### Handles

Measures ball security and self-creation.

Preferred inputs:

- Turnover percentage
- Assist-to-turnover ratio
- Usage rate
- Unassisted field goals or possession data, if available
- Position adjustment

Historical box scores cannot fully measure dribbling skill. Use a lower confidence score when tracking data is unavailable.

### Rebounding

Measures offensive and defensive rebounding relative to opportunity and position.

Preferred inputs:

- Offensive rebound percentage
- Defensive rebound percentage
- Rebounds per 40 minutes
- Team rebound environment
- Positional percentile

## 8. Appraisal calculation

### 8.1 Normalize by season and position

Raw per-game statistics are unfair across eras, pace levels, roles, and positions. Calculate rate statistics, then compare a player with his season and positional group.

For each metric:

```text
rate = stat / possessions_or_minutes
z = (rate - comparison_group_mean) / comparison_group_standard_deviation
percentile = normalCDF(z)
attribute = 40 + (percentile × 59)
```

Base card attributes are clamped to `40..99`. Apply empirical-Bayes shrinkage toward the group average when attempts or minutes are small.

Recommended comparison groups:

- Lead guards
- Combo guards/wings
- Forwards
- Centers/bigs

If a precise role is not available, use the listed position and height as a fallback.

### 8.2 Suggested attribute formulas

The following are starting weights, not final truth. Validate them against expert review and known season archetypes.

```text
Finishing = 40% 2P efficiency
          + 25% 2P volume per 40
          + 20% free-throw attempt rate
          + 15% size/role adjustment

Playmaking = 45% assist percentage
           + 25% assists per 40
           + 20% assist-to-turnover quality
           + 10% usage-adjusted creation

Shooting = 35% adjusted 3P percentage
         + 30% 3P volume per 40
         + 20% FT percentage
         + 15% effective field-goal percentage

Defense = 25% steal percentage
        + 25% block percentage
        + 20% defensive rebound percentage
        + 15% foul discipline
        + 15% team/impact context

Physical = 35% positional size index
         + 25% minutes/workload
         + 20% rim-pressure proxy
         + 20% availability/foul endurance

Handles = 35% inverse turnover percentage
        + 30% assist-to-turnover quality
        + 20% usage-adjusted responsibility
        + 15% role/position adjustment

Rebounding = 40% offensive rebound percentage
           + 40% defensive rebound percentage
           + 20% rebounds per 40 versus position
```

### 8.3 Position-weighted Overall

Overall should reflect role instead of rewarding every position for the same skills.

| Attribute | PG | SG | SF | PF | C |
|---|---:|---:|---:|---:|---:|
| Finishing | 12% | 15% | 18% | 22% | 25% |
| Playmaking | 25% | 18% | 14% | 9% | 6% |
| Shooting | 18% | 24% | 20% | 14% | 8% |
| Defense | 12% | 13% | 16% | 19% | 22% |
| Physical | 8% | 8% | 12% | 15% | 17% |
| Handles | 20% | 17% | 10% | 6% | 3% |
| Rebounding | 5% | 5% | 10% | 15% | 19% |
| **Total** | **100%** | **100%** | **100%** | **100%** | **100%** |

Then blend statistical Overall with contextual appraisal:

```text
seasonAppraisalOverall =
    0.82 × positionWeightedAttributes
  + 0.10 × roleAndMinutesValue
  + 0.08 × teamAndAwardContext
```

Awards should only provide a small contextual adjustment. They must not override the underlying season data.

### 8.4 Era calibration

Rating percentiles should be generated within each season first, then calibrated across eras using common anchor groups:

- Consensus national player-of-the-year tier
- Consensus All-America tier
- All-conference starter tier
- Regular starter tier
- Rotation tier
- Low-minute roster tier

This avoids giving every modern player inflated shooting values merely because the three-point environment changed.

### 8.5 Comparative balance and sanity review

Every generated batch must run automated comparisons so an obviously stronger player does not receive an inexplicably lower attribute than a weaker comparable player. Compare within season, era, position, height band, role, and minutes threshold.

Examples of flags for human review:

- A larger, more productive and more durable comparable forward has a meaningfully lower Physical rating without a documented reason.
- A high-volume efficient shooter ranks below a low-volume shooter whose percentage came from a tiny sample.
- A leading rebounder ranks below a similar-position reserve after opportunity adjustment.
- A player has an Overall inconsistent with his seven attributes and positional weights.
- The same player's adjacent-season ratings swing sharply without a corresponding role or production change.

These checks do not require every famous player to have a higher value. An attribute may differ because of role, efficiency, sample size, era, or position, but the database must store an explainable reason. Uncertain historical attributes should be estimated from comparable-player groups and marked with lower `dataConfidence`.

## 9. Potential model

Potential should be produced only when adequate source data exists.

Suggested inputs:

- Contemporary recruiting grade/rank
- Recruiting-service agreement or disagreement
- Age and class year
- Positional size
- College role at the time of the card
- Contemporary draft outlook, if used consistently
- Exceptional youth/international event performance, if licensed and sourced

Suggested starting model:

```text
potentialScore =
    0.50 × recruitingPercentile
  + 0.15 × ageAdjustedProductionPercentile
  + 0.15 × positionalToolsPercentile
  + 0.10 × contemporaryDraftPercentile
  + 0.10 × evaluatorAgreementConfidence
```

Convert the result to a ceiling, then apply eligibility thresholds:

- All-Star Potential eligible: approximately top 2% of adequately sourced prospects.
- HOF Potential is not assigned automatically by a percentile. It is a manually controlled whitelist containing exactly eight approved Legacy cards.

Never use later NBA success to calculate what a player's potential card “was” during an earlier college season unless the card is explicitly labeled `Retrospective`. Otherwise the model leaks future information and makes historical cards inconsistent.

Historical recruiting coverage becomes less complete toward 2000. Missing potential data must result in `potentialStatus = unavailable`, not a guessed low ceiling.

### 9.1 The eight HOF Potential cards

The design contains exactly eight HOF Potential/Legacy anchors. These names and seasons are internal research and balance references; public use of the real identities, marks, likenesses, or closely altered versions still requires the appropriate rights.

| Internal balance reference | Signature college season | Program | Public-release treatment |
|---|---|---|---|
| Earvin “Magic” Johnson | 1978-79 | Michigan State | Licensed identity or fully original Legacy analogue |
| Michael Jordan (“MJ”) | 1983-84 | North Carolina | Licensed identity or fully original Legacy analogue |
| Shaquille O'Neal | 1991-92 | LSU | Licensed identity or fully original Legacy analogue |
| Oscar Robertson | 1959-60 | Cincinnati | Licensed identity or fully original Legacy analogue |
| Pete Maravich | 1969-70 | LSU | Licensed identity or fully original Legacy analogue |
| Jayson Tatum | 2016-17 | Duke | Licensed identity or fully original Legacy analogue |
| Derrick Rose | 2007-08 | Memphis | Licensed identity or fully original Legacy analogue |
| Kyrie Irving | 2010-11 | Duke | Licensed identity or fully original Legacy analogue |

Rules:

- No ninth HOF Potential card can be generated through the normal model without an explicit design-document change.
- These cards occupy the `101–110` band, with final attributes and OVR assigned only after cross-era calibration.
- HOF Potential represents the card game's highest ceiling tier; it does not state that every referenced player is currently inducted into a real-world Hall of Fame.
- Kyrie Irving's college sample was limited, so his HOF card must be ceiling-based rather than a claim that his Base Season production exceeded full-season stars.
- Each card's attributes must reflect its player's actual archetype; the same flat boost cannot be applied to all eight.
- These seasons fall outside the five-season school-season dataset, but the cards can still appear through the explicitly disclosed global HOF override described in Section 11.
- HOF is the sole random-roll exception to the current school-season roster rule. The card retains its correct historical school and season metadata even when the active run is modern.

### 9.2 Direct-purchase non-college players

Four special players did not play college basketball and must be unlocked through a direct store purchase. They never appear through Roll, Reroll, Refresh, HOF odds, quests, or ordinary collection rewards.

| Internal balance reference | Initial eligible positions | Acquisition |
|---|---|---|
| Kobe Bryant | `SG/SF` | Direct purchase only |
| LeBron James | `SF/PF/PG` | Direct purchase only |
| Luka Doncic | `PG/SG/SF` | Direct purchase only |
| Nikola Jokic | `C/PF` | Direct purchase only |

Rules:

- Prices and whether purchase uses Robux or an earned premium currency remain TBD.
- This must be a direct, clearly priced purchase—not a randomized purchase.
- Purchase permanently unlocks the card immediately; `FINISH TEAM` is not required for the entitlement.
- The cards use `sourceType = NON_COLLEGE` and have no `schoolSeasonId`.
- They appear in a separate `Non-College Players` collection category and do not increase completion requirements for recent college seasons.
- Once purchased, they may be placed into a lineup in any eligible position and count normally toward position chemistry and Team Overall.
- They cannot duplicate an already equipped version of the same `playerId`.
- Their ratings and special variants remain TBD and must be calibrated from a separate professional/international reference model rather than college statistics.
- Real names, likenesses, nicknames, photographs, and recognizable analogues still require appropriate rights for public commercial use. Without those rights, use fully original non-college Legend identities.

## 10. Variants

Recommended launch variants:

| Variant | Basis | Typical adjustment | Eligibility |
|---|---|---:|---|
| Base Season | Full-season appraisal | +0 | Every qualified player-season |
| Breakout | Strong late-season or role growth | +2 to +5 | Data-supported |
| Tournament | Tournament performance | +3 to +7 | Qualified tournament sample |
| Award Winner | Official season award | +3 to +7 | Verified award |
| All-Star Potential | Prospect ceiling | Set to 95–100 | Potential threshold |
| HOF Potential | Generational ceiling | Set to 101–110 | Extremely rare + human review |

Variant adjustments should change individual attributes logically. A Tournament card earned through defense should not receive identical boosts to Shooting and Handles.

Do not create a rare potential version for every roster player. Variant eligibility is part of the data record.

## 11. Roll probability model

### Candidate, special-tier, and reveal generation

1. Start/Restart selects the current school-season.
2. The server generates three unique visible candidates from that eligible roster using rarity-aware player weights.
3. Refresh replaces all three candidates with another three-player roster sample. It may contain any mix of positions.
4. Roll makes one mutually exclusive special-tier check using a server-generated integer from `1..800`.
5. Result `1` returns a global HOF card (`1/800`). Results `2..9` return an eligible All-Star Potential card (`8/800 = 1/100`). Results `10..800` continue to the ordinary candidate result.
6. For an ordinary result, Roll randomly selects one of the three current candidates and then selects an eligible ordinary variant.
7. Reroll repeats the same special-tier process while replacing only the revealed result.
8. Exclude `playerId` values already accepted into the active team and avoid duplicate candidates within the same three-player pool.

Every school-season must pass a pre-release validation proving that five unique eligible players can complete PG, SG, SF, PF, and C using primary or secondary position eligibility. Multi-position players may cover missing roles. If the roster cannot produce a legal five-player lineup, that school-season is blocked from release until its position data or eligibility is corrected.

Initial tuning targets for the **final card rarity distribution**, before luck boosts:

| Rarity | Initial target chance |
|---|---:|
| Common | 47.875% |
| Uncommon | 27.0% |
| Rare | 16.0% |
| Epic | 8.0% |
| All-Star Potential | 1.0% (`1/100`) |
| HOF Potential | 0.125% (`1/800`) |
| **Total** | **100%** |

The HOF and All-Star chances are fixed design requirements; lower-tier weights remain balance placeholders. A HOF hit selects one of the eight HOF cards uniformly unless later documented otherwise, making the chance of one specific HOF card `1/6400`. The HOF and All-Star outcomes are mutually exclusive—not independent checks—so one Roll cannot return both. HOF uses the disclosed global override; All-Star selects from an eligible All-Star pool. Do not silently invent an ineligible special card.

### Duplicate policy

- A rolled card remains provisional until `FINISH TEAM` commits the completed five.
- The same underlying `playerId` cannot be selected twice in one active team, even through another variant or season.
- A candidate pool should filter out players already accepted into the active team. If an invalid duplicate reaches the UI because of stale state, Accept must be disabled and explain that the player is already on the team.
- Duplicate cards convert into `Training Points` or `Card XP`.
- The first copy permanently unlocks the collection entry.
- Duplicate value scales with rarity.
- A shiny/foil treatment is cosmetic and independently rare; it should not replace the meaningful variant system.

### No pity system

The game will not launch with a pity counter. Every Roll/Reroll and Refresh uses the published weights independently. Free actions, earned actions, and paid actions do not build hidden guaranteed-rarity progress.

If Rolls or luck boosts can be purchased with Robux, comply with Roblox's randomized virtual-item rules, display applicable odds, use `PolicyService`, and obtain legal review before launch.

## 12. School-season and offer-pool selection

Uniformly selecting every school-season creates two problems: enormous choice dilution and unequal roster sizes. Use curated pools.

Recommended Restart matchmaking modes:

- `Any Era`: all released school-seasons.
- `Modern`: latest five completed seasons.
- `Decade`: 2000s, 2010s, or 2020s.
- `Conference`: only a licensed/original conference pool.
- `Featured`: rotating school-seasons with no hidden odds changes.

After Restart chooses a school-season, the interface displays exactly three candidate players. Refresh replaces all three with another roster-wide mix. Roll chooses one of those candidates; Reroll replaces only the revealed individual. Multi-position players may be placed in any eligible slot, but one player can occupy only one lineup slot. Previously seen but unselected players may reappear because Refresh does not permanently remove them from the roster pool.

Each school-season needs:

- A stable ID
- Display name
- Starting season year
- Roster card IDs
- Team strength tier
- Release status
- Source/audit status
- Licensing status

Do not automatically make famous programs rarer unless the odds are clearly explained. Opaque prestige weighting will feel unfair.

## 13. Cooper Flagg example

This is an **illustrative calibration example**, not a final published card.

Official Duke statistics for 2024-25 list 37 games, 19.2 points, 7.5 rebounds, 156 assists, 52 steals, 50 blocks, .481 field-goal shooting, .385 three-point shooting, and .840 free-throw shooting. Duke also described him as the top player in the 2024 recruiting class by both 247Sports and ESPN and reported a 1.0000 247Sports rating.

Example cards after the complete season-wide normalization model is available:

| Card | OVR | FIN | PLY | SHT | DEF | PHY | HDL | REB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 2024-25 Base Season (illustrative) | 96 | 95 | 92 | 89 | 96 | 94 | 88 | 95 |
| 2024-25 All-Star Potential (illustrative) | 100 | 99 | 96 | 94 | 100 | 98 | 94 | 99 |

The Base rating must ultimately be calculated against the complete 2024-25 comparison population. Cooper Flagg is not on the fixed eight-card HOF Potential whitelist, so his highest proposed version is All-Star Potential unless the whitelist is deliberately revised.

### 13.1 Collection index

The Collection is a permanent discovery catalog, organized by era, school-season, position, rarity, and variant.

Recommended era tabs:

- Recent Seasons (the five completed launch seasons)
- 2020s (`2020-21` onward)
- Historical Eras (appears when older batches release)
- All Eras

Before discovery, an entry appears locked using a silhouette/obscured card treatment. When a completed team is committed through `FINISH TEAM`, each of its five cards unlocks the applicable player and variant entries. Merely seeing a candidate or revealed card does not unlock it.

Each collection view shows:

- Unlocked count and total released count
- Completion percentage
- Locked card placeholders
- Filters for era, school-season, position, rarity, and variant
- Player detail and all discovered versions after first unlock
- A separate Non-College Players store/collection tab for the four direct-purchase cards

The same player appearing in multiple seasons has separate player-season card entries. A parent player page can group them under one stable `playerId`.

### 13.2 Leaderboards

Launch with two global leaderboards:

1. `Highest Team Overall` — ranks the highest valid completed five by unrounded Final Team Overall.
2. `Players Collected` — ranks unique permanently unlocked player-season entries, with a separate variant-completion statistic available in the profile.

Leaderboard submissions are created only by `FINISH TEAM` on the server. Save an immutable snapshot containing the five card IDs, positions, Base Team Overall, chemistry bonus, Final Team Overall, rating-model version, and submission time. Recalculate and reject impossible submissions instead of trusting client values.

Display the top teams' five cards so the leaderboard is aspirational and auditable. Apply the tie-break rules from Section 5.3.

### 13.3 Active-play money quests

Daily active-play quests award the main soft currency:

| Cumulative active play today | Additional reward | Total earned that day |
|---:|---:|---:|
| 1 hour | 5,000 | 5,000 |
| 2 hours | 10,000 | 15,000 |
| 3 hours | 20,000 | 35,000 |

The two- and three-hour rewards are additional milestone claims, not replacements for earlier rewards. Progress is account-wide, persists across server changes, and resets at one clearly displayed daily boundary.

Only active playtime counts. The server pauses accrual after an AFK threshold and resumes it after meaningful input or gameplay. A reward claim must be server-authoritative and idempotent so reconnecting cannot grant it twice. Do not require three uninterrupted hours in one server.

The currency name is still an open presentation decision (`Cash`, `Coins`, or another original name). Its spending sinks and economy balance must be specified before implementation.

## 14. Minimum data schema

Use immutable IDs so transfers, duplicate names, and school renaming do not break saves.

```lua
export type PlayerSeasonCard = {
    cardId: string,                 -- e.g. "p_000123:duke:2024:base:v1"
    playerId: string,               -- stable person/entity ID
    schoolSeasonId: string?,        -- nil only for NON_COLLEGE cards
    sourceType: "COLLEGE" | "LEGACY_HOF" | "NON_COLLEGE",
    displayName: string,
    seasonStartYear: number,
    classYear: "FR" | "SO" | "JR" | "SR" | "GR" | "UNK",
    primaryPosition: "PG" | "SG" | "SF" | "PF" | "C",
    eligiblePositions: {"PG" | "SG" | "SF" | "PF" | "C"}, -- 1 to 3 unique values
    variant: "BASE" | "BREAKOUT" | "TOURNAMENT" | "AWARD"
        | "ALL_STAR_POTENTIAL" | "HOF_POTENTIAL",
    rarity: "COMMON" | "UNCOMMON" | "RARE" | "EPIC"
        | "ALL_STAR_POTENTIAL" | "HOF_POTENTIAL",
    overall: number,
    attributes: {
        finishing: number,
        playmaking: number,
        shooting: number,
        defense: number,
        physical: number,
        handles: number,
        rebounding: number,
    },
    seasonAppraisalOverall: number,
    potentialCeilingOverall: number?,
    rollWeight: number,
    dataConfidence: number,         -- 0.00 to 1.00
    ratingModelVersion: string,
    sourceRecordIds: {string},
    rightsStatus: "PLACEHOLDER" | "CLEARED" | "BLOCKED",
    acquisitionType: "ROLL" | "DIRECT_PURCHASE",
    storeProductId: number?,        -- required for directly purchased cards
}
```

Supporting records:

```lua
export type SchoolSeason = {
    id: string,
    displayName: string,
    seasonStartYear: number,
    conferenceId: string?,
    rosterCardIds: {string},
    releasePoolIds: {string},
    sourceRecordIds: {string},
    rightsStatus: "PLACEHOLDER" | "CLEARED" | "BLOCKED",
}
```

The active run is separate from permanent account data:

```lua
export type ActiveTeamRun = {
    runId: string,
    schoolSeasonId: string,
    candidatePlayerIds: {string},   -- exactly 3 visible candidates
    revealedCardId: string?,
    acceptedCardIdsByPosition: {[string]: string},
    freeRerollsRemaining: number,   -- always initialized to 1
    freeRefreshesRemaining: number, -- always initialized to 1
    baseTeamOverall: number,
    chemistryBonus: number,         -- 0, 1, or 2
    finalTeamOverall: number,
    startedAtUnix: number,
    revision: number,
}
```

## 15. Server roll requirements

All valuable random selection must occur on the server.

```text
Client requests Roll, Refresh, Restart, or Finish Team
  → Server validates player, balance, cooldown, and current school-season
  → Server atomically reserves the applicable resource or run revision
  → Server uses the approved weighted table or clears the active run
  → Server records an audit event and updates provisional/permanent state
  → Server returns reveal payload
  → Client only animates the already-decided result
```

Required safeguards:

- Never trust a card ID sent by the client.
- Make currency deduction and reward grant idempotent.
- Store roll transaction IDs.
- Rate-limit Roll, Refresh, Restart, and Finish Team remotes.
- Make Restart replace free-action balances with `1` rather than incrementing them.
- Never bank provisional cards from a scratched run.
- Commit the completed five exactly once through an idempotent Finish Team transaction.
- Keep tables and odds in server-only modules.
- Version rating data and roll tables.
- Preserve cards already owned when a future rating model changes, or display their model edition clearly.

## 16. Data acquisition pipeline

### Coverage definition

Confirmed coverage:

- NCAA Division I **men's** basketball
- The latest five **completed** seasons at the dataset freeze date
- For the September 2026 planning snapshot: `2021-22`, `2022-23`, `2023-24`, `2024-25`, and `2025-26`
- A player-season is eligible for a Base card only after appearing in at least one official game
- Players listed on a roster with zero official appearances are excluded
- Transfers receive separate cards for each school-season

Women's Division I is outside the planned game scope. Older men's seasons remain a later expansion rather than a launch requirement.

### Source priority

1. NCAA official statistics and archived rankings.
2. Official school roster and cumulative-statistics pages.
3. Official conference records and award releases.
4. Licensed data vendor for bulk historical/advanced data.
5. Recruiting services only under permitted access/licensing terms.

Do not scrape or republish a commercial site's proprietary database without permission. Record the URL/source, retrieval date, fields used, and license status for every imported source.

### ETL stages

```text
Source inventory
  → Rights/terms review
  → Raw immutable import
  → School and player identity resolution
  → Season and position normalization
  → Derived rate statistics
  → Attribute model
  → Appraisal and potential model
  → Human anomaly review
  → Versioned Roblox-ready export
```

### Data-quality flags

Each card must carry:

- `dataConfidence`
- Missing-field list
- Source count
- Rating model version
- Last reviewed date
- Manual override reason, author, and timestamp

Never silently turn missing data into zero. Zero means the player recorded none; missing means the source does not provide it.

## 17. Rollout plan

Attempting every school and every year before proving the game would likely prevent launch. Use releases that validate the loop while the data platform grows.

### College-season launch strategy

The intended public-launch window is the opening of the men's college basketball season, when interest begins rising and the game has months to build toward tournament season. Treat opening week as an amplifier, not the first real test:

1. Complete the launch feature set and five-season data freeze well before the college season begins.
2. Run private tests first, then a limited soft launch four to six weeks before the intended public release.
3. Fix onboarding, mobile UI, saving, purchases, and Restart exploits before buying traffic.
4. Prepare featured fictional school-seasons and updates in advance for opening week, conference play, and the later national-tournament-style event.
5. Use original marketing language and artwork unless protected tournament, school, conference, athlete, and NCAA rights have been secured.

Do not wait until opening week to discover retention or data-loss problems. The public seasonal release should scale an already stable game. A second major content push can coincide with college tournament season without copying protected event branding.

### Milestone 1 — mechanics prototype

- 4 fictional school-seasons
- 40 placeholder players
- Single-player Roll, individual Reroll, three-candidate Refresh, Accept, Finish Team, and Restart
- One non-stackable free Reroll and free Refresh per run
- Six rarities
- Seven attributes
- Multi-position switching, chemistry, team Overall, collection, duplicate conversion, and best-five lineup
- Highest Team Overall and Players Collected leaderboards
- One-, two-, and three-hour active-play money quests
- Server-authoritative transactions

### Milestone 2 — rating calibration set

- 12–20 cleared or fictional school-seasons
- Include stars, starters, specialists, reserves, guards, wings, and bigs
- Validate attributes against basketball reviewers
- Publish the rating methodology inside the game

### Milestone 3 — launch dataset

- A curated, legally cleared set large enough to make Refresh exciting
- Modern and decade pools
- Collection index
- Eight-card global HOF pool with exact `1/800` tier odds
- Four direct-purchase Non-College Player definitions, store entitlements, and separate collection tab
- Disclosed odds with no pity counter
- Analytics for every funnel step
- Launch-readiness testing scheduled ahead of men's college tournament season

### Milestone 4 — featured and historical expansion

- Add seasons in versioned batches
- Build the `Legacy HOF` expansion around the eight fixed HOF Potential references and their correctly associated school-season pools
- Resolve transferred players and school/conference changes
- Add advanced data only when coverage is consistent
- Recalibrate era anchors before each batch

### Milestone 5 — broader historical ambition

- Bulk data agreement or explicitly permitted official-source pipeline
- Automated anomaly reports
- Human review queue for top-tier and low-confidence cards
- Repeatable seasonal update process

## 18. Known loopholes and required decisions

These are product decisions that must be answered before the corresponding system is finalized:

1. **Men only or men's and women's Division I?** Resolved: men's Division I only.
2. **Does Refresh change the team-season, or only refresh roster choices?** Resolved: Refresh changes only the available player choices and preserves school-season; Restart changes school-season.
3. **Are real schools and players mandatory?** Resolved for the prototype/release plan: use fully original player identities, school/team names, uniforms, and logos; do not use recognizable name variations as a workaround.
4. **What counts as a card-eligible roster member?** Resolved: at least one official game appearance; zero-appearance roster members are excluded.
5. **Contemporary versus retrospective ratings?** Recommended: Season Appraisal uses only that season; later knowledge requires a clearly labeled Retrospective variant.
6. **Who is eligible for HOF Potential?** Resolved: exactly the eight manually approved Legacy references in Section 9.1; the normal rating model cannot create additional HOF cards.
7. **Can ratings exceed 99?** This document allows only special/potential cards to reach 100–110.
8. **How are shortened or exceptional seasons handled?** Use rate stats, sample shrinkage, and season-level normalization.
9. **How are transfers handled?** Separate school-season cards under one stable player ID.
10. **How are duplicate names handled?** Stable internal IDs; never use names as database keys.
11. **How are players with missing historical data handled?** Lower confidence or no card; never fabricated attributes.
12. **Are potential variants based on high-school reputation, college upside, or pro upside?** This document recommends a documented blend with the source components visible internally.
13. **Will the game simulate matches or only rank a lineup?** The current card loop can launch without matches, but tournament play is the strongest long-term goal.
14. **Will Roll/Refresh be monetized?** If yes, randomized-item compliance and player-trust design must happen before sale.
15. **Do cards change after balance updates?** Recommended: preserve owned editions and issue newly versioned cards, or announce and apply universal recalibration transparently.
16. **Can Restart farm free actions or cards?** Resolved: freebies are replaced rather than stacked, incomplete-run cards are provisional, and a scratched run banks nothing.
17. **What does Restart erase?** Resolved: it scratches only the active run; permanent account progress is protected.
18. **How many candidates appear?** Resolved: Refresh displays exactly three candidates; Roll reveals one random candidate and Reroll replaces only that revealed individual.
19. **How are positions represented in the candidate pool?** Resolved: the three candidates may contain any roster-valid mix of positions; lineup flexibility comes from multi-position eligibility and switching.
20. **Can one player fill multiple positions?** Resolved: cards may have one to three eligible positions and can be switched before Finish Team.
21. **Can the same player appear twice in one lineup?** Resolved: no; uniqueness is enforced by `playerId`, even across variants or seasons.
22. **Is there a pity counter?** Resolved: no pity system at launch.
23. **Does pay-to-win balance block the current design phase?** Resolved: no; competitive monetization balance is deferred, while platform purchase rules and server security remain mandatory.
24. **How can historical HOF cards appear when the active school-season is recent?** Resolved: HOF is an explicitly disclosed global override with a `1/800` chance; it is the sole random-roll exception to roster matching.
25. **How are Kobe Bryant, LeBron James, Luka Doncic, and Nikola Jokic obtained?** Resolved: direct purchase only, never through random rolls or quests, with prices and final ratings still TBD.

## 19. Acceptance criteria for the first playable version

The first version is ready for private testing when:

- Start and Restart always return a valid school-season.
- Refresh preserves the school-season and returns exactly three unique, server-generated roster candidates with any positional mix.
- Roll reveals exactly one randomly selected candidate, and Reroll replaces only the revealed individual.
- No candidate pool or active team contains the same underlying `playerId` twice.
- Cards with one to three eligible positions can be switched, and every eligible slot correctly counts toward chemistry.
- Team Overall equals the unrounded five-card average plus the documented 0, 1, or 2 chemistry bonus.
- Every new run begins with exactly one free Reroll and one free Refresh, regardless of unused freebies in the scratched run.
- Restart scratches every provisional card and never deletes permanent progress.
- Restart confirmation accurately identifies current-run progress that will be lost.
- Finish Team commits the completed five exactly once.
- A player cannot select a requested reward through an exploited client remote.
- Base and potential ratings are separately stored and explained.
- Every attribute is visible and affects Overall according to position.
- Rarity and final OVR agree with the published rarity table.
- Ineligible players cannot roll special potential variants.
- The HOF whitelist contains exactly eight entries and the server returns the HOF tier on exactly one of 800 equally likely roll outcomes.
- The All-Star tier returns on exactly eight of the other 800 outcomes, producing a mutually exclusive `1/100` chance.
- The four Non-College Player cards cannot appear in any random pool and unlock only after a verified direct purchase.
- Duplicate conversion cannot lose the first owned copy.
- No pity state exists or changes roll results.
- Collection entries unlock only after Finish Team and filter correctly by era.
- Both leaderboards accept only server-recalculated completed-team or collection values.
- Active-play quests grant 5,000 at one hour, another 10,000 at two hours, and another 20,000 at three hours exactly once per daily cycle.
- Save/rejoin preserves currency, current school-season, candidate pool, revealed card, inventory, collection, quest progress, and equipped lineup.
- The UI works on phone, desktop, and console input.
- At least 20 target players can understand Roll/Reroll, Refresh, Restart, and Finish Team without developer explanation.

## 20. Research references

- [NCAA men's basketball statistics and records](https://www.ncaa.org/championships/statistics-and-records/mens-basketball/) — official current, team-by-season, and archived national-ranking entry points, including an archive from 2000 onward.
- [NCAA Division I member schools](https://www.ncaa.org/division-i/member-schools/) — official Division I scale and membership context.
- [NCAA historical membership resource](https://www.ncaa.org/media-center-new-ncaa-historical-resource-details-membership-history-of-schools-conferences/) — official year/division/school/conference membership history.
- [Duke 2024-25 cumulative statistics](https://goduke.com/sports/mens-basketball/stats/2024-25) — official Cooper Flagg season-stat example.
- [Duke Cooper Flagg roster biography](https://goduke.com/sports/mens-basketball/roster/cooper-flagg/20760) — official roster and achievement context.
- [Duke contemporary recruiting summary](https://goduke.com/documents/download/2024/11/7/Army__11-08-24_.pdf) — official Duke material recording his recruiting-service status.
- [Michigan State profile for Earvin “Magic” Johnson](https://msuspartans.com/news/2002/6/7/Earvin_Magic_Johnson_Elected_To_Basketball_Hall_Of_Fame) — official Michigan State historical reference.
- [FIBA Hall of Fame profile for Michael Jordan](https://about.fiba.basketball/en/fiba-hall-of-fame/hall-of-famers/michael-jordan) — official career and North Carolina years reference.
- [LSU 1991-92 Shaquille O'Neal roster profile](https://lsusports.net/sports/mb/roster/season/1991-92/player/shaquille-oneal) — official LSU historical reference.
- [Cincinnati Oscar Robertson profile](https://gobearcats.com/oscar-robertson-1) — official Cincinnati season-stat reference.
- [LSU 1969-70 Pete Maravich roster profile](https://lsusports.net/sports/mb/roster/season/1969-70/player/pete-maravich) — official LSU season-stat reference.
- [Duke 2016-17 Jayson Tatum roster profile](https://goduke.com/sports/mens-basketball/roster/jayson-tatum/4423) — official Duke season reference.
- [Memphis 2007-08 Derrick Rose roster profile](https://gotigersgo.com/sports/mens-basketball/roster/derrick-rose/3110) — official Memphis season reference.
- [Duke 2010-11 Kyrie Irving roster profile](https://goduke.com/sports/mens-basketball/roster/kyrie-irving/4338) — official Duke season reference.
- [NCAA brand and licensing](https://www.ncaa.org/championships/brand-licensing/) — official notice that commercial use of NCAA names or logos requires licensing.
- [Roblox IP licensing guidance for creators](https://create.roblox.com/docs/ip-licensing/creators) — official Roblox intellectual-property guidance.
- [Roblox monetization documentation](https://create.roblox.com/docs/production/monetization) — official randomized-item and regional-policy considerations.
- [Build A Soccer Squad official Roblox listing](https://www.roblox.com/games/82524183928567/Build-A-Soccer-Squad) — reference for the team/year card-roll fantasy; its current listing explicitly describes its players as fictional.
- [Draft A Basketball Squad official Roblox listing](https://www.roblox.com/games/120342469789318/Draft-A-Basketball-Squad) — reference for five-position, school/team-season-style roster rolling and rare variants.

## 21. Recommended next implementation document

After resolving the questions in Section 18, create a technical specification covering:

- Roblox service/module boundaries
- DataStore profile and migration format
- Server Roll/Refresh APIs
- Weighted-random library and deterministic tests
- Card inventory/index API
- Initial placeholder dataset
- UI screen map
- Analytics events
- Exploit and purchase threat model

The recommended first implementation target is not the complete historical dataset. It is one reliable vertical slice in which players enjoy receiving a school-season, refreshing its available player choices, rolling its roster, recognizing why a card is valuable, and deciding to roll again.
