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
-- badges() keeps both, where resolve() shows only the role.
for _, role in {'Creator', 'Admin', 'Tester'} do
 local both = titles.badges(role, 1)
 assert(#both == 2 and both[1] == role and both[2] == 'Top 1', 'role and rank are both kept, role first')
 assert(#titles.badges(role, nil) == 1 and titles.badges(role, nil)[1] == role)
 assert(#titles.badges(role, 0) == 1, 'an out-of-range rank contributes nothing')
end
assert(#titles.badges(nil, 4) == 1 and titles.badges(nil, 4)[1] == 'Top 50')
assert(#titles.badges('Unknown', 2) == 1 and titles.badges('Unknown', 2)[1] == 'Top 2')
assert(#titles.badges(nil, nil) == 0)
print('PASS: seven scripts compile; rank boundaries, role precedence and combined badges pass')

local chat = {}
local role, rank = nil, nil
local player = {GetAttribute = function(_, name)
 if name == 'HoopsRole' then return role end
 if name == 'LeaderboardRank' then return rank end
 return nil
end}
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
local function tag(value)
 return '<font color="#' .. titles.Colors[value]:ToHex() .. '">[' .. value .. ']</font>'
end
local function prefixNow()
 local result = chat.OnIncomingMessage({TextSource = {UserId = 7}, PrefixText = 'Player1:'})
 return result and result.PrefixText
end
-- Rank alone.
role = nil
for value, at in {['Top 1'] = 1, ['Top 2'] = 2, ['Top 3'] = 3, ['Top 50'] = 4} do
 rank = at
 assert(prefixNow() == tag(value) .. ' Player1:')
end
-- Role alone.
rank = nil
for _, value in {'Creator', 'Admin', 'Tester'} do
 role = value
 assert(prefixNow() == tag(value) .. ' Player1:')
end
-- Both, role first and each in its own colour: [Creator][Top 1] Player1:
for _, value in {'Creator', 'Admin', 'Tester'} do
 role = value
 for named, at in {['Top 1'] = 1, ['Top 3'] = 3, ['Top 50'] = 50} do
  rank = at
  assert(prefixNow() == tag(value) .. tag(named) .. ' Player1:')
 end
end
-- An out-of-range rank leaves the role standing alone.
role, rank = 'Creator', 51
assert(prefixNow() == tag('Creator') .. ' Player1:')
role, rank = nil, nil
assert(chat.OnIncomingMessage({TextSource = {UserId = 7}, PrefixText = 'Player1:'}) == nil)
assert(chat.OnIncomingMessage({PrefixText = 'System:'}) == nil)
assert(chat.OnIncomingMessage({TextSource = {UserId = 99}, PrefixText = 'Departed:'}) == nil)
print('PASS: rank-only, role-only and combined [role][rank] chat tags; unranked, system, and departed-player messages remain unchanged')
