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
 local sounds=require(script.Parent:WaitForChild("RollSounds")).mount(ui.gui)
 local Chemistry=require(shared:WaitForChild("TeamChemistry"))
 local hover=require(script.Parent:WaitForChild("ChemistryHover")).mount(ui.canvas)
 local positions=Chemistry.Positions
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
 local function previewText(pos,card,isSlot)
  if not card or not state or not state.rollState then return nil end
  local draft=state.rollState
  local preview=Chemistry.preview(draft.squad,pos,card)
  local rating=preview.after.cards[pos]
  local action=isSlot and "IN YOUR LINEUP" or (draft.squad[pos] and "IF REPLACING "..draft.squad[pos].name or "IF ADDED AT "..pos)
  local availability=not isSlot and ((draft.finished or not draft.pickAvailable) and " · Comparison only: roll again to pick" or "") or ""
  return string.format("%s%s\n%s · %d +%d OVR = %d\nSchool: %s (%d players) +%d  |  Era: %s (%d players) +%d\nTEAM OVR: %d → %d (%+d)  |  Base change: %+d  |  Chemistry change: %+d",
   action,availability,card.name,rating.baseOverall,rating.bonus,rating.overall,card.school or "None",rating.schoolCount,rating.schoolBonus,
   card.era or card.season or "None",rating.eraCount,rating.eraBonus,preview.before.overall,preview.after.overall,preview.delta,preview.baseDelta,preview.chemistryDelta)
 end
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
  local isSlot=table.find(ui.slots,parent)~=nil
  local preview=card and state and state.rollState and Chemistry.preview(state.rollState.squad,pos,card)
  local bonus=preview and preview.after.cards[pos].bonus or 0
  parent.CardName.Text=card and (card.name.." · "..card.overall.." +"..bonus.." OVR") or "EMPTY"
  hover.bind(parent,function() return previewText(pos,card,isSlot) end)
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
  hover.hide()
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
  local chemistry=Chemistry.evaluate(draft and draft.squad or {})
  ui.canvas.Overall.Text=filled>0 and string.format("TEAM OVR: %d +%d = %d",chemistry.baseOverall,chemistry.bonus,chemistry.overall) or "TEAM OVR: —"
  ui.lineup.Text=string.format("ROLLED SQUAD  |  %d / 5",filled)
  ui.counters.Text=state and string.format("Rerolls: %d free + %d quest\nRefreshes: %d free + %d quest",state.freeRollRerolls,state.rerolls,state.freeRollRefreshes,state.refreshes) or "Loading…"
  ui.buttons.Reroll.Text="REROLL TEAM"
  local card=draft and selected and (draft.squad[selected] or draft.candidates[selected])
  ui.reveal.Text=card and (card.name.."\n"..(card.school or "Non-college").." "..(card.season or "")) or "Select a prospect"
  ui.status.Text=message
  wheel.render(draft,pending)
  for name,button in pairs(ui.buttons) do
   button.Active=not pending or name=="Exit"
   if name=="Reroll" then
    button.Active=not pending and draft~=nil and draft.pickAvailable and not draft.finished
     and (state.freeRollRerolls+state.rerolls>0)
   elseif name=="Roll" then
    button.Active=not pending and (not draft or not draft.finished)
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
   sounds.play(action,result.code)
   local messages={READY="Choose one player or a rare hit. A rare pick replaces its position; Refresh keeps the wheel.",ROLLED="Player saved! Press Roll for another college team and choose one player.",
    LOCKED="Buy this player in the Shop before rolling them.",
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
  message="Squad complete and saved. Press Restart to build another."; render()
 end)
 ui.buttons.Reroll.Activated:Connect(function()
  local draft=state and state.rollState
  if not draft then return end
  local filled=0
  for _ in pairs(draft.squad) do filled+=1 end
  if filled==5 or draft.finished then return
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
