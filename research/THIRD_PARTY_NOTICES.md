# Research data attribution

The five `data/player_box_*.parquet` files are SportsDataverse men's college
basketball player box scores, upstream ESPN, copyright 2026 hoopR.mbb authors.

- [Dataset and release metadata](https://github.com/sportsdataverse/sportsdataverse-data/releases/tag/espn_mens_college_basketball_player_boxscores)
- [Publisher's data license](https://raw.githubusercontent.com/sportsdataverse/hoopR-mbb-data/main/LICENSE.md)
- [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/)

Changes made here: filter team-season candidates, aggregate player-game records
into player-school-season records, retain only recorded appearances, reconcile
selected official-stat corrections, infer game positions, derive game-owned
ratings, create special variants, and generate Luau ModuleScripts. These changes
are by this project and do not imply endorsement by SportsDataverse or ESPN.

Preserve this attribution with redistributed data and derived tables. Individual
source URLs, filenames, and SHA-256 hashes are recorded in
`data/source_manifest.json`; official correction URLs appear in
`data/applied_corrections.json`. Historical HOF facts are separately attributed
inside `data/special_players.json` and their generated game entries.
