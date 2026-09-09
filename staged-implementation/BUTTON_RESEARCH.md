# Squad button UI: research and implementation decisions

Audience: the game creator implementing the first Roblox Studio feature. Research date: September 5, 2026 UTC. Scope: this project's UI stage, with server architecture guidance for later stages.

## Answer

Use one LocalScript at StarterPlayer > StarterPlayerScripts > HoopsUI to create a ScreenGui under PlayerGui. This stage implements display, navigation, input, confirmations, and explicitly disposable Studio previews. The current source includes the complete feature; it does not depend on any server scripts.

## Behavior and evidence

| Control | Project intent | Implemented in this UI stage |
|---|---|---|
| Reroll | Replace the revealed individual, not all three candidates | Requires a preview reveal; consumes one disposable Reroll counter |
| Refresh | Replace three candidates, preserving school-season | Consumes the separate Refresh preview counter; generates no cards |
| Restart | Scratch unfinished run; choose school-season; assign both freebies to exactly 1 | Clears preview slots/reveal, resets counters; confirms loss when slots exist |
| Exit | User explicitly specified normal POV and bottom BUILD to reopen | Hides page, shows BUILD, preserves in-session UI state |
| Finish Squad | Existing design calls this Finish Team; intended to commit a completed five | Five-slot preview gate and confirmation; explicitly reports no saving |
| Roll / Accept | Reveal a card / place it into the lineup | Labeled placeholders allow testing the UI progression only |

These game rules come from project context and the user's clarification, not Roblox documentation. The saved stage plan flags which earlier design statements still need confirmation. The attached screenshot supports dark rectangular controls and outlines, but cannot establish the source game's mechanics. Its Auto Reveal, flag and 2010 are not implemented as inferred requirements.

## Roblox implementation findings

- TextButton.Activated provides the button event used by this implementation. Roblox documents click/tap activation and button feedback. [Roblox: Text & image buttons](https://create.roblox.com/docs/ui/buttons).
- CoreUISafeInsets keeps controls clear of the top bar and device cutouts. ScreenGui controls visibility; the implementation hides only the page Frame so BUILD remains accessible. [Roblox: On-screen UI containers](https://create.roblox.com/docs/ui/on-screen-containers).
- Later gameplay must validate actions and resources on the server and rate-limit requests. Client counters in this feature are test fixtures, not an economy. [Roblox: Securing the client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary).
- RemoteEvents support asynchronous client/server messages and can live in ReplicatedStorage. A later request should identify the action; the server should produce the outcome. [Roblox: Remote events and callbacks](https://create.roblox.com/docs/scripting/events/remote).
- For later Finish Squad saving, UpdateAsync updates a single data-store key and can handle competing server updates. Proposed design: save the finished squad and its discoveries together under one player profile key, with a committed run ID to prevent repeat awards. This is an implementation recommendation, not a completed transaction system. [Roblox: Data stores](https://create.roblox.com/docs/cloud-services/data-stores).

UI decisions: readable labels instead of unidentified icons, separate resource labels, 60-pixel button heights, 8-pixel gaps, vertical scrolling, explicit modal input guards, and controller selection links. The local UI/UX skill's confirmation and focus recommendations informed these choices; Roblox rendering still needs device testing.

## Unresolved decisions

The complete ambiguity list remains in IMPLEMENTATION_STAGES.md. Before actual rolls, resolve roster-wide versus visible-three sampling, candidate replenishment after Accept, Refresh's effect on an existing reveal, ordinary Roll costs, global special-tier scope, and mixed-school progression. No original-game mechanics were independently established because the source game remains unidentified. Exit is now resolved by the user's direct instruction.

## Research boundaries and verification

Discovery: searched Roblox button activation/safe areas and client/server validation/persistence. Follow-up: read official button, container, security, data-store and remote documentation; inspected UpdateAsync semantics. Highest-impact findings are client/server ownership and avoiding a false save success. Evidence is sufficient for this UI stage; further generic searches would not resolve project-specific game rules. The planning tool requested by the research workflow was unavailable, so scope and phases were tracked in the task notes.

The code was inspected and the staged Rojo project built. Studio visual and input testing is outstanding. Installation and a concrete test sequence are in IMPLEMENTATION_STAGES.md.
