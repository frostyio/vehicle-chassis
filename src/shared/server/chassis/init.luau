local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local replicatedShared = ReplicatedStorage:WaitForChild("shared")
local chassis = require(replicatedShared:WaitForChild("chassis"))
local types = require(replicatedShared.chassis.types)

--

type ChassisProto = {
	vehicle: Model,
	wheels: Folder,
	root: BasePart,
	seat: VehicleSeat,
	prompt: ProximityPrompt,
	config: types.VehicleConfig,
	lastCharacter: Model?,
}

local Chassis = {}
Chassis.__index = Chassis
export type Chassis = typeof(Chassis) & ChassisProto

--

local enterPrompt = Instance.new("ProximityPrompt")
enterPrompt.Name = "EnterPrompt"
enterPrompt.KeyboardKeyCode = Enum.KeyCode.F
enterPrompt.ActionText = "Enter"
enterPrompt.RequiresLineOfSight = false
enterPrompt.HoldDuration = 0.6

local enterPrompts: { [ProximityPrompt]: Chassis } = {}

local function weldModel(root: BasePart, model: Instance)
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") or root == part then
			continue
		end

		local constraint = Instance.new("WeldConstraint")
		constraint.Part0 = root
		constraint.Part1 = part
		constraint.Parent = part

		part.Anchored = false
	end
end

--

function Chassis.new(vehicle: Model): Chassis
	local wheels, base, seat, config = chassis.util.getComponents(vehicle)

	local self = setmetatable({
		vehicle = vehicle,
		wheels = wheels,
		root = base,
		seat = seat,
		config = config,
	} :: ChassisProto, Chassis)

	self:weldBody()
	self:createConstraints()
	self:createFlip()
	self:createEnterPrompt()
	-- base.Anchored = true

	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		self:occupantChanged(seat.Occupant)
	end)

	base.Destroying:Connect(function()
		self.destroy()
	end)

	vehicle.Destroying:Connect(function()
		self.destroy()
	end)

	base.Anchored = false

	return self
end

function Chassis.createConstraints(self: Chassis)
	local constraints = Instance.new("Folder")
	constraints.Name = "Constraints"

	for _, wheel in self.wheels:GetChildren() do
		local name = wheel.Name

		-- attachments
		local baseAttachment = Instance.new("Attachment")
		local wheelAttachment = Instance.new("Attachment")

		baseAttachment.Name = name
		baseAttachment.CFrame = self.root.CFrame:ToObjectSpace(wheel.CFrame)
			* CFrame.Angles(0, math.rad(180), math.rad(90))

		wheelAttachment.Name = name

		baseAttachment.Parent = self.root
		wheelAttachment.Parent = wheel

		-- constraints
		local cylindrical = Instance.new("CylindricalConstraint")
		local spring = Instance.new("SpringConstraint")

		spring.LimitsEnabled = true

		cylindrical.Name = name .. "C"
		spring.Name = name .. "S"

		cylindrical.Attachment0 = baseAttachment
		spring.Attachment0 = baseAttachment

		cylindrical.Attachment1 = wheelAttachment
		spring.Attachment1 = wheelAttachment

		cylindrical.Parent = constraints
		spring.Parent = constraints

		-- config
		cylindrical.InclinationAngle = 90
		cylindrical.LimitsEnabled = true

		local cylConfig = self.config.cylindrical[name]
		local sprConfig = self.config.springs[name]

		cylindrical.AngularActuatorType = cylConfig.angularActuator or Enum.ActuatorType.None
		cylindrical.UpperLimit = cylConfig.upperLimit
		cylindrical.LowerLimit = cylConfig.lowerLimit
		cylindrical.MotorMaxTorque = cylConfig.maxTorque

		spring.Damping = sprConfig.damping
		spring.Stiffness = sprConfig.stiffness
		spring.FreeLength = sprConfig.freeLength

		weldModel(wheel, wheel)
		wheel.Anchored = false
	end

	constraints.Parent = self.vehicle
end

function Chassis.weldBody(self: Chassis)
	local body = self.vehicle:FindFirstChild("Body")
	if not body then
		return
	end

	weldModel(self.root, body)
end

function Chassis.createFlip(self: Chassis)
	local centerAttachment = Instance.new("Attachment")
	centerAttachment.Name = "Center"
	centerAttachment.Parent = self.root

	local alignment = Instance.new("AlignOrientation")
	alignment.Enabled = false
	alignment.MaxTorque = math.huge
	alignment.Responsiveness = 1
	alignment.MaxAngularVelocity = 10
	alignment.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignment.Attachment0 = centerAttachment
	alignment.CFrame = CFrame.new()
	alignment.Name = "Flip"
	alignment.Parent = self.root
end

function Chassis.occupantChanged(self: Chassis, occupant: Humanoid?)
	if occupant then
		local character = occupant.Parent
		self.lastCharacter = character
		local player = Players:GetPlayerFromCharacter(character)
		if player == nil then
			warn("could not find player to humanoid")
			return
		end

		self.root.Anchored = false
		self.root:SetNetworkOwner(player)
		self.prompt.Enabled = false
	else
		self.root:SetNetworkOwner(nil)
		-- self.root.Anchored = true
		self.prompt.Enabled = true

		if self.lastCharacter then
			chassis.util.setMassless(self.lastCharacter, false)
		end
	end
end

function Chassis.createEnterPrompt(self: Chassis)
	local prompt = enterPrompt:Clone()
	prompt.Parent = self.root

	self.prompt = prompt
	enterPrompts[prompt] = self
end

function Chassis.handleEnterPrompt(self: Chassis, player: Player)
	local character = player.Character
	if character == nil then
		return
	end

	chassis.util.setMassless(character, true)
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	self.seat:Sit(humanoid)
end

function Chassis.destroy(self: Chassis)
	enterPrompts[self.prompt] = nil
	self.vehicle:Destroy()
end

-- handle enter prompts

local function handleEnterPrompt(prompt: ProximityPrompt, player: Player)
	local promptChassis = enterPrompts[prompt]

	if promptChassis == nil then
		return
	end

	promptChassis:handleEnterPrompt(player)
end

ProximityPromptService.PromptTriggered:Connect(handleEnterPrompt)

return Chassis
