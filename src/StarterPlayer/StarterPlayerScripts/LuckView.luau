local Luck = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Luck"))
local View = {}
function View.mount(ui, request)
 local green = Color3.fromRGB(82,239,135)
 local function make(class, parent, props)
  local object=Instance.new(class)
  for key,value in pairs(props) do object[key]=value end
  object.Parent=parent
  return object
 end
 local panel=make("Frame",ui.canvas,{Name="LuckMeter",Position=UDim2.fromOffset(592,806),Size=UDim2.fromOffset(496,190),BackgroundColor3=Color3.fromRGB(12,29,25),BorderSizePixel=0})
 make("UICorner",panel,{CornerRadius=UDim.new(0,14)})
 local function label(value,x,y,w,h,size)
  return make("TextLabel",panel,{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,TextColor3=green,Font=Enum.Font.GothamBold,TextSize=size})
 end
 local title=label("LUCK · 1×",12,4,472,26,18)
 local tube=make("Frame",panel,{Name="ThermometerTube",Position=UDim2.fromOffset(44,44),Size=UDim2.fromOffset(424,22),BackgroundColor3=Color3.fromRGB(21,61,37),BorderSizePixel=0,ClipsDescendants=true})
 make("UICorner",tube,{CornerRadius=UDim.new(1,0)})
 local fill=make("Frame",tube,{Name="Mercury",Size=UDim2.fromScale(0,1),BackgroundColor3=green,BorderSizePixel=0})
 make("UICorner",fill,{CornerRadius=UDim.new(1,0)})
 local bulb=make("Frame",panel,{Name="ThermometerBulb",Position=UDim2.fromOffset(20,36),Size=UDim2.fromOffset(38,38),BackgroundColor3=green,BorderSizePixel=0})
 make("UICorner",bulb,{CornerRadius=UDim.new(1,0)})
 for i,tier in ipairs(Luck.Tiers) do
  local x=44+(i-1)*106
  label(tostring(tier.multiplier).."×",x-24,76,48,18,12)
  make("Frame",panel,{Position=UDim2.fromOffset(x,64),Size=UDim2.fromOffset(2,7),BackgroundColor3=green,BorderSizePixel=0})
 end
 local function button(name,x)
  local b=make("TextButton",panel,{Name=name,Position=UDim2.fromOffset(x,108),Size=UDim2.fromOffset(226,63),BackgroundColor3=Color3.fromRGB(23,76,46),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=22})
  make("UICorner",b,{CornerRadius=UDim.new(0,8)})
  return b
 end
 local cash=button("BuyLuckCash",16)
 local robux=button("BuyLuckRobux",254)
 cash.Activated:Connect(function() if cash.Active then request("UpgradeLuck") end end)
 robux.Activated:Connect(function() if robux.Active then request("PurchaseLuck") end end)
 label("Permanent · boosts gold, HOF, non-college & higher OVR odds",12,173,472,16,11)
 local view={}
 function view.render(state,pending)
  local creator=state and state.luckMultiplier == 50
  local level=creator and #Luck.Tiers or (state and state.luckLevel or 1)
  local nextTier=Luck.Tiers[level+1]
  title.Text="LUCK · "..tostring(state and state.luckMultiplier or 1).."×"
  fill.Size=UDim2.fromScale((level-1)/4,1)
  local credit=state and (state.luckCredit or 0)>0
  local prices={[2]="250K",[3]="1M",[4]="5M",[5]="10M"}
  cash.Text=creator and "CREATOR · 50×" or not state and "Loading…" or not nextTier and "MAX LUCK" or credit and "ACTIVATE UPGRADE" or tostring(nextTier.multiplier).."× · $"..prices[level+1]
  robux.Text=creator and "50× ACTIVE" or not nextTier and "3× UNLOCKED" or credit and "UPGRADE OWNED" or tostring(nextTier.multiplier).."× · "..nextTier.robux.." Robux"
  cash.Active=state~=nil and nextTier~=nil and not pending and (not credit or state.paidAllowed==true)
  robux.Active=cash.Active and state.paidAllowed==true
  for _,b in ipairs({cash,robux}) do b.Selectable=b.Active;b.AutoButtonColor=b.Active;b.BackgroundTransparency=b.Active and 0 or .65 end
 end
 return view
end
return View
