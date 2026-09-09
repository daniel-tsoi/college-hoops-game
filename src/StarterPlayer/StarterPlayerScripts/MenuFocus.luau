-- Only controller navigation needs a selected GUI button. Keyboard selection
-- consumes character movement and jump input, even after a menu closes.
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local function usingGamepad()
	return UserInputService:GetLastInputType().Name:match("^Gamepad") ~= nil
end

local function clearKeyboardFocus()
	local selected = GuiService.SelectedObject
	if not usingGamepad() and selected and selected:IsDescendantOf(playerGui) then
		GuiService.SelectedObject = nil
	end
end

local function updateInputMode()
	GuiService.AutoSelectGuiEnabled = usingGamepad()
	clearKeyboardFocus()
end

UserInputService.LastInputTypeChanged:Connect(updateInputMode)
GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(clearKeyboardFocus)
updateInputMode()

local MenuFocus = {}
function MenuFocus.select(button)
	GuiService.SelectedObject = usingGamepad() and button or nil
end

return MenuFocus
