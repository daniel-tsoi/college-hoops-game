-- Every quest resets on each new connection. Playtime milestones measure the
-- current session, not lifetime `playSeconds`, so the hours must be played again
-- to re-earn the reward. Lifetime `playSeconds` is kept for stats and history.
-- Time quests carry `hours`; the UI formats their progress as a duration.
-- Activity rewards scale with effort: 2/5 for unique unlocks, 10/25 for roll milestones.
return table.freeze({
	table.freeze({ id = "hour1", doublePrice = 49, scope = "SESSION", metric = "sessionSeconds", hours = 1, seconds = 3600, target = 3600, cash = 10000, rerolls = 5, refreshes = 5 }),
	table.freeze({ id = "hour2", doublePrice = 99, scope = "SESSION", metric = "sessionSeconds", hours = 2, seconds = 7200, target = 7200, cash = 25000, rerolls = 10, refreshes = 10 }),
	table.freeze({ id = "hour4", doublePrice = 199, scope = "SESSION", metric = "sessionSeconds", hours = 4, seconds = 14400, target = 14400, cash = 50000, rerolls = 25, refreshes = 25 }),
	table.freeze({ id = "unlock5", doublePrice = 49, scope = "SESSION", metric = "sessionUnlocks", target = 5, title = "UNLOCK 5 PLAYERS", cash = 25000, rerolls = 2, refreshes = 2 }),
	table.freeze({ id = "unlock10", doublePrice = 99, scope = "SESSION", metric = "sessionUnlocks", target = 10, title = "UNLOCK 10 PLAYERS", cash = 50000, rerolls = 5, refreshes = 5 }),
	table.freeze({ id = "reroll100", doublePrice = 49, scope = "SESSION", metric = "sessionRolls", target = 100, title = "ROLL 100 TIMES", cash = 50000, rerolls = 10, refreshes = 10 }),
	table.freeze({ id = "reroll200", doublePrice = 99, scope = "SESSION", metric = "sessionRolls", target = 200, title = "ROLL 200 TIMES", cash = 100000, rerolls = 25, refreshes = 25 }),
})
