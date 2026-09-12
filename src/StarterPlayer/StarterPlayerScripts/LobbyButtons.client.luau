-- Larger lobby controls share one responsive layout; Daily remains compact.
local playerGui=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local rows={Shop={0,0},Quests={1,0},Collection={0,1},GoldCards={1,1},BestTeam={0,2},Leaderboard={1,2}}
local tracked=setmetatable({},{__mode="k"})
local function attach(button)
 if not button:IsA("TextButton") or not button.Parent:IsA("ScreenGui") or tracked[button] then return end
 local row=rows[button.Name]
 if not row and button.Name~="Build" and button.Name~="Settings" then return end
 tracked[button]=true
 local updating=false
 local function fit()
  if updating or not button.Parent then return end
  updating=true
  local camera=workspace.CurrentCamera
  local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
  if row then
   local width=math.min(276,(viewport.X-60)/2)
   local height=math.min(78,math.max(52,(viewport.Y-190)/4))
   button.Size=UDim2.fromOffset(width,height)
   button.Position=UDim2.new(row[1],row[1]==0 and 20 or -width-20,1,-120-(3-row[2])*(height+10))
   button.TextSize=24;button.TextScaled=true
  elseif button.Name=="Build" then
   button.Size=UDim2.new(1,-32,0,96);button.TextSize=30
   local limit=button:FindFirstChildOfClass("UISizeConstraint")
   if limit then limit.MaxSize=Vector2.new(480,96) end
  else
   button.Size=UDim2.fromOffset(81,81);button.TextSize=46
  end
  updating=false
 end
 if row then
  local limit=Instance.new("UITextSizeConstraint");limit.MaxTextSize=24;limit.MinTextSize=13;limit.Parent=button
 end
 button:GetPropertyChangedSignal("Position"):Connect(fit)
 button:GetPropertyChangedSignal("Size"):Connect(fit)
 local function bindCamera()
  local camera=workspace.CurrentCamera
  if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
  fit()
 end
 workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
 bindCamera()
end
playerGui.DescendantAdded:Connect(attach)
for _,object in ipairs(playerGui:GetDescendants()) do attach(object) end
