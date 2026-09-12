local Focus=require(script.Parent:WaitForChild("MenuFocus"))
local View={}
function View.mount(ui,request,redraw)
 local overlay=Instance.new("Frame")
 overlay.Name="SquadCompletion";overlay.Size=UDim2.fromScale(1,1)
 overlay.BackgroundColor3=Color3.fromRGB(0,0,0);overlay.BackgroundTransparency=.55
 overlay.ZIndex=50;overlay.Active=true;overlay.Visible=false;overlay.Parent=ui.canvas
 local panel=Instance.new("Frame")
 panel.Name="SixthManPrompt";panel.AnchorPoint=Vector2.new(.5,.5)
 panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.fromOffset(420,180)
 panel.BackgroundColor3=Color3.fromRGB(15,27,44);panel.BorderSizePixel=0;panel.Parent=overlay
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=panel
 local title=Instance.new("TextLabel")
 title.Name="Question";title.Text="Do you want a 6th man?";title.BackgroundTransparency=1
 title.Position=UDim2.fromOffset(20,20);title.Size=UDim2.fromOffset(380,65)
 title.Font=Enum.Font.GothamBold;title.TextSize=24;title.TextColor3=Color3.fromRGB(241,244,249);title.TextWrapped=true;title.Parent=panel
 local function button(name,text,x)
  local b=Instance.new("TextButton");b.Name=name;b.Text=text;b.Font=Enum.Font.GothamBold;b.TextSize=20
  b.Position=UDim2.fromOffset(x,110);b.Size=UDim2.fromOffset(175,48)
  b.BackgroundColor3=Color3.fromRGB(20,48,90);b.TextColor3=Color3.fromRGB(241,244,249);b.Parent=panel
  local round=Instance.new("UICorner");round.CornerRadius=UDim.new(0,8);round.Parent=b
  return b
 end
 local yes=button("TrySixth","Yes",25)
 local no=button("KeepTeam","No",220)
 local view={}
 local acceptedKey,currentDraft,promptOpen=nil,nil,false
 local function closeBuilder()
  promptOpen=false;overlay.Visible=false
  ui.background.Visible=false;ui.build.Visible=true;Focus.select(ui.build)
 end
 yes.Activated:Connect(function()
  if not yes.Active then return end
  request("AcceptSixth")
  if currentDraft and currentDraft.sixthAccepted then
   acceptedKey=currentDraft.rareRoll;promptOpen=false;redraw()
   Focus.select(ui.canvas:FindFirstChild("SixthManChoice1"))
  end
 end)
 no.Activated:Connect(function()
  if no.Active then request("DeclineSixth") end
 end)
 function view.finish()
  if not currentDraft or not currentDraft.finished then return end
  local any=false
  for _,available in pairs(currentDraft.sixthAvailable or {}) do any=any or available end
  if currentDraft.sixthDeclined or currentDraft.squad.SIXTH or not any then closeBuilder();return end
  promptOpen=true;redraw();Focus.select(no)
 end
 function view.render(draft,pending)
  currentDraft=draft
  if not draft or not draft.finished then acceptedKey=nil;promptOpen=false end
  if draft and (draft.sixthDeclined or draft.squad.SIXTH) then
   if promptOpen and draft.sixthDeclined then closeBuilder() end
   promptOpen=false
  end
  overlay.Visible=promptOpen
  for _,b in ipairs({yes,no}) do b.Active=promptOpen and not pending;b.Selectable=b.Active;b.AutoButtonColor=b.Active end
  local allowSixth=draft~=nil and draft.finished and not draft.sixthDeclined and not draft.squad.SIXTH
   and (draft.sixthAccepted or acceptedKey==draft.rareRoll) and not promptOpen
  return promptOpen,allowSixth
 end
 return view
end
return View
