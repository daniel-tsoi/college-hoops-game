-- One hover/focus panel shared by lineup, regular candidates, and rare cards.
local Hover = {}
function Hover.mount(canvas)
	local panel = Instance.new("TextLabel")
	panel.Name = "ChemistryPreview"
	panel.Position = UDim2.fromOffset(340, 275)
	panel.Size = UDim2.fromOffset(750, 184)
	panel.BackgroundColor3 = Color3.fromRGB(16, 25, 38)
	panel.TextColor3 = Color3.fromRGB(232, 245, 255)
	panel.Font = Enum.Font.GothamMedium
	panel.TextSize = 17
	panel.TextWrapped = true
	panel.ZIndex = 30
	panel.Visible = false
	panel.Parent = canvas
	local corner = Instance.new("UICorner"); corner.Parent = panel
	local entries, active = {}, nil
	local view = {}
	function view.hide() active = nil; panel.Visible = false end
	function view.bind(button, getText)
		if entries[button] then entries[button] = getText; return end
		entries[button] = getText
		local function show()
			local text = entries[button]()
			active = button; panel.Text = text or ""; panel.Visible = text ~= nil
		end
		local function hide() if active == button then view.hide() end end
		button.MouseEnter:Connect(show)
		button.MouseLeave:Connect(hide)
		button.SelectionGained:Connect(show)
		button.SelectionLost:Connect(hide)
	end
	return view
end
return Hover
