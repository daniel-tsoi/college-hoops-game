local Rules=require(script.Parent:WaitForChild("RareActionRules"))
local Focus=require(script.Parent:WaitForChild("MenuFocus"))
local View={}
function View.mount(ui,current,redraw)
 local pg=ui.gui.Parent
 local function make(kind,parent,props)
  local item=Instance.new(kind);for k,v in pairs(props) do item[k]=v end;item.Parent=parent;return item
 end
 local gui=make("ScreenGui",pg,{Name="HoopsRareActionConfirm",DisplayOrder=95,ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,Enabled=false})
 local overlay=make("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=.35,Active=true})
 local page=make("Frame",overlay,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(490,272),BackgroundColor3=Color3.fromRGB(18,26,38),BorderSizePixel=0})
 make("UICorner",page,{CornerRadius=UDim.new(0,16)})
 local scale=make("UIScale",page,{Scale=1})
 local function fit() scale.Scale=math.min(1,(overlay.AbsoluteSize.X-24)/490,(overlay.AbsoluteSize.Y-24)/272) end
 overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit);fit()
 local function label(y,h,size)
  return make("TextLabel",page,{Position=UDim2.fromOffset(20,y),Size=UDim2.fromOffset(450,h),TextWrapped=true,BackgroundTransparency=1,TextColor3=Color3.fromRGB(241,244,249),TextSize=size,Font=Enum.Font.GothamBold})
 end
 local title=label(16,40,24);local body=label(62,126,17)
 local function button(name,x)
  return make("TextButton",page,{Name=name,Text=name,Position=UDim2.fromOffset(x,210),Size=UDim2.fromOffset(210,44),BackgroundColor3=Color3.fromRGB(36,61,65),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=20})
 end
 local no=button("No",20);local yes=button("Yes",260)
 local ticket,callback,previous,returnFocus
 local view={}
 function view.isOpen() return ticket~=nil end
 local function close(accepted)
  if not ticket then return end
  local run=Rules.consume(ticket,current(),accepted)
  local invoke=callback
  ticket=nil;callback=nil;gui.Enabled=false
  if pg:GetAttribute("HoopsPanel")=="RareConfirm" then pg:SetAttribute("HoopsPanel",previous) end
  redraw();Focus.select(returnFocus)
  if run then invoke() end
 end
 function view.ask(action,invoke)
  if ticket then return true end
  local heading,detail=Rules.warning(action,current())
  if not heading then return false end
  ticket={snapshot=current()};callback=invoke
  previous=pg:GetAttribute("HoopsPanel")
  returnFocus=ui.buttons[action=="RestartRoll" and "Restart" or action=="RerollPlayer" and "Reroll" or action=="RefreshRoll" and "Refresh" or "Roll"]
  title.Text=heading;body.Text=detail;gui.Enabled=true
  pg:SetAttribute("HoopsPanel","RareConfirm");redraw();Focus.select(no)
  return true
 end
 no.Activated:Connect(function() close(false) end)
 yes.Activated:Connect(function() close(true) end)
 local input=game:GetService("UserInputService").InputBegan:Connect(function(key,processed)
  if not processed and (key.KeyCode==Enum.KeyCode.Escape or key.KeyCode==Enum.KeyCode.ButtonB) then close(false) end
 end)
 local panelChanged=pg:GetAttributeChangedSignal("HoopsPanel"):Connect(function()
  if ticket and pg:GetAttribute("HoopsPanel")~="RareConfirm" then close(false) end
 end)
 ui.gui.Destroying:Connect(function() close(false);input:Disconnect();panelChanged:Disconnect();gui:Destroy() end)
 return view
end
return View
