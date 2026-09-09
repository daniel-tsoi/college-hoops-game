# College Hoops player database research

September 5, 2026 UTC · Prepared for the game developer

## What is now in the project

The game data now contains **25,393 real player-school-season base cards** across
**1,812 school-seasons**, plus **1,077 All-Star season variants**,
the exact eight HOF cards, and four purchase-only non-college cards. Every base
card has a name, stable identity, school-season, position, Overall, five attributes,
underlying recorded statistics, and rating confidence. Transfers remain separate
school-season cards. This is a broad sourced import with sampled verification;
it is **not an individually verified scouting report for every player**.

The bulk source is the [SportsDataverse player-box release](https://github.com/sportsdataverse/sportsdataverse-data/releases/tag/espn_mens_college_basketball_player_boxscores),
which identifies ESPN as its upstream provider. Its [data license is CC BY 4.0](https://raw.githubusercontent.com/sportsdataverse/hoopR-mbb-data/main/LICENSE.md).
Raw inputs and hashes are preserved locally, and the build script can reproduce
the ratings without further network access.

| Season | School-seasons | Base cards | Listed but no recorded appearance, excluded |
|---|---:|---:|---:|
| 2021–22 | 358 | 5,090 | 737 |
| 2022–23 | 363 | 5,102 | 729 |
| 2023–24 | 362 | 5,063 | 770 |
| 2024–25 | 364 | 5,119 | 758 |
| 2025–26 | 365 | 5,019 | 661 |

A card requires a recorded game appearance, following design section 16. Players
seen only as DNP are retained in the research exclusion file, not given fictional
season performances. A box-score source cannot prove that every zero-appearance
roster member was listed. No missing-ID records occur within the selected teams.

## Coverage and primary-source checks

The importer identifies Division I candidates from at least 20 recorded games in
the season. This removes lower-division opponents that appear in a few box scores.
The resulting totals and year-to-year membership changes were checked, but the
threshold is **not an independent NCAA membership certification**. The original
362-team current discovery list was not used as a historical roster universe.

The selected team sets add Queens, Texas A&M-Commerce, Southern Indiana,
Stonehill and Lindenwood in 2022–23; add Le Moyne and remove Hartford and
St. Francis Brooklyn in 2023–24; add Mercyhurst and West Georgia in 2024–25;
and add New Haven in 2025–26. The latest count matches the NCAA's projected
**365 men's Division I basketball programs** in its [sport sponsorship table](https://www.ncaa.org/about-us/membership-directory/membership-composition-and-sport-sponsorship/).
[New Haven's announcement](https://www.newhaven.edu/news/releases/2025/northeast-conference-invitation.php),
[Mercyhurst's announcement](https://www.mercyhurst.edu/news/mercyhurst-university-marks-new-era-athletics-move-division-I),
and [Hartford's 2023–24 schedule announcement](https://hartfordhawks.com/story.aspx?file_date=10%2F13%2F2023&filename=mens-basketball-toomey-announces-2023-24-schedule)
corroborate those transition dates.

Checks against primary sources included:

- All 14 imported Duke 2021–22 names match the [official roster archive](https://goduke.com/sports/mens-basketball/roster/2021-22).
- Paolo Banchero's 39 appearances, 671 points, 304 rebounds and 124 assists match
  [Duke's cumulative table](https://goduke.com/sports/mens-basketball/stats/2021-22).
- Zach Edey's 757 points/438 rebounds in 2022–23 and 983 points/474 rebounds in
  2023–24 are corroborated by [Purdue's player biography](https://purduesports.com/sports/mens-basketball/roster/edey-zach/12351).
- Flagg's 709 points and 278 rebounds match [Duke's current 2024–25 cumulative table](https://goduke.com/sports/mens-basketball/stats/2024-25).
  That table lists 156 assists, while the [season recap](https://goduke.com/documents/download/2025/8/7/Season_Recap__2024-25_.pdf)
  says 155. The current tabular 156 is retained; the disagreement is not concealed.
- Cameron Boozer's 855 points, 389 rebounds and 157 assists match [Duke's 2025–26 table](https://goduke.com/sports/mens-basketball/stats/2025-26).
  That table lists 95 turnovers; the feed has 96. The current school table takes precedence.
- AJ Dybantsa's 894 points agree with [BYU's season review](https://byucougars.com/news/2026/04/17/byu-mens-basketball-25-26-season-recap).

Four field corrections are applied reproducibly from two official school tables:
Flagg's minutes, defensive rebounds, and total rebounds; Boozer's turnovers.
The before/after ledger preserves the original feed values. Rounded game minutes
can differ from cumulative minutes. Most of the remaining records have not been
individually reconciled against their school's final statistics.

## Ratings: game-owned estimates

**Overall and the five attributes are not official NCAA, NBA, or 2K ratings.**
They are reproducible game balance estimates (`boxscore-five-attributes-v1`).
Base attributes are integers in 1–99; the current model uses 40–99. Ordinary
Overall tiers are Common 1–64, Rare 65–79, Epic 80–89 and Legendary 90–99.
All-Star is 100–105 and HOF is 105–110, preserving the user's overlap at 105.

Each season and inferred position is calibrated separately. Per-40 rates shrink
toward position-group averages with a 200-minute prior; shooting percentages use
50 three-point, 30 free-throw and 100 field-goal attempt priors. This limits
extreme ratings based on very small samples.

| Attribute | Inputs and interpretation |
|---|---|
| Shooting | 35% adjusted 3P percentage rank, 30% 3P attempts per 40 rank, 20% FT percentage rank, 15% effective FG percentage rank |
| Dribbling | 40% assists per 40 rank, 35% assist/turnover quality rank, 25% ball-security rank; an indirect proxy for handling |
| Defense | 30% steals per 40 rank, 30% blocks per 40 rank, 25% defensive rebounds per 40 rank, 15% foul-discipline rank; omits tracking and film |
| Speed | Explicit unmeasured position prior: PG 82, SG 78, SF 73, PF 66, C 58; **not individual sprint research** |
| Stamina | 75% minutes per appearance relative to 40 minutes, 25% share of recorded team games played; a workload proxy |

Overall blends 65% position-weighted attributes with 35% season production rank,
then maps appraisal rank to 40–99 within its group. Under 200 minutes caps Overall
at 64; under 500 minutes caps it at 79. The formula and every input are available
in `scripts/build_player_database.py`. It is a starting balance model, without
opponent-strength, recruiting, tracking or film calibration. A center's handling
rank is relative to centers; cross-position comparisons need care.

Generic G/F source positions are interpreted from assists and shooting role and
marked estimated. Missing/ATH positions fall back to SF with low confidence. Exact
source PG/SG/SF/PF/C values are retained. This intentionally does not manufacture
secondary positions to make every school pass lineup validation.

Examples of **derived base-card game ratings**, not official measurements:

| Player | Season | OVR | Shooting | Dribbling | Defense | Speed | Stamina |
|---|---|---:|---:|---:|---:|---:|---:|
| Paolo Banchero | 2021-22 | 98 | 69 | 94 | 90 | 73 | 91 |
| Zach Edey | 2022-23 | 96 | 71 | 81 | 78 | 58 | 89 |
| Zach Edey | 2023-24 | 97 | 78 | 88 | 78 | 58 | 90 |
| Cooper Flagg | 2024-25 | 99 | 84 | 97 | 97 | 73 | 88 |
| Cameron Boozer | 2025-26 | 99 | 82 | 95 | 88 | 73 | 92 |

Rarity multipliers are 1.00, 1.05, 1.10, 1.15, 1.20 and 1.25. A future gameplay
consumer applies its multiplier once to base attributes, rounds, and clamps to
1–99. Overall is not multiplied again.

## Special players and exact odds

The HOF pool contains only Magic Johnson (Michigan State 1978–79), Michael Jordan
(North Carolina 1983–84), Shaquille O'Neal (LSU 1991–92), Oscar Robertson
(Cincinnati 1959–60), Pete Maravich (LSU 1969–70), Jayson Tatum (Duke 2016–17),
Derrick Rose (Memphis 2007–08), and Kyrie Irving (Duke 2010–11).

Their official historical totals and source URLs are stored alongside the cards.
Their special ceilings and attribute ratings remain explicitly **manual archetype
estimates**, not a statistical claim that their college seasons scored 105–110.
Unavailable historical fields are omitted, never filled with zero. The sources
include [MSU's record book](https://msuspartans.com/documents/download/2015/4/30/_msu_m_baskbl__0910MBBRecords.pdf),
[UNC's record book](https://goheels.com/documents/download/2025/12/30/25-26_M-Basketball_Record_Book.pdf),
[LSU's Shaq record](https://lsusports.net/sports/mb/roster/player/shaquille-oneal),
[Cincinnati's Oscar record](https://gobearcats.com/oscar-robertson-1),
[LSU's Maravich record](https://lsusports.net/sports/mb/roster/season/1969-70/player/pete-maravich),
[Duke's Tatum season](https://goduke.com/documents/download/2022/8/15/2016-17_Stats.pdf),
[Memphis's Rose guide](https://gotigersgo.com/documents/download/2015/5/27/_m_baskbl__2008-09CompleteGuide.pdf),
and [Duke's Irving season](https://goduke.com/documents/download/2022/8/15/2010-11_Stats.pdf).

| Uniform ticket in 1–800 | Outcome | Probability |
|---|---|---:|
| 1 | One of the eight HOF cards, uniformly | 1/800 = 0.125% |
| 2–9 | An eligible All-Star from the current school-season | 8/800 = 1/100 = 1% |
| 10–800 | Ordinary school-season card | 791/800 = 98.875% |

These are mutually exclusive outcomes. Each individual HOF card has unconditional
probability 1/6400. All-Star season variants currently require base Overall at least
97, at least 500 minutes and at least 15 appearances. This is an explicit game-owned
**season-performance** criterion, not an inferred NBA future or recruiting ceiling.
It replaces the earlier prototype's All-NBA name with the user's latest All-Star name.

Kobe Bryant, LeBron James, Luka Doncic and Nikola Jokic are a separate non-college
pool, locked by default, with direct purchase required and random eligibility false.
The server catalog contains no guessed price or product ID. The prior school-free
paths are corroborated by [NBA's Kobe profile](https://jr.nba.com/player-profile-kobe-bryant/),
[LeBron's NBA bio](https://www.nba.com/player/2544/lebron-james/bio),
[Real Madrid's Luka history](https://www.realmadrid.com/en-US/the-club/history/basketball-legends/luka-doncic/),
and [Jokic's NBA bio](https://www.nba.com/player/203999/nikola-jokic/bio).

## What is still needed before gameplay

The data and configuration are in the root Rojo game tree. This task does not
implement random draws, grants, payments, UI wiring, or spawning. To make purchases
operational requires real store IDs and a verified server entitlement handler.

1,013 school-seasons currently have no qualified All-Star variant.
1,060 cannot yet form PG/SG/SF/PF/C from five unique players using the
currently supported positions. The future summon service must reject unsupported
school-seasons before charging or drawing; it must not silently reduce the promised
1% chance, invent an eligible special card, or substitute a purchase-only player.
All school-seasons are marked not release-ready pending coverage, position and
rating review. They remain available in the data for development.

The remaining research is a full school-by-school archive reconciliation, film or
tracking work for individual speed/handling, secondary-position review, and balance
calibration. The import should not be described as exhaustive individual scouting.

## Verification

See the final verification record appended below. The automated check enumerates
all 800 tickets, verifies the exact HOF whitelist, excludes purchase cards from
random pools, checks every linked school-season and card, and runs source spot checks.
A standalone test copy changes only Roblox Instance-based require paths to equivalent
filesystem paths; production module bodies are otherwise unchanged.

Luau **0.737 strict static analysis passed** for every new data/config module and test.
Runtime checks passed for all cards and school-seasons and the exhaustive 800-ticket
odds check. Rojo **7.6.1 built successfully**, with 146 ModuleScripts, including
the player database and both server configurations. No Studio playtest was run.
