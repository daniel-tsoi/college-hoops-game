-- A sleeveless scoop-neck uniform, fitted and welded to R6/R15 body segments.
local Palette=require(game:GetService("ReplicatedStorage").Shared.PlayerSettings)
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
 local function topAt(x)
  local u=math.abs(x)*2/width
  local top=.5
  if u<.60 then top=.21+.29*(u/.60)^2 end
  if u>.78 then top=.5-.36*((u-.78)/.22)^2 end
  return top*height
 end
 -- Shared strip boundaries prevent coplanar overlap (flickering vertical seams).
 -- Bounded curve slopes keep fabric edges covered by the raised piping.
 local segments=48
 for i=1,segments do
  local x=-width/2+(i-.5)*width/segments
  local top=math.min(topAt(x-width/segments/2),topAt(x+width/segments/2))
  piece("TankFabric",torso,Vector3.new(width/segments,top+height/2,depth),CFrame.new(x,(top-height/2)/2,0))
 end
 -- Thin piping follows the scoop neck and each arm opening, front and back.
 for _,z in ipairs({-depth/2-.026,depth/2+.026}) do
  for i=1,segments do
   local x1=-width/2+(i-1)*width/segments
   local x2=x1+width/segments
   local a,b=Vector3.new(x1,topAt(x1),z),Vector3.new(x2,topAt(x2),z)
   local delta=b-a
   piece("NeckAndArmTrim",torso,Vector3.new(delta.Magnitude,.055,.04),
    CFrame.new((a+b)/2)*CFrame.Angles(0,0,math.atan2(delta.Y,delta.X)),ink)
  end
 end
 for _,x in ipairs({-.39*width,-.30*width,.30*width,.39*width}) do
  piece("ShoulderTrim",torso,Vector3.new(.055,.04,depth+.09),CFrame.new(x,.5*height,0),ink)
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
