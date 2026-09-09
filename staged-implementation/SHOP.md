# Player shop

Open the canonical **CollegeHoops-UI-Trial-v3.rbxlx** in Roblox Studio → **Play** → **SHOP** at the lower left. The existing Build Your Squad button remains available in the lobby. Closing the shop returns to normal POV. The two tabs contain all 12 existing special players; HOF is the game's existing card tier.

Each card has an original colored jersey/avatar icon, player name, position, OVR, school/season where applicable, shooting, dribbling, defense, speed, stamina, ownership state, and a cash buy button below. Icons are jersey illustrations, not player photographs. Existing estimated ratings are preserved. Cards scroll vertically with one to four columns according to viewport width.

| HOF card | College season | OVR | Cash price |
|---|---|---:|---:|
| Oscar Robertson | Cincinnati 1959–60 | 108 | $450,000 |
| Pete Maravich | LSU 1969–70 | 107 | $425,000 |
| Shaquille O'Neal | LSU 1991–92 | 109 | $400,000 |
| Magic Johnson | Michigan State 1978–79 | 108 | $375,000 |
| Michael Jordan | North Carolina 1983–84 | 110 | $350,000 |
| Derrick Rose | Memphis 2007–08 | 106 | $225,000 |
| Jayson Tatum | Duke 2016–17 | 105 | $175,000 |
| Kyrie Irving | Duke 2010–11 | 106 | $150,000 |

Prices are initial gameplay balance choices informed by the college seasons already recorded in the research, with Shaq's requested $400k anchor. They are deliberately separate from the legacy OVR rankings. Oscar and Pete's scoring/playmaking production receives the highest prices; the shorter college careers cost less, with Kyrie's 11-game season lowest.

| Non-college card | OVR | Cash price |
|---|---:|---:|
| LeBron James | 105 | $450,000 |
| Kobe Bryant | 105 | $425,000 |
| Nikola Jokic | 104 | $375,000 |
| Luka Doncic | 103 | $325,000 |

These four have no college season; their prices are separate premium-card balance choices.

## Purchase behavior

- Studio: each player starts with $1,000,000 test cash, and buying deducts the price and marks the card Owned. Reopening the shop, respawning, and restarting the squad preview preserve purchases within the Play session. Stopping Play clears them. Studio never writes live shop saves.
- Live: wallets begin with $0. A single DataStore UpdateAsync operation checks funds and ownership, deducts cash, and stores the entitlement. The server accepts only a known card ID, looks up its own price, rate-limits requests, and prevents duplicate charges. Failed storage requests do not fall back to disposable wallets.
- The later quest milestone now awards cash through playtime quests (see QUESTS.md). Match rewards remain unimplemented. This shop milestone does not connect owned cards to the unfinished squad/collection systems, or sell Robux products. Future rewards must update this same wallet atomically; a leaderstats display must never be treated as the source of funds.
- DataStore key: `CollegeHoopsShop_v1` / `player_<UserId>`. New production rewards and future inventory migrations must preserve this wallet and its `owned` card-ID set. Each live purchase commits immediately. The later playtime milestone also checkpoints elapsed time periodically and on exit.

## Verification

`python3 scripts/check_shop.py --luau /path/to/luau --compiler /path/to/luau-compile` checks all modified Luau scripts compile, all 12 offers have attributes and prices, the 8/4 split, the $400k Shaq price, successful purchase, exact funds, insufficient funds, duplicate requests, profile immutability, and player isolation. Rojo builds both the focused shop trial and the full project.

Studio rendering, controller navigation, touch input, and live DataStore behavior still need an actual Studio/live session. Suggested checks:

1. Play → Shop. Confirm $1,000,000 and eight HOF cards; scroll to see all eight. Switch tabs and see exactly four non-college cards.
2. Buy Shaq. Balance becomes $600,000; his button reads Owned and cannot charge again.
3. Buy Oscar. Balance becomes $150,000; expensive cards are disabled. Buy Kyrie for exactly $150,000 and verify $0.
4. Close/reopen, respawn, and open/exit the squad builder. Ownership remains; lobby buttons do not overlap the squad screen.
5. Stop and start Play. Trial wallet and ownership reset. Resize to phone portrait/landscape and desktop; check scrolling and the close button.
6. In a dedicated published test place, seed test funds server-side, purchase, reconnect, and verify the persisted wallet and unlock. Test unavailable storage and concurrent purchase requests before release.
