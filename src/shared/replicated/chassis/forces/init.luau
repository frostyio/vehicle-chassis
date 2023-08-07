local types = require(script.Parent.types)
local Wheel = require(script.wheel)

--

type ForcesProto = {
	root: BasePart,
	center: Attachment,
	force: VectorForce,

	config: types.VehicleConfig,
	wheels: { [string]: Wheel.Wheel },
}

local Forces = {}
Forces.__index = Forces
export type Forces = typeof(Forces) & ForcesProto

function Forces.new(root: BasePart, config: types.VehicleConfig, raycastParams: RaycastParams): Forces
	local centerAttachment = root:WaitForChild("Center") :: Attachment

	local nWheels = 0
	for _ in config.wheels do
		nWheels += 1
	end

	local wheels = {}
	for name, wheelConfig in config.wheels do
		local attachment = root:FindFirstChild(name)
		assert(attachment, "could not find wheel attachment")

		wheels[name] = Wheel.new(root, attachment, wheelConfig, nWheels, centerAttachment.Position, raycastParams)
	end

	local centerForce = Instance.new("VectorForce")
	centerForce.Attachment0 = centerAttachment
	centerForce.RelativeTo = Enum.ActuatorRelativeTo.World
	centerForce.Parent = centerAttachment

	return setmetatable(
		{ root = root, center = centerAttachment, force = centerForce, config = config, wheels = wheels } :: Forces,
		Forces
	)
end

function Forces.updateWheels(self: Forces, dt: number)
	for _, wheel in self.wheels do
		wheel:step(dt)
	end
end

function Forces.calculateReferenceArea(self: Forces, surface: Vector3): number
	local size = self.root.Size
	local x, y, z = size.X, size.Y, size.Z
	return if surface == Vector3.xAxis
		then x * y
		elseif surface == Vector3.zAxis then z * y
		elseif surface == Vector3.yAxis then x * z
		else 0
end

function Forces.downForce(self: Forces): Vector3
	local dir = self.root.CFrame.UpVector
	return -dir * self.root.AssemblyLinearVelocity:Dot(dir) * self.config.downforceCoefficient
end

function Forces.dragForce(_self: Forces): Vector3
	-- local dir = self.root.CFrame.LookVector
	-- return -dir * self.root.AssemblyLinearVelocity:Dot(dir) * self.config.dragCoefficient
	return Vector3.zero
end

function Forces.lateralForce(self: Forces): Vector3
	local dir = self.root.CFrame.RightVector
	return -dir * self.root.AssemblyLinearVelocity:Dot(dir) * self.config.lateralCoefficient
end

function Forces.step(self: Forces, dt: number)
	self:updateWheels(dt)

	-- self.force.Force = (self:dragForce() + self:lateralForce() + self:downForce()) / dt * self.root.AssemblyMass
	self.force.Force = self:dragForce() / dt * self.root.AssemblyMass
end

function Forces.Destroy(self: Forces)
	for _, wheel in self.wheels do
		wheel:Destroy()
	end
	self.force:Destroy()
end

return Forces
