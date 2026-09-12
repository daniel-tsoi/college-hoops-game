local TweenService = game:GetService("TweenService")
local Motion = {}
local attached = setmetatable({}, {__mode = "k"})
local ease = TweenInfo.new(.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Motion.attach(object, darken)
 if attached[object] then return attached[object] end
 local scale = Instance.new("UIScale")
 scale.Name = "CardMotionScale"; scale.Parent = object
 local shade
 if darken then
  shade = Instance.new("Frame")
  shade.Name = "HoverShade"; shade.Size = UDim2.fromScale(1,1)
  shade.BackgroundColor3 = Color3.new(0,0,0); shade.BackgroundTransparency = 1
  shade.BorderSizePixel = 0; shade.ZIndex = 50; shade.Active = false; shade.Parent = object
  local corner = object:FindFirstChildOfClass("UICorner")
  if corner then corner:Clone().Parent = shade end
 end
 local hovered, focused, popping = false, false, false
 local scaleTween, shadeTween
 local connections = {}
 local function visible()
  local ancestor = object
  while ancestor do
   if ancestor:IsA("GuiObject") and not ancestor.Visible then return false end
   if ancestor:IsA("ScreenGui") and not ancestor.Enabled then return false end
   ancestor = ancestor.Parent
  end
  return true
 end
 local function highlighted()
  return visible() and (not object:IsA("GuiButton") or object.Active) and (hovered or focused)
 end
 local function update()
  local active = highlighted()
  if not popping then
   if scaleTween then scaleTween:Cancel() end
   scaleTween = TweenService:Create(scale,ease,{Scale=active and 1.035 or 1})
   scaleTween:Play()
  end
  if shade then
   if shadeTween then shadeTween:Cancel() end
   shadeTween = TweenService:Create(shade,ease,{BackgroundTransparency=active and .7 or 1})
   shadeTween:Play()
  end
 end
 local function connect(signal, callback) table.insert(connections,signal:Connect(callback)) end
 connect(object.MouseEnter,function() hovered=true; update() end)
 connect(object.MouseLeave,function() hovered=false; update() end)
 connect(object.SelectionGained,function() focused=true; update() end)
 connect(object.SelectionLost,function() focused=false; update() end)
 if object:IsA("GuiButton") then
  object.AutoButtonColor=false
  connect(object:GetPropertyChangedSignal("AutoButtonColor"),function() object.AutoButtonColor=false end)
  connect(object:GetPropertyChangedSignal("Active"),update)
 end
 local ancestor=object
 while ancestor do
  local property=ancestor:IsA("GuiObject") and "Visible" or ancestor:IsA("ScreenGui") and "Enabled"
  if property then
   connect(ancestor:GetPropertyChangedSignal(property),function()
    if not visible() then hovered=false; focused=false end
    update()
   end)
  end
  ancestor=ancestor.Parent
 end
 local view={}
 function view.pop(overall)
  popping=true
  if scaleTween then scaleTween:Cancel() end
  scale.Scale=.2
  local big=(overall or 0)>=96
  scaleTween=TweenService:Create(scale,TweenInfo.new(big and .24 or .18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=big and 1.22 or 1.08})
  scaleTween:Play(); scaleTween.Completed:Wait()
  scaleTween=TweenService:Create(scale,TweenInfo.new(.14,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1})
  scaleTween:Play(); scaleTween.Completed:Wait()
  popping=false; update()
 end
 connect(object.Destroying,function()
  if scaleTween then scaleTween:Cancel() end
  if shadeTween then shadeTween:Cancel() end
  for _,connection in ipairs(connections) do connection:Disconnect() end
  attached[object]=nil
 end)
 attached[object]=view
 return view
end
return Motion
