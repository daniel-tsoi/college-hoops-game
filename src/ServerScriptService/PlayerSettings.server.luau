local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StudioSaving=require(script.Parent.Config.StudioSaving)
local inStudio=game:GetService("RunService"):IsStudio()
-- Studio saves only when opted in, and then under a separate key namespace.
local studioSaving=inStudio and StudioSaving.enabled==true
local preview=inStudio and not studioSaving
local Settings=require(ReplicatedStorage.Shared.PlayerSettings)
local Jersey=require(script.Parent.Customization.Jersey)
local store=not preview and game:GetService("DataStoreService"):GetDataStore("HoopsPlayerSettings_v1") or nil
local remote=Instance.new("RemoteFunction"); remote.Name="HoopsPlayerSettings"; remote.Parent=ReplicatedStorage
local profiles,busy,last={}, {}, {}
local function key(player) return (studioSaving and StudioSaving.keyPrefix or "")..tostring(player.UserId) end
local function apply(player)
 local data=profiles[player]
 if not data then return end
 for key,value in pairs(data) do player:SetAttribute("HoopsSettings_"..key,value) end
 if player.Character then Jersey.apply(player,player.Character,data) end
end
local function load(player)
 local data=store and store:GetAsync(key(player)) or nil
 if player.Parent~=Players then return false end
 profiles[player]=Settings.validate(data) or Settings.defaults()
 apply(player)
 return true
end
remote.OnServerInvoke=function(player,value)
 if busy[player] or (last[player] and os.clock()-last[player]<.4) then return {code="BUSY"} end
 last[player]=os.clock(); busy[player]=true
 local ok,result=pcall(function()
  if not profiles[player] and not load(player) then return {code="UNAVAILABLE"} end
  if value~=nil then
   local valid=Settings.validate(value)
   if not valid then return {code="INVALID"} end
   if store then store:UpdateAsync(key(player),function() return valid end) end
   if player.Parent~=Players then return {code="UNAVAILABLE"} end
   profiles[player]=valid; apply(player)
  end
  return {code="OK",settings=profiles[player],preview=preview}
 end)
 busy[player]=nil
 if not ok then return {code="UNAVAILABLE"} end
 return result
end
local function joined(player)
 player.CharacterAdded:Connect(function(character)
  character:WaitForChild("Humanoid",10)
  local torso=character:WaitForChild("HumanoidRootPart",10)
  if torso and character==player.Character then apply(player) end
 end)
 player.CharacterAppearanceLoaded:Connect(function() apply(player) end)
 busy[player]=true
 local ok=pcall(load,player)
 busy[player]=nil
 if not ok then warn("Player settings unavailable; menu can retry for",player.UserId) end
end
Players.PlayerAdded:Connect(joined)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(joined,player) end
Players.PlayerRemoving:Connect(function(player) profiles[player]=nil; last[player]=nil end)
