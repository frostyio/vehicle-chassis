local Chassis = require(script.Parent.Parent.client)

export type Config = {
	wheels: { string },
	gearRatios: { number },
	finalDriveRatio: number,
	reverseRatio: number,
	clutchEngagementRate: number,

	transmissionMode: "Manual" | "Semi" | "Auto",
	shiftTime: number,
}

type DriveTrainProto = {
	chassis: Chassis.Chassis,
	config: Config,
	state: { [any]: any },
	lastShift: number,
	lastPowerSlope: number,
}

local DriveTrain = {}
DriveTrain.__index = DriveTrain
type DriveTrain = typeof(DriveTrain) & DriveTrainProto

function DriveTrain.new(chassis: Chassis.Chassis, config: Config): DriveTrain
	return setmetatable({
		chassis = chassis,
		config = config,
		state = {
			wheelTorques = {},
			isClutchEngaged = false,
			isEngineBreaking = false,
			currentGear = 1,
			currentPower = 0,
		},
		lastShift = 0,
		lastPowerSlope = 0,
	} :: DriveTrain, DriveTrain)
end

function DriveTrain.getGearRatio(self: DriveTrain, gear: number?): number
	local state, config = self.state, self.config
	gear = gear or state.currentGear

	return if gear < 0
		then config.reverseRatio
		elseif gear == 0 or gear > #config.gearRatios then 0
		else config.gearRatios[gear]
end

function DriveTrain.shiftUp(self: DriveTrain)
	self.state.currentGear = math.min(self.state.currentGear + 1, #self.config.gearRatios)
	self.lastShift = os.clock()
end

function DriveTrain.shiftDown(self: DriveTrain)
	self.state.currentGear = math.max(self.state.currentGear - 1, 0)
	self.lastShift = os.clock()
end

function DriveTrain.step(self: DriveTrain, _dt: number)
	local state, config, chassisState = self.state, self.config, self.chassis.state

	local engineIsOn = (chassisState.engine.isOn and 1 or 0)

	local throttle = engineIsOn * chassisState.input.throttle
	state.isClutchEngaged = state.currentGear ~= 0 and chassisState.input.clutch == 0
	state.isEngineBreaking = throttle < 0

	local engine = self.chassis:getComponent("engine")
	local engineTorque = engine:getTorque(engine.state.currentRPM)
	local throttleInfluence = math.min(engineIsOn * engine.config.idleThrottle + math.abs(throttle), 1)
		* (state.isClutchEngaged and 1 or 0)

	local gearRatio = self:getGearRatio()
	local baseTorque = engineTorque * throttleInfluence
	local outputTorque = baseTorque * gearRatio * config.finalDriveRatio

	--- shifting
	state.currentPower = engine.calculatePower(engineTorque, engine.state.currentRPM)
	if os.clock() - self.lastShift > config.shiftTime and state.isClutchEngaged then
		--- can shift

		if config.transmissionMode == "Semi" then
			if state.currentGear > 0 then
				-- in gear
				if engine.state.currentRPM > engine.config.peakRPM then
					self:shiftUp()
				elseif state.currentGear > 1 then
					if engine.state.currentRPM < engine.config.peakRPM / 3 then
						self:shiftDown()
					end
				end
			end
		end
	end

	--- wheel update

	for _, wheel in self.config.wheels do
		local wheelObject = self.chassis.forces.wheels[wheel]
		assert(wheelObject, "could not find wheel")

		wheelObject.maxTorque = math.huge
		wheelObject.angularVelocity = outputTorque
		state.wheelTorques[wheel] = baseTorque
	end
end

function DriveTrain.Destroy(_self: DriveTrain) end

return DriveTrain
