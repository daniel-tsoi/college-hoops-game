local Appearance=require(script.Parent.CardAppearance)
local Portrait={}
local function make(kind,parent,props)
 local object=Instance.new(kind)
 for key,value in pairs(props) do object[key]=value end
 object.Parent=parent
 return object
end
local function color(hex) return Color3.fromHex(hex) end
function Portrait.mount(parent,card,position,size)
 local old=parent:FindFirstChild("CardPortrait")
 local key=card and ((card.id or card.name)..tostring(card.gold==true)) or ""
 if old and old:GetAttribute("CardKey")==key then return old end
 if old then old:Destroy() end
 if not card then return nil end
 local art=Appearance.get(card)
 local root=make("Frame",parent,{Name="CardPortrait",AnchorPoint=Vector2.new(.5,0),Position=position,Size=size,BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true})
 root:SetAttribute("CardKey",key)
 root:SetAttribute("HairStyle",art.hair)
 root:SetAttribute("JerseyNumber",art.number)
 root:SetAttribute("JerseySource",art.jerseySource)
 make("UIAspectRatioConstraint",root,{AspectRatio=1.15,DominantAxis=Enum.DominantAxis.Height})
 local auraColor=color(art.aura)
 local backdrop=make("Frame",root,{Name="Backdrop",Position=UDim2.fromScale(.08,.03),Size=UDim2.fromScale(.84,.94),BackgroundColor3=color(art.premium and "25121E" or "172638"),BorderSizePixel=0})
 make("UICorner",backdrop,{CornerRadius=UDim.new(.12,0)})
 make("UIGradient",backdrop,{Color=ColorSequence.new(auraColor:Lerp(Color3.new(),.65),Color3.fromRGB(9,14,22)),Rotation=90})
 if art.premium or art.gold then
  local aura=make("Frame",root,{Name="Aura",Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
  for i=1,12 do
   local angle=(i-1)*math.pi*2/12
   local flame=make("Frame",aura,{Name="Flame"..i,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5+math.cos(angle)*.34,.52+math.sin(angle)*.35),
    Size=UDim2.fromScale(.07,.25),Rotation=math.deg(angle)+90,BackgroundColor3=auraColor,BackgroundTransparency=.3,BorderSizePixel=0})
   make("UICorner",flame,{CornerRadius=UDim.new(.5,0)})
   make("UIGradient",flame,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.55,.05),NumberSequenceKeypoint.new(1,1)}),Rotation=90})
   flame:SetAttribute("BaseRotation",flame.Rotation)
  end
  local outline=make("UIStroke",backdrop,{Name="EnergyOutline",Color=auraColor,Thickness=2,Transparency=.1})
  if art.gold then outline.Color=Color3.fromRGB(255,215,92) end
  game:GetService("CollectionService"):AddTag(root,"HoopsCardAura")
 end
 local view=make("ViewportFrame",root,{Name="Avatar",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
  Ambient=Color3.fromRGB(195,195,195),LightColor=Color3.fromRGB(255,243,224),LightDirection=Vector3.new(-1,-1,-2)})
 local world=make("WorldModel",view,{Name="PortraitWorld"})
 local model=make("Model",world,{Name="SmilingRobloxPlayer"})
 local function part(name,pos,dimensions,tint,shape)
  -- Wemby's elongated body rises beyond the fixed portrait camera. Keep the
  -- actual head intact above the crop, so every shared card view gets the joke.
  if art.extraTall then
   pos=Vector3.new(pos.X*.82,(pos.Y+.64)*2.9-.64,pos.Z)
   dimensions=Vector3.new(dimensions.X*.82,dimensions.Y*2.9,dimensions.Z)
  end
  return make("Part",model,{Name=name,Position=pos,Size=dimensions,Color=tint,Material=Enum.Material.SmoothPlastic,
   Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Shape=shape or Enum.PartType.Block})
 end
 local skin=color(art.skin)
 local jersey=color(art.jersey)
 part("Jersey",Vector3.new(0,0,0),Vector3.new(1.32,1.28,.7),jersey)
 part("Neck",Vector3.new(0,.74,0),Vector3.new(.46,.3,.48),skin)
 local head=part("Head",Vector3.new(0,1.29,0),Vector3.new(1.04,1.04,.9),skin)
 make("SpecialMesh",head,{MeshType=Enum.MeshType.Head,Scale=Vector3.new(1.05,1.05,1.05)})
 for _,side in ipairs({-1,1}) do
  local arm=part("Arm",Vector3.new(side*.94,-.02,0),Vector3.new(.48,1.18,.6),skin)
  arm.Orientation=Vector3.new(0,0,side*10)
  part("JerseyTrim",Vector3.new(side*.58,.22,-.36),Vector3.new(.065,.91,.03),Color3.new(1,1,1))
  part("Eye",Vector3.new(side*.19,1.37,-.46),Vector3.new(.085,.12,.05),Color3.fromRGB(20,16,14),Enum.PartType.Ball)
 end
 -- Classic friendly smile, made from geometry so it needs no external face asset.
 for i=0,10 do
  local x=-.22+i*.044
  local y=1.07+.12*(x/.22)^2
  part("Smile",Vector3.new(x,y,-.465),Vector3.new(.057,.05,.038),Color3.fromRGB(25,18,16),Enum.PartType.Ball)
 end
 local hair=color(art.hairColor)
 if art.hair~="bald" then
  part("HairCap",Vector3.new(0,1.78,.015),Vector3.new(1.05,art.hair=="buzz" and .12 or .23,.91),hair)
  if art.hair=="curls" or art.hair=="twists" then
   for i=1,9 do
    local x=((i-1)%3-1)*.32
    local z=(math.floor((i-1)/3)-1)*.28
    local lock=part("HairLock",Vector3.new(x,1.89+(i%2)*.07,z),Vector3.new(.32,art.hair=="twists" and .5 or .33,.33),hair,Enum.PartType.Ball)
    lock.Orientation=Vector3.new(0,0,(i%3-1)*20)
   end
  elseif art.hair=="swept" then
   for i=1,4 do
    local lock=part("SweptHair",Vector3.new(-.44+i*.18,1.94,-.04),Vector3.new(.27,.31,.83),hair)
    lock.Orientation=Vector3.new(0,0,-25)
   end
  elseif art.hair=="fade" then
   part("TexturedTop",Vector3.new(0,1.96,0),Vector3.new(.85,.2,.78),hair)
  end
 end
 local camera=make("Camera",view,{FieldOfView=31,CFrame=CFrame.lookAt(Vector3.new(0,.72,-6.6),Vector3.new(0,.7,0))})
 view.CurrentCamera=camera
 -- Jersey lettering stays crisp at card size; the body itself is a 3D Roblox rig.
 make("TextLabel",root,{Name="JerseyNumber",Position=UDim2.fromScale(.36,.58),Size=UDim2.fromScale(.28,.23),BackgroundTransparency=1,
  Text=art.number,Font=Enum.Font.GothamBlack,TextScaled=true,TextColor3=Color3.new(1,1,1),TextStrokeColor3=jersey:Lerp(Color3.new(),.5),TextStrokeTransparency=.2})
 game:GetService("CollectionService"):AddTag(root,"HoopsCardPortrait")
 return root
end
return Portrait
