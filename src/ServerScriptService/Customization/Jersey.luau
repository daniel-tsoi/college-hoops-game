-- A sleeveless scoop-neck uniform, fitted and welded to R6/R15 body segments.
local Palette=require(game:GetService("ReplicatedStorage").Shared.PlayerSettings)
local Geometry=require(game:GetService("ReplicatedStorage").Shared.JerseyGeometry)
local Jersey={}
function Jersey.apply(player, character, settings)
 local torso=character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
 if not torso or not torso:IsA("BasePart") then return end
 local old=character:FindFirstChild("HoopsJersey")
 if old then old:Destroy() end
 local model=Instance.new("Model"); model.Name="HoopsJersey"
 local color=Color3.fromRGB(table.unpack(Palette.colors[settings.color].rgb))
 local ink=(settings.color==5 or settings.color==6) and Color3.fromRGB(20,26,36) or Color3.new(1,1,1)
 local function piece(name,body,size,offset,tint)
  local part=Instance.new("Part"); part.Name=name; part.Size=size
  part.Color=tint or color; part.Material=Enum.Material.SmoothPlastic; part.Massless=true
  part.CanCollide=false; part.CanTouch=false; part.CanQuery=false; part.CastShadow=false
  part.CFrame=body.CFrame*offset; part.Parent=model
  local weld=Instance.new("WeldConstraint"); weld.Part0=body; weld.Part1=part; weld.Parent=part
  return part
 end
 local width,height,depth=torso.Size.X+.065,torso.Size.Y,torso.Size.Z+.085
 -- Neck and armholes are actual openings, showing the avatar underneath.
 -- Slab tops sit on their chord's midpoint and the trim is at least as thick as
 -- a slab is wide, which covers the fabric corners at every slope. See
 -- JerseyGeometry for the proof and tests/jersey_fit.spec.luau for the check.
 local shape=Geometry.build(width,height)
 for _,slab in ipairs(shape.slabs) do
  piece("TankFabric",torso,Vector3.new(slab.width,slab.top+height/2,depth),
   CFrame.new(slab.x,(slab.top-height/2)/2,0))
 end
 -- One piping band per slab, wrapping the whole torso depth. A single enclosing
 -- band replaces the two ribbons that used to float clear of the fabric edge.
 for _,chord in ipairs(shape.trims) do
  piece("NeckAndArmTrim",torso,
   Vector3.new(chord.length,shape.trimThickness,depth+Geometry.TrimDepthMargin),
   CFrame.new(chord.x,chord.y,0)*CFrame.Angles(0,0,chord.angle),ink)
 end
 -- Number centered on the chest; username appears only on the back.
 local printHeight=height*.64
 local printPanel=piece("JerseyPrint",torso,Vector3.new(width,printHeight,depth+.008),CFrame.new(0,-height*.18,0))
 printPanel.Transparency=1
 for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
  local surface=Instance.new("SurfaceGui"); surface.Name=face.Name; surface.Face=face
  surface.CanvasSize=Vector2.new(512,512*printHeight/width); surface.LightInfluence=.35; surface.Parent=printPanel
  local function label(value,y,h,maxSize)
   local text=Instance.new("TextLabel"); text.BackgroundTransparency=1
   text.Position=UDim2.fromScale(.1,y); text.Size=UDim2.fromScale(.8,h)
   text.Text=value; text.TextColor3=ink; text.Font=Enum.Font.GothamBlack; text.TextScaled=true
   local limit=Instance.new("UITextSizeConstraint"); limit.MaxTextSize=maxSize; limit.Parent=text
   text.Parent=surface
  end
  if face==Enum.NormalId.Back then label(player.Name,.01,.19,50) end
  label(settings.number,face==Enum.NormalId.Back and .23 or .02,face==Enum.NormalId.Back and .74 or .95,300)
 end
 local lower=character:FindFirstChild("LowerTorso")
 if lower and lower:IsA("BasePart") then
  piece("JerseyWaist",lower,lower.Size+Vector3.new(.065,.025,.085),CFrame.new())
 end
 -- Shorts stop above the knees and follow each leg independently.
 for _,names in ipairs({{"LeftUpperLeg","Left Leg"},{"RightUpperLeg","Right Leg"}}) do
  local leg=character:FindFirstChild(names[1]) or character:FindFirstChild(names[2])
  if leg and leg:IsA("BasePart") then
   local length=leg.Size.Y*(leg.Name:find("Upper") and .88 or .46)
   local y=(leg.Size.Y-length)/2
   local size=Vector3.new(leg.Size.X+.08,length,leg.Size.Z+.09)
   piece("BasketballShorts",leg,size,CFrame.new(0,y,0))
   piece("ShortsHem",leg,Vector3.new(size.X+.012,.075,size.Z+.012),CFrame.new(0,y-length/2+.0375,0),ink)
   piece("Waistband",leg,Vector3.new(size.X+.01,.065,size.Z+.01),CFrame.new(0,leg.Size.Y/2-.0325,0),color:Lerp(ink,.2))
   local side=leg.Name:find("Left") and -1 or 1
   piece("ShortsSideTrim",leg,Vector3.new(.026,length-.07,size.Z+.014),CFrame.new(side*size.X/2,y-.015,0),ink)
  end
 end
 model.Parent=character
end
return Jersey
