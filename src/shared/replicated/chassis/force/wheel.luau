-- local types = require(script.Parent.Parent:WaitForChild("types"))

--

type WheelProto = {
	springLoad: number,
	wheelTrack: number,
	wheelBase: number,
	offsetX: number,
	offsetZ: number,

	root: BasePart,
	wheelPart: BasePart,
	raycastParams: RaycastParams,

	springAttachment: Attachment,
	attachment: Attachment,

	springLength: number,
	freeSuspensionLength: number,
	maxSuspensionLength: number,

	force: VectorForce,
	beam: Beam,

	radius: number,
}

local Wheel = {}
Wheel.__index = Wheel
export type Wheel = typeof(Wheel) & WheelProto

local maxSuspensionLength = 3
local freeSuspensionLength = 2
local numberOfWheels = 4
local damperStiffness = 1
local kMult = 3

local noHitColor, hitColor = Color3.fromHex("#03fc5a"), Color3.fromHex("#fc0352")

function Wheel.new(wheelPart: BasePart, root: BasePart, wheelTrack: number, wheelBase: number): Wheel
	local name = wheelPart.Name

	local attachment, springAttachment, force
	if 1 == 2 then
		attachment = Instance.new("Attachment") -- my X_X_Point
		springAttachment = Instance.new("Attachment") -- my X_X_Spring

		attachment.Name = `{name}`
		springAttachment.Name = `{name}_Spring`

		attachment.Visible = true
		springAttachment.Visible = true

		attachment.CFrame = wheelPart.CFrame:ToObjectSpace(root.CFrame)
		springAttachment.CFrame = wheelPart.CFrame:ToObjectSpace(root.CFrame)

		attachment.Parent = root
		springAttachment.Parent = root

		force = Instance.new("VectorForce")
		force.Attachment0 = attachment
		force.Parent = attachment
	else
		attachment = root:FindFirstChild(name)
		springAttachment = root:FindFirstChild(`{name}_Spring`)
		force = attachment:FindFirstChildOfClass("VectorForce")
	end

	local springLoad = root.AssemblyMass / numberOfWheels -- hard coded 4 wheels
	local centerOfMass = root.CenterOfMass
	local x = (wheelTrack - math.abs(centerOfMass.X + springAttachment.Position.X))
		* math.sign(springAttachment.Position.X)
	local z = (wheelBase - math.abs(centerOfMass.Z - springAttachment.Position.Z))
		* math.sign(springAttachment.Position.Z)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { root.Parent }

	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment
	beam.Attachment1 = springAttachment
	beam.FaceCamera = true
	beam.Width0 = 0.2
	beam.Width1 = 0.2
	beam.Parent = workspace

	local self = setmetatable({
		springLoad = springLoad,
		wheelTrack = wheelTrack,
		wheelBase = wheelBase,
		offsetX = x,
		offsetZ = z,

		root = root,
		wheelPart = wheelPart,
		raycastParams = params,

		attachment = attachment,
		springAttachment = springAttachment,

		springLength = maxSuspensionLength,
		freeSuspensionLength = freeSuspensionLength,
		maxSuspensionLength = maxSuspensionLength,

		force = force,
		beam = beam,
		radius = wheelPart.Size.Y / 2,
	} :: WheelProto, Wheel)

	return self
end

function Wheel.step(self: Wheel, dt: number, acceleration: Vector3, centerOfGravityHeight: number)
	local dir = -self.root.CFrame.UpVector * self.maxSuspensionLength
	local raycast = workspace:Raycast(self.attachment.WorldPosition, dir, self.raycastParams)

	local newSpringLength = self.maxSuspensionLength
	local newSpringPosition = self.attachment.WorldPosition
		- self.root.CFrame.UpVector * (self.maxSuspensionLength - self.radius)

	if raycast then
		newSpringLength = (self.attachment.WorldPosition - raycast.Position).Magnitude
		newSpringPosition = raycast.Position + self.root.CFrame.UpVector * self.radius
		self.beam.Color = ColorSequence.new(hitColor)
	else
		self.beam.Color = ColorSequence.new(noHitColor)
	end

	local gravity = workspace.Gravity

	local dx = (newSpringLength - self.springLength) / dt
	self.springLength = newSpringLength

	local mass = self.root.AssemblyMass
	local baseMass = math.abs(self.offsetX / self.wheelTrack * self.offsetZ / self.wheelBase) * mass
	local accelerationForce = (
		(centerOfGravityHeight / self.wheelTrack) * acceleration.X * math.sign(self.offsetX)
		+ (centerOfGravityHeight / self.wheelBase) * acceleration.Z * math.sign(self.offsetZ)
	) * mass
	local wheelForce = baseMass * gravity - accelerationForce

	--
	local springD = 2 * math.sqrt(baseMass * gravity * self.springLoad + accelerationForce) * damperStiffness
	local springK = wheelForce * (self.freeSuspensionLength - newSpringLength) * kMult
	local springF = springK - springD * dx

	local normal = if raycast then raycast.Normal else Vector3.zero
	local force = self.root.CFrame:VectorToObjectSpace(normal * springF)
	self.force.Force = force
	self.springAttachment.CFrame = self.root.CFrame:ToObjectSpace(
		CFrame.lookAt(newSpringPosition, newSpringPosition + self.root.CFrame.LookVector, self.root.CFrame.UpVector)
	)
	self.wheelPart.CFrame = self.springAttachment.WorldCFrame
end

function Wheel.destroy(_self: Wheel) end

return Wheel
