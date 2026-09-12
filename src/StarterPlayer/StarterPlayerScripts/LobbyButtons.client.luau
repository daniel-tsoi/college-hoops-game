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
  -- One scale from the viewport's shortest side against a 1280x720 reference.
  -- Sizing each control off the width alone kept them at half the screen no
  -- matter how small it got, which is why they looked oversized on a
  -- half-screen window, a phone or a tablet. Everything shrinks together now.
  local scale=math.clamp(math.min(viewport.X/1280,viewport.Y/720),.5,1)
  local pad=math.round(20*scale)
  if row then
   local width=math.max(72,math.min(math.round(276*scale),(viewport.X-3*pad)/2))
   -- Floor first, so a very short viewport cannot invert the clamp.
   local tallest=math.max(34,(viewport.Y-math.round(190*scale))/4)
   local height=math.clamp(math.round(78*scale),34,tallest)
   local gap=math.round(10*scale)
   button.Size=UDim2.fromOffset(width,height)
   button.Position=UDim2.new(row[1],row[1]==0 and pad or -width-pad,1,-math.round(120*scale)-(3-row[2])*(height+gap))
   button.TextScaled=true
   local textLimit=button:FindFirstChildOfClass("UITextSizeConstraint")
   if textLimit then textLimit.MaxTextSize=math.max(12,math.round(24*scale)) end
  elseif button.Name=="Build" then
   local height=math.round(96*scale)
   button.Size=UDim2.new(1,-2*pad,0,height);button.TextSize=math.max(15,math.round(30*scale))
   local limit=button:FindFirstChildOfClass("UISizeConstraint")
   if limit then limit.MaxSize=Vector2.new(math.round(480*scale),height) end
  else
   local size=math.round(81*scale)
   button.Size=UDim2.fromOffset(size,size);button.TextSize=math.max(18,math.round(46*scale))
  end
  updating=false
 end
 if row then
  -- The floor sits below the smallest MaxTextSize fit() can set, so the
  -- constraint can never end up with a minimum above its maximum.
  local limit=Instance.new("UITextSizeConstraint");limit.MaxTextSize=24;limit.MinTextSize=10;limit.Parent=button
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
