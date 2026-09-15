local fs=require('@lune/fs')
local luau=require('@lune/luau')
local serde=require('@lune/serde')
local T=require('../src/ServerScriptService/Shop/Transactions')
for _,path in ipairs({
 'src/StarterPlayer/StarterPlayerScripts/Tutorial.client.luau',
 'src/StarterPlayer/StarterPlayerScripts/SettingsUI.client.luau',
 'src/StarterPlayer/StarterPlayerScripts/RollController.luau',
 'src/StarterPlayer/StarterPlayerScripts/DailySpinUI.client.luau',
 'src/ServerScriptService/ShopServer.server.luau',
}) do luau.compile(fs.readFile(path)) end
local fresh=T.migrate(T.newProfile(123))
assert(fresh.tutorialDone==false)
assert(T.startSession(fresh,'first',100).tutorialDone==false)
local before=serde.encode('json',fresh)
local completed,code=T.completeTutorial(fresh)
assert(completed.tutorialDone==true and code=='TUTORIAL_COMPLETED')
assert(serde.encode('json',fresh)==before,'Pure function must not mutate input')
assert(T.startSession(completed,'second',200).tutorialDone==true)
local rejoined=T.startSession(serde.decode('json',serde.encode('json',completed)),'rejoin',300)
assert(rejoined.tutorialDone==true)
-- Same completion in two serialized commit callbacks, including their checkpoint.
local function commit(profile)
 return T.completeTutorial(T.advanceSession(profile,'rejoin',25))
end
local once=commit(rejoined)
local twice=commit(serde.decode('json',serde.encode('json',once)))
local function equal(a,b)
 if type(a)~='table' then return a==b end
 if type(b)~='table' then return false end
 for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
assert(equal(once,twice),'Duplicate completion commits must be idempotent')
assert(once.balance==123 and once.sessionSeconds==25 and once.tutorialDone)
assert(equal(T.completeTutorial(rejoined),T.completeTutorial(rejoined)),'UpdateAsync callback retry')
print('PASS: tutorial defaults false; survives session reset and serde rejoin; pure completion; duplicate commits idempotent; five integration scripts compile')

local Rules=require('../src/StarterPlayer/StarterPlayerScripts/TutorialRules')
for _,reply in ipairs({false,'bad',{},{ready=false,tutorialDone=false},{ready=true},{ready=true,tutorialDone='false'}}) do
 assert(not Rules.ready(reply))
 assert(not Rules.saved(reply))
end
assert(not Rules.ready(nil))
for _,code in ipairs({'BUSY','UNAVAILABLE','STALE_SESSION','INVALID','READY'}) do
 assert(not Rules.saved({ready=true,tutorialDone=true,code=code}))
end
assert(not Rules.saved({ready=true,tutorialDone=false,code='TUTORIAL_COMPLETED'}))
local calls,waits=0,0
assert(not Rules.save(function() calls+=1;error('offline') end,function() waits+=1 end))
assert(calls==4 and waits==3,'Failed saves stop retrying and leave completion false')
local good={ready=true,tutorialDone=true,code='TUTORIAL_COMPLETED'}
calls=0
assert(Rules.save(function()
 calls+=1
 if calls==1 then error('timeout after commit') end
 if calls==2 then return {ready=true,code='BUSY',tutorialDone=false} end
 return good
end,function() end))
assert(calls==3,'A retry can recover after an ambiguous save or BUSY response')
assert(Rules.save(function() return good end,function() error('Successful save must not wait') end))
for _,code in ipairs({'BUSY','LOCKED','FILLED','ROLL_REQUIRED','UNAVAILABLE','INVALID','EMPTY'}) do
 for _,action in ipairs({'RollPlayer','ChooseRare','RollState'}) do
  for step=1,8 do assert(Rules.advance(step,action,{ready=true,code=code,rollState={}})==step) end
 end
end
assert(Rules.advance(1,'RollState',{ready=true,code='READY',rollState={}})==2)
assert(Rules.advance(2,'ChooseRare',{ready=true,code='ROLLED',rollState={}})==3)
assert(Rules.advance(2,'RollPlayer',{ready=true,code='FINISHED',rollState={}})==3)
assert(Rules.advance(7,'Exit',{ready=true,rollState={finished=true}})==7,'Exit is not Finish')
assert(Rules.advance(7,'TutorialRunFinished',{ready=true,rollState={finished=false}})==7)
assert(Rules.advance(7,'TutorialRunFinished',{ready=true,rollState={finished=true}})==8)
assert(Rules.advance(2,'RollPlayer',nil)==2)
assert(Rules.advance(2,'RollPlayer',{ready=false,code='ROLLED',rollState={}})==2)
-- The same live button moves/resizes mid-tutorial. Every arrow tip must remain
-- on its boundary, including horizontal/vertical and coincident-center cases.
for _,factor in ipairs({.5,.65,1}) do
 for _,origin in ipairs({{20,100},{510,240},{80,470}}) do
  local x,y,w,h=origin[1],origin[2],150*factor,60*factor
  for _,center in ipairs({{0,0},{900,700},{x+w/2,y-100},{x+w/2,y+h/2},{x-100,y+h/2}}) do
   local ax,ay=Rules.arrow(center[1],center[2],x,y,w,h)
   local eps=.0001
   assert(ax>=x-eps and ax<=x+w+eps and ay>=y-eps and ay<=y+h+eps)
   assert(math.abs(ax-x)<eps or math.abs(ax-x-w)<eps or math.abs(ay-y)<eps or math.abs(ay-y-h)<eps)
  end
 end
end
for _,name in ipairs({'TutorialRules','RareActionRules','RareActionConfirm','SquadCompletion','LobbyButtons.client'}) do
 luau.compile(fs.readFile('src/StarterPlayer/StarterPlayerScripts/'..name..'.luau'))
end
print('PASS: tutorial offline/malformed/BUSY/stale-save failures, retry recovery, rejected picks, actual Finish-only completion, moving/resized arrow targets and integration compilation')

-- Execute the actual client with a small GUI/service harness. This exercises
-- button wiring, panel pauses and save failures, beyond compiling the script.
local InputGate=require('../src/StarterPlayer/StarterPlayerScripts/TutorialInputGate')
local roblox=require('@lune/roblox')
local function clientHarness(saved)
 local objects,tasks={},{}
 local function signal()
  local callbacks={}
  return {Connect=function(_,fn) table.insert(callbacks,fn);return {Disconnect=function() end} end,
   Fire=function(_,...) for _,fn in ipairs(callbacks) do fn(...) end end}
 end
 local function new(class)
  local o={ClassName=class,Name=class,Visible=true,Enabled=true,Active=true,Selectable=true,Interactable=true,DisplayOrder=0,
   AbsolutePosition=roblox.Vector2.new(0,0),AbsoluteSize=roblox.Vector2.new(1280,720),
   Activated=signal(),Destroying=signal(),Event=signal(),attributes={},signals={}}
  function o:IsA(kind)
   return kind==self.ClassName or kind=='GuiButton' and self.ClassName=='TextButton'
    or kind=='GuiObject' and (self.ClassName=='Frame' or self.ClassName=='TextButton' or self.ClassName=='TextLabel')
  end
  function o:FindFirstChild(name,recursive)
   for _,child in ipairs(objects) do
    if child.Name==name then
     local parent=child.Parent
     while parent do
      if parent==self then return child end
      if not recursive then break end
      parent=parent.Parent
     end
    end
   end
  end
  function o:GetDescendants()
   local descendants={}
   for _,object in ipairs(objects) do
    local parent=object.Parent
    while parent do
     if parent==self then table.insert(descendants,object);break end
     parent=parent.Parent
    end
   end
   return descendants
  end
  function o:FindFirstAncestorOfClass(kind)
   local parent=self.Parent
   while parent do if parent.ClassName==kind then return parent end;parent=parent.Parent end
  end
  function o:GetPropertyChangedSignal(name) return self:GetAttributeChangedSignal('property:'..name) end
  function o:WaitForChild(name) return assert(self:FindFirstChild(name),'Missing mock '..name) end
  function o:GetAttribute(name) return self.attributes[name] end
  function o:GetAttributeChangedSignal(name)
   self.signals[name]=self.signals[name] or signal();return self.signals[name]
  end
  function o:SetAttribute(name,value)
   if self.attributes[name]==value then return end
   self.attributes[name]=value;self:GetAttributeChangedSignal(name):Fire()
  end
  function o:Fire(...) self.Event:Fire(...) end
  table.insert(objects,o);return o
 end
 local function child(class,parent,name)
  local o=new(class);o.Parent=parent;o.Name=name;return o
 end
 local pg=new('PlayerGui')
 local main=child('ScreenGui',pg,'CollegeHoopsUI')
 local background=child('Frame',main,'Background')
 child('Frame',background,'SquadCanvas')
 local build=child('TextButton',main,'Build')
 build.AbsolutePosition=roblox.Vector2.new(320,580);build.AbsoluteSize=roblox.Vector2.new(200,60)
 child('TextButton',background,'Roll')
 local positions={'PG','SG','SF','PF','C'}
 for _,pos in ipairs(positions) do child('TextButton',background,'Candidate'..pos) end
 for _,name in ipairs({'Restart','Refresh','Reroll','KeepTeam','SixthManChoice1','HOFResult','NonCollegeResult','CurrentPlayers','RareWheel'}) do
  child('TextButton',background,name)
 end
 local rs=new('ReplicatedStorage')
 local remote=child('RemoteFunction',rs,'HoopsShop')
 local completionReply={ready=true,tutorialDone=true,code='TUTORIAL_COMPLETED'}
 local completionCalls=0
 function remote:InvokeServer(action)
  if action=='State' then return {ready=true,tutorialDone=saved,code='READY'} end
  assert(action=='CompleteTutorial');completionCalls+=1
  if completionReply=='error' then error('offline') end
  return completionReply
 end
 local frame=signal()
 local source=luau.load(fs.readFile('src/StarterPlayer/StarterPlayerScripts/Tutorial.client.luau'),{environment={
  Instance={new=new},UDim2=roblox.UDim2,UDim=roblox.UDim,Vector2=roblox.Vector2,Color3=roblox.Color3,Enum=roblox.Enum,
  script={Parent={WaitForChild=function(_,name) return name end}},
  require=function(name) return name=='TutorialRules' and Rules or name=='TutorialInputGate' and InputGate or {select=function() end} end,
  workspace={CurrentCamera={ViewportSize=roblox.Vector2.new(1280,720)}},
  game={GetService=function(_,name)
   if name=='Players' then return {LocalPlayer={WaitForChild=function() return pg end}} end
   if name=='ReplicatedStorage' then return rs end
   if name=='RunService' then return {RenderStepped=frame} end
   error(name)
  end},
  task={spawn=function(fn) table.insert(tasks,coroutine.create(fn)) end,wait=function() coroutine.yield() end},
 }})
 source()
 local function pump()
  for _=1,8 do
   for _,co in ipairs(tasks) do
    if coroutine.status(co)~='dead' then local ok,err=coroutine.resume(co);assert(ok,err) end
   end
  end
  frame:Fire()
 end
 local function get(name) return assert(pg:FindFirstChild(name,true),'Missing '..name) end
 pump()
 return {pg=pg,main=main,build=build,get=get,pump=pump,frame=frame,add=child,
  reply=function(value) completionReply=value end,calls=function() return completionCalls end,
  click=function(name) local button=get(name);if button.Interactable and button.Active then button.Activated:Fire() end;pump() end}
end
local client=clientHarness(false)
assert(client.get('Guide').Visible and client.get('ArrowHead').Visible,'First-time guide and arrow show')
client.build.AbsolutePosition=roblox.Vector2.new(700,440)
client.build.AbsoluteSize=roblox.Vector2.new(250,80)
client.frame:Fire()
local tip=client.get('ArrowHead').Position
assert(tip.X.Offset>=700 and tip.X.Offset<=950 and tip.Y.Offset>=440 and tip.Y.Offset<=520,'Actual client follows moved button')
client.pg:SetAttribute('HoopsPanel','Settings');client.frame:Fire()
assert(not client.get('Guide').Visible and not client.get('ArrowHead').Visible,'Menu pauses actual guide')
client.pg:SetAttribute('HoopsPanel',nil);client.frame:Fire()
assert(client.get('Guide').Visible,'Guide resumes after menu')
client.reply('error');client.click('SkipTutorial')
assert(client.calls()==4 and client.get('Guide').Visible and client.get('Continue').Text=='Retry')
assert(client.pg:GetAttribute('HoopsTutorialDone')~=true,'Failed skip never claims persistence')
client.reply({ready=true,tutorialDone=true,code='TUTORIAL_COMPLETED'});client.click('Continue')
assert(client.pg:GetAttribute('HoopsTutorialDone')==true and not client.get('Guide').Visible,'Retry dismisses after server save')
local returning=clientHarness(true)
assert(not returning.get('Guide').Visible and returning.calls()==0,'Returning player is left alone')
returning.pg:SetAttribute('HoopsTutorialReplay',1);returning.pump()
assert(returning.get('Guide').Visible,'Settings replay starts without clearing done')
returning.click('SkipTutorial')
assert(returning.calls()==0 and returning.pg:GetAttribute('HoopsTutorialDone')==true,'Replay skip retains permanent completion')
print('PASS: actual tutorial client startup, live arrow movement, panel pause/resume, failed skip, Retry recovery, returning-player suppression and Settings replay')
local run=clientHarness(false)
local response=run.get('SquadResponse')
local draft={pickAvailable=true,squad={},candidates={PG={id='pg',name='College Prospect'}},rare={HOF={id='hof',name='Hall of Famer'}}}
run.get('Background').Visible=true;run.build.Visible=false
run.main:SetAttribute('PanelOpen',true)
response:Fire('RollState',{ready=true,code='READY',rollState=draft});run.pump()
assert(run.get('Instructions').Text:find('HOF RESULT CARD',1,true),'Actual tutorial points to available HOF hit')
response:Fire('ChooseRare',{ready=true,code='LOCKED',rollState=draft});run.pump()
assert(run.get('Title').Text:find('2 / 8',1,true),'Rejected rare acceptance cannot progress')
response:Fire('ChooseRare',{ready=true,code='ROLLED',rollState=draft});run.pump()
assert(run.get('Instructions').Text:find('Reroll',1,true))
run.click('Continue');assert(run.get('Instructions').Text:find('Refresh',1,true))
run.click('Continue');assert(run.get('Instructions').Text:find('Restart',1,true))
run.click('Continue');assert(run.get('Instructions').Text:find('Chemistry',1,true))
run.click('Continue');assert(run.get('Instructions').Text:find('Gold cards',1,true))
run.click('Continue');assert(run.get('Instructions').Text:find('ELIGIBILITY',1,true))
run.click('Continue');assert(run.get('Instructions').Text:find('does NOT guarantee',1,true))
run.click('Continue');assert(run.get('Instructions').Text:find('RESULT CARD',1,true))
run.click('Continue');assert(run.get('Title').Text:find('7 / 8',1,true))
run.main:SetAttribute('PanelOpen',false);run.pump()
assert(run.get('Instructions').Text:find('BUILD YOUR SQUAD',1,true) and not run.get('Continue').Visible)
assert(run.pg:GetAttribute('HoopsTutorialDone')~=true,'Leaving an unfinished run does not complete tutorial')
run.main:SetAttribute('PanelOpen',true)
draft.finished=true
response:Fire('TutorialRunFinished',{ready=true,rollState=draft});run.pump()
assert(run.get('Title').Text=='YOU\'RE READY' and run.get('Continue').Text=="Let's play")
run.click('Continue')
assert(run.pg:GetAttribute('HoopsTutorialDone')==true and run.calls()==1)
print('PASS: actual client full ordered lesson, rare-hit target, rejected rare pick, Exit/resume and completed-run save')

local locked=clientHarness(false)
assert(locked.build.Interactable and locked.get('SkipTutorial').Interactable)
for _,name in ipairs({'Roll','Restart','Refresh','Reroll','CandidatePG','HOFResult'}) do
 assert(not locked.get(name).Interactable and not locked.get(name).Selectable,'Off-step control must reject touch/mouse/controller: '..name)
end
local wrongClicks=0
locked.get('Restart').Activated:Connect(function() wrongClicks+=1 end)
locked.click('Restart');assert(wrongClicks==0,'Off-step click cannot invoke its handler')
assert(locked.get('ArrowLine').BackgroundColor3==roblox.Color3.new(1,1,1))
assert(locked.get('ArrowLine').Size.Y.Offset==30 and locked.get('ArrowHead').ClassName=='Frame','Solid thick geometric arrow')
assert(locked.get('ArrowTriangle19').Size.X.Offset==40 and locked.get('ArrowTriangle20').Size.X.Offset==40,'Triangle apex reaches the target tip')
for i=0,39 do
 local row=locked.get('ArrowTriangle'..i)
 assert(row.Position.X.Offset==-40 and row.Position.Y.Offset==-40+i*2)
 for _,factor in ipairs({.5,.65,1}) do
  assert(row.Size.X.Offset*factor>=1 and row.Size.Y.Offset*factor>=1,'Arrowhead rows must not collapse below a physical pixel')
 end
 assert(row.Size.X.Offset==locked.get('ArrowTriangle'..(39-i)).Size.X.Offset,'Arrowhead is symmetric')
end
assert(locked.get('GuideShadow').Visible and locked.get('Shade1').Visible)
-- Advance: only the highlighted rare result and Skip can be pressed.
locked.get('Background').Visible=true;locked.build.Visible=false;locked.main:SetAttribute('PanelOpen',true)
locked.get('SquadResponse'):Fire('RollState',{ready=true,code='READY',rollState={
 pickAvailable=true,squad={},candidates={},rare={HOF={id='h',name='Rare Player'}}}})
locked.pump()
assert(locked.get('HOFResult').Interactable and not locked.get('CandidatePG').Interactable)
locked.get('SquadResponse'):Fire('ChooseRare',{ready=true,code='ROLLED',rollState={pickAvailable=false,squad={},rare={}}})
locked.pump()
assert(locked.get('Continue').Interactable and not locked.get('Reroll').Interactable,'Explanation does not allow spending a reroll')
-- Required confirmation is permitted, but background remains blocked.
local confirm=locked.add('ScreenGui',locked.pg,'HoopsRareActionConfirm');confirm.DisplayOrder=95
local yes=locked.add('TextButton',confirm,'Yes')
local no=locked.add('TextButton',confirm,'No')
local celebration=locked.add('ScreenGui',locked.pg,'Celebration');celebration.DisplayOrder=100
local dismiss=locked.add('TextButton',celebration,'Dismiss')
locked.pg:SetAttribute('HoopsPanel','RareConfirm');locked.pump()
assert(yes.Interactable and no.Interactable and dismiss.Interactable)
assert(not locked.get('Roll').Interactable and not locked.get('Guide').Visible)
locked.pg:SetAttribute('HoopsPanel','Tutorial');locked.pump()
assert(locked.get('Continue').Interactable and dismiss.Interactable and not yes.Interactable)
locked.click('SkipTutorial')
assert(locked.get('Roll').Interactable and locked.get('Roll').Selectable,'Skip restores normal controls')
assert(not locked.get('Shade1').Visible and not locked.get('GuideShadow').Visible)
-- Full shade area covers everything outside the live hole, without overlap.
for _,rect in ipairs({{20,100,150,60},{700,440,250,80},{-20,-10,100,70},{1200,680,200,100},{0,0,0,0}}) do
 local pieces=Rules.shades(1280,720,table.unpack(rect))
 local area=0
 for _,piece in ipairs(pieces) do
  assert(piece[3]>=0 and piece[4]>=0)
  area+=piece[3]*piece[4]
 end
 local l=math.clamp(rect[1],0,1280);local t=math.clamp(rect[2],0,720)
 local r=math.clamp(rect[1]+rect[3],l,1280);local b=math.clamp(rect[2]+rect[4],t,720)
 assert(area==1280*720-(r-l)*(b-t),'Shade must cover exactly the complement of the button')
end
luau.compile(fs.readFile('src/StarterPlayer/StarterPlayerScripts/TutorialInputGate.luau'))
print('PASS: large white arrows, shade coverage, actual off-step click rejection, controller exclusion, step transitions, modal/celebration exceptions and Skip restores input')

-- Fractional button positions/sizes from UIScale must not create raster seams.
local shadeFunction=Rules.shades
Rules.saved({ready=true,tutorialDone=true,code='TUTORIAL_COMPLETED'})
assert(Rules.shades==shadeFunction,'Saving must not replace the corrected geometry function')
for _,hole in ipairs({{12.25,34.75,80.6,22.3},{-2.5,7.2,45.7,20.9},{110.8,64.2,40.6,30.8},{33.3,21.6,0,0}}) do
 local pieces=Rules.shades(128,80,table.unpack(hole))
 for _,piece in ipairs(pieces) do
  for _,value in ipairs(piece) do assert(value%1==0,'Every shared edge uses whole pixels') end
 end
 for y=0,79 do for x=0,127 do
  local hits=0
  for _,p in ipairs(pieces) do
   if x>=p[1] and x<p[1]+p[3] and y>=p[2] and y<p[2]+p[4] then hits+=1 end
  end
  local inside=hole[3]>0 and hole[4]>0 and x>=math.floor(hole[1]) and x<math.ceil(hole[1]+hole[3]) and y>=math.floor(hole[2]) and y<math.ceil(hole[2]+hole[4])
  assert(hits==(inside and 0 or 1),'No bright gaps or double-dark overlap outside spotlight')
 end end
end
local reading=clientHarness(false)
reading.get('Background').Visible=true;reading.main:SetAttribute('PanelOpen',true)
reading.get('SquadResponse'):Fire('RollState',{ready=true,code='READY',rollState={}})
reading.get('SquadResponse'):Fire('RollPlayer',{ready=true,code='ROLLED',rollState={}})
reading.pump()
assert(reading.get('Shade1').Visible and reading.get('Shade1').Size==roblox.UDim2.fromOffset(1280,720))
for i=2,4 do assert(not reading.get('Shade'..i).Visible,'Reading steps use a single continuous shadow') end
print('PASS: fractional spotlight edges have no gaps/overlaps; reading steps use one continuous scrim; save preserves geometry')
