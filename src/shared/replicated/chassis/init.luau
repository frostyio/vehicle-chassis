local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Client = Players.LocalPlayer

local util = require(script:WaitForChild("util"))
local types = require(script:WaitForChild("types"))
local Debug = require(script:WaitForChild("debug"))
local Sound = require(script:WaitForChild("sound"))
local plugins = script:WaitForChild("plugins")

local random = Random.new()

--

type ChassisProto = {
	vehicle: Model,
	character: Model,
	humanoid: Humanoid,

	wheels: Folder,
	root: BasePart,
	seat: VehicleSeat,
	constraints: Folder,
	config: types.VehicleConfig,

	--

	driveConstraints: { [string]: CylindricalConstraint },
	driveWheels: { [string]: BasePart },

	steerConstraints: { [string]: CylindricalConstraint },
	steerAttachments: { [string]: Attachment },

	--

	engineState: types.EngineState,
	engineLoop: thread,

	--

	vehicleState: types.VehicleState,
	currentGear: number,

	rpm: number,
	currentTorque: number,
	currentSteer: number,
	isBreaking: boolean,
	isTCSActive: boolean,
	flipping: boolean,
	clutchEnganged: boolean,
	lastClutchDisenganged: number,
	velocity: Vector3,

	-- input values
	throttleFloat: number,
	steerFloat: number,
	parkingBreak: boolean,

	-- connections
	seatConnection: RBXScriptConnection,
	inputBeganConnection: RBXScriptConnection,
	inputEndedConnection: RBXScriptConnection,
	jummpRequest: RBXScriptConnection,

	--
	debug: Debug.Debug,
	beams: { any }?,
	sound: Sound.SoundPanel,
	plugins: { any },
}

local Chassis = {
	util = util, -- re-export

	engineState = false,
	vehicleState = "Neutral",
	currentGear = 1,
	isBreaking = false,
	isTCSActive = false,
	isABSActive = false,
	flipping = false,
	clutchEnganged = true,

	rpm = 0,
	currentSteer = 0,

	throttleFloat = 0,
	steerFloat = 0,
	parkingBreak = false,
}
Chassis.__index = Chassis
export type Chassis = typeof(Chassis) & ChassisProto

function Chassis.initialize(vehicle: Model): Chassis
	local wheels, base, seat, config = util.getComponents(vehicle)

	local character = Client.Character
	local humanoid: Humanoid = character:WaitForChild("Humanoid")

	local self = setmetatable({
		vehicle = vehicle,
		character = character,
		humanoid = humanoid,
		constraints = vehicle:WaitForChild("Constraints"),
		wheels = wheels,
		root = base,
		seat = seat,
		config = config,
		sound = Sound.new(base, config),
		currentTorque = 0,
		lastClutchDisenganged = 0,
	} :: ChassisProto, Chassis)

	--

	self.driveConstraints = self:getDriveConstraints()
	self.driveWheels = self:getDriveWheels()
	self.steerAttachments = self:getSteerAttachments()

	self:createEngineLoop()
	self:createSeatConnection()
	self:createInputConnection()

	--

	self:initializePlugins()
	self:enableDebug()

	return self
end

function Chassis.initializePlugins(self: Chassis)
	local pluginsTbl = {}

	local possiblePlugins = self.config.plugins or {}
	for _, pluginName in possiblePlugins do
		local plugin = plugins:FindFirstChild(pluginName)
		assert(plugin, `could not find plugin '{pluginName}'`)
		local module = require(plugin)

		print(`loading plugin '{pluginName}'`)
		table.insert(pluginsTbl, module.new(self))
	end

	self.plugins = pluginsTbl
end

function Chassis.stepPlugins(self: Chassis, state: types.ChassisState, dt: number)
	for _, plugin in self.plugins do
		plugin:step(state, dt)
	end
end

function Chassis.destroyPlugins(self: Chassis)
	for _, plugin in self.plugins do
		plugin:destroy()
	end
	self.plugins = {}
end

--

function Chassis.setEngineState(self: Chassis, state: types.EngineState)
	self.engineState = state
	print(`Setting engine state to {state}`)

	-- resume main loop
	if state == "On" then
		coroutine.resume(self.engineLoop)
	else
		for _, cylindrical in self.constraints:GetChildren() do
			if not cylindrical:IsA("CylindricalConstraint") then
				continue
			end

			cylindrical.MotorMaxTorque = 0
			cylindrical.AngularVelocity = 0
		end
	end
end

function Chassis.getEngineState(self: Chassis): boolean
	return self.engineState == "On"
end

function Chassis.checkEngineOn(self: Chassis): boolean
	local state = self:getEngineState()
	if not state then
		warn("Engine is not on.")
	end

	return state
end

function Chassis.setVehicleState(self: Chassis, state: types.VehicleState)
	self.vehicleState = state
	print(`Setting vehicle state to {state}`)
end

function Chassis.getVehicleState(self: Chassis)
	return self.vehicleState
end

function Chassis.getDriveConstraints(self: Chassis): { [string]: CylindricalConstraint }
	local constraints = {}

	for name, config in self.config.cylindrical do
		if config.angularActuator ~= Enum.ActuatorType.Motor then
			continue
		end

		local constraint = self.constraints:FindFirstChild(name .. "C")
		if not constraint then
			continue
		end

		constraints[name] = constraint
	end

	return constraints
end

function Chassis.getSteerConstraints(self: Chassis): { [string]: CylindricalConstraint }
	local constraints = {}

	for name, config in self.config.cylindrical do
		if config.angularActuator == Enum.ActuatorType.Motor then
			continue
		end

		local constraint = self.constraints:FindFirstChild(name .. "C")
		if not constraint then
			continue
		end

		constraints[name] = constraint
	end

	return constraints
end

function Chassis.getSteerAttachments(self: Chassis): { [string]: Attachment }
	local constraints = self:getSteerConstraints()
	local attachments = {}

	for name in constraints do
		local attachment = self.root:FindFirstChild(name)

		if not attachment then
			continue
		end

		attachments[name] = attachment
	end

	return attachments
end

function Chassis.getDriveWheels(self: Chassis): { [string]: BasePart }
	local driveWheels = {}

	local constraints = self.driveConstraints
	for name in constraints do
		local wheel = self.wheels:FindFirstChild(name)
		if not wheel then
			continue
		end

		driveWheels[name] = wheel
	end

	return driveWheels
end

-- shifting

function Chassis.setGear(self: Chassis, gear: number)
	assert(gear > 0 and gear <= #self.config.gearRatios, "Cannot set gear, out of bounds")

	self.currentGear = gear
end

function Chassis.getGearRatio(self: Chassis, gear: number?)
	return self.config.gearRatios[gear or self.currentGear]
end

function Chassis.shiftUp(self: Chassis)
	if not self:checkEngineOn() then
		return
	end

	if self.clutchEnganged and self.config.transmissionMode ~= "Semi" then
		return
	end

	local state = self:getVehicleState()

	if state == "Neutral" then
		self:setGear(1)
		self:setVehicleState("Forward")
	elseif state == "Reversing" then
		self:setVehicleState("Neutral")
	else
		if self.currentGear + 1 > #self.config.gearRatios then
			return
		end

		self:setGear(self.currentGear + 1)
	end
end

function Chassis.shiftDown(self: Chassis)
	if not self:checkEngineOn() then
		return
	end

	if self.clutchEnganged and self.config.transmissionMode ~= "Semi" then
		return
	end

	local state = self:getVehicleState()

	if state == "Neutral" then
		self:setGear(1)
		self:setVehicleState("Reversing")
	elseif self.currentGear == 1 then
		self:setVehicleState("Neutral")
	else
		self:setGear(self.currentGear - 1)
	end
end

--

function Chassis.getAverageRPS(self: Chassis): number
	local driveWheels = self.driveWheels
	local count, sum = 0, 0

	for _, wheel in driveWheels do
		count += 1
		sum += wheel.AssemblyAngularVelocity.Magnitude
	end

	return sum / count
end

function Chassis.ackermannSteering(self: Chassis): (number, number)
	-- calculate rear track
	local leftRear = self.wheels:FindFirstChild("BL")
	local rightRear = self.wheels:FindFirstChild("BR")
	assert(leftRear and rightRear, "cannot find rear wheels")

	local rearTrack = (leftRear.Position - rightRear.Position).Magnitude

	-- calculate wheel base
	local front = self.wheels:FindFirstChild("FL") or self.wheels:FindFirstChild("FR")
	local rear = leftRear or rightRear
	assert(front, "cannot find wheel base")

	local wheelBase = (front.Position - rear.Position).Magnitude

	local turnRadius = self.config.turnRadius

	--

	if (self.currentSteer :: number) > 0 then -- right
		local leftSteer = math.atan(wheelBase / (turnRadius + rearTrack / 2)) * self.currentSteer
		local rightSteer = math.atan(wheelBase / (turnRadius - rearTrack / 2)) * self.currentSteer

		return math.deg(leftSteer), math.deg(rightSteer)
	elseif (self.currentSteer :: number) < 0 then -- left
		local leftSteer = math.atan(wheelBase / (turnRadius - rearTrack / 2)) * self.currentSteer
		local rightSteer = math.atan(wheelBase / (turnRadius + rearTrack / 2)) * self.currentSteer

		return math.deg(leftSteer), math.deg(rightSteer)
	else
		return 0, 0
	end
end

--

function Chassis.step(self: Chassis, dt: number)
	local config = self.config
	local vehicleState = self:getVehicleState()

	-- reset
	self.isTCSActive = false
	self.isABSActive = false

	-- active input

	-- handle throttle input
	local throttleFloat = self.throttleFloat :: number
	local throttleInfluence = if vehicleState == "Forward" and throttleFloat > 0
		then 1
		elseif vehicleState == "Reversing" and throttleFloat :: number > 0 then -1
		else 0
	if vehicleState == "Forward" then
		throttleInfluence = math.max(throttleInfluence, config.idleThrottle)
	elseif vehicleState == "Reversing" then
		throttleInfluence = math.min(throttleInfluence, -config.idleThrottle)
	end
	self.isBreaking = throttleFloat < 0

	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		-- parking break
		self.isBreaking = true
		self.parkingBreak = true
	else
		self.parkingBreak = false
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or vehicleState == "Neutral" then
		self.clutchEnganged = false
	elseif vehicleState ~= "Neutral" then
		self.clutchEnganged = true
	end

	--

	local finalDriveRatio = (config.finalDriveRatio or 3.42) * 1 -- differential * multiplyer

	-- when vehicle is off, rpm is 0, otherwise idle RPM
	local minRPM = if self:getEngineState() then config.idleRPM else 0

	--
	local avgSpin = self:getAverageRPS()
	local ratio = self:getGearRatio()

	local delta = os.clock() - self.lastClutchDisenganged

	if self.clutchEnganged then
		-- https://devforum.roblox.com/t/how-does-one-calculate-rpm-without-irl-measurements/1127312/6
		local v = avgSpin * ratio * finalDriveRatio
		local rpm = math.clamp(v * 30 / math.pi, minRPM, config.redlineRPM)

		local shiftRatio = math.clamp(delta / config.clutchEngangmentRate, 0, 1) -- higher = closer to actual rpm
		self.rpm = self.rpm * (1 - shiftRatio) + rpm * shiftRatio
	else
		self.lastClutchDisenganged = os.clock()
		if throttleFloat == 1 then
			self.rpm = math.min(self.rpm + config.rpmAccel * dt * 60, config.redlineRPM)
		else
			self.rpm = math.max(self.rpm - config.rpmDecay * dt * 60, config.idleRPM)
		end
	end

	-- rpm limiting
	local torque = 0
	if self.rpm :: number > config.peakRPM + (config.redlineRPM - config.peakRPM) / 2 then
		if (self.currentGear :: number) < #config.gearRatios then
			self.rpm -= config.redlineKickback
		else
			self.rpm -= config.redlineKickback / 2
		end
		-- else
	end
	torque = util.getTorqueLUT(self.rpm, config.torqueCurve)
	-- roblox torque to N-m
	-- https://devforum.roblox.com/t/understanding-roblox-physics-and-their-conversions-to-real-units/1847678
	-- yeah no i'm just fiddling
	self.currentTorque = torque
	torque *= 3.5 * (self.vehicle:GetAttribute("torqueMultiplyer") or 1)
	-- end

	-- shifting

	if
		vehicleState == "Forward"
		and self.clutchEnganged
		and config.transmissionMode == "Semi"
		and delta > (config.shiftTime or 0.2)
	then
		if self.rpm :: number > config.peakRPM + config.autoUpBias and self.currentGear + 1 <= #config.gearRatios then
			self.clutchEnganged = false
			self.lastClutchDisenganged = os.clock()
			self:shiftUp()
		elseif
			-- get RPM for next downshift
			self.currentGear :: number > 1
			and math.clamp(
					avgSpin * self:getGearRatio(self.currentGear - 1) * finalDriveRatio * 30 / math.pi,
					minRPM,
					config.peakRPM
				)
				< config.peakRPM - config.autoDownBias
		then
			self.clutchEnganged = false
			self.lastClutchDisenganged = os.clock()
			self:shiftDown()
		end
	end

	--

	if not self.isBreaking then
		local throttle = if self.clutchEnganged then throttleInfluence else 0

		-- applying velocity
		local rps = avgSpin / 60 -- revolutions per second
		-- local maxTorque = math.abs(torque * (1 + rps) * throttle) * (ratio / 2)
		-- local angularVelocity = config.redlineRPM * math.pi / (30 * ratio * finalDriveRatio) * throttle

		-- rework
		local maxTorque = math.abs(torque * (1 + rps) * throttle)
		local angularVelocity = config.redlineRPM * math.pi / (30 * ratio * finalDriveRatio) * throttle

		for name, cylindrical in self.driveConstraints do
			local wheel = self.wheels:FindFirstChild(name)
			if not wheel then
				continue
			end

			-- tcs
			local wheelRadius = wheel.Size.Y / 2
			local velocity = wheel.AssemblyLinearVelocity.Magnitude
			local angVelocity = wheel.AssemblyAngularVelocity.Magnitude

			local slippage = math.max(math.abs(angVelocity * wheelRadius - velocity) - config.tcsThreshold, 0)
			local tcs = 1 - (math.min(slippage / config.tcsGradient, 1) * (1 - config.tcsLimit))
			self.isTCSActive = tcs < 1

			--
			cylindrical.MotorMaxAngularAcceleration = 100000
			cylindrical.MotorMaxTorque = maxTorque * tcs
			cylindrical.AngularVelocity = angularVelocity
		end
	else
		-- breaking
		for _, cylindrical in self.constraints:GetChildren() do
			local wheel = self.wheels:FindFirstChild(cylindrical.Name:sub(1, -2))
			if not wheel then
				print(`cannot find wheel {cylindrical.Name:sub(1, -2)}`)
				continue
			end

			if not cylindrical:IsA("CylindricalConstraint") then
				continue
			end

			if not self.parkingBreak then
				-- abs
				local wheelRadius = wheel.Size.Y / 2
				local velocity = wheel.AssemblyLinearVelocity.Magnitude
				local angVelocity = wheel.AssemblyAngularVelocity.Magnitude
				local slippage = math.abs(angVelocity * wheelRadius - velocity) - config.absThreshold
				local abs = if slippage > 1 then 0 else 1
				if abs == 0 then
					self.isABSActive = true
				end

				local force = cylindrical.Name:match("F.") and config.frontBreakForce or config.rearBreakForce

				cylindrical.MotorMaxTorque = force * abs
			elseif cylindrical.AngularActuatorType == Enum.ActuatorType.Motor then
				cylindrical.MotorMaxTorque = config.parkingBreakForce
			else
				cylindrical.MotorMaxTorque = 0
			end

			cylindrical.AngularVelocity = 0
		end
	end

	-- steering

	local forgiveness = self.config.turnForgiveness / math.max(avgSpin, self.config.turnForgiveness)
	local steerGoal = self.steerFloat * forgiveness
	self.currentSteer += (steerGoal - self.currentSteer) * math.min(dt * config.turnSpeed, 1)

	local leftSteeringAttachment = self.steerAttachments["FL"]
	local rightSteeringAttachment = self.steerAttachments["FR"]
	local leftSteer, rightSteer = self:ackermannSteering()
	leftSteeringAttachment.Orientation = Vector3.new(0, -leftSteer, 90)
	rightSteeringAttachment.Orientation = Vector3.new(0, -rightSteer, 90)

	-- flip
	local pos = self.root.Position
	local isFlipped = pos.Y > (pos + self.root.CFrame.UpVector).Y
	if isFlipped and vehicleState == "Neutral" and self.flipping == false then
		-- commence flippage
		local flip = self.root:FindFirstChild("Flip")
		if not flip then
			return
		end

		self.flipping = true
		flip.Enabled = true
		task.delay(2, function()
			flip.Enabled = false
			self.flipping = false
		end)
	end
end

function Chassis.createEngineLoop(self: Chassis)
	self.engineLoop = coroutine.create(function()
		while true do
			if not self:getEngineState() then
				coroutine.yield()
			end

			local dt = task.wait()

			self:step(dt)

			-- other
			self.velocity = self.root.AssemblyLinearVelocity
			local mph = math.floor(util.toMPH(self.velocity.Magnitude))

			local state: types.ChassisState = {
				engineState = self:getEngineState(),
				rpm = self.rpm,
				torque = self.currentTorque,
				speed = mph,
				gear = self.currentGear,
				vehicleState = self:getVehicleState(),
				isBreaking = self.isBreaking,
				isParkingBreak = self.parkingBreak,
				isTCSActive = self.isTCSActive,
				isABSActive = self.isABSActive,
			}

			if self.debug then
				self.debug:update(state)
			end
			self.sound:update(state)
			self:stepPlugins(state, dt)
		end
	end)
end

function Chassis.createSeatConnection(self: Chassis)
	self.jummpRequest = UserInputService.JumpRequest:Connect(function()
		self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end)

	self.seatConnection = self.seat.Changed:Connect(function(property)
		if property == "SteerFloat" then
			self.steerFloat = self.seat.SteerFloat
		elseif property == "ThrottleFloat" then
			self.throttleFloat = self.seat.ThrottleFloat
		end
	end)
end

-- handles everything related to input
function Chassis.createInputConnection(self: Chassis)
	local crankKey = Enum.KeyCode.R
	local isCranking = false
	local crankId = 0

	local outKey = Enum.KeyCode.F
	local isWantingOut = false

	self.inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end

		local keyCode = input.KeyCode

		if keyCode == crankKey then
			-- turn off
			if self:getEngineState() then
				self:setEngineState("Off")
				return
			end

			-- crank on
			isCranking = true
			local crankTime = if not self.config.crankRange
				then 0
				else random:NextNumber(self.config.crankRange.min, self.config.crankRange.max)

			if crankTime ~= 0 then
				self.sound:playSound("crank")
				self.sound:adjustVolume("crank")
				self.sound:adjustPitch("crank")
				crankId += 1
				local myCrankId = crankId

				task.delay(crankTime, function()
					if not isCranking or self:getEngineState() or crankId ~= myCrankId then
						return
					end

					self.sound:stopSound("crank")
					self:setEngineState("On")
					self.rpm = self.config.peakRPM
				end)
			else
				self:setEngineState("On")
				self.rpm = self.config.peakRPM
			end
		elseif keyCode == outKey then
			-- jump out request
			isWantingOut = true
			task.delay(1, function()
				if isWantingOut then
					self.humanoid.Sit = false
				end
			end)
		end
	end)

	self.inputEndedConnection = UserInputService.InputEnded:Connect(function(input, gpe)
		if gpe then
			return
		end

		local keyCode = input.KeyCode

		if keyCode == Enum.KeyCode.Q then
			-- downshift
			self:shiftDown()
		elseif keyCode == Enum.KeyCode.E then
			-- upshift
			self:shiftUp()
		elseif keyCode == crankKey and not self:getEngineState() then
			isCranking = false
			self.sound:stopSound("crank")
		elseif keyCode == Enum.KeyCode.F then
			isWantingOut = false
		end
	end)
end

--

function Chassis.enableDebug(self: Chassis)
	print("enabling debug")
	self.debug = Debug.new(Client:WaitForChild("PlayerGui"), self.config)

	local wheelBeams = {}
	for _, wheel in self.wheels:GetChildren() do
		table.insert(wheelBeams, Debug.Beam.new(wheel, CFrame.new(), CFrame.new(30, 0, 0)))
		table.insert(wheelBeams, Debug.Beam.new(wheel, CFrame.new(), CFrame.new(-30, 0, 0)))
	end

	self.beams = wheelBeams
end

function Chassis.destroy(self: Chassis)
	self:setEngineState("Off")
	self:destroyPlugins()
	self.seatConnection:Disconnect()
	self.jummpRequest:Disconnect()
	self.inputBeganConnection:Disconnect()
	self.inputEndedConnection:Disconnect()
	self.debug:destroy()
	self.sound:destroy()
	local beams = self.beams or {}
	for _, beam in beams do
		beam:destroy()
	end
end

return Chassis
