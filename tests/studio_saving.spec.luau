-- The Studio persistence opt-in. Guards the two things that matter: it ships
-- off, and when on it cannot collide with a live player's saved profile.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Config = require("../src/ServerScriptService/Config/StudioSaving")

for _, path in
	{
		"src/ServerScriptService/Config/StudioSaving.luau",
		"src/ServerScriptService/ShopServer.server.luau",
		"src/ServerScriptService/PlayerSettings.server.luau",
	}
do
	luau.compile(fs.readFile(path))
end

-- Must ship disabled: enabled in a live place would be harmless (live ignores
-- it) but a committed `true` makes every developer's Studio session write real
-- rows, which is not something to discover by accident.
assert(Config.enabled == false, "StudioSaving must be committed disabled")
assert(type(Config.keyPrefix) == "string" and #Config.keyPrefix > 0, "A key prefix is required")
assert(type(Config.startingBalance) == "number" and Config.startingBalance > 0, "Studio needs cash to test with")

-- Studio keys must never coincide with live keys, in either store's format.
local function shopKey(prefix: string, userId: number): string
	return prefix .. "player_" .. userId
end
local function settingsKey(prefix: string, userId: number): string
	return prefix .. tostring(userId)
end
for _, userId in { 1, 1123697419, 9999999999 } do
	assert(shopKey("", userId) ~= shopKey(Config.keyPrefix, userId), "Shop keys must differ for user " .. userId)
	assert(settingsKey("", userId) ~= settingsKey(Config.keyPrefix, userId), "Settings keys must differ for user " .. userId)
	-- A prefixed key must not be reachable as some other user's live key.
	assert(not string.match(shopKey(Config.keyPrefix, userId), "^player_%d+$"), "Prefixed shop key must not look live")
	assert(not string.match(settingsKey(Config.keyPrefix, userId), "^%d+$"), "Prefixed settings key must not look live")
end

print("Studio saving tests passed: three scripts compile; opt-in ships disabled, prefix is set, and Studio keys cannot collide with live profiles")
