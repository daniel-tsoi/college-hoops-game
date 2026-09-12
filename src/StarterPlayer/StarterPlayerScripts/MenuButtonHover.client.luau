local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local Motion = require(script.Parent:WaitForChild("CardMotion"))
local entries = {
 HoopsShopUI = {Shop=true}, HoopsCollectionUI = {Collection=true,GoldCards=true},
 HoopsBestTeamUI = {BestTeam=true}, HoopsQuestsUI = {Quests=true},
 HoopsLeaderboardUI = {Leaderboard=true},
}
local function attach(object)
 if not object:IsA("GuiButton") then return end
 local gui=object:FindFirstAncestorOfClass("ScreenGui")
 if gui and (gui.Name=="CollegeHoopsUI" or (object.Parent==gui and entries[gui.Name] and entries[gui.Name][object.Name])) then
  Motion.attach(object,true)
 end
end
playerGui.DescendantAdded:Connect(attach)
for _,object in ipairs(playerGui:GetDescendants()) do attach(object) end
