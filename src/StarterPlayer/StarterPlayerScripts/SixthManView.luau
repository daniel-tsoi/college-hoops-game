local TweenService=game:GetService("TweenService")
local SettingsState=require(script.Parent:WaitForChild("SettingsState"))
local View={}
function View.mount(ui,decorate,onPick,onDecline)
 ui.reveal.Visible=false
 local heading=Instance.new("TextLabel")
 heading.Name="SixthManTitle";heading.BackgroundTransparency=1
 heading.Position=UDim2.fromOffset(24,800);heading.Size=UDim2.fromOffset(220,28)
 heading.TextColor3=Color3.fromRGB(241,244,249);heading.Font=Enum.Font.GothamBold;heading.TextSize=13
 heading.Parent=ui.canvas
 local skip=Instance.new("TextButton")
 skip.Name="KeepFive";skip.Text="KEEP FIVE";skip.Font=Enum.Font.GothamBold;skip.TextSize=12
 skip.Position=UDim2.fromOffset(254,800);skip.Size=UDim2.fromOffset(94,28)
 skip.BackgroundColor3=Color3.fromRGB(19,39,76);skip.TextColor3=Color3.fromRGB(241,244,249)
 skip.Parent=ui.canvas;skip.Activated:Connect(function() if skip.Active then onDecline() end end)
 local sound=Instance.new("Sound")
 sound.Name="CardFlipSFX";sound.SoundId="rbxassetid://77158612385089";sound.Volume=.55
 sound.SoundGroup=SettingsState.soundGroup();sound.Parent=ui.gui
 task.spawn(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync({sound}) end) end)
 local cards={}
 for i=1,3 do
  local card=Instance.new("TextButton")
  card.Name="SixthManChoice"..i;card.Text="";card.AnchorPoint=Vector2.new(.5,.5)
  card.Position=UDim2.fromOffset(112+(i-1)*184,910);card.Size=UDim2.fromOffset(164,152)
  card.BackgroundColor3=Color3.fromRGB(10,31,68);card.BorderSizePixel=0;card.ClipsDescendants=true
  card.Parent=ui.canvas
  local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,8);corner.Parent=card
  local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(190,155,78);stroke.Thickness=2;stroke.Parent=card
  card.Activated:Connect(function() if card.Active then onPick(i) end end)
  cards[i]=card
 end
 local view={}
 function view.render(draft,pending,allowPick,state)
  local chosen=draft and draft.squad.SIXTH
  for i,card in ipairs(cards) do
   card.Visible=allowPick==true or chosen~=nil
   local available=draft and draft.sixthAvailable and draft.sixthAvailable[i]
   card.Active=available==true and not pending and (allowPick==true or (chosen~=nil and state and state.paidAllowed))
   card.Selectable=card.Active;card.AutoButtonColor=card.Active
   card.BackgroundTransparency=0
   local revealedCard=chosen and draft.sixthChoice==i and chosen or nil
   local replaced=draft and draft.sixthRevealed and draft.sixthRevealed[i] and not revealedCard
   local revealed=revealedCard~=nil
   card.Size=UDim2.fromOffset(164,152)
   decorate(card,"SIXTH",revealedCard,true)
   card.Text=replaced and "UNCLAIMED" or not revealed and chosen and available and ((state and (state.sixthCredits or 0)>0) and "REPLACE" or "REPLACE\n29 Robux") or ""
   card.Font=Enum.Font.GothamBold;card.TextSize=12;card.TextColor3=Color3.fromRGB(255,207,89)
   for _,child in ipairs(card:GetChildren()) do
    if child:IsA("GuiObject") and child.Name~="ButtonDepth" then child.Visible=revealed==true end
   end
  end
  skip.Visible=allowPick==true;skip.Active=skip.Visible and not pending;skip.Selectable=skip.Active
  heading.Visible=allowPick==true or chosen~=nil
  heading.Text=chosen and "REPLACE SIXTH MAN" or "CHOOSE YOUR SIXTH MAN"
 end
 function view.flip(index,card,previousIndex)
  if previousIndex and previousIndex~=index then
   local previous=cards[previousIndex]
   local close=TweenService:Create(previous,TweenInfo.new(.18),{Size=UDim2.fromOffset(0,152),Rotation=-8})
   close:Play();close.Completed:Wait()
   decorate(previous,"SIXTH",nil,true)
   for _,child in ipairs(previous:GetChildren()) do if child:IsA("GuiObject") and child.Name~="ButtonDepth" then child.Visible=false end end
   previous.Text="UNCLAIMED"
   TweenService:Create(previous,TweenInfo.new(.22),{Size=UDim2.fromOffset(164,152),Rotation=0}):Play()
  end
  local button=cards[index]
  sound.TimePosition=0;sound:Play()
  local close=TweenService:Create(button,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.fromOffset(0,152),Rotation=8})
  close:Play();close.Completed:Wait()
  button.Text=""
  decorate(button,"SIXTH",card,true)
  for _,child in ipairs(button:GetChildren()) do if child:IsA("GuiObject") and child.Name~="ButtonDepth" then child.Visible=true end end
  local open=TweenService:Create(button,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(164,152),Rotation=0})
  open:Play();open.Completed:Wait()
 end
 return view
end
return View
