local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local MenuFocus=require(script.Parent:WaitForChild("MenuFocus"))
local Settings=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerSettings"))
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("HoopsSettingsUI") then return end
local white=Color3.fromRGB(240,245,248)
local muted=Color3.fromRGB(161,175,188)
local mint=Color3.fromRGB(100,229,170)
local data=Settings.defaults()
local ready,pending=false,false
local function make(kind,parent,props)
 local item=Instance.new(kind)
 for key,value in pairs(props) do item[key]=value end
 item.Parent=parent
 return item
end
local function round(item,radius) make("UICorner",item,{CornerRadius=UDim.new(0,radius or 14)}) end
local function label(parent,value,x,y,w,h,size,color)
 return make("TextLabel",parent,{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,
  TextColor3=color or white,Font=Enum.Font.GothamBold,TextSize=size or 16,TextWrapped=true})
end
local function button(parent,name,value,x,y,w,h)
 local item=make("TextButton",parent,{Name=name,Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
  BackgroundColor3=Color3.fromRGB(40,49,61),TextColor3=white,Font=Enum.Font.GothamBold,TextSize=16,BorderSizePixel=0,Selectable=true})
 round(item,12); return item
end
local gui=make("ScreenGui",playerGui,{Name="HoopsSettingsUI",ResetOnSpawn=false,DisplayOrder=30,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets})
local entry=button(gui,"Settings","⚙",20,100,54,54); entry.TextSize=34
local overlay=make("Frame",gui,{Name="Overlay",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=.35,Visible=false,Active=true,BorderSizePixel=0})
local page=make("Frame",overlay,{Name="SettingsPage",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(720,510),BackgroundColor3=Color3.fromRGB(19,25,34),BorderSizePixel=0})
round(page,26)
make("UIStroke",page,{Color=Color3.fromRGB(65,88,92),Thickness=1})
local scale=make("UIScale",page,{Scale=1})
local function fit() scale.Scale=math.min(1,(overlay.AbsoluteSize.X-24)/720,(overlay.AbsoluteSize.Y-24)/510) end
overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit); fit()
label(page,"SETTINGS",26,20,600,36,28).TextXAlignment=Enum.TextXAlignment.Left
label(page,"Your look. Your game.",26,60,360,24,14,muted).TextXAlignment=Enum.TextXAlignment.Left
local close=button(page,"Close","×",650,22,44,44)
local function row(name,x,y)
 local frame=make("Frame",page,{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(322,62),BackgroundColor3=Color3.fromRGB(29,37,48),BorderSizePixel=0}); round(frame,20); return frame
end
local hof=row("HOFEffects",26,104); label(hof,"HOF VFX",16,0,170,62,16).TextXAlignment=Enum.TextXAlignment.Left
local hofButton=button(hof,"Toggle","On",226,12,80,38)
local non=row("NonCollegeEffects",372,104); label(non,"Non-college VFX",16,0,200,62,16).TextXAlignment=Enum.TextXAlignment.Left
local nonButton=button(non,"Toggle","On",226,12,80,38)
local sound=row("Sound",26,180); label(sound,"SFX",16,0,54,62,16)
local bars={}
for i=1,5 do bars[i]=button(sound,"Bar"..i,"",82+(i-1)*34,16,27,30) end
local mute=button(sound,"Mute","0",265,12,40,38)
label(page,"Five steps of sound · 0 to mute",378,188,310,44,14,muted)
label(page,"PLAYER JERSEY",26,258,310,24,15,mint).TextXAlignment=Enum.TextXAlignment.Left
local preview=make("Frame",page,{Name="JerseyPreview",Position=UDim2.fromOffset(38,304),Size=UDim2.fromOffset(136,150),BorderSizePixel=0}); round(preview,16)
local username=label(preview,player.Name,6,16,124,32,13)
local jerseyNumber=label(preview,"23",8,49,120,88,62)
label(page,"COLOR",198,300,100,24,12,muted).TextXAlignment=Enum.TextXAlignment.Left
local swatches={}
for i,color in ipairs(Settings.colors) do
 local swatch=button(page,"Color"..i,"",198+(i-1)*42,332,34,34)
 swatch.BackgroundColor3=Color3.fromRGB(table.unpack(color.rgb)); swatches[i]=swatch
end
local colorName=label(page,"Mint",198,375,330,24,14,muted); colorName.TextXAlignment=Enum.TextXAlignment.Left
label(page,"NUMBER",560,300,120,24,12,muted)
local number=make("TextBox",page,{Name="JerseyNumber",Text="23",PlaceholderText="00–99",ClearTextOnFocus=false,Position=UDim2.fromOffset(562,332),Size=UDim2.fromOffset(116,54),BackgroundColor3=Color3.fromRGB(40,49,61),TextColor3=white,TextSize=28,Font=Enum.Font.GothamBold,BorderSizePixel=0}); round(number)
label(page,"Name uses your Roblox username",198,411,480,28,14,muted).TextXAlignment=Enum.TextXAlignment.Left
local status=label(page,"Loading settings…",26,462,486,30,13,muted); status.TextXAlignment=Enum.TextXAlignment.Left
local save=button(page,"Save","Save changes",536,454,158,40)
local function render()
 hofButton.Text=data.hofVFX and "On" or "Off"; nonButton.Text=data.nonCollegeVFX and "On" or "Off"
 hofButton.TextColor3=data.hofVFX and mint or muted; nonButton.TextColor3=data.nonCollegeVFX and mint or muted
 for i,bar in ipairs(bars) do bar.BackgroundColor3=i<=data.sfx and mint or Color3.fromRGB(56,65,76) end
 mute.TextColor3=data.sfx==0 and mint or muted
 for i,swatch in ipairs(swatches) do swatch.Text=i==data.color and "✓" or ""; swatch.TextColor3=(i==5 or i==6) and Color3.new() or white end
 preview.BackgroundColor3=Color3.fromRGB(table.unpack(Settings.colors[data.color].rgb))
 local ink=(data.color==5 or data.color==6) and Color3.fromRGB(20,26,36) or white
 username.TextColor3=ink; jerseyNumber.TextColor3=ink; jerseyNumber.Text=data.number; number.Text=data.number
 colorName.Text=Settings.colors[data.color].name
end
local function changed() render(); status.Text="Unsaved changes" end
hofButton.Activated:Connect(function() if ready and not pending then data.hofVFX=not data.hofVFX; changed() end end)
nonButton.Activated:Connect(function() if ready and not pending then data.nonCollegeVFX=not data.nonCollegeVFX; changed() end end)
for i,bar in ipairs(bars) do bar.Activated:Connect(function() if ready and not pending then data.sfx=i; changed() end end) end
mute.Activated:Connect(function() if ready and not pending then data.sfx=0; changed() end end)
for i,swatch in ipairs(swatches) do swatch.Activated:Connect(function() if ready and not pending then data.color=i; changed() end end) end
local function readNumber()
 if not number.Text:match("^%d%d?$") then status.Text="Use a jersey number from 00 to 99."; return false end
 data.number=number.Text; return true
end
number.FocusLost:Connect(function() if ready and not pending and readNumber() then changed() end end)
local function request(saving)
 if pending then return end
 if saving and not readNumber() then return end
 pending=true; save.Text="Please wait…"; status.Text=saving and "Saving…" or "Loading settings…"
 local ok,result=pcall(function()
  local remote=ReplicatedStorage:WaitForChild("HoopsPlayerSettings",10)
  if not remote then error("Unavailable") end
  return remote:InvokeServer(saving and data or nil)
 end)
 pending=false
 if ok and result.code=="OK" then
  data=result.settings; ready=true; render(); status.Text=result.preview and "Applied · Studio session only" or "Saved"
 else status.Text="Could not "..(saving and "save" or "load")..". Press "..(ready and "Save changes" or "Retry").." to try again." end
 save.Text=ready and "Save changes" or "Retry"
end
save.Activated:Connect(function() request(ready) end)
local main,wasEnabled
local function visibility()
 local root=playerGui:FindFirstChild("CollegeHoopsUI")
 entry.Visible=not playerGui:GetAttribute("HoopsPanel") and not (root and root:GetAttribute("PanelOpen"))
end
entry.Activated:Connect(function()
 if playerGui:GetAttribute("HoopsPanel") then return end
 main=playerGui:FindFirstChild("CollegeHoopsUI"); if main then wasEnabled=main.Enabled; main.Enabled=false end
 playerGui:SetAttribute("HoopsPanel","Settings"); overlay.Visible=true; MenuFocus.select(close)
 if not ready then task.spawn(request,false) end
end)
local function closePage()
 if not overlay.Visible then return end
 overlay.Visible=false; if main and main.Parent then main.Enabled=wasEnabled end
 playerGui:SetAttribute("HoopsPanel",nil); MenuFocus.select(entry)
end
local replay=button(page,"ReplayTutorial","Replay tutorial",440,62,190,32)
replay.Activated:Connect(function()
 closePage()
 playerGui:SetAttribute("HoopsTutorialReplay",(playerGui:GetAttribute("HoopsTutorialReplay") or 0)+1)
end)
close.Activated:Connect(closePage)
UserInputService.InputBegan:Connect(function(input,processed)
 if not processed and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB) then closePage() end
end)
playerGui:GetAttributeChangedSignal("HoopsPanel"):Connect(visibility)
local function bindMain(root) if root.Name=="CollegeHoopsUI" then root:GetAttributeChangedSignal("PanelOpen"):Connect(visibility); visibility() end end
playerGui.ChildAdded:Connect(bindMain); for _,root in ipairs(playerGui:GetChildren()) do bindMain(root) end
render(); visibility()
