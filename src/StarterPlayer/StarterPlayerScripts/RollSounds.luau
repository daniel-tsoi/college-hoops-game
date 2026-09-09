-- Free Creator Store effects. Local menu audio; never broadcast to other players.
local SettingsState=require(script.Parent:WaitForChild("SettingsState"))
local Sounds={}
function Sounds.mount(gui)
 local ContentProvider=game:GetService("ContentProvider")
 local dice=Instance.new("Sound")
 dice.SoundGroup=SettingsState.soundGroup()
 dice.Name="DiceRollSFX"; dice.SoundId="rbxassetid://94408745106202"; dice.Volume=.55; dice.Parent=gui
 local chest=Instance.new("Sound")
 chest.SoundGroup=SettingsState.soundGroup()
 chest.Name="ChestOpenSFX"; chest.SoundId="rbxassetid://116841971399984"; chest.Volume=.55; chest.Parent=gui
 task.spawn(function() pcall(function() ContentProvider:PreloadAsync({dice,chest}) end) end)
 local view={}
 function view.play(action,code)
  local sound
  if action=="RefreshRoll" and code=="REFRESHED" then sound=chest
  elseif action=="RerollPlayer" and code=="REROLLED" then sound=dice
  elseif (action=="NextRoll" or action=="RestartRoll") and code=="READY" then sound=dice end
  if sound then
   dice:Stop(); chest:Stop()
   sound.TimePosition=0; sound:Play()
  end
 end
 return view
end
return Sounds
