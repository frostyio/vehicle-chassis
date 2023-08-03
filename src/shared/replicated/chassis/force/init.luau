-- handles all the forces for a vehicle
-- i.e. suspension, torque, etc

-- local types = require(script.Parent:WaitForChild("types"))
local Wheel = require(script.wheel)

local function calculateWheelTrackAndBase(wheels: Folder): (number, number)
	local frontLeft = wheels:FindFirstChild("FL")
	local frontRight = wheels:FindFirstChild("FR")
	local backLeft = wheels:FindFirstChild("BL")
	assert(frontLeft and frontRight and backLeft, "Could not find needed wheels")

	return (frontLeft.Position - frontRight.Position).Magnitude, (frontLeft.Position - backLeft.Position).Magnitude
end

--

type ForceProto = {
	root: BasePart,
	wheels: { [string]: Wheel.Wheel },

	wheelTrack: number,
	wheelBase: number,

	lastVelocity: Vector3,
	raycastParams: RaycastParams,
}

local Force = {}
Force.__index = Force
export type Force = typeof(Force) & ForceProto

function Force.new(wheelsFolder: Folder, root: BasePart): Force
	local wheelTrack, wheelBase = calculateWheelTrackAndBase(wheelsFolder)

	local wheels = {}
	for _, wheel in wheelsFolder:GetChildren() do
		wheels[wheel.Name] = Wheel.new(wheel, root, wheelTrack, wheelBase)
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { root.Parent }

	local self = setmetatable({
		root = root,
		wheels = wheels,
		wheelTrack = wheelTrack,
		wheelBase = wheelBase,
		lastVelocity = Vector3.new(),
		raycastParams = params,
	} :: ForceProto, Force)

	return self
end

function Force.step(self: Force, dt: number)
	local currentVelocity = self.root.CFrame:VectorToObjectSpace(self.root.AssemblyLinearVelocity)
		* Vector3.new(1, 0, 1)
	local acceleration: Vector3 = (currentVelocity - self.lastVelocity) / dt
	acceleration = Vector3.new(math.clamp(acceleration.X, -75, 75), 0, math.clamp(acceleration.Z, -20, 20))
	self.lastVelocity = currentVelocity

	local castLength = 3 * 1.2
	local massPoint = self.root.CFrame:PointToWorldSpace(self.root.CenterOfMass)
	local centreOfGravityCast =
		workspace:Raycast(massPoint, -self.root.CFrame.UpVector * castLength, self.raycastParams)
	local centerOfGravityHeight = centreOfGravityCast and (massPoint - centreOfGravityCast.Position).Magnitude
		or castLength

	for _, wheel in self.wheels do
		wheel:step(dt, acceleration, centerOfGravityHeight)
	end
end

function Force.destroy(_self: Force) end

return Force
