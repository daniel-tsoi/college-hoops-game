local View = {}
function View.mount(canvas, decorate, choose)
 local TweenService=game:GetService("TweenService")
 local panel=Instance.new("Frame")
 panel.Name="RareWheel"; panel.Position=UDim2.fromOffset(930,470); panel.Size=UDim2.fromOffset(160,198)
 panel.BackgroundColor3=Color3.fromRGB(20,27,40); panel.BorderSizePixel=0; panel.Parent=canvas
 local corner=Instance.new("UICorner"); corner.Parent=panel
 local function label(parent,text,x,y,w,h,size)
  local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Text=text
  l.Position=UDim2.fromOffset(x,y); l.Size=UDim2.fromOffset(w,h); l.Font=Enum.Font.GothamBold
  l.TextSize=size; l.TextColor3=Color3.fromRGB(241,244,249); l.TextWrapped=true; l.Parent=parent
  return l
 end
 label(panel,"RARE WHEEL",0,0,160,22,15)
 local entries={}
 for i,kind in ipairs({"HOF","NonCollege"}) do
  local x=6+(i-1)*78
  local color=i==1 and Color3.fromRGB(255,207,89) or Color3.fromRGB(154,167,255)
  local disc=Instance.new("Frame"); disc.Name=kind; disc.Position=UDim2.fromOffset(x+6,25)
  disc.Size=UDim2.fromOffset(60,60); disc.BackgroundColor3=Color3.fromRGB(35,44,61); disc.Parent=panel
  local round=Instance.new("UICorner"); round.CornerRadius=UDim.new(1,0); round.Parent=disc
  local stroke=Instance.new("UIStroke"); stroke.Thickness=2; stroke.Color=color; stroke.Parent=disc
  local rotor=Instance.new("Frame"); rotor.Size=UDim2.fromScale(1,1); rotor.BackgroundTransparency=1; rotor.Parent=disc
  local pointer=label(rotor,"▼",22,-6,16,20,18); pointer.TextColor3=color
  label(disc,i==1 and "HOF\n100% TEST" or "NON-COL\n0.13%",2,12,56,38,10)
  local button=Instance.new("TextButton"); button.Name=kind.."Result"
  button.Position=UDim2.fromOffset(x,94); button.Size=UDim2.fromOffset(72,98)
  button.BackgroundColor3=Color3.fromRGB(25,33,46); button.TextColor3=color
  button.Font=Enum.Font.GothamBold; button.TextSize=11; button.TextWrapped=true; button.Parent=panel
  button.Activated:Connect(function() if button.Active then choose(kind) end end)
  entries[kind]={button=button,rotor=rotor}
 end
 local view={serial=nil,tweens={}}
 function view.render(draft,pending)
  local serial=draft and draft.rareRoll or 0
  for _,kind in ipairs({"HOF","NonCollege"}) do
   local entry=entries[kind]
   if serial~=view.serial then
    if view.tweens[kind] then view.tweens[kind]:Cancel() end
    entry.rotor.Rotation=0
    if serial>0 then
     local tween=TweenService:Create(entry.rotor,TweenInfo.new(.7,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Rotation=720})
     view.tweens[kind]=tween; tween:Play()
    end
   end
   local card=draft and draft.rare and draft.rare[kind]
   if card then
    decorate(entry.button,card.position,card,true)
   else
    decorate(entry.button,"",nil,true) -- Clear any previous hit's hover preview.
    for _,child in ipairs(entry.button:GetChildren()) do child:Destroy() end
    entry.button.Text=serial>0 and "NO HIT\n\nNext roll: new chance" or "ROLL TO\nREVEAL"
   end
   local enabled=card~=nil and draft.pickAvailable and not draft.finished and not pending
   entry.button.Active=enabled==true; entry.button.Selectable=enabled==true; entry.button.AutoButtonColor=enabled==true
  end
  view.serial=serial
 end
 return view
end
return View
