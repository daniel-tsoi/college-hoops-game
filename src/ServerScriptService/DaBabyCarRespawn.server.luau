-- Keep the existing lobby car available after any number of trips off the map.
local carName = "DaBaby Car [ORIGINAL]"
local car = workspace:WaitForChild(carName, 30)
if not car or not car:IsA("Model") then
	warn("DaBaby car respawn: the lobby car is missing from this place.")
	return
end

local spawnPivot = car:GetPivot()
local originalArchivable = car.Archivable
car.Archivable = true
local template = car:Clone()
car.Archivable = originalArchivable
-- The unparented server-only template cannot fall or execute its vehicle scripts.
template.Parent = nil
local chassis = car:FindFirstChild("Chassis")
assert(chassis and chassis:IsA("BasePart"), "DaBaby car needs its Chassis")
local respawns = 0

local function respawn()
	local previous = car
	local passengers = {}
	for _, seat in ipairs(previous:GetDescendants()) do
		if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
			local humanoid = seat.Occupant
			if humanoid and humanoid.Parent then
				passengers[humanoid.Parent] = humanoid
				humanoid.Sit = false
				local weld = seat:FindFirstChild("SeatWeld")
				if weld then weld:Destroy() end
			end
		end
	end
	-- Destroy the old vehicle before parenting its replacement: exactly one car.
	previous:Destroy()
	car = template:Clone()
	car:PivotTo(spawnPivot)
	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	respawns += 1
	car:SetAttribute("RespawnCount", respawns)
	car.Parent = workspace
	chassis = car:FindFirstChild("Chassis")
	-- Return any seated players alongside the car, clear of its large body.
	for character, humanoid in pairs(passengers) do
		if character.Parent and humanoid.Health > 0 then
			character:PivotTo(spawnPivot * CFrame.new(40, 3, 0))
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
	end
end

while script.Parent do
	task.wait(0.25)
	-- Catch a fall well before FallenPartsDestroyHeight, and also recover if
	-- destruction occurred between checks. The fixed center never follows the car.
	local resetHeight = math.max(spawnPivot.Position.Y - 80, workspace.FallenPartsDestroyHeight + 60)
	if not car:IsDescendantOf(workspace) or not chassis or not chassis:IsDescendantOf(car)
		or chassis.Position.Y < resetHeight or not car:FindFirstChild("DriveSeat") then
		respawn()
	end
end
template:Destroy()
