local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
if player.UserId~=1123697419 then return end
local pg=player:WaitForChild("PlayerGui")
local settings=pg:WaitForChild("HoopsSettingsUI")
local settingsPage=settings:WaitForChild("Overlay"):WaitForChild("SettingsPage")
local function make(kind,parent,props)
 local item=Instance.new(kind)
 for key,value in pairs(props) do item[key]=value end
 item.Parent=parent
 return item
end
local white=Color3.fromRGB(240,245,248)
local function button(parent,name,value,position,size)
 local b=make("TextButton",parent,{Name=name,Text=value,Position=position,Size=size,BackgroundColor3=Color3.fromRGB(34,83,62),TextColor3=white,TextSize=16,Font=Enum.Font.GothamBold,BorderSizePixel=0})
 make("UICorner",b,{CornerRadius=UDim.new(0,10)})
 return b
end
local entry=button(settingsPage,"CreatorSettings","CREATOR GIFTS",UDim2.fromOffset(460,65),UDim2.fromOffset(180,28))
local gui=make("ScreenGui",pg,{Name="HoopsCreatorSettings",DisplayOrder=45,ResetOnSpawn=false,Enabled=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets})
local overlay=make("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=.25,Active=true})
local page=make("Frame",overlay,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(580,500),BackgroundColor3=Color3.fromRGB(19,25,34),BorderSizePixel=0})
make("UICorner",page,{CornerRadius=UDim.new(0,20)})
local scale=make("UIScale",page,{Scale=1})
local function fit() scale.Scale=math.min(1,(overlay.AbsoluteSize.X-24)/580,(overlay.AbsoluteSize.Y-24)/500) end
overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit);fit()
local function label(text,y,h,size)
 return make("TextLabel",page,{Text=text,Position=UDim2.fromOffset(24,y),Size=UDim2.fromOffset(532,h),BackgroundTransparency=1,TextColor3=white,TextSize=size or 15,Font=Enum.Font.GothamBold,TextWrapped=true})
end
label("CREATOR GIFTS",20,32,25)
label("Unlimited cash · unlimited actions · 50× luck",55,25,15)
label("Gift a player in this server using their exact username.",84,30,14)
local boxes={}
local function field(key,title,y,default)
 label(title,y,24,14).TextXAlignment=Enum.TextXAlignment.Left
 boxes[key]=make("TextBox",page,{Name=key,Text=default,PlaceholderText=key=="username" and "Roblox username (not display name)" or "0",ClearTextOnFocus=false,Position=UDim2.fromOffset(24,y+25),Size=UDim2.fromOffset(532,34),BackgroundColor3=Color3.fromRGB(35,45,58),TextColor3=white,TextSize=16,Font=Enum.Font.Gotham,BorderSizePixel=0})
end
field("username","RECIPIENT",120,"")
field("cash","CASH · up to 1 trillion",182,"0")
field("rerolls","REROLLS · up to 1 million",244,"0")
field("refreshes","REFRESHES · up to 1 million",306,"0")
local status=label("Unused gifts stay saved until spent.",369,53,13)
local send=button(page,"SendGift","SEND GIFT",UDim2.fromOffset(24,437),UDim2.fromOffset(350,42))
local close=button(page,"Close","CLOSE",UDim2.fromOffset(390,437),UDim2.fromOffset(166,42))
local pending=false
local retryRequest,previousPanel
entry.Activated:Connect(function()
 previousPanel=pg:GetAttribute("HoopsPanel")
 pg:SetAttribute("HoopsPanel","CreatorGifts")
 gui.Enabled=true
end)
close.Activated:Connect(function()
 gui.Enabled=false
 if pg:GetAttribute("HoopsPanel")=="CreatorGifts" then pg:SetAttribute("HoopsPanel",previousPanel) end
end)
local messages={FORBIDDEN="Creator access required.",INVALID="Use a username and whole, non-negative amounts within the limits; at least one amount must be positive.",NOT_HERE="That username is not in this server.",BUSY="Server busy. Retry the same gift.",UNAVAILABLE="Save not confirmed. Retry the same gift.",STALE_SESSION="Player changed servers. Rejoin their server to gift them."}
send.Activated:Connect(function()
 if pending then return end
 local request=retryRequest or {requestId=HttpService:GenerateGUID(false),username=boxes.username.Text:match("^%s*(.-)%s*$"),cash=tonumber(boxes.cash.Text),rerolls=tonumber(boxes.rerolls.Text),refreshes=tonumber(boxes.refreshes.Text)}
 pending=true;send.Text="SAVING…";send.Active=false
 for _,box in pairs(boxes) do box.TextEditable=false end
 status.Text="Saving gift for "..request.username.."…"
 local ok,result=pcall(function()
  local remote=ReplicatedStorage:WaitForChild("HoopsCreatorGift",10)
  if not remote then error("Unavailable") end
  return remote:InvokeServer(request)
 end)
 local code=ok and type(result)=="table" and result.code or "UNAVAILABLE"
 local success=code=="GIFTED" or code=="ALREADY_GIFTED"
 if success then
  retryRequest=nil
  status.Text=string.format("%s received $%s, %s rerolls and %s refreshes.%s",result.username,tostring(request.cash),tostring(request.rerolls),tostring(request.refreshes),result.preview and " Studio test only: this session does not save." or " Saved!")
 else
  status.Text=messages[code] or "Gift not confirmed. Retry the same gift."
  if code=="INVALID" or code=="FORBIDDEN" or code=="NOT_HERE" or code=="STALE_SESSION" then retryRequest=nil
  else retryRequest=request end
 end
 pending=false;send.Active=true;send.Text=retryRequest and "RETRY SAME GIFT" or "SEND GIFT"
 for _,box in pairs(boxes) do box.TextEditable=retryRequest==nil end
end)
