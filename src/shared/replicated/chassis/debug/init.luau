local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local packages = ReplicatedStorage:WaitForChild("packages")

local plasma = require(packages:WaitForChild("plasma"))

local create = plasma.create

local plotTorqueCurve = require(script:WaitForChild("torqueCurve"))
local beam = require(script:WaitForChild("beam"))
local types = require(script.Parent:WaitForChild("types"))

--

local function richTextBoolean(value: boolean): string
	return `<font color="{value and "#42f56c" or "#f54842"}">{tostring(value)}</font>`
end

--

type DebugProto = {
	ui: ScreenGui,
	config: types.VehicleConfig,
	state: { [string]: any },
	root: any,
	torqueCurve: Frame?,
	torqueGraphHandler: any,

	updateLoop: RBXScriptConnection,

	zeroedTime: number,
	wasZeroed: boolean,
}

local Debug = {
	Beam = beam,
}
Debug.__index = Debug
export type Debug = typeof(Debug) & DebugProto

function Debug.new(playerGui: PlayerGui, config: types.VehicleConfig): Debug
	local ui = create("ScreenGui", {
		Name = "Debug",
		Parent = playerGui,
	})

	local root = plasma.new(ui)

	local self = setmetatable({
		ui = ui,
		config = config,

		state = {},
		root = root,
		torqueCurve = false,

		zeroedTime = 0,
		wasZeroed = false,
	} :: DebugProto, Debug)

	--

	self.updateLoop = self:plotStats()

	return self
end

function Debug.update(self: Debug, newState: types.ChassisState)
	for key, value in newState do
		self.state[key] = value
	end

	if newState.speed < 1 then
		self.zeroedTime = os.clock()
		self.wasZeroed = true
	elseif newState.speed > 62 and self.wasZeroed then
		self.wasZeroed = false
		print(("0-60: %.3fs"):format(os.clock() - self.zeroedTime))
	end
end

function Debug.plotStats(self: Debug): RBXScriptConnection
	return RunService.Heartbeat:Connect(function()
		plasma.start(self.root, function()
			plasma.window({
				title = "Vehicle",
				closable = true,
				movable = true,
				resizable = false,
			}, function()
				local state = self.state

				if state.engineState then
					local speed = math.floor(state.speed or 0)
					local rpm = math.floor(state.rpm or 0)
					local gear = state.gear or 0
					local vehicleState = state.vehicleState or ""

					plasma.table({
						{ "Speed", `{speed}mph` },
						{ "RPM", rpm },
						{ "Torque", math.floor(state.torque or 0) },
						{ "HP", math.floor((state.torque or 0) * rpm / 5252) },
						{ "Gear", gear },
						{ "State", vehicleState },
						{
							"Breaking",
							richTextBoolean(state.isBreaking),
						},
						{
							"Park Break",
							richTextBoolean(state.isParkingBreak),
						},
						{
							"TCS",
							richTextBoolean(state.isTCSActive),
						},
						{
							"ABS",
							richTextBoolean(state.isABSActive),
						},
					})
				end

				if plasma.button("Torque Curve"):clicked() then
					self:toggleTorqueCurve()
				end
			end)
		end)
	end)
end

function Debug.plotTorqueCurve(self: Debug): Frame
	local frame = create("Frame", {
		Name = "torqueCurve",
		Size = UDim2.fromScale(0.4, 0.4),
		Position = UDim2.fromScale(0.59, 0.575),
		BackgroundTransparency = 1,
		ZIndex = -10,
		Parent = self.ui,
	})
	self.torqueGraphHandler = plotTorqueCurve(frame, 0, self.config.redlineRPM, self.config.torqueCurve)

	return frame
end

function Debug.toggleTorqueCurve(self: Debug)
	if self.torqueCurve then
		self.torqueCurve:Destroy()
		self.torqueCurve = nil
	else
		self.torqueCurve = self:plotTorqueCurve()
	end
end

function Debug.destroy(self: Debug)
	self.updateLoop:Disconnect()
	self.ui:Destroy()
end

return Debug
