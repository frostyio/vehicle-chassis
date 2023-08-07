local Chassis = require(script.Parent.Parent.client)

export type Config = {
	idleRPM: number,
	peakRPM: number,
	redlineRPM: number,
	redlineKickback: number,

	rpmAccel: number,
	rpmDecay: number,

	idleThrottle: number,

	torqueCurve: { { number } },
}

type EngineProto = {
	chassis: Chassis.Chassis,
	config: Config,
	state: { [any]: any },

	lastIgnitionPress: number,
	clutchLastDisengaged: number,
}

local Engine = {}
Engine.__index = Engine
type Engine = typeof(Engine) & EngineProto

function Engine.new(chassis: Chassis.Chassis, config: Config): Engine
	return setmetatable({
		chassis = chassis,
		config = config,
		state = {
			isOn = false,
			currentRPM = 0,
		},
		clutchLastDisengaged = 0,
		lastIgnitionPress = 0,
	} :: Engine, Engine)
end

function Engine.getAverageSpin(self: Engine): number -- radians per second
	local sum = 0
	local drivetrain = self.chassis:getComponent("drivetrain")

	for _, wheel in drivetrain.config.wheels do
		local wheelObject = self.chassis.forces.wheels[wheel]
		assert(wheelObject, "could not find wheel")

		sum += wheelObject.currentAngularVelocity
	end

	return sum / #drivetrain.config.wheels
end

function Engine.calculateRPMForGearRatio(self: Engine, gearRatio: number): number
	return math.min((math.abs(self:getAverageSpin()) + 1) * 60 / (2 * math.pi) * gearRatio, self.config.redlineRPM)
end

function Engine.step(self: Engine, _dt: number)
	local config, state, chassisState = self.config, self.state, self.chassis.state
	local drivetrain = self.chassis:getComponent("drivetrain")

	-- ignition / turn off
	if chassisState.input.ignition == 1 then
		if os.clock() - self.lastIgnitionPress > 1 then
			self.lastIgnitionPress = os.clock()
			self.state.isOn = not self.state.isOn
		end
	end

	local engineIsOn = (chassisState.engine.isOn and 1 or 0)

	local throttle = engineIsOn * chassisState.input.throttle
	local isClutchEngaged = drivetrain.state.isClutchEngaged
	state.isEngineBreaking = throttle < 0

	local gearRatio = drivetrain:getGearRatio()

	if state.isOn then
		if isClutchEngaged then
			local effectiveRPM = self:calculateRPMForGearRatio(gearRatio * drivetrain.config.finalDriveRatio)
			local shiftRatio =
				math.clamp((os.clock() - self.clutchLastDisengaged) / drivetrain.config.clutchEngagementRate, 0, 1)
			local newRPM = self.state.currentRPM * (1 - shiftRatio) + effectiveRPM * shiftRatio
			state.currentRPM = math.max(state.currentRPM + (newRPM - state.currentRPM) * 0.1, config.idleRPM)
		else
			self.clutchLastDisengaged = os.clock()
			throttle = isClutchEngaged and throttle or 0 -- wont go anywhere without it engaged
			state.currentRPM = if chassisState.input.throttle > 0
				then math.min(state.currentRPM + config.rpmAccel, config.redlineRPM)
				else math.max(state.currentRPM - config.rpmDecay, config.idleRPM)
		end
	else
		state.currentRPM = 0
	end
end

function Engine.getTorque(self: Engine, rpm: number): number
	local lastRPM, lastTorque = 0, 0

	for _, data in self.config.torqueCurve do
		local thisRPM, thisTorque = unpack(data)

		if thisRPM > rpm then
			-- simple lerp
			local t = (rpm - lastRPM) / (thisRPM - lastRPM)
			return lastTorque + (thisTorque - lastTorque) * t
		end

		lastRPM, lastTorque = thisRPM, thisTorque
	end

	return math.max(lastTorque, 0)
end

function Engine.Destroy(_self: Engine) end

----

function Engine.calculatePower(torque: number, rpm: number): number
	return torque * rpm / 5_252
end

return Engine
