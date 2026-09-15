-- One guided run. Only the server commits completion; replay never clears it.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local InputGate=require(script.Parent:WaitForChild("TutorialInputGate"))
local Rules=require(script.Parent:WaitForChild("TutorialRules"))
local MenuFocus=require(script.Parent:WaitForChild("MenuFocus"))
local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("HoopsTutorialUI") then return end
local function make(kind,parent,props)
 local item=Instance.new(kind)
 for key,value in pairs(props) do item[key]=value end
 item.Parent=parent
 return item
end
local gui=make("ScreenGui",playerGui,{Name="HoopsTutorialUI",ResetOnSpawn=false,DisplayOrder=90,
 ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local responseEvent=make("BindableEvent",gui,{Name="SquadResponse"})
local root=make("Frame",gui,{Name="Bounds",Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
local white=Color3.new(1,1,1)
local gate=InputGate.new(playerGui)
local shades={}
for i=1,4 do shades[i]=make("Frame",root,{Name="Shade"..i,BackgroundColor3=Color3.new(),BackgroundTransparency=.28,BorderSizePixel=0,Active=true,Visible=false,ZIndex=1}) end
local cardShadow=make("Frame",root,{Name="GuideShadow",BackgroundColor3=Color3.new(),BackgroundTransparency=.2,BorderSizePixel=0,Visible=false,ZIndex=2})
make("UICorner",cardShadow,{CornerRadius=UDim.new(0,18)})
local mint=Color3.fromRGB(100,229,170)
local function button(parent,name,text)
 local b=make("TextButton",parent,{Name=name,Text=text,Size=UDim2.fromOffset(190,40),
 BackgroundColor3=Color3.fromRGB(32,61,56),TextColor3=white,TextSize=17,Font=Enum.Font.GothamBold,BorderSizePixel=0,Selectable=true})
 make("UICorner",b,{CornerRadius=UDim.new(0,10)})
 return b
end
local entry=button(gui,"Tutorial","Tutorial")
local card=make("Frame",root,{Name="Guide",Size=UDim2.fromOffset(440,238),BackgroundColor3=Color3.fromRGB(17,25,35),BorderSizePixel=0,Visible=false,Active=true,ZIndex=3})
make("UICorner",card,{CornerRadius=UDim.new(0,16)})
make("UIStroke",card,{Color=mint,Thickness=2})
local scale=make("UIScale",card,{Scale=1})
local function label(name,y,h,size,color)
 return make("TextLabel",card,{Name=name,Position=UDim2.fromOffset(18,y),Size=UDim2.fromOffset(404,h),BackgroundTransparency=1,
 TextColor3=color,TextSize=size,Font=Enum.Font.GothamBold,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top})
end
local title=label("Title",14,28,19,mint)
local body=label("Instructions",48,132,17,white)
local skip=button(card,"SkipTutorial","Skip tutorial");skip.Position=UDim2.fromOffset(18,184)
local nextButton=button(card,"Continue","Next");nextButton.Position=UDim2.fromOffset(232,184)
local highlight=make("Frame",root,{Name="Highlight",BackgroundTransparency=1,Visible=false,Active=false,ZIndex=5})
make("UICorner",highlight,{CornerRadius=UDim.new(0,8)})
make("UIStroke",highlight,{Color=white,Thickness=5})
-- One solid silhouette, matching the reference: long thick shaft and a broad
-- triangular head. Geometry avoids font glyph padding, outlines and seams.
-- The zero-size pivot is the exact tip, so rotating never moves it off-target.
local arrowHead=make("Frame",root,{Name="ArrowHead",Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,Visible=false,ZIndex=6,Active=false})
local arrowScale=make("UIScale",arrowHead,{Scale=1})
local arrowLine=make("Frame",arrowHead,{Name="ArrowLine",Position=UDim2.fromOffset(-184,-15),Size=UDim2.fromOffset(145,30),BackgroundColor3=white,BorderSizePixel=0,Active=false})
-- Two-pixel horizontal rows stay at least one physical pixel tall at the
-- minimum 0.5 UI scale. Subpixel vertical strips can round to zero width in
-- Roblox, leaving only the shaft visible. Every row meets the shaft edge.
for i=0,39 do
 local y=-40+i*2
 local width=40-math.abs(y+1)+1
 make("Frame",arrowHead,{Name="ArrowTriangle"..i,Position=UDim2.fromOffset(-40,y),Size=UDim2.fromOffset(width,2),BackgroundColor3=white,BorderSizePixel=0,Active=false})
end
local main=playerGui:WaitForChild("CollegeHoopsUI")
local positions={"PG","SG","SF","PF","C"}
local active,done,saving=false,false,false
local step,comparison,lesson=1,1,1
local draft,lastTarget,lastVisible
local saveError=false
local function find(name)
 return main:FindFirstChild(name,true)
end
local function visible(item)
 if not item then return false end
 local node=item
 while node and node~=playerGui do
  if node:IsA("GuiObject") and not node.Visible then return false end
  if node:IsA("ScreenGui") and not node.Enabled then return false end
  node=node.Parent
 end
 return node==playerGui
end
local function start()
 if active then return end
 active=true;step=1;comparison=1;lesson=1;saveError=false
 -- Replay begins in the lobby without resetting or discarding the current squad.
 local canvas=find("SquadCanvas")
 if canvas then canvas.Parent.Visible=false end
 find("Build").Visible=true
 if not playerGui:GetAttribute("HoopsPanel") then playerGui:SetAttribute("HoopsPanel","Tutorial") end
end
local function complete()
 if saving then return end
 saving=true;saveError=false
 task.spawn(function()
  local success=done
  if not success then
   local remote=ReplicatedStorage:WaitForChild("HoopsShop",10)
   if remote then success=Rules.save(function() return remote:InvokeServer("CompleteTutorial") end,task.wait) end
  end
  saving=false
  if success then
   done=true;active=false;gate.clear();card.Visible=false;highlight.Visible=false
   for _,shade in ipairs(shades) do shade.Visible=false end
   cardShadow.Visible=false;arrowHead.Visible=false;arrowLine.Visible=false
   playerGui:SetAttribute("HoopsTutorialDone",true)
   if playerGui:GetAttribute("HoopsPanel")=="Tutorial" then playerGui:SetAttribute("HoopsPanel",nil) end
   MenuFocus.select(main:GetAttribute("PanelOpen") and find("Roll") or find("Build"))
  else saveError=true end
 end)
end
entry.Activated:Connect(start)
skip.Activated:Connect(complete)
nextButton.Activated:Connect(function()
 if saving then return end
 if saveError or step==8 then complete();return end
 if step>=3 and step<=6 then
  if step==3 and comparison<3 then comparison+=1
  elseif step==6 and lesson<3 then lesson+=1 else step+=1 end
 end
end)
playerGui:GetAttributeChangedSignal("HoopsTutorialReplay"):Connect(start)
responseEvent.Event:Connect(function(action,result)
 if type(result)~="table" or result.ready~=true then return end
 if result.rollState then draft=result.rollState end
 if active then step=Rules.advance(step,action,result) end
end)
local comparisons={
 {"Reroll","Reroll draws a NEW school/year and new candidates. Your accepted squad stays. This replaces HOF/non-college wheel results. Press Next; no reroll needed."},
 {"Refresh","Refresh redraws candidates within the CURRENT school/year. HOF/non-college wheel results STAY. Your accepted squad stays too. Press Next; no refresh needed."},
 {"Restart","Restart clears this squad but keeps every player you already accepted in your collection. Unaccepted wheel results are replaced. Press Next; do not restart now."},
}
local function content()
 local target
 nextButton.Visible=step>=3 and step~=7
 nextButton.Text=step==8 and "Let's play" or "Next"
 title.Text=string.format("TUTORIAL · %d / 8",step)
 if step==1 then
  body.Text="Press Build Your Squad to start a run. We'll walk through one complete squad, then leave you to play."
  target=find("Build")
 elseif step==2 then
  body.Text="Roll fills one candidate per position. Click a candidate to ACCEPT that player into your squad and collection. Unaccepted candidates count for nothing. Accept one now."
  target=find("Roll")
  if draft and draft.finished then
   body.Text="Your previous squad is complete. Press Restart to begin the practice run; your collected players stay yours."
   target=find("Restart")
  elseif draft and draft.pickAvailable then
   for _,pos in ipairs(positions) do if not draft.squad[pos] then target=find("Candidate"..pos);break end end
  end
 elseif step==3 then
  body.Text=comparisons[comparison][2];target=find(comparisons[comparison][1])
 elseif step==4 then
  body.Text="Chemistry: green lines mean same school, yellow means same year, blue means both. Matching players raise TEAM OVR without changing the cards. Press Next."
  target=find("CurrentPlayers")
 elseif step==5 then
  body.Text="Gold cards: every roll independently has a 5% base chance of gold, adding +5 OVR to that card. Luck upgrades can improve those odds. Press Next."
  target=find("Roll")
 elseif step==6 then
  title.Text="6 / 8 · RARE PLAYERS · "..lesson.." / 3"
  if lesson==1 then
   body.Text="HOF = Hall of Fame. Non-college = players who did not play college basketball. In the lobby, press Shop, choose either category, then a player's cash or Robux button to buy ELIGIBILITY — NOT the card. Press Next; no purchase needed now."
   target=find("RareWheel")
  elseif lesson==2 then
   body.Text="Buying only adds that player to the possible wheel results. Roll or Reroll gives the HOF and non-college wheels a chance to hit. A purchase does NOT guarantee a hit or put a card in your collection. Press Next."
   target=find("HOFResult")
  else
   body.Text="When a wheel hits, press its HOF or non-college RESULT CARD to accept the player into your squad and collection. Refresh keeps the result. Roll, Reroll and Restart replace it. Only Reroll and Restart ask for confirmation. Press Next."
   target=find("NonCollegeResult")
  end
 elseif step==7 then
  local count=0
  for _,pos in ipairs(positions) do if draft and draft.squad[pos] then count+=1 end end
  body.Text=string.format("%d / 5 accepted. Roll, then accept an empty position until all five are filled. Finish saves the run. Best Team keeps your highest-rated completed lineup; global Top 50 ranks that team.",count)
  target=find("Roll")
  if draft and draft.finished then
   body.Text="Press Finish to wrap up this saved run. If asked about a sixth man, press NO to keep five and finish this tutorial run. Best Team keeps your highest-rated completed lineup; global Top 50 ranks it."
   if visible(find("KeepTeam")) then target=find("KeepTeam")
   elseif draft.sixthAccepted and not draft.squad.SIXTH then target=find("SixthManChoice1") end
  elseif draft and draft.pickAvailable then
   for _,pos in ipairs(positions) do if not draft.squad[pos] then target=find("Candidate"..pos);break end end
  end
 elseif step==8 then
  title.Text="YOU'RE READY"
  body.Text="Daily spin: open Daily for your available spin.\nQuests reset every login.\nLuck upgrades improve rare odds.\n\nThat's it — this tutorial won't appear again unless you replay it."
 end
 if (step==2 or step==7) and draft and draft.pickAvailable and not draft.finished then
  for _,kind in ipairs({"HOF","NonCollege"}) do
   local result=find(kind.."Result")
   if draft.rare and draft.rare[kind] and visible(result) and result.Active then
    target=result
    body.Text="RARE HIT! Press the "..(kind=="HOF" and "HOF" or "non-college").." RESULT CARD: "..draft.rare[kind].name..". This accepts the player into your squad and collection. Refresh keeps this result; Roll, Reroll or Restart replace it."
    break
   end
  end
  if target and target.Name:match("^Candidate") then
   local pos=target.Name:gsub("^Candidate","")
   local candidate=draft.candidates and draft.candidates[pos]
   body.Text="Press the "..pos.." candidate"..(candidate and ": "..candidate.name or "").." to ACCEPT that player. Roll fills one candidate per position, but only the card you accept joins your squad and collection. Unaccepted candidates count for nothing."
  elseif target==find("Roll") then
   body.Text="Press ROLL to draw one candidate per position. Then press a candidate for an empty squad position to accept that player."
  end
 end
 if step==7 and target==find("KeepTeam") then
  body.Text="Press NO to keep your five-player team and finish this tutorial run. You can try a sixth man on a later run. Best Team keeps your highest-rated completed lineup; global Top 50 ranks it."
 elseif step==7 and target==find("SixthManChoice1") then
  body.Text="Press the highlighted SIXTH-MAN CARD to choose your sixth player. After it is saved, press FINISH to return to the lobby."
 end
 if step>1 and step<8 and not main:GetAttribute("PanelOpen") then
  nextButton.Visible=false
  target=find("Build");body.Text="Press BUILD YOUR SQUAD to continue where you left off. Your accepted players are saved."
 end
 if saving then body.Text="Saving tutorial completion…" end
 if saveError then body.Text="Couldn't save tutorial completion. Check your connection and press Retry. We won't mark it complete until the server saves it.";nextButton.Visible=true;nextButton.Text="Retry" end
 return target
end
-- Resolve named instances, then follow their live absolute geometry every frame.
-- Convert to our safe-area origin so GUI insets and ancestor UIScales are included.
local heartbeat=RunService.RenderStepped:Connect(function()
 local camera=workspace.CurrentCamera
 local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
 local factor=math.clamp(math.min(viewport.X/1280,viewport.Y/720),.5,1)
 scale.Scale=factor
 -- LobbyButtons owns the Tutorial / gear layout together.
 local panel=playerGui:GetAttribute("HoopsPanel")
 entry.Visible=not active and not panel and not main:GetAttribute("PanelOpen")
 if active and not panel then playerGui:SetAttribute("HoopsPanel","Tutorial");panel="Tutorial" end
 local show=active and panel=="Tutorial"
 card.Visible=show
 if not show then
  highlight.Visible=false;arrowLine.Visible=false;arrowHead.Visible=false;cardShadow.Visible=false
  for _,shade in ipairs(shades) do shade.Visible=false end
  -- A required rare-action confirmation belongs to this step. Its Yes/No
  -- and the celebration above us retain input while background controls stay gated.
  if active and panel=="RareConfirm" then
   local allowed={}
   for _,button in ipairs(playerGui:GetDescendants()) do
    if button:IsA("GuiButton") then
     local screen=button:FindFirstAncestorOfClass("ScreenGui")
     if screen and (screen.DisplayOrder>=100 or screen.Name=="HoopsRareActionConfirm" and panel=="RareConfirm") then allowed[button]=true end
    end
   end
   gate.update(allowed)
  else gate.clear() end
  lastVisible=false;return
 end
 local target=content()
 -- The spotlight, arrow and input permission always identify the SAME button.
 local arrowTarget=nextButton.Visible and nextButton or target
 target=arrowTarget
 highlight.Visible=not saving and visible(target)
 if highlight.Visible then
  highlight.Position=UDim2.fromOffset(target.AbsolutePosition.X-root.AbsolutePosition.X-4,target.AbsolutePosition.Y-root.AbsolutePosition.Y-4)
  highlight.Size=UDim2.fromOffset(target.AbsoluteSize.X+8,target.AbsoluteSize.Y+8)
 end
 local size=root.AbsoluteSize
 local w,h=440*factor,238*factor
 local pad=12*factor
 -- Pick the corner with least overlap with the target. No button coordinates.
 local choices={Vector2.new(size.X-w-pad,pad),Vector2.new(pad,pad),Vector2.new(size.X-w-pad,size.Y-h-pad),Vector2.new(pad,size.Y-h-pad)}
 local best,score=choices[1],math.huge
 for _,point in ipairs(choices) do
  local overlap=0
  if highlight.Visible then
   local p=highlight.AbsolutePosition-root.AbsolutePosition;local s=highlight.AbsoluteSize
   overlap=math.max(0,math.min(point.X+w,p.X+s.X)-math.max(point.X,p.X))*math.max(0,math.min(point.Y+h,p.Y+s.Y)-math.max(point.Y,p.Y))
  end
  if overlap<score then best=point;score=overlap end
 end
 -- Next lives inside the guide: keep its placement stable rather than trying
 -- to dodge our own button, which would oscillate between corners each frame.
 if arrowTarget==nextButton then best=choices[1] end
 card.Position=UDim2.fromOffset(math.max(0,best.X),math.max(0,best.Y))
 cardShadow.Visible=true
 cardShadow.Position=UDim2.fromOffset(math.max(0,best.X)+6*factor,math.max(0,best.Y)+8*factor)
 cardShadow.Size=UDim2.fromOffset(w,h)
 local holeX,holeY,holeW,holeH=0,0,0,0
 if highlight.Visible then
  local position=target.AbsolutePosition-root.AbsolutePosition
  local bounds=target.AbsoluteSize
  holeX,holeY,holeW,holeH=position.X,position.Y,bounds.X,bounds.Y
  highlight.Position=UDim2.fromOffset(holeX-5,holeY-5)
  highlight.Size=UDim2.fromOffset(holeW+10,holeH+10)
 end
 -- The guide (including Next) is already above the scrim. A hole there
 -- unnecessarily splits the shadow across the entire screen.
 local shadeW,shadeH=holeW,holeH
 if target==nextButton then shadeW,shadeH=0,0 end
 for i,rect in ipairs(Rules.shades(size.X,size.Y,holeX,holeY,shadeW,shadeH)) do
  shades[i].Visible=rect[3]>0 and rect[4]>0
  shades[i].Position=UDim2.fromOffset(rect[1],rect[2]);shades[i].Size=UDim2.fromOffset(rect[3],rect[4])
 end
 local allowed={[skip]=true}
 if not saving and arrowTarget and visible(arrowTarget) then allowed[arrowTarget]=true end
 for _,button in ipairs(playerGui:GetDescendants()) do
  if button:IsA("GuiButton") then
   local screen=button:FindFirstAncestorOfClass("ScreenGui")
   if screen and screen.DisplayOrder>=100 then allowed[button]=true end
  end
 end
 gate.update(allowed)
 arrowLine.Visible=not saving and visible(arrowTarget)
 arrowHead.Visible=arrowLine.Visible
 if arrowLine.Visible then
  local p=arrowTarget.AbsolutePosition-root.AbsolutePosition
  local z=arrowTarget.AbsoluteSize
  local center=card.AbsolutePosition-root.AbsolutePosition+card.AbsoluteSize/2
  -- Bold white arrow outside the target, ending at its live edge.
  if arrowTarget==nextButton then center=Vector2.new(p.X+z.X/2,p.Y+z.Y+184*factor) end
  local x,y=Rules.arrow(center.X,center.Y,p.X,p.Y,z.X,z.Y)
  local tip=Vector2.new(x,y)
  local delta=tip-center
  local direction=delta.Magnitude>0 and delta.Unit or Vector2.new(0,1)
  local rotation=math.deg(math.atan2(direction.Y,direction.X))
  arrowHead.Position=UDim2.fromOffset(tip.X,tip.Y)
  arrowHead.Rotation=rotation
  arrowScale.Scale=factor
 end
 if arrowTarget~=lastTarget or not lastVisible then
  MenuFocus.select(visible(arrowTarget) and arrowTarget:IsA("GuiButton") and arrowTarget.Selectable and arrowTarget or skip)
 end
 lastTarget=arrowTarget;lastVisible=true
end)
gui.Destroying:Connect(function() heartbeat:Disconnect();gate.clear() end)
task.spawn(function()
 local remote=ReplicatedStorage:WaitForChild("HoopsShop")
 while gui.Parent do
  local ok,result=pcall(function() return remote:InvokeServer("State") end)
  if ok and Rules.ready(result) then
   done=done or result.tutorialDone;draft=draft or result.rollState
   playerGui:SetAttribute("HoopsTutorialDone",done)
   if not done then start() end
   return
  end
  task.wait(2)
 end
end)
