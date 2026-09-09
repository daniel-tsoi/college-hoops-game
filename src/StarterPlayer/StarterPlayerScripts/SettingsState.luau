local player=game:GetService("Players").LocalPlayer
local defaults=require(game:GetService("ReplicatedStorage").Shared.PlayerSettings).defaults()
local State={}
function State.get(key)
 local value=player:GetAttribute("HoopsSettings_"..key)
 if value==nil then return defaults[key] end
 return value
end
function State.vfx(kind)
 return State.get(kind=="HOF" and "hofVFX" or "nonCollegeVFX")
end
function State.soundGroup()
 local service=game:GetService("SoundService")
 local group=service:FindFirstChild("HoopsSFX")
 if not group then
  group=Instance.new("SoundGroup"); group.Name="HoopsSFX"; group.Volume=State.get("sfx")/5; group.Parent=service
  player:GetAttributeChangedSignal("HoopsSettings_sfx"):Connect(function() group.Volume=State.get("sfx")/5 end)
 end
 return group
end
return State
