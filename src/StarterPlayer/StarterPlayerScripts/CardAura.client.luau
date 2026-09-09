-- One shared, visibility-aware animation loop for all card auras, including overhead cards.
local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local roots={}
local function attach(root)
 task.spawn(function()
  local view=root:WaitForChild("Avatar",5)
  if not view then return end
  local camera=view:FindFirstChildOfClass("Camera")
  if not camera then camera=Instance.new("Camera"); camera.Name="Camera"; camera.Parent=view end
  camera.FieldOfView=31
  camera.CFrame=CFrame.lookAt(Vector3.new(0,.72,-6.6),Vector3.new(0,.7,0))
  view.CurrentCamera=camera -- Cameras and CurrentCamera need client-local setup for overhead cards.
  if root.Parent and root:FindFirstChild("Aura") then roots[root]=true end
 end)
end
CollectionService:GetInstanceAddedSignal("HoopsCardPortrait"):Connect(attach)
CollectionService:GetInstanceRemovedSignal("HoopsCardPortrait"):Connect(function(root) roots[root]=nil end)
for _,root in ipairs(CollectionService:GetTagged("HoopsCardPortrait")) do attach(root) end
local function visible(root)
 local node=root
 while node do
  if node:IsA("GuiObject") and not node.Visible then return false end
  if node:IsA("LayerCollector") and not node.Enabled then return false end
  if node:IsA("BillboardGui") and node.Adornee and workspace.CurrentCamera then
   if (workspace.CurrentCamera.CFrame.Position-node.Adornee.Position).Magnitude>node.MaxDistance then return false end
  end
  node=node.Parent
 end
 return true
end
local elapsed=0
RunService.RenderStepped:Connect(function(dt)
 elapsed+=dt
 if elapsed<.05 then return end
 elapsed=0
 local time=os.clock()
 for root in pairs(roots) do
  if not root.Parent then roots[root]=nil
  elseif visible(root) then
   for i,flame in ipairs(root.Aura:GetChildren()) do
    local wave=math.sin(time*3.4+i*.8)
    flame.BackgroundTransparency=.3+wave*.15
    flame.Rotation=(flame:GetAttribute("BaseRotation") or 0)+wave*7
   end
   local outline=root.Backdrop:FindFirstChild("EnergyOutline")
   if outline then outline.Transparency=.2+math.sin(time*2.4)*.15 end
  end
 end
end)
