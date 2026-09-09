# Playtime quests

Open the canonical **CollegeHoops-UI-Trial-v3.rbxlx** in Roblox Studio, press **Play**, then click **QUESTS** on the right of the lobby. The place includes the existing Shop and squad preview.

| Total online playtime | Cash | Rerolls | Refreshes |
|---|---:|---:|---:|
| 1 hour | $10,000 | 5 | 5 |
| 2 hours | $25,000 | 10 | 10 |
| 4 hours | $50,000 | 25 | 25 |

The three playtime milestones are cumulative across visits, each claimable once per account, with no daily reset. All three rewards stack: $85,000, 40 rerolls, and 40 refreshes. Online time includes time in the lobby and menus; no offline time accrues. AFK detection is not implemented. These rules are reasonable defaults for the requested playing-hours quests and can be changed later.

The page shows a ticking total-time counter, progress bars, remaining times, exact reward bundles, and Locked / Claim / Claimed buttons. A claim adds the entire bundle atomically with its claimed flag to the same profile used by Shop. The server determines elapsed time and rewards; the client only submits the quest ID. Duplicate claims do not award again. Money immediately updates the Shop balance.

Quest rerolls and refreshes are separate from the one free reroll/refresh supplied by each squad-preview restart. The preview uses the free action first, then spends a quest reward through the server. Restart never resets or refills the quest balances. Live roster execution is still a later feature; earned balances are saved and displayed, while spending through the current squad UI is available in the Studio preview.

## Activity quests — reset each login

| Goal during the current login | Cash |
|---|---:|
| Unlock 5 new players | $25,000 |
| Unlock 10 new players | $50,000 |
| Complete 100 rerolls | $50,000 |
| Complete 200 rerolls | $100,000 |

These four quests start from zero each time the player joins a server. Both progress and their claim flags reset; cash already earned, permanent ownership, bonus actions, and lifetime playtime milestones remain saved. Each reward can be claimed once per login. Claiming a lower tier does not consume progress toward the higher tier. All four rewards stack to $225,000.

A newly unlocked card currently means a successful first-time Shop purchase during this login. Existing ownership, duplicate purchase attempts, failed purchases, and selecting disposable squad-preview prospects do not count. Only twelve permanent cards exist in the current shop, so repeat unlock quests will need more unlockable players and the future roster/inventory acquisition path. That future server path must increment `sessionUnlocks` in the same transaction that first grants ownership. Respawning, reopening Quests, or restarting the squad does not reset these quests.

Both free and bonus rerolls count; refreshes and failed rerolls do not. The Studio squad preview now sends its free rerolls and restarts to the server, which checks the free/bonus balance and increments progress atomically. Preview endpoints are rejected outside Studio. The live reroll reward-spend path also increments progress, for integration with the later real squad service. There is no arbitrary client “add progress” remote.

## Saving and migration

`CollegeHoopsShop_v1` keeps the existing store name/key. Version 2 added `playSeconds`, `rerolls`, `refreshes`, `claimedQuests`, `clockSession`, and `sessionSeconds`, preserving existing money and purchased cards. Version 3 adds per-login unlock/reroll counts and claim flags, plus the server-owned Studio free-reroll counter. A new login resets only these activity fields. Old connections cannot mutate the newer login’s profile. Saved totals checkpoint every 60 seconds, on purchases/claims/reward spends, on leave, and on shutdown. Normal reconnects continue the total. An abrupt crash may lose the time since the last successful checkpoint; saved claims and reward balances remain intact.

Only the newest connected session advances time. Absolute elapsed checkpoints prevent an UpdateAsync retry from adding the same seconds twice. A new connection never adds time spent offline. Failed live storage requests do not fall back to a local wallet. Studio uses disposable profiles and a real-time clock and never touches production saves. Stopping Play clears Studio rewards and progress.

## Verification

Run:

```sh
python3 scripts/check_shop.py --luau /path/to/luau --compiler /path/to/luau-compile
```

Tests cover all exact reward bundles, one second before versus at each threshold, duplicate claims, out-of-order claims, stacked totals, version-1 migration, reconnects, no offline credit, stale-session suppression, checkpoint retries, reward spending, and purchases using quest cash. The existing shop checks also run. All shop, quest, and squad scripts compile, and both Rojo project builds pass.

Studio rendering, touch/controller input, and live DataStore integration have not been run by the assistant. To verify rewards quickly in a disposable Studio session, use a debugger/test harness to seed a profile near a threshold; no client-accessible time-skip or claim bypass is shipped. The Luau transaction tests simulate all four hours without changing the actual thresholds.

Manual checks: open/close Shop and Quests, resize to a narrow phone viewport, confirm no lobby controls cover Build, watch the timer, claim at a milestone, verify updated cash and action balances, spend a bonus action after the free one, and restart the squad. Test reconnect persistence and failed saves in a dedicated published test place before release.

Activity quest verification also checks one below and exactly at all four thresholds, reward re-earning after a new login, duplicate/failed purchase exclusion, free and bonus reroll counting, failed reroll/refresh exclusion, squad restart preservation, and permanent reward/ownership retention across login resets. The focused trial is rebuilt and its embedded sources are checked against all seven current modules. Studio visual/runtime testing remains pending.
