local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assets = ReplicatedStorage:WaitForChild("assets")
local smokeEmitter = assets:WaitForChild("Smoke")
local tire_trail = assets:WaitForChild("tire_trail")

local sounds = ReplicatedStorage:WaitForChild("sounds")
local tire_squeal = sounds:WaitForChild("tire_squeal")

local Chassis = require(script.Parent.Parent) -- oo spooky cyclic

-- local util = Chassis.util
local types = require(script.Parent.Parent:WaitForChild("types"))

--

local slipRatioThreshold = 0.2
-- local slipAngleThreshold = 15
local velocityThreshold = 3
local smokeMagnitude = 15

local function calculateSlipAngle(velocity: Vector3, forwardVector: Vector3): number
	local forwardVelocity = velocity:Dot(forwardVector)
	local sideVelocity = velocity.Magnitude * forwardVector.Magnitude
	return math.atan2(sideVelocity, forwardVelocity * (180 / math.pi))
end

local function calculateSlipRatio(
	tireSpeed: number,
	vehicleSpeed: number,
	tireRotationSpeed: number,
	tireRadius: number
): number
	local tireLinearSpeed = tireSpeed * math.pi * 2 * tireRadius
	local tireRotationalLinearSpeed = tireRotationSpeed * math.pi * 2 * tireRadius
	return (tireLinearSpeed - (vehicleSpeed + tireRotationalLinearSpeed)) / tireLinearSpeed
end

--

type PluginProto = {
	chassis: Chassis.Chassis,
	wheelSmokes: { [Instance]: ParticleEmitter },
	attachments: { [Instance]: Attachment },
	wheelTrails: { [Instance]: Trail },
	destroyed: boolean,
}

local plugin = {}
plugin.__index = plugin
type plugin = typeof(plugin) & PluginProto

function plugin.new(chassis: Chassis.Chassis): plugin
	local wheelSmokes = {}
	local attachments = {}
	local trails = {}

	for _, wheel in chassis.wheels:GetChildren() do
		local smoke = smokeEmitter:Clone()
		smoke.Parent = wheel
		wheelSmokes[wheel] = smoke

		local attach0 = Instance.new("Attachment")
		local attach1 = Instance.new("Attachment")

		attach0.Name = "WheelTrail0"
		attach1.Name = "WheelTrail1"

		attach0.Parent = wheel
		attach1.Parent = wheel

		local trail = tire_trail:Clone() :: Trail
		trail.Attachment0 = attach0
		trail.Attachment1 = attach1
		trail.Parent = wheel

		attachments[wheel] = { attach0, attach1 }
		trails[wheel] = trail
	end

	local self = setmetatable({
		chassis = chassis,
		wheelSmokes = wheelSmokes,
		attachments = attachments,
		wheelTrails = trails,
		destroyed = false,
	} :: PluginProto, plugin)

	chassis.sound:loadSound("tire_squeal", {
		name = "tire_sqeual",
		object = tire_squeal,
		pitch = { min = 0.2, max = 0.2 },
	} :: types.VehicleSound)
	chassis.sound:adjustVolume("tire_squeal", 0)
	chassis.sound:playSound("tire_squeal")
	chassis.sound:adjustPitch("tire_squeal")

	return self
end

function plugin.step(self: plugin, _state: types.ChassisState, _dt: number)
	if self.destroyed then
		return
	end

	local chassis = self.chassis
	local forwardVector = chassis.root.CFrame.LookVector
	local velocity = chassis.velocity
	local velVal = velocity.Magnitude > velocityThreshold and 1 or 0

	local highestRatio, highestAngle = 0, 0

	for _, wheel in chassis.wheels:GetChildren() do
		local tireSpeed = wheel.AssemblyLinearVelocity.Magnitude
		local tireRotationalSpeed = wheel.AssemblyAngularVelocity.Magnitude
		local tireRadius = wheel.Size.Y / 2

		local slipAngle = calculateSlipAngle(velocity, forwardVector)
		local slipRatio = calculateSlipRatio(tireSpeed, velocity.Magnitude, tireRotationalSpeed, tireRadius)

		local smoke = self.wheelSmokes[wheel]
		smoke.Rate = (slipRatio > slipRatioThreshold and slipRatio * smokeMagnitude or 0) * velVal

		local attachs = self.attachments[wheel]
		local attach0, attach1 = attachs[1], attachs[2]

		local offsetX, offsetY = wheel.Size.X / 4, wheel.Size.Y / 2 - 0.1
		attach0.WorldCFrame = wheel.CFrame + Vector3.new(-offsetX, -offsetY, 0)
		attach1.WorldCFrame = wheel.CFrame + Vector3.new(offsetX, -offsetY, 0)

		self.wheelTrails[wheel].Enabled = highestRatio > slipRatioThreshold and velVal == 1

		highestRatio = math.max(highestRatio, slipRatio)
		highestAngle = math.max(highestAngle, slipAngle)
	end

	local volume = math.min(0.4, math.abs(highestRatio) / slipRatioThreshold)
		* (highestRatio > slipRatioThreshold and 1 or 0)
		* velVal
	chassis.sound:adjustVolume("tire_squeal", volume)

	-- print(("highest slip ratio: %.2f, velocity: %.2f, velVal: %s"):format(highestRatio, velocity.Magnitude, velVal))
end

function plugin.destroy(self: plugin)
	for _, attachs in self.attachments do
		attachs[1]:Destroy()
		attachs[2]:Destroy()
	end
	self.attachments = {}
	for _, smoke in self.wheelSmokes do
		smoke:Destroy()
	end
	self.wheelSmokes = {}
	for _, trail in self.wheelTrails do
		trail:Destroy()
	end
	self.wheelTrails = {}
	self.destroyed = true
	-- does chassis get cleaned up now?
end

return plugin
