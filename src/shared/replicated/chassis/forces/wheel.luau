local types = require(script.Parent.Parent.types)
local util = require(script.Parent.Parent.util)

local Raycast, DebugBeam = util.Raycast, util.DebugBeam

--- simplified Pacejka 'magic formula'
local function lateralForceMagicFormula(wheelCF: CFrame, worldVelocity: Vector3): Vector3
	local lateralDirection = wheelCF.RightVector
	local lateralVelocity = lateralDirection:Dot(worldVelocity)
	local forwardVelocity = wheelCF.LookVector:Dot(worldVelocity)
	local slipAngle = math.atan2(lateralVelocity, forwardVelocity)

	local B = 10.0 -- stiffness
	local C = 1.5 -- shape factor
	local D = 10.0 -- peak value

	local lateralForce = D * math.sin(C * math.atan(B * slipAngle))
	return -lateralForce
end

--

type WheelProto = {
	root: BasePart,
	wheelConfig: types.WheelConfig,
	offset: CFrame,
	centerOfMass: Vector3,

	raycast: util.Raycast,
	forwardBeam: util.DebugBeam,
	rightBeam: util.DebugBeam,

	numberOfSprings: number,

	attachment: Attachment,
	force: VectorForce,

	lastTractionForce: Vector3,

	steeringAngle: number,
	rotationX: number,

	currentVelocity: number,
	currentAngularVelocity: number,

	maxTorque: number,
	angularVelocity: number,
}

local Wheel = {}
Wheel.__index = Wheel
export type Wheel = typeof(Wheel) & WheelProto

function Wheel.new(
	root: BasePart,
	attachment: Attachment,
	wheelConfig: types.WheelConfig,
	numberOfSprings: number,
	center: Vector3,
	raycastParams: RaycastParams
): Wheel
	local force = Instance.new("VectorForce")
	force.Attachment0 = attachment
	force.Parent = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World

	return setmetatable({
		root = root,
		offset = attachment.CFrame,
		wheelConfig = wheelConfig,
		raycast = Raycast.new(nil, nil, raycastParams, false),
		numberOfSprings = numberOfSprings,
		centerOfMass = center,

		attachment = attachment,
		force = force,
		lastTractionForce = Vector3.zero,

		steeringAngle = 0,
		rotationX = 0,

		currentVelocity = 0,
		currentAngularVelocity = 0,

		maxTorque = math.huge,
		angularVelocity = 0, -- rad/s

		-- debugs
		forwardBeam = DebugBeam.new(true, util.colors.tertiary),
		rightBeam = DebugBeam.new(true, util.colors.quaternary),
	} :: Wheel, Wheel)
end

function Wheel.getSpringLoad(self: Wheel): number
	-- assumes weight is uniform
	local dist = (self.centerOfMass - self.offset.Position).Magnitude
	local load = self.root.AssemblyMass / self.numberOfSprings
	load += dist / self.numberOfSprings
	return load
end

function Wheel.suspensionForce(self: Wheel, raycast: RaycastResult, worldVelocity: Vector3): Vector3
	local rootCF = self.root.CFrame
	local wheelConfig = self.wheelConfig
	local velocity = self.root.CFrame:VectorToObjectSpace(worldVelocity)
	local springLoad = self:getSpringLoad()

	local offset = wheelConfig.restSuspension - raycast.Distance
	local springForce = offset * workspace.Gravity * wheelConfig.springStiffness
	local dampingForce = velocity.Y * wheelConfig.springDamper
	return rootCF.UpVector * (springForce - dampingForce) * springLoad
end

function Wheel.frictionalForce(self: Wheel, wheelCF: CFrame, _raycast: RaycastResult, worldVelocity: Vector3): Vector3
	local config = self.wheelConfig

	local normalForce = config.wheelMass
	local grip_u_k, grip_u_s = config.grip_u_k, config.grip_u_s
	local rolling_u_k, rolling_u_s = config.rolling_u_k, config.rolling_u_s

	--- calculate slope modifications
	-- local maxAngle = 10
	-- local dot = raycast.Normal:Dot(Vector3.yAxis)
	-- local slopeAngle = math.deg(math.acos(dot))
	-- slopeAngle = if slopeAngle ~= slopeAngle then 0 else slopeAngle -- nan check
	-- local normalizedAngle = math.abs(slopeAngle) / maxAngle
	-- grip_u_s *= (1 - normalizedAngle) -- increase lateral grip on a slope
	-- grip_u_k *= (1 - normalizedAngle)

	---- lateral friction / grip / slip
	local lateralDirection = wheelCF.RightVector
	local lateralVelocity = lateralDirection:Dot(worldVelocity)
	local lateralOpposing = -lateralVelocity * lateralDirection

	local magicFormulaLateralForce = lateralForceMagicFormula(wheelCF, worldVelocity)

	-- local normalGrip_f_n = lateralOpposing * (1 - magicFormulaLateralForce.Magnitude)
	local normalGrip_f_n = lateralDirection * magicFormulaLateralForce
	-- local gripForce = if normalGrip_f_n.Magnitude <= normalForce * grip_u_s
	-- 	then lateralOpposing -- should completely resist movement
	-- 	else normalGrip_f_n * grip_u_k
	local gripForce = if normalGrip_f_n.Magnitude <= grip_u_s
		then lateralOpposing -- should completely resist movement
		else normalGrip_f_n

	----- longitudinal friction / rolling resistance
	local rollingDirection = if worldVelocity.Magnitude ~= 0
		then -worldVelocity.Unit -- Opposite to wheel's velocity
		else Vector3.zero -- prevent NaN

	local rollingVelocity = worldVelocity:Dot(rollingDirection)
	local rollingOpposing = -rollingVelocity * rollingDirection

	local normalRoll_f_n = rollingOpposing
	local rollingResistanceForce = if normalRoll_f_n.Magnitude <= normalForce * rolling_u_s
		then rollingOpposing
		else normalRoll_f_n * rolling_u_k

	return gripForce + rollingResistanceForce
end

function Wheel.accelerationForce(self: Wheel, wheelCF: CFrame, _dt: number): Vector3
	local linearVelocity = self.angularVelocity * self.wheelConfig.wheelRadius
	-- local f = linearVelocity / dt * self.wheelConfig.wheelMass
	local f = linearVelocity * self:getSpringLoad()

	--[[ works ]]
	-- a = change in velocity / dt
	-- F = ma
	-- local a = linearVelocity / dt -- Angular Acceleration (α)
	-- local f = self.wheelConfig.wheelMass * a
	--[[      ]]

	-- acceleration (α) = (target angular velocity - current angular velocity) / dt
	-- torque (τ) = Iα | moment of intertia for a cylinder: Mr^2/2
	-- clamped torque = min(target torque, max torque)
	-- F = (clamped torque) / radius
	-- local a = (self.angularVelocity - self.currentAngularVelocity) / dt
	-- local t = a * (self.wheelConfig.wheelMass ^ 2) / 2
	-- local clampedT = math.min(t, self.maxTorque)
	-- local f = clampedT / self.wheelConfig.wheelRadius

	return f * wheelCF.LookVector
end

function Wheel.step(self: Wheel, dt: number)
	local rootCF = self.root.CFrame
	local wheelConfig = self.wheelConfig

	-- the place where the wheel is by default
	local wheelWorldCF =
		rootCF:ToWorldSpace(CFrame.new(self.offset.Position + Vector3.new(0, wheelConfig.wheelRadius, 0)))
	local direction = -rootCF.UpVector * (wheelConfig.maxSuspension - wheelConfig.wheelRadius)

	-- raycast downwards at wheel
	if direction.Magnitude ~= direction.Magnitude then
		return -- some 0/0 NaN error some where, helps prevent that
	end
	local raycast = self.raycast:sphere(wheelConfig.wheelRadius, wheelWorldCF.Position, direction)
	local position = if raycast then wheelWorldCF * (-rootCF.UpVector * raycast.Distance) else wheelWorldCF * direction

	-- where the wheel rests with steering
	local wheelCF = rootCF
		* CFrame.new(rootCF:PointToObjectSpace(position))
		* CFrame.Angles(0, math.rad(self.steeringAngle), 0)

	-- calculate wheel rotation
	local worldVelocity = self.root:GetVelocityAtPosition(wheelCF.Position)
	local localVelocity = worldVelocity:Dot(wheelCF.LookVector)

	self.currentVelocity = localVelocity
	self.currentAngularVelocity = localVelocity / wheelConfig.wheelRadius

	self.rotationX += self.currentAngularVelocity * dt
	self.attachment.WorldCFrame = wheelCF * CFrame.Angles(-self.rotationX, 0, 0)

	--

	local force = Vector3.zero
	if raycast then
		force += self:suspensionForce(raycast, worldVelocity)

		local toForce = 1 / dt * self.wheelConfig.wheelMass
		force += self:frictionalForce(wheelCF, raycast, worldVelocity) * toForce
		force += self:accelerationForce(wheelCF, dt) * dt
	end

	self.force.Force = force

	--- debug
	-- local maxVisualForce = 500
	-- local maxLen = 4
	-- self.forwardBeam:dir(position, -wheelCF.LookVector * (force.Z / maxVisualForce) * maxLen)
	-- self.rightBeam:dir(position, wheelCF.RightVector * (force.X / maxVisualForce) * maxLen)
end

function Wheel.Destroy(self: Wheel)
	self.raycast:Destroy()
	self.forwardBeam:Destroy()
	self.rightBeam:Destroy()
	self.force:Destroy()
end

return Wheel
