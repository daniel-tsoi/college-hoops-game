-- Cosmetic only: the server announces committed, shop-eligible rare hits.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local Debris=game:GetService("Debris")
local TextChatService=game:GetService("TextChatService")
local localPlayer=Players.LocalPlayer
local SettingsState=require(script.Parent:WaitForChild("SettingsState"))
local random=Random.new()
local queue={}
local playing=false
local function tween(object,duration,properties)
 TweenService:Create(object,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties):Play()
end
local function escape(text)
 return text:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
end
local function announce(hit,color)
 local message=hit.playerName.." got "..(hit.gold and "GOLD " or "")..(hit.kind=="HOF" and "HOF " or "NON-COLLEGE ")..hit.cardName
 task.spawn(function()
  local channels=TextChatService:WaitForChild("TextChannels",10)
  local channel=channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildWhichIsA("TextChannel"))
  if channel then
   channel:DisplaySystemMessage('<font color="#'..color:ToHex()..'">'..escape(message)..'</font>')
  end
 end)
end
local function burst(hit,color)
 local player=Players:GetPlayerByUserId(hit.userId)
 local root=player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root then return end
 local anchor=Instance.new("Part")
 anchor.Name="RareRevealBurst"; anchor.Size=Vector3.one
 anchor.Transparency=1; anchor.Anchored=true; anchor.CanCollide=false; anchor.CanTouch=false; anchor.CanQuery=false
 anchor.CFrame=root.CFrame; anchor.Parent=workspace
 Debris:AddItem(anchor,4)
 -- HOF is 1.5 times the red burst: broad rising energy around the avatar.
 local scale=hit.kind=="HOF" and 1.5 or 1
 local attachment=Instance.new("Attachment"); attachment.Parent=anchor
 for _,layer in ipairs({{texture="rbxasset://textures/particles/smoke_main.dds",count=55,size=7,speed=15},
  {texture="rbxasset://textures/particles/sparkles_main.dds",count=110,size=1.3,speed=30}}) do
  local particles=Instance.new("ParticleEmitter")
  particles.Texture=layer.texture; particles.Color=ColorSequence.new(color,Color3.new(1,1,1))
  particles.LightEmission=1; particles.Rate=0; particles.Lifetime=NumberRange.new(.65,1.6)
  particles.Speed=NumberRange.new(layer.speed*.45*scale,layer.speed*scale)
  particles.SpreadAngle=Vector2.new(70,70); particles.Acceleration=Vector3.new(0,16*scale,0)
  particles.Drag=3; particles.Rotation=NumberRange.new(0,360); particles.RotSpeed=NumberRange.new(-100,100)
  particles.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,layer.size*scale),NumberSequenceKeypoint.new(1,0)})
  particles.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(1,1)})
  particles.Parent=attachment; particles:Emit(layer.count)
 end
 local light=Instance.new("PointLight"); light.Color=color; light.Brightness=8; light.Range=30*scale; light.Parent=anchor
 tween(light,1,{Brightness=0})
 -- Expanding neon shells and ground rings provide the explosion's impact.
 for i=1,3 do
  local ring=Instance.new("Part"); ring.Name="EnergyShockwave"; ring.Shape=Enum.PartType.Cylinder
  ring.Material=Enum.Material.Neon; ring.Color=color; ring.Transparency=.35
  ring.Anchored=true; ring.CanCollide=false; ring.CanTouch=false; ring.CanQuery=false
  ring.Size=Vector3.new(.12,2,2)
  ring.CFrame=CFrame.new(root.Position-Vector3.new(0,2.7,0))*CFrame.Angles(0,0,math.pi/2)
  ring.Parent=anchor
  tween(ring,.5+i*.18,{Size=Vector3.new(.05,(14+i*5)*scale,(14+i*5)*scale),Transparency=1})
 end
end
local function localReveal(hit,color)
 local gui=Instance.new("ScreenGui"); gui.Name="RareHitCelebration"; gui.IgnoreGuiInset=true
 gui.ResetOnSpawn=false; gui.DisplayOrder=100; gui.Parent=localPlayer:WaitForChild("PlayerGui")
 Debris:AddItem(gui,3)
 local flash=Instance.new("Frame"); flash.Size=UDim2.fromScale(1,1); flash.BackgroundColor3=color
 flash.BackgroundTransparency=.7; flash.BorderSizePixel=0; flash.Parent=gui
 tween(flash,.7,{BackgroundTransparency=1})
 local title=Instance.new("TextLabel"); title.AnchorPoint=Vector2.new(.5,.5)
 title.Position=UDim2.fromScale(.5,.25); title.Size=UDim2.fromScale(.85,.17)
 title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBlack; title.TextScaled=true
 title.TextColor3=color; title.TextStrokeTransparency=.15; title.TextWrapped=true
 title.Text=(hit.gold and "GOLD " or "")..(hit.kind=="HOF" and "HALL OF FAME" or "NON-COLLEGE").."\n"..hit.cardName
 title.Parent=gui
 local limit=Instance.new("UITextSizeConstraint"); limit.MaxTextSize=48; limit.Parent=title
 local elapsed=0
 local binding="HoopsRareShake"
 local camera,offset
 local function clearOffset()
  if camera and offset then camera.CFrame=camera.CFrame*offset:Inverse() end
  offset=nil
 end
 RunService:BindToRenderStep(binding.."Restore",Enum.RenderPriority.Camera.Value-1,clearOffset)
 RunService:BindToRenderStep(binding,Enum.RenderPriority.Camera.Value+1,function(dt)
  elapsed+=dt
  camera=workspace.CurrentCamera
  if camera and elapsed<.8 and SettingsState.vfx(hit.kind) then
   local strength=(1-elapsed/.8)*(hit.kind=="HOF" and .45 or .3)
   offset=CFrame.new(random:NextNumber(-strength,strength),random:NextNumber(-strength,strength),0)
   camera.CFrame=camera.CFrame*offset
  end
 end)
 task.wait(.85)
 RunService:UnbindFromRenderStep(binding); RunService:UnbindFromRenderStep(binding.."Restore"); clearOffset()
 task.wait(.85); tween(title,.45,{TextTransparency=1,TextStrokeTransparency=1})
 task.wait(.5); gui:Destroy()
end
ReplicatedStorage:WaitForChild("HoopsRareReveal").OnClientEvent:Connect(function(hit)
 local color=hit.kind=="HOF" and Color3.fromRGB(186,65,255) or Color3.fromRGB(255,45,65)
 announce(hit,color)
 if not SettingsState.vfx(hit.kind) then return end
 if hit.userId~=localPlayer.UserId then burst(hit,color); return end
 table.insert(queue,{hit=hit,color=color})
 if playing then return end
 playing=true
 task.spawn(function()
  while #queue>0 do
   local nextHit=table.remove(queue,1)
   if SettingsState.vfx(nextHit.hit.kind) then
    burst(nextHit.hit,nextHit.color)
    localReveal(nextHit.hit,nextHit.color)
   end
  end
  playing=false
 end)
end)
