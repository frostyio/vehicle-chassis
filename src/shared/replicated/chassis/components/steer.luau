local Chassis = require(script.Parent.Parent.client)

export type Config = { wheels: { string }, turnForgiveness: number, turnSpeed: number, turnRadius: number }

type SteeringProto = { chassis: Chassis.Chassis, config: Config, state: { currentSteer: number } }
local Steering = {}
Steering.__index = Steering
type Steering = typeof(Steering) & SteeringProto

function Steering.new(chassis: Chassis.Chassis, config: Config): Steering
	return setmetatable({ chassis = chassis, config = config, state = { currentSteer = 0 } } :: Steering, Steering)
end

function Steering.step(self: Steering, dt: number)
	local engine = self.chassis:getComponent("engine")
	local avgSpin = engine:getAverageSpin()
	local forgiveness = self.config.turnForgiveness / math.max(avgSpin, self.config.turnForgiveness)
	local steerGoal = self.chassis.state.input.steer * forgiveness
	self.state.currentSteer += (steerGoal - self.state.currentSteer) * math.min(dt * self.config.turnSpeed, 1)

	-- local leftSteer, rightSteer = self:ackermannSteering()
	local leftSteer, rightSteer = self.state.currentSteer, self.state.currentSteer
	self.chassis.forces.wheels["FL"].steeringAngle = math.deg(leftSteer)
	self.chassis.forces.wheels["FR"].steeringAngle = math.deg(rightSteer)
end

function Steering.Destroy(_self: Steering) end

return Steering
