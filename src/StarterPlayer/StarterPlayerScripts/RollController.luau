local Controller = {}
function Controller.attach(ui)
 -- Give the taller court its own space; scale the whole layout to the safe area.
 ui.canvas.Size=UDim2.fromOffset(1120,1000)
 ui.resizeConnection:Disconnect()
 local function fitCanvas()
  local size=ui.background.AbsoluteSize
  ui.canvas:FindFirstChildOfClass("UIScale").Scale=math.min(size.X/1120,size.Y/1000)
 end
 ui.resizeConnection=ui.background:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitCanvas)
 fitCanvas()
 ui.slots[1].Parent.Position=UDim2.fromOffset(340,96)
 ui.slots[1].Parent.Size=UDim2.fromOffset(748,484)
 local teamOverall=ui.canvas.Overall
 teamOverall.Position=UDim2.fromOffset(340,4)
 teamOverall.Size=UDim2.fromOffset(748,58)
 teamOverall.Font=Enum.Font.GothamBlack
 teamOverall.TextSize=38
 teamOverall.BackgroundColor3=Color3.fromRGB(12,23,39)
 teamOverall.BackgroundTransparency=0.08
 teamOverall.BorderSizePixel=0
 local overallCorner=Instance.new("UICorner")
 overallCorner.CornerRadius=UDim.new(0,12);overallCorner.Parent=teamOverall
 local overallBorder=Instance.new("UIStroke")
 overallBorder.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 overallBorder.Color=Color3.fromRGB(104,192,255)
 overallBorder.Thickness=2;overallBorder.Transparency=0.35;overallBorder.Parent=teamOverall
 ui.canvas.SchoolSeason.Position=UDim2.fromOffset(340,66)
 ui.canvas.SchoolSeason.Size=UDim2.fromOffset(748,26)

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
 local Lines=require(script.Parent:WaitForChild("ChemistryLines"))
 local connections=Lines.mount(ui.slots[1].Parent,ui.slots)
 Lines.legend(ui.slots[1].Parent,UDim2.fromOffset(468,8),UDim2.fromOffset(266,22))
 ui.lineup.Size=UDim2.fromOffset(270,26)
 -- Five starters form a symmetric pentagon: PG, two wings, two big men.
 local courtLocations={Vector2.new(294,8),Vector2.new(80,174),Vector2.new(508,174),Vector2.new(160,338),Vector2.new(428,338)}
 for i,slot in ipairs(ui.slots) do
  slot.Position=UDim2.fromOffset(courtLocations[i].X,courtLocations[i].Y)
  slot.Size=UDim2.fromOffset(160,140)
 end
 local CardMotion=require(script.Parent:WaitForChild("CardMotion"))
 local positions=Chemistry.Positions
 local state, selected, pending = nil,nil,false
 local message=""
 ui.canvas.CandidatesTitle.Position=UDim2.fromOffset(340,582)
 ui.canvas.CandidatesTitle.Size=UDim2.fromOffset(574,36)
 ui.canvas.CandidatesTitle.Font=Enum.Font.GothamBlack
 ui.canvas.CandidatesTitle.TextScaled=true
 local titleLimit=Instance.new("UITextSizeConstraint")
 titleLimit.MaxTextSize=30; titleLimit.MinTextSize=16; titleLimit.Parent=ui.canvas.CandidatesTitle
 ui.canvas.SchoolSeason.Font=Enum.Font.GothamBlack
 ui.canvas.SchoolSeason.TextSize=24
 for _,button in pairs(ui.buttons) do
  button.Size=UDim2.fromOffset(240,75)
  button.TextSize=24
 end
 ui.buttons.Roll.Size=UDim2.fromOffset(240,132)
 ui.buttons.Roll.Font=Enum.Font.GothamBlack
 ui.buttons.Roll.TextSize=21
 ui.buttons.Roll.TextWrapped=true
 ui.buttons.Reroll.Text="Loading…"
 ui.buttons.Refresh.Text="Loading…"
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
  local isSlot=table.find(ui.slots,parent)~=nil
  local preview=card and state and state.rollState and Chemistry.preview(state.rollState.squad,pos,card)
  local bonus=preview and preview.after.cards[pos].bonus or 0
  parent.CardName.Text=card and (card.name.." · "..card.overall.." +"..bonus.." OVR") or "EMPTY"
  header.TextColor3=card and card.gold and Color3.fromRGB(255,207,89) or Color3.fromRGB(240,244,249)
  local largeCard=isSlot or pos=="SIXTH" or table.find(ui.candidates,parent)~=nil
  if largeCard then
   local overall=parent:FindFirstChild("CardOverall")
   if not overall then
    overall=Instance.new("TextLabel");overall.Name="CardOverall";overall.BackgroundTransparency=1
    overall.Position=UDim2.fromOffset(4,18);overall.Size=UDim2.new(1,-8,0,28)
    overall.Font=Enum.Font.GothamBlack;overall.TextScaled=true;overall.Parent=parent
    local limit=Instance.new("UITextSizeConstraint");limit.MinTextSize=16;limit.MaxTextSize=26;limit.Parent=overall
   end
   overall.Text=card and string.format("%d +%d",card.overall,bonus) or "—"
   overall.TextColor3=card and card.gold and Color3.fromRGB(255,207,89) or Color3.fromRGB(241,244,249)
   header.Text=pos.." · OVR";header.TextSize=12
   parent.CardName.Text=card and card.name or "EMPTY"
   parent.CardName.TextSize=(isSlot or pos=="SIXTH") and 14 or 12
   Portrait.mount(parent,card,UDim2.new(.5,0,0,46),UDim2.fromOffset(68,58))
  else
  Portrait.mount(parent,card,UDim2.new(.5,0,0,18),UDim2.fromOffset(compact and 60 or 98,compact and 51 or 85))
  end
 end
 for i,button in ipairs(ui.candidates) do
  button.Position=UDim2.fromOffset(340+(i-1)*116,621)
  button.Size=UDim2.fromOffset(110,136)
  local cross=Instance.new("Frame")
  cross.Name="PositionUsedX";cross.Size=UDim2.fromScale(1,1);cross.BackgroundTransparency=1
  cross.Visible=false;cross.ZIndex=20;cross.Parent=button
  for _,angle in ipairs({51,-51}) do
   local bar=Instance.new("Frame")
   bar.AnchorPoint=Vector2.new(.5,.5);bar.Position=UDim2.fromScale(.5,.5)
   bar.Size=UDim2.fromOffset(160,14);bar.Rotation=angle
   bar.BackgroundColor3=Color3.new(0,0,0);bar.BorderSizePixel=0;bar.ZIndex=21;bar.Parent=cross
  end
 end
 ui.status.Position=UDim2.fromOffset(340,764)
 ui.status.Size=UDim2.fromOffset(574,24)
 ui.status.TextSize=13
 local buy
 local sixthPurchase
 local wheel=require(script.Parent:WaitForChild("RareWheelView")).mount(ui.canvas,decorate,function(kind)
  request("ChooseRare",kind)
 end)
 local sixth=require(script.Parent:WaitForChild("SixthManView")).mount(ui,decorate,function(index)
  if state and state.rollState and state.rollState.squad.SIXTH and (state.sixthCredits or 0)<1 then
   sixthPurchase={index=index,serial=state.rollState.rareRoll}
   buy("Sixth")
  else request("ChooseSixth",index) end
 end,function() request("DeclineSixth") end)
 local render
 local confirm=require(script.Parent:WaitForChild("RareActionConfirm")).mount(ui,function() return state and state.rollState end,function() if render then render() end end)
 local completion=require(script.Parent:WaitForChild("SquadCompletion")).mount(ui,function(action) request(action) end,function() render() end,function(draft)
  local tutorial=ui.gui.Parent:FindFirstChild("HoopsTutorialUI")
  local event=tutorial and tutorial:FindFirstChild("SquadResponse")
  if event then event:Fire("TutorialRunFinished",{ready=true,rollState=draft}) end
 end)
 local luckView=require(script.Parent:WaitForChild("LuckView")).mount(ui,function(action) request(action) end)
 local choosingSixth=false
 render=function()
  local draft=state and state.rollState
  local filled,total=0,0
  for i,pos in ipairs(positions) do
   local card=draft and draft.squad[pos]
   if card then filled+=1; total+=card.overall end
   decorate(ui.slots[i],pos,card,true)
   ui.slots[i].TextSize=16
   ui.slots[i].TextColor3=card and card.gold and Color3.fromRGB(255,207,89) or Color3.fromRGB(241,244,249)
   local candidate=draft and draft.candidates[pos]
   decorate(ui.candidates[i],pos,candidate,true)
   ui.candidates[i].TextSize=15
   ui.candidates[i].TextColor3=candidate and candidate.gold and Color3.fromRGB(255,207,89) or Color3.fromRGB(241,244,249)
   ui.candidates[i].BackgroundColor3=selected==pos and Color3.fromRGB(43,56,74) or Color3.fromRGB(25,33,46)
   local canPick=not pending and not confirm.isOpen() and draft~=nil and draft.pickAvailable and not draft.finished and not draft.squad[pos]
   ui.candidates[i].PositionUsedX.Visible=card~=nil
   ui.candidates[i].Active=canPick == true
   ui.candidates[i].Selectable=canPick == true
   ui.candidates[i].AutoButtonColor=canPick == true
   ui.candidates[i].BackgroundTransparency=canPick and 0.05 or 0.65
  end
  local team=draft and draft.team
  local teamLabel=team and (string.upper(team.school).." · "..team.season) or "COLLEGE TEAM · YEAR"
  ui.canvas.CandidatesTitle.Text=teamLabel
  ui.canvas.SchoolSeason.Text=teamLabel
  local chemistry=Chemistry.evaluate(draft and draft.squad or {})
  ui.canvas.Overall.Text=filled>0 and string.format("TEAM OVR: %d +%d = %d",chemistry.baseOverall,chemistry.bonus,chemistry.overall) or "TEAM OVR: —"
  ui.lineup.Text=string.format("ROLLED SQUAD  |  %d / 5%s",filled,draft and draft.squad.SIXTH and " + 6TH MAN" or "")
  local rerolls=state and (state.freeRollRerolls+state.rerolls+(state.paidRerolls or 0)) or 0
  local refreshes=state and (state.freeRollRefreshes+state.refreshes+(state.paidRefreshes or 0)) or 0
  ui.buttons.Reroll.Text=state and state.unlimitedActions and "∞ rerolls" or state and rerolls==0 and "10 rerolls · 49 Robux" or state and string.format("%d %s",rerolls,rerolls==1 and "reroll" or "rerolls") or "Loading…"
  ui.buttons.Refresh.Text=state and state.unlimitedActions and "∞ refreshes" or state and refreshes==0 and "10 refreshes · 49 Robux" or state and string.format("%d %s",refreshes,refreshes==1 and "refresh" or "refreshes") or "Loading…"
  local card=draft and selected and (draft.squad[selected] or draft.candidates[selected])
  ui.reveal.Text=card and (card.name.."\n"..(card.school or "Non-college").." "..(card.season or "")) or "Select a prospect"
  ui.status.Text=message
  if draft and draft.pickAvailable and not draft.finished then
   for _,rare in pairs(draft.rare or {}) do
    if draft.squad[rare.position] then
     ui.status.Text="Rare position already filled. Choose a normal player for an open position before pressing Roll."
     break
    end
   end
  end
  local connectedPlayers={}
  for i,pos in ipairs(positions) do connectedPlayers[i]=draft and draft.squad[pos] end
  connections.render(connectedPlayers)
  wheel.render(draft,pending or confirm.isOpen(),state)
  local modal,allowSixth=completion.render(draft,pending or confirm.isOpen())
  luckView.render(state,pending or modal)
  choosingSixth=allowSixth
  ui.buttons.Roll.Text=filled==5 and not allowSixth and "FINISH" or "ROLL"
  if allowSixth and not pending then ui.status.Text="Choose one of the three cards below for your sixth man." end
  sixth.render(draft,pending,allowSixth,state)
  for name,button in pairs(ui.buttons) do
   button.Active=not pending or name=="Exit"
   if name=="Reroll" then
    button.Active=not pending and draft~=nil and draft.pickAvailable and not draft.finished

   elseif name=="Roll" then
    button.Active=not pending and (not draft or draft.finished or not draft.pickAvailable)
   elseif name=="Refresh" then
    button.Active=not pending and draft~=nil and draft.pickAvailable and not draft.finished

   end
   if confirm.isOpen() or modal or (allowSixth and (name=="Roll" or name=="Restart")) then button.Active=false end
   button.BackgroundTransparency=button.Active and 0.12 or 0.65
   button.Selectable=button.Active
   button.AutoButtonColor=button.Active
  end
 end
 request=function(action,pos,confirmed)
  if pending or confirm.isOpen() then return end
  if not confirmed and confirm.ask(action,function() request(action,pos,true) end) then return end
  local hadDraft=state and state.rollState
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
  if ok and result.ready then
   if action=="ChooseSixth" and result.code=="SIXTH_ADDED" then
    local flipped,flipError=pcall(function() sixth.flip(pos,result.rollState.squad.SIXTH,state and state.rollState and state.rollState.sixthChoice) end)
    if not flipped then warn("Sixth-man animation: "..tostring(flipError)) end
   end
   state=result
   sounds.play(action,result.code)
   local messages={LUCK_UPGRADED="Luck upgraded permanently! Future rolls use your new multiplier.",LUCK_MAX="You have maximum 3× luck.",INSUFFICIENT="Not enough cash for the next luck upgrade.",READY="",ROLLED="Player saved.",
    LOCKED="Buy this player in the Shop before rolling them.",
    ROLL_REQUIRED="Press Roll before choosing another player.",CHOOSE_FIRST="Choose one player from this roll first.",
    REROLLED="",
    REFRESHED="",FINISHED="Five players saved. Press Finish to complete your squad.",
    SIXTH_DECLINED="Your five-player team is complete and saved.",
    SIXTH_ACCEPTED="Choose a sixth-man card below.",CHOOSE_SIXTH="Choose your sixth man before starting another squad.",SIXTH_ADDED="Sixth man saved to your squad and collection. Only the current sixth-man reward is kept.",SIXTH_TAKEN="Your sixth man is already saved.",NO_SIXTH="No eligible player behind this card.",
    PURCHASE_PROMPTED="Confirm or cancel in the Roblox purchase window.",
    PRODUCT_UNCONFIGURED="This purchase is not available yet.",PAID_RESTRICTED="Paid random rewards are unavailable for this account.",
    NOT_ELIGIBLE="This offer is not available right now.",
    EMPTY="Out of actions. Buy a pack of 10 or claim quest rewards.",FILLED="That player is already on your team. Choose an empty position.",
    INVALID="Select a valid position.",NOT_READY="Open the squad builder again to load prospects.",INCOMPLETE="Fill all five positions first."}
   message=messages[result.code] or "Could not complete the roll. Please try again."
  else message="Could not reach the roll server. Reopen Build Your Squad to retry." end
  if ok and result.ready then
   local reveal=(action=="NextRoll" or action=="RestartRoll" or (action=="RollState" and not hadDraft)) and result.code=="READY"
    or action=="RerollPlayer" and result.code=="REROLLED"
    or action=="RefreshRoll" and result.code=="REFRESHED"
   if reveal and result.rollState then
    render()
    for _,button in ipairs(ui.candidates) do button.Visible=false end
    local animated,animationError=pcall(function()
     for i,position in ipairs(positions) do
      if not ui.background.Visible then break end
      local button=ui.candidates[i]
      local card=result.rollState.candidates[position]
      button.Visible=true
      if card then CardMotion.attach(button,true).pop(card.overall) end
     end
    end)
    for _,button in ipairs(ui.candidates) do button.Visible=true end
    if not animated then warn("Prospect reveal: "..tostring(animationError)) end
   end
  end
  pending=false
  render()
  -- Tutorial observes confirmed responses, never infers saves from clicks.
  local tutorial=ui.gui.Parent:FindFirstChild("HoopsTutorialUI")
  local event=tutorial and tutorial:FindFirstChild("SquadResponse")
  if event and ok and result.ready then event:Fire(action,result) end
 end
 buy=function(kind)
  if not pending then request("PurchaseProduct",kind) end
 end
 local grantedConnection=game:GetService("ReplicatedStorage"):WaitForChild("HoopsPurchaseGranted").OnClientEvent:Connect(function(productId)
  while pending do task.wait(0.1) end
  request("State")
  if state and (state.luckCredit or 0)>0 and state.paidAllowed then
   request("PurchaseLuck")
  end
  local target=sixthPurchase
  if target and state and state.products and productId==state.products.Sixth.id then
   sixthPurchase=nil
   local draft=state.rollState
   if draft and draft.rareRoll==target.serial and (draft.sixthAvailable or {})[target.index] and (state.sixthCredits or 0)>0 then
    request("ChooseSixth",target.index)
    return
   end
  end
  message="Purchase saved! Your rewards are ready to use."
  render()
 end)
 ui.gui.Destroying:Connect(function() grantedConnection:Disconnect() end)
 for i,button in ipairs(ui.candidates) do
  button.Activated:Connect(function()
   if pending or not state or not state.rollState or not state.rollState.pickAvailable or state.rollState.finished then return end
   selected=positions[i]
   if not state.rollState.squad[selected] then request("RollPlayer",selected) else render() end
  end)
 end
 ui.buttons.Roll.Activated:Connect(function()
  if not ui.buttons.Roll.Active then return end
  local draft=state and state.rollState
  if not draft then request("RollState"); return end
  if draft.finished then
   if not choosingSixth then completion.finish() end
   return
  end
  for _,pos in ipairs(positions) do if not draft.squad[pos] then selected=nil; request("NextRoll"); return end end
  message="Squad complete and saved. Press Restart to build another."; render()
 end)
 ui.buttons.Reroll.Activated:Connect(function()
  if not ui.buttons.Reroll.Active then return end
  if state and not state.unlimitedActions and state.freeRollRerolls+state.rerolls+(state.paidRerolls or 0)==0 then buy("Rerolls"); return end
  local draft=state and state.rollState
  if not draft then return end
  local filled=0
  for _ in pairs(draft.squad) do filled+=1 end
  if filled==5 or draft.finished then return
  elseif draft.pickAvailable then selected=nil; request("RerollPlayer")
  else message="Player already saved. Press Roll for another team before rerolling choices."; render() end
 end)
 ui.buttons.Refresh.Activated:Connect(function()
  if not ui.buttons.Refresh.Active then return end
  if state and not state.unlimitedActions and state.freeRollRefreshes+state.refreshes+(state.paidRefreshes or 0)==0 then buy("Refreshes")
  else request("RefreshRoll") end
 end)
 ui.buttons.Restart.Activated:Connect(function() if not ui.buttons.Restart.Active then return end; selected=nil; sixthPurchase=nil; request("RestartRoll") end)
 ui.gui.Destroying:Connect(function() ui.resizeConnection:Disconnect() end)
 local disconnectBalances=require(script.Parent:WaitForChild("QuestBalanceSync")).bind(
  game:GetService("Players").LocalPlayer,function() return state end,render)
 ui.gui.Destroying:Connect(disconnectBalances)
 render()
 if ui.background.Visible then request("RollState") end
end
return Controller
