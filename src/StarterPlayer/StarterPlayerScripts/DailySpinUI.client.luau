local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Input=game:GetService("UserInputService")
local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("HoopsDailyUI") then return end
local Config=require(RS:WaitForChild("Shared"):WaitForChild("DailySpinConfig"))
local Geometry=require(RS.Shared:WaitForChild("DailySpinGeometry"))
local visualRandom=Random.new()
local Focus=require(script.Parent:WaitForChild("MenuFocus"))
local function make(class,parent,props)
 local object=Instance.new(class)
 for key,value in pairs(props) do object[key]=value end
 object.Parent=parent
 return object
end
local function round(object,radius) make("UICorner",object,{CornerRadius=UDim.new(radius or 1,0)}) end
local function text(parent,name,value,pos,size,fontSize,color)
 return make("TextLabel",parent,{Name=name,Text=value,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=color or Color3.fromRGB(240,249,247),Font=Enum.Font.GothamBold,TextSize=fontSize,TextWrapped=true})
end
local gui=make("ScreenGui",playerGui,{Name="HoopsDailyUI",ResetOnSpawn=false,DisplayOrder=50,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local navy=Color3.fromRGB(9,14,22)
local muted=Color3.fromRGB(170,182,201)
local gold=Color3.fromRGB(255,207,89)
local green=Color3.fromRGB(100,239,170)
local red=Color3.fromRGB(247,111,124)
local function stroke(object,color,transparency)
 return make("UIStroke",object,{Color=color,Thickness=2,Transparency=transparency or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end
local function gradient(object,top,bottom)
 return make("UIGradient",object,{Color=ColorSequence.new(top,bottom),Rotation=90})
end
local function button(parent,name,value,pos,size,color)
 local b=make("TextButton",parent,{Name=name,Text=value,AnchorPoint=Vector2.new(.5,.5),Position=pos+UDim2.fromOffset(size.X.Offset/2,size.Y.Offset/2),Size=size,BackgroundColor3=color,TextColor3=navy,Font=Enum.Font.GothamBold,TextSize=24,BorderSizePixel=0,Selectable=true})
 make("UICorner",b,{CornerRadius=UDim.new(0,14)})
 stroke(b,color)
 gradient(b,Color3.new(1,1,1),Color3.fromRGB(179,190,204))
 local zoom=make("UIScale",b,{Scale=1})
 local hovering=false
 local activeTween
 local function feedback(value)
  if activeTween then activeTween:Cancel() end
  activeTween=TweenService:Create(zoom,TweenInfo.new(.12),{Scale=value});activeTween:Play()
 end
 b.MouseEnter:Connect(function() hovering=true;if b.Active then feedback(1.035) end end)
 b.MouseLeave:Connect(function() hovering=false;feedback(1) end)
 b.SelectionGained:Connect(function() if b.Active then feedback(1.035) end end)
 b.SelectionLost:Connect(function() feedback(1) end)
 b.InputBegan:Connect(function(input)
  if b.Active and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonA) then feedback(.96) end
 end)
 b.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonA then feedback(hovering and b.Active and 1.035 or 1) end
 end)
 b:GetPropertyChangedSignal("Active"):Connect(function() if not b.Active then feedback(1) end end)
 return b
end
local entry=button(gui,"Daily","DAILY",UDim2.new(1,-142,0,18),UDim2.fromOffset(122,48),green)
entry.TextSize=19
local overlay=make("Frame",gui,{Name="DailyOverlay",Size=UDim2.fromScale(1,1),BackgroundColor3=navy,BackgroundTransparency=.12,BorderSizePixel=0,Visible=false,Active=true})
local canvas=make("Frame",overlay,{Name="DailyCanvas",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(650,780),BackgroundColor3=navy,BorderSizePixel=0})
make("UICorner",canvas,{CornerRadius=UDim.new(0,24)});stroke(canvas,muted,.7)
gradient(canvas,Color3.fromRGB(25,35,51),navy)
local scale=make("UIScale",canvas,{Scale=1})
local function fit() scale.Scale=math.min((overlay.AbsoluteSize.X-20)/650,(overlay.AbsoluteSize.Y-20)/780) end
local resize=overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit);fit()
local title=text(canvas,"Title","DAILY SPIN",UDim2.fromOffset(28,19),UDim2.fromOffset(420,44),32)
title.TextXAlignment=Enum.TextXAlignment.Left
text(canvas,"Rules","One free spin every 12 hours · Holds 1 spin maximum",UDim2.fromOffset(20,69),UDim2.fromOffset(610,30),17,muted)
local function disc(parent,name,pos,size,color)
 local object=make("Frame",parent,{Name=name,AnchorPoint=Vector2.new(.5,.5),Position=pos,Size=UDim2.fromOffset(size,size),BackgroundColor3=color,BorderSizePixel=0})
 round(object);return object
end
local shadow=disc(canvas,"WheelShadow",UDim2.fromOffset(325,336),458,Color3.new(0,0,0));shadow.BackgroundTransparency=.45
local glow=disc(canvas,"WheelGlow",UDim2.fromOffset(325,326),462,navy);glow.BackgroundTransparency=1
local glowStroke=stroke(glow,gold,.85);glowStroke.Thickness=6
local border=disc(canvas,"WheelBorder",UDim2.fromOffset(325,326),448,navy)
stroke(border,muted,.3);gradient(border,Color3.fromRGB(71,84,104),navy)
-- Conical color bands fill five true pie sectors on ONE smooth circular face.
-- Wheel, rim and hub share (325,326); only Wheel.Rotation is animated.
local wheel=disc(canvas,"Wheel",UDim2.fromOffset(325,326),428,Color3.new(1,1,1))
stroke(wheel,muted,.65)
local accents={gold,red,green,Color3.fromRGB(145,196,255),Color3.fromRGB(218,174,255)}
-- One shared wedge background, dark enough for light labels. The dividers and
-- each reward's accent-coloured percentage are what separate the slices now.
local slice=Color3.fromRGB(34,46,66)
local fills=table.create(#Config.Rewards,slice)
local bands={}
for index,color in ipairs(fills) do
 local start=(index-1)/#fills
 local finish=index/#fills
 table.insert(bands,ColorSequenceKeypoint.new(start,color))
 table.insert(bands,ColorSequenceKeypoint.new(index==#fills and 1 or finish-.0001,color))
end
-- Zero degrees points right; -90 starts slice 1 at the top, matching target().
make("UIGradient",wheel,{Name="PieSlices",Type=Enum.GradientType.Conical,Rotation=-90,Offset=Vector2.new(0,0),Color=ColorSequence.new(bands)})
local labels={}
local highlights={}
for index,reward in ipairs(Config.Rewards) do
 local edgeX,edgeY,rotation=Geometry.ray(212,(index-1)*72)
 make("Frame",wheel,{Name="Divider"..index,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(edgeX+2,edgeY+2),Size=UDim2.fromOffset(212,2),Rotation=rotation,BackgroundColor3=muted,BackgroundTransparency=.73,BorderSizePixel=0})
 local angle=math.rad((index-.5)*72-90)
 local x,y=214+math.cos(angle)*143,214+math.sin(angle)*143
 local label=make("Frame",wheel,{Name="Reward"..index,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(116,72),BackgroundColor3=navy,BackgroundTransparency=1,BorderSizePixel=0})
 make("UICorner",label,{CornerRadius=UDim.new(0,12)})
 highlights[index]=stroke(label,accents[index],1)
 text(label,"Chance",tostring(reward.chance).."%",UDim2.fromOffset(0,5),UDim2.fromOffset(116,22),17,accents[index])
 text(label,"Name",reward.label,UDim2.fromOffset(4,28),UDim2.fromOffset(108,38),18)
 labels[index]=label
end
local hubShadow=disc(canvas,"HubShadow",UDim2.fromOffset(325,332),116,Color3.new(0,0,0));hubShadow.BackgroundTransparency=.4
local hub=disc(canvas,"Hub",UDim2.fromOffset(325,326),110,navy)
stroke(hub,gold,.25);gradient(hub,Color3.fromRGB(37,49,67),navy)
local spinCount=text(hub,"Spins","1 / 1\nSPIN",UDim2.fromScale(0,0),UDim2.fromScale(1,1),23)
-- A bordered diamond marker overlaps the rim; its lower tip is the landing tick.
local pointer=make("Frame",canvas,{Name="Pointer",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(325,112),Size=UDim2.fromOffset(30,30),Rotation=45,BackgroundColor3=gold,BorderSizePixel=0})
stroke(pointer,navy);gradient(pointer,Color3.fromRGB(255,238,186),gold)
local reveal=make("Frame",canvas,{Name="WinPresentation",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(325,611),Size=UDim2.fromOffset(594,98),BackgroundColor3=navy,BorderSizePixel=0})
make("UICorner",reveal,{CornerRadius=UDim.new(0,16)})
local revealBorder=stroke(reveal,muted,.65);gradient(reveal,Color3.fromRGB(28,39,56),navy)
local revealScale=make("UIScale",reveal,{Scale=1})
local revealTitle=text(reveal,"WinTitle","YOUR NEXT REWARD",UDim2.fromOffset(12,10),UDim2.fromOffset(570,22),14,muted)
local revealName=text(reveal,"WinReward","Five prizes. One free spin.",UDim2.fromOffset(14,35),UDim2.fromOffset(566,53),26)
revealName.TextScaled=true
local revealTextLimit=make("UITextSizeConstraint",revealName,{MinTextSize=18,MaxTextSize=26})
local status=text(canvas,"Status","Loading your spin…",UDim2.fromOffset(25,666),UDim2.fromOffset(600,38),16,muted)
local spin=button(canvas,"Spin","SPIN",UDim2.fromOffset(155,715),UDim2.fromOffset(340,52),green)
local close=button(canvas,"Exit","EXIT",UDim2.fromOffset(523,20),UDim2.fromOffset(100,42),red);close.TextSize=18
local tickTween
local previousSector=0
local spinningVisual=false
local rotationChanged=wheel:GetPropertyChangedSignal("Rotation"):Connect(function()
 -- Counter-rotation keeps names upright throughout the animation.
 for _,label in ipairs(labels) do label.Rotation=-wheel.Rotation end
 local sector=math.floor(wheel.Rotation/72)
 if spinningVisual and sector~=previousSector then
  if tickTween then tickTween:Cancel() end
  pointer.Rotation=33
  tickTween=TweenService:Create(pointer,TweenInfo.new(.1),{Rotation=45});tickTween:Play()
 end
 previousSector=sector
end)
local function showWin(result)
 local index=result.index
 local reward=Config.Rewards[index]
 local rare=reward.chance<=2.5
 local accent=accents[index]
 highlights[index].Transparency=0
 revealTitle.Text=rare and "RARE PULL · "..reward.label or "REWARD COLLECTED"
 revealTitle.TextColor3=accent
 revealName.Text=result.name or reward.label
 revealTextLimit.MaxTextSize=rare and 30 or 26
 revealBorder.Color=accent;revealBorder.Transparency=.1
 revealScale.Scale=rare and .88 or .96
 TweenService:Create(revealScale,TweenInfo.new(.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
 glowStroke.Color=accent;glowStroke.Transparency=rare and .05 or .45
 TweenService:Create(glowStroke,TweenInfo.new(rare and 1.5 or .6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,rare and 2 or 0,true),{Transparency=.85}):Play()
end
local state,pending,receivedAt=nil,false,os.clock()
local main,wasEnabled
local function visibility()
 local root=playerGui:FindFirstChild("CollegeHoopsUI")
 entry.Visible=not playerGui:GetAttribute("HoopsPanel") and not (root and root:GetAttribute("PanelOpen"))
end
local function render()
 local now=state and state.serverTime+(os.clock()-receivedAt) or 0
 local remaining=state and math.max(0,(state.nextDailySpinAt or 0)-now) or 0
 local available=state and state.ready and remaining==0
 spinCount.Text=(available and "1 / 1" or "0 / 1").."\nSPIN"
 spin.Text=pending and "SPINNING…" or available and "SPIN" or "SPIN USED"
 spin.Active=available==true and not pending;spin.Selectable=spin.Active;spin.AutoButtonColor=spin.Active
 spin.BackgroundTransparency=spin.Active and 0 or .5
 if not pending then
  if not state or not state.ready then status.Text="Loading your spin…"
  elseif remaining>0 then
   local result=state.dailyReward
   local reward=result and (result.name or ("$"..tostring(result.cash))) or "Reward collected"
   status.Text=reward..string.format(" · Next spin in %02d:%02d:%02d",math.floor(remaining/3600),math.floor(remaining/60)%60,math.floor(remaining)%60)
  else status.Text="Your free spin is ready!" end
 end
end
local function open()
 if playerGui:GetAttribute("HoopsPanel") and playerGui:GetAttribute("HoopsPanel")~="Daily" then return false end
 main=playerGui:FindFirstChild("CollegeHoopsUI")
 if main then wasEnabled=main.Enabled;main.Enabled=false end
 overlay.Visible=true;playerGui:SetAttribute("HoopsPanel","Daily");render();Focus.select(spin.Active and spin or close)
 return true
end
local function exit()
 overlay.Visible=false
 if main and main.Parent then main.Enabled=wasEnabled end
 if playerGui:GetAttribute("HoopsPanel")=="Daily" then playerGui:SetAttribute("HoopsPanel",nil) end
 Focus.select(entry)
end
local function fetch(action)
 local remote=RS:WaitForChild("HoopsShop",10)
 if not remote then return nil end
 for _=1,4 do
  local ok,result=pcall(function() return remote:InvokeServer(action) end)
  if ok and type(result)=="table" and result.code~="BUSY" then return result end
  task.wait(.5)
 end
 return nil
end
spin.Activated:Connect(function()
 if not spin.Active or pending then return end
 pending=true;render();status.Text="Spinning…"
 revealTitle.Text="DAILY SPIN";revealTitle.TextColor3=muted
 revealName.Text="Good luck!";revealTextLimit.MaxTextSize=26
 revealBorder.Color=muted;revealBorder.Transparency=.65
 for _,highlight in ipairs(highlights) do highlight.Transparency=1 end
 local result=fetch("DailySpin")
 if result then state=result;receivedAt=os.clock() end
 if result and result.code=="DAILY_SPUN" and result.dailyReward then
  wheel.Rotation=wheel.Rotation%360
  local target=Geometry.target(wheel.Rotation,result.dailyReward.index,#Config.Rewards,visualRandom:NextNumber())
  local tween=TweenService:Create(wheel,TweenInfo.new(5,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Rotation=target})
  spinningVisual=true
  tween:Play();tween.Completed:Wait()
  spinningVisual=false
  if tickTween then tickTween:Cancel() end
  pointer.Rotation=45
  showWin(result.dailyReward)
 end
 pending=false;render()
 if not result then status.Text="Could not reach the server. Reopen Daily to check your spin."
 elseif result.code=="DAILY_UNAVAILABLE" then status.Text="This reward is unavailable. Your spin has been kept." end
end)
entry.Activated:Connect(function()
 if open() then task.spawn(function() if not pending then local result=fetch("State");if result then state=result;receivedAt=os.clock();render() end end end) end
end)
close.Activated:Connect(exit)
local input=Input.InputBegan:Connect(function(key,processed)
 if overlay.Visible and not processed and (key.KeyCode==Enum.KeyCode.Escape or key.KeyCode==Enum.KeyCode.ButtonB) then exit() end
end)
local panelChanged=playerGui:GetAttributeChangedSignal("HoopsPanel"):Connect(visibility)
local function bind(root) if root.Name=="CollegeHoopsUI" then root:GetAttributeChangedSignal("PanelOpen"):Connect(visibility) end end
playerGui.ChildAdded:Connect(bind)
for _,root in ipairs(playerGui:GetChildren()) do bind(root) end
visibility()
task.spawn(function()
 while gui.Parent and (not state or not state.ready) do
  state=fetch("State");receivedAt=os.clock()
  if not state or not state.ready then task.wait(2) end
 end
 -- Once per login, including when today's spin has already been used.
 while gui.Parent and not open() do task.wait(1) end
 while gui.Parent do task.wait(1);if overlay.Visible then render() end end
end)
gui.Destroying:Connect(function() input:Disconnect();panelChanged:Disconnect();resize:Disconnect();rotationChanged:Disconnect();if tickTween then tickTween:Cancel() end end)
