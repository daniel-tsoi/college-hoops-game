local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Chemistry = require(shared:WaitForChild("TeamChemistry"))
local Geometry = require(shared:WaitForChild("ChemistryLineGeometry"))
local Lines = {}
local colors = {
	School = Color3.fromRGB(88, 205, 127),
	Year = Color3.fromRGB(237, 207, 86),
	Both = Color3.fromRGB(94, 176, 255),
	-- Rare tiers: purple between Hall of Famers, red between non-college
	-- players, and amber where the two meet.
	HOF = Color3.fromRGB(178, 124, 255),
	NonCollege = Color3.fromRGB(247, 111, 124),
	Cross = Color3.fromRGB(255, 164, 86),
}
-- Both lineup canvases use fixed design coordinates and a parent UIScale.
function Lines.mount(parent, cards, blockers)
	local layer = Instance.new("Frame")
	layer.Name = "ChemistryConnections"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.ZIndex = 1
	layer.Parent = parent
	for _, card in ipairs(cards) do card.ZIndex = math.max(card.ZIndex, 2) end
	local function rectangle(object, padding)
		local size = Vector2.new(object.Size.X.Offset + object.Size.X.Scale * parent.Size.X.Offset,
			object.Size.Y.Offset + object.Size.Y.Scale * parent.Size.Y.Offset)
		local point = Vector2.new(object.Position.X.Offset + object.Position.X.Scale * parent.Size.X.Offset,
			object.Position.Y.Offset + object.Position.Y.Scale * parent.Size.Y.Offset)
		local origin = point - size * object.AnchorPoint
		return {x = origin.X - padding, y = origin.Y - padding, w = size.X + padding * 2, h = size.Y + padding * 2}
	end
	local view = {}
	function view.render(players)
		layer:ClearAllChildren()
		local rectangles, centers = {}, {}
		for i, card in ipairs(cards) do
			local r = rectangle(card, 4)
			table.insert(rectangles, r)
			centers[i] = Vector2.new(r.x + r.w / 2, r.y + r.h / 2)
		end
  -- Best Team mounts a sixth frame for the sixth man, so this counts at least
  -- five rather than exactly five. isFull only ever inspects the starters.
  if #cards >= 5 and Chemistry.isFull(players) then
   local center = Vector2.zero
   for _, point in ipairs(centers) do center += point end
   center /= 5
   local badge = Instance.new("TextLabel")
   badge.Name = "FullChem"; badge.AnchorPoint = Vector2.new(.5,.5)
   badge.Position = UDim2.fromOffset(center.X,center.Y)
   badge.Size = UDim2.fromOffset(112,112)
   badge.BackgroundColor3 = Color3.fromRGB(12,35,26)
   -- A saved run with a sixth man reads FULL CHEM +1. The sixth is still outside
   -- the rule itself; the badge only notes that the lineup carries one.
   badge.TextColor3 = colors.School
   badge.Text = players[6] and "FULL\nCHEM +1" or "FULL\nCHEM"
   badge.Font = Enum.Font.GothamBlack; badge.TextSize = 22
   badge.BorderSizePixel = 0; badge.Parent = layer
   local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = badge
   local stroke = Instance.new("UIStroke"); stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
   stroke.Color = colors.School; stroke.Thickness = 3; stroke.Parent = badge
   return
  end
		for _, blocker in ipairs(blockers or {}) do table.insert(rectangles, rectangle(blocker, 4)) end
		for i = 1, #cards - 1 do
			for j = i + 1, #cards do
				local kind = Chemistry.link(players[i], players[j])
				if kind then
					local a, b = centers[i], centers[j]
					local delta = b - a
					for part, span in ipairs(Geometry.visible(a.X, a.Y, b.X, b.Y, rectangles)) do
						local middle = a + delta * ((span[1] + span[2]) / 2)
						local line = Instance.new("Frame")
						line.Name = string.format("%s_%d_%d_%d", kind, i, j, part)
						line.AnchorPoint = Vector2.new(0.5, 0.5)
						line.Position = UDim2.fromOffset(middle.X, middle.Y)
						line.Size = UDim2.fromOffset(delta.Magnitude * (span[2] - span[1]), 5)
						line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
						line.BackgroundColor3 = colors[kind]
						line.BackgroundTransparency = 0.2
						line.BorderSizePixel = 0
						line.Parent = layer
					end
				end
			end
		end
	end
	return view
end
function Lines.legend(parent, position, size)
	local label = Instance.new("TextLabel")
	label.Name = "ChemistryLegend"
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.RichText = true
	label.Text = '<font color="#58CD7F">School</font>  ·  <font color="#EDCF56">Year</font>  ·  <font color="#5EB0FF">Both</font>'
		.. '  ·  <font color="#B27CFF">HOF</font>  ·  <font color="#F76F7C">Non-college</font>  ·  <font color="#FFA456">Mixed</font>'
	label.Parent = parent
	return label
end
return Lines
