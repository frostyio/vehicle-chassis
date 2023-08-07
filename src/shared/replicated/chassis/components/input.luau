local UserInputService = game:GetService("UserInputService")

local Chassis = require(script.Parent.Parent.client)

local function isKeyDown(key: Enum.KeyCode): number
	return UserInputService:IsKeyDown(key) and 1 or 0
end

export type Config = {}

type InputProto = {
	chassis: Chassis.Chassis,
	config: Config,

	state: { [any]: any },
}

local Input = {}
Input.__index = Input
type Input = typeof(Input) & InputProto

function Input.new(chassis: Chassis.Chassis, config: Config): Input
	return setmetatable({
		chassis = chassis,
		config = config,
		state = {
			throttle = 0,
			steer = 0,
			ignition = 0,
			clutch = 0,
		},
	} :: Input, Input)
end
function Input.step(self: Input, _dt: number)
	if not self.chassis.state.isOccupied then
		return
	end

	self.state.throttle = isKeyDown(Enum.KeyCode.W) - isKeyDown(Enum.KeyCode.S)
	self.state.steer = isKeyDown(Enum.KeyCode.A) - isKeyDown(Enum.KeyCode.D)
	self.state.ignition = isKeyDown(Enum.KeyCode.F)
	self.state.clutch = isKeyDown(Enum.KeyCode.LeftShift)
end
function Input.Destroy(_self: Input) end

return Input
