-- Every quest resets on each new connection. Playtime milestones measure the
-- current session, not lifetime `playSeconds`, so the hours must be played again
-- to re-earn the reward. Lifetime `playSeconds` is kept for stats and history.
-- Time quests carry `hours`; the UI formats their progress as a duration.
return table.freeze({
	table.freeze({ id = "hour1", scope = "SESSION", metric = "sessionSeconds", hours = 1, seconds = 3600, target = 3600, cash = 10000, rerolls = 5, refreshes = 5 }),
	table.freeze({ id = "hour2", scope = "SESSION", metric = "sessionSeconds", hours = 2, seconds = 7200, target = 7200, cash = 25000, rerolls = 10, refreshes = 10 }),
	table.freeze({ id = "hour4", scope = "SESSION", metric = "sessionSeconds", hours = 4, seconds = 14400, target = 14400, cash = 50000, rerolls = 25, refreshes = 25 }),
	table.freeze({ id = "unlock5", scope = "SESSION", metric = "sessionUnlocks", target = 5, title = "UNLOCK 5 PLAYERS", cash = 25000, rerolls = 0, refreshes = 0 }),
	table.freeze({ id = "unlock10", scope = "SESSION", metric = "sessionUnlocks", target = 10, title = "UNLOCK 10 PLAYERS", cash = 50000, rerolls = 0, refreshes = 0 }),
	table.freeze({ id = "reroll100", scope = "SESSION", metric = "sessionRerolls", target = 100, title = "USE 100 REROLLS", cash = 50000, rerolls = 0, refreshes = 0 }),
	table.freeze({ id = "reroll200", scope = "SESSION", metric = "sessionRerolls", target = 200, title = "USE 200 REROLLS", cash = 100000, rerolls = 0, refreshes = 0 }),
})
