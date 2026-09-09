-- Studio normally hands out a throwaway profile, so nothing is read from or
-- written to a DataStore and progress cannot survive a rejoin. That is why
-- testing persistence with Play/Play Here appears to lose everything: it is the
-- intended default, not a failure, and "Enable Studio Access to API Services"
-- does not change it because the save path is skipped before that would matter.
--
-- Set `enabled = true` to make Studio read and write the REAL DataStores so a
-- rejoin restores progress. Studio then uses `keyPrefix`, a separate key
-- namespace, so a Studio session can never read or overwrite a live player's
-- profile. Live servers ignore every value here.
--
-- The global best-team leaderboard is deliberately left out: its ordered store
-- is keyed by user ID with no room for a prefix, so Studio play would land in
-- the live rankings. Studio rankings stay session-local either way.
return {
	enabled = false,
	keyPrefix = "studio_",
	-- Starting cash for a fresh profile in Studio, saving or not.
	startingBalance = 1000000,
}
