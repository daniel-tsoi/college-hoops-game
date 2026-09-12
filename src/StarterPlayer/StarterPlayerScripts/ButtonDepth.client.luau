-- Shared raised surfaces for every game-owned button, including dynamic cards.
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local styled = setmetatable({}, {__mode="k"})
local function attach(button)
 if not button:IsA("GuiButton") or styled[button] then return end
 styled[button]=true
 local layer=Instance.new("Frame")
 layer.Name="ButtonDepth";layer.BackgroundTransparency=1;layer.Size=UDim2.fromScale(1,1)
 layer.BorderSizePixel=0;layer.Active=false;layer.ClipsDescendants=true;layer.ZIndex=button.ZIndex+1
 layer.Parent=button
 local function surface(name,color,size,position,transparency)
  local frame=Instance.new("Frame")
  frame.Name=name;frame.BackgroundColor3=color;frame.BackgroundTransparency=transparency
  frame.BorderSizePixel=0;frame.Size=size;frame.Position=position;frame.ZIndex=layer.ZIndex
  frame.Active=false;frame.Parent=layer
  return frame
 end
 local gloss=surface("TopLight",Color3.new(1,1,1),UDim2.fromScale(1,1),UDim2.new(),0)
 local gradient=Instance.new("UIGradient")
 gradient.Rotation=90
 gradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.83),NumberSequenceKeypoint.new(.42,1),NumberSequenceKeypoint.new(1,1)})
 gradient.Parent=gloss
 local top=surface("BevelHighlight",Color3.new(1,1,1),UDim2.new(1,-8,0,2),UDim2.fromOffset(4,3),.66)
 local bottom=surface("BottomDepth",Color3.new(0,0,0),UDim2.new(1,-4,0,6),UDim2.new(0,2,1,-8),.22)
 local right=surface("RightDepth",Color3.new(0,0,0),UDim2.new(0,3,1,-10),UDim2.new(1,-5,0,4),.48)
 local function corners()
  local source=button:FindFirstChildOfClass("UICorner")
  if source then
   for _,target in ipairs({layer,gloss}) do
    local corner=target:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius=source.CornerRadius;corner.Parent=target
   end
  end
 end
 corners()
 button.ChildAdded:Connect(function(child) if child:IsA("UICorner") then corners() end end)
 local animations={}
 local function press(down)
  for _,tween in ipairs(animations) do tween:Cancel() end
  animations={}
  local function animate(object,properties)
   local tween=TweenService:Create(object,TweenInfo.new(.09),properties)
   table.insert(animations,tween);tween:Play()
  end
  animate(bottom,{Size=UDim2.new(1,-4,0,down and 2 or 6),Position=UDim2.new(0,2,1,down and -4 or -8)})
  animate(right,{BackgroundTransparency=down and .75 or .48})
  animate(top,{BackgroundTransparency=down and .93 or .66})
  animate(gloss,{BackgroundTransparency=down and .65 or 0})
 end
 local function isPress(input)
  return input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonA or input.KeyCode==Enum.KeyCode.Return or input.KeyCode==Enum.KeyCode.Space
 end
 button.InputBegan:Connect(function(input) if button.Active and isPress(input) then press(true) end end)
 button.InputEnded:Connect(function(input) if isPress(input) then press(false) end end)
 button.MouseLeave:Connect(function() press(false) end)
 button.SelectionLost:Connect(function() press(false) end)
 button:GetPropertyChangedSignal("Visible"):Connect(function() if not button.Visible then press(false) end end)
 button:GetPropertyChangedSignal("Active"):Connect(function() if not button.Active then press(false) end end)
 button:GetPropertyChangedSignal("ZIndex"):Connect(function()
  layer.ZIndex=button.ZIndex+1
  for _,child in ipairs(layer:GetChildren()) do if child:IsA("GuiObject") then child.ZIndex=layer.ZIndex end end
 end)
 button.Destroying:Connect(function() for _,tween in ipairs(animations) do tween:Cancel() end end)
end
playerGui.DescendantAdded:Connect(attach)
for _,object in ipairs(playerGui:GetDescendants()) do attach(object) end
