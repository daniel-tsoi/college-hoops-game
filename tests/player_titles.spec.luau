local fs = require('@lune/fs')
local luau = require('@lune/luau')
local roblox = require('@lune/roblox')
-- Run from the repository root: lune run tests/player_titles.spec.luau
local root = './'
local files = {
'src/shared/PlayerTitles.luau', 'src/ServerScriptService/Config/TitleRoles.luau',
'src/ServerScriptService/OverheadTitles.server.luau', 'src/ServerScriptService/EquippedCard.server.luau',
'src/ServerScriptService/LeaderboardServer.server.luau',
'src/StarterPlayer/StarterPlayerScripts/ChatTitles.client.luau',
'src/StarterPlayer/StarterPlayerScripts/EquippedCard.client.luau',
}
for _, path in files do luau.compile(fs.readFile(root .. path)) end
local titles = luau.load(fs.readFile(root .. files[1]), {environment = {Color3 = roblox.Color3}})()
for rank = 1, 50 do assert(titles.forRank(rank) == (rank <= 3 and 'Top '..rank or 'Top 50')) end
for _, rank in {0, -1, 51, 1.5, math.huge, 0/0, '1', false} do assert(titles.forRank(rank) == nil) end
assert(titles.forRank(nil) == nil)
for _, role in {'Creator', 'Admin', 'Tester'} do assert(titles.resolve(role, 1) == role) end
assert(titles.resolve('Unknown', 2) == 'Top 2')
assert(titles.resolve(nil, nil) == nil)
print('PASS: seven scripts compile; rank boundaries and role precedence pass')

local chat = {}
local title = 'Top 1'
local player = {GetAttribute = function() return title end}
local players = {GetPlayerByUserId = function(_, id) return id == 7 and player or nil end}
local replicated = {Shared = {PlayerTitles = {}}}
local services = {Players = players, TextChatService = chat, ReplicatedStorage = replicated}
luau.load(fs.readFile(root .. 'src/StarterPlayer/StarterPlayerScripts/ChatTitles.client.luau'), {
 environment = {
  game = {GetService = function(_, name) return services[name] end},
  require = function() return titles end,
  Instance = {new = function() return {} end},
 }
})()
for _, value in {'Top 1', 'Top 2', 'Top 3', 'Top 50', 'Creator', 'Admin', 'Tester'} do
 title = value
 local prefix = chat.OnIncomingMessage({TextSource = {UserId = 7}, PrefixText = 'Player1:'}).PrefixText
 assert(prefix == '<font color="#' .. titles.Colors[value]:ToHex() .. '">[' .. value .. ']</font> Player1:')
end
title = nil
assert(chat.OnIncomingMessage({TextSource = {UserId = 7}, PrefixText = 'Player1:'}) == nil)
assert(chat.OnIncomingMessage({PrefixText = 'System:'}) == nil)
assert(chat.OnIncomingMessage({TextSource = {UserId = 99}, PrefixText = 'Departed:'}) == nil)
print('PASS: all seven colored chat tags; unranked, system, and departed-player messages remain unchanged')
