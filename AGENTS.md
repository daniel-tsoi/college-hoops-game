# Canonical Roblox Studio project

- These instructions apply to this entire project, every subfolder, and every
  future user prompt. Continue adding to the same existing game each time.
  Do not start a new game, place, project, or deliverable document for a feature
  or fix unless the user explicitly requests one. Update existing documentation
  in place. Supporting source modules may be added under `src/` when needed;
  they are part of the same game, not separate Studio places.
- The only Studio place that receives ongoing changes is
  `staged-implementation/CollegeHoops-UI-Trial-v3.rbxlx`.
- Do not create `v4`, `Trial`, milestone, feature-specific, or other new `.rbxl`/`.rbxlx`
  files for normal development.
- Put every add-on and gameplay change in the root `src/` tree. Keep the existing
  UI bootstrap at
  `staged-implementation/src/StarterPlayer/StarterPlayerScripts/HoopsUI.client.luau`
  until it is migrated into root `src/`.
- Use the root `default.project.json` for every Rojo connection:
  `rojo serve default.project.json`.
- Open the canonical place in Studio, connect the Rojo plugin to that server, and
  save back to the same canonical file. Do not use `rojo build` to generate a new
  place for each feature.
- Verify the open Studio document is the canonical local file before editing or
  saving. A cloud place title alone does not establish that it is the local file.
  Do not use Download a Copy or Save As to create another place, including an
  accidentally double-suffixed `.rbxlx.rbxl` file. If saving is blocked, preserve
  the source changes and report the blocker rather than creating another file.
- Historical builds are stored in `staged-implementation/archive/` with the
  `.rbxlx.archive` extension so Studio will not offer them as openable projects.
  Never restore or target them unless the user explicitly requests recovery.

# GitHub publishing preference

- When the user says to put, save, sync, upload, or push this project's work to
  GitHub, treat that request as authorization to commit the relevant project
  changes and push them to the configured GitHub remote without asking for
  another confirmation. The current repository is
  `https://github.com/daniel-tsoi/college-hoops-game.git`.
- Inspect the diff, exclude secrets and unrelated files, run checks appropriate
  to the changes, and use a descriptive commit message. Respect any narrower
  scope the user specifies. Do not force-push or discard existing work.
- Publish when the user requests it; do not push after every edit by default.
  Report the commit and push result, or the concrete blocker if publishing fails.
- This preference covers project files in this workspace, not exporting private
  Codex chat transcripts or work from other projects.
