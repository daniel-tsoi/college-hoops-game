local Controller = {}
function Controller.attach(ui)

 local MenuFocus = require(script.Parent:WaitForChild("MenuFocus"))
 -- Navigation must work even while replicated gameplay modules are loading.
 local request
 ui.buttons.Exit.Activated:Connect(function()
  ui.background.Visible=false; ui.build.Visible=true; MenuFocus.select(ui.build)
 end)
 ui.build.Activated:Connect(function()
  ui.build.Visible=false; ui.background.Visible=true; MenuFocus.select(ui.buttons.Roll)
  if request then request("RollState") else ui.status.Text="Loading squad controls…" end
 end)
 local shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
 local Portrait=require(shared:WaitForChild("CardPortrait"))
 local positions={"PG","SG","SF","PF","C"}
 local state, selected, pending = nil,nil,false
 local message="Choose ONE player, then press Roll for the next college team."
 ui.canvas.CandidatesTitle.Position=UDim2.fromOffset(340,470)
 ui.canvas.CandidatesTitle.Size=UDim2.fromOffset(574,36)
 ui.canvas.CandidatesTitle.Font=Enum.Font.GothamBlack
 ui.canvas.CandidatesTitle.TextScaled=true
 local titleLimit=Instance.new("UITextSizeConstraint")
 titleLimit.MaxTextSize=30; titleLimit.MinTextSize=16; titleLimit.Parent=ui.canvas.CandidatesTitle
 ui.canvas.SchoolSeason.Font=Enum.Font.GothamBlack
 ui.canvas.SchoolSeason.TextSize=24
 ui.buttons.Roll.Size=UDim2.fromOffset(240,88)
 ui.buttons.Roll.Font=Enum.Font.GothamBlack
 ui.buttons.Roll.TextSize=21
 ui.buttons.Roll.TextWrapped=true
 ui.buttons.Refresh.Text="REFRESH PLAYERS"
 ui.reveal.Position=UDim2.fromOffset(24,552)
 local function decorate(parent,pos,card,compact)
  parent.Text=""
  local header=parent:FindFirstChild("CardHeading")
  if not header then
   header=Instance.new("TextLabel");header.Name="CardHeading";header.BackgroundTransparency=1
   header.Size=UDim2.new(1,-8,0,18);header.Position=UDim2.fromOffset(4,0);header.Font=Enum.Font.GothamBold
   header.TextSize=compact and 10 or 12;header.TextColor3=Color3.fromRGB(240,244,249);header.Parent=parent
   local name=header:Clone();name.Name="CardName";name.Position=UDim2.new(0,4,1,-31);name.Size=UDim2.new(1,-8,0,30)
   name.TextWrapped=true;name.TextSize=compact and 11 or 13;name.Parent=parent
  end
  header.Text=pos
  parent.CardName.Text=card and (card.name.." · "..card.overall.." OVR") or "EMPTY"
  header.TextColor3=card and card.gold and Color3.fromRGB(255,207,89) or Color3.fromRGB(240,244,249)
  Portrait.mount(parent,card,UDim2.new(.5,0,0,18),UDim2.fromOffset(compact and 60 or 98,compact and 51 or 85))
 end
 for i,button in ipairs(ui.candidates) do
  button.Position=UDim2.fromOffset(340+(i-1)*116,509)
  button.Size=UDim2.fromOffset(110,100)
 end
 ui.status.Size=UDim2.fromOffset(574,46)
 local wheel=require(script.Parent:WaitForChild("RareWheelView")).mount(ui.canvas,decorate,function(kind)
  request("ChooseRare",kind)
 end)
 local function render()
  local draft=state and state.rollState
  local filled,total=0,0
  for i,pos in ipairs(positions) do
   local card=draft and draft.squad[pos]
   if card then filled+=1; total+=card.overall end
   decorate(ui.slots[i],pos,card,false)
   ui.slots[i].TextSize=16
   ui.slots[i].TextColor3=card and card.gold and Color3.fromRGB(255,207,89) or Color3.fromRGB(241,244,249)
   local candidate=draft and draft.candidates[pos]
   decorate(ui.candidates[i],pos,candidate,true)
   ui.candidates[i].TextSize=15
   ui.candidates[i].TextColor3=candidate and candidate.gold and Color3.fromRGB(255,207,89) or Color3.fromRGB(241,244,249)
   ui.candidates[i].BackgroundColor3=selected==pos and Color3.fromRGB(43,56,74) or Color3.fromRGB(25,33,46)
   local canPick=not pending and draft~=nil and draft.pickAvailable and not draft.finished and not draft.squad[pos]
   ui.candidates[i].Active=canPick == true
   ui.candidates[i].Selectable=canPick == true
   ui.candidates[i].AutoButtonColor=canPick == true
   ui.candidates[i].BackgroundTransparency=canPick and 0.05 or 0.65
  end
  local team=draft and draft.team
  local teamLabel=team and (string.upper(team.school).." · "..team.season) or "COLLEGE TEAM · YEAR"
  ui.canvas.CandidatesTitle.Text=teamLabel
  ui.canvas.SchoolSeason.Text=teamLabel
  ui.buttons.Roll.Text="ROLL"
  ui.canvas.Overall.Text="TEAM OVR: "..(filled>0 and tostring(math.floor(total/filled+0.5)) or "—")
  ui.lineup.Text=string.format("ROLLED SQUAD  |  %d / 5",filled)
  ui.counters.Text=state and string.format("Rerolls: %d free + %d quest\nRefreshes: %d free + %d quest",state.freeRollRerolls,state.rerolls,state.freeRollRefreshes,state.refreshes) or "Loading…"
  ui.buttons.Reroll.Text=filled==5 and (draft.finished and "FINISHED" or "FINISH") or "REROLL TEAM"
  local card=draft and selected and (draft.squad[selected] or draft.candidates[selected])
  ui.reveal.Text=card and (card.name.."\n"..(card.school or "Non-college").." "..(card.season or "")) or "Select a prospect"
  ui.status.Text=message
  wheel.render(draft,pending)
  for name,button in pairs(ui.buttons) do
   button.Active=not pending or name=="Exit"
   if name=="Reroll" and filled<5 then
    button.Active=not pending and draft~=nil and draft.pickAvailable and not draft.finished
     and (state.freeRollRerolls+state.rerolls>0)
   elseif name=="Refresh" then
    button.Active=not pending and draft~=nil and draft.pickAvailable and not draft.finished
     and (state.freeRollRefreshes+state.refreshes>0)
   end
   button.Selectable=button.Active
   button.AutoButtonColor=button.Active
  end
 end
 request=function(action,pos)
  if pending then return end
  pending=true
  message="Rolling / saving…"
  render()
  local ok,result=pcall(function()
   local remote=game:GetService("ReplicatedStorage"):WaitForChild("HoopsShop",10)
   if not remote then error("Roll server unavailable") end
   local response
   for _=1,3 do
    response=remote:InvokeServer(action,pos)
    if response.code~="BUSY" then break end
    task.wait(0.5)
   end
   return response
  end)
  pending=false
  if ok and result.ready then
   state=result
   local messages={READY="Choose one player or a rare hit. A rare pick replaces its position; Refresh keeps the wheel.",ROLLED="Player saved! Press Roll for another college team and choose one player.",
    ROLL_REQUIRED="Press Roll before choosing another player.",CHOOSE_FIRST="Choose one player from this roll first.",
    REROLLED="New random school and year! Choose ONE player to add to your team.",
    REFRESHED="Players reshuffled within this college team and year. Choose ONE.",FINISHED="Squad finished and saved. Restart to build another squad.",
    EMPTY="No free or quest actions left. Claim quest rewards for more.",FILLED="That player is already on your team. Choose an empty position.",
    INVALID="Select a valid position.",NOT_READY="Open the squad builder again to load prospects.",INCOMPLETE="Fill all five positions first."}
   message=messages[result.code] or "Could not complete the roll. Please try again."
  else message="Could not reach the roll server. Reopen Build Your Squad to retry." end
  render()
 end
 for i,button in ipairs(ui.candidates) do
  button.Activated:Connect(function()
   if pending or not state or not state.rollState or not state.rollState.pickAvailable or state.rollState.finished then return end
   selected=positions[i]
   if not state.rollState.squad[selected] then request("RollPlayer",selected) else render() end
  end)
 end
 ui.buttons.Roll.Activated:Connect(function()
  local draft=state and state.rollState
  if not draft then request("RollState"); return end
  for _,pos in ipairs(positions) do if not draft.squad[pos] then selected=nil; request("NextRoll"); return end end
  message="All five slots are filled. Press Finish."; render()
 end)
 ui.buttons.Reroll.Activated:Connect(function()
  local draft=state and state.rollState
  if not draft then return end
  local filled=0
  for _ in pairs(draft.squad) do filled+=1 end
  if filled==5 then request("FinishRoll")
  elseif draft.pickAvailable then selected=nil; request("RerollPlayer")
  else message="Player already saved. Press Roll for another team before rerolling choices."; render() end
 end)
 ui.buttons.Refresh.Activated:Connect(function() request("RefreshRoll") end)
 ui.buttons.Restart.Activated:Connect(function() selected=nil; request("RestartRoll") end)
 ui.gui.Destroying:Connect(function() ui.resizeConnection:Disconnect() end)
 render()
 if ui.background.Visible then request("RollState") end
end
return Controller
