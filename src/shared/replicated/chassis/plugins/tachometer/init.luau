local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Client = Players.LocalPlayer
local PlayerGui = Client:WaitForChild("PlayerGui")

local packages = ReplicatedStorage:WaitForChild("packages")

local Fusion = require(packages:WaitForChild("fusion"))
local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value

local Chassis = require(script.Parent.Parent) -- oo spooky cyclic
local types = require(script.Parent.Parent:WaitForChild("types"))

local UI = require(script.ui)

type PluginProto = {
	chassis: Chassis.Chassis,

	ui: ScreenGui,
	props: UI.TachometerProps,
}

local plugin = {}
plugin.__index = plugin
type plugin = typeof(plugin) & PluginProto

function plugin.new(chassis: Chassis.Chassis): plugin
	local config = chassis.config

	local props: UI.TachometerProps = {
		peakRPM = config.peakRPM + (config.autoUpBias * 2),
		redlineRPM = config.redlineRPM,

		currentGear = Value("P"),
		currentRPM = Value(0),
		currentSpeed = Value(0),
		absActive = Value(false),
		tcsActive = Value(false),

		speedMetric = Value("MPH"),
	}

	local ui = New("ScreenGui")({
		Name = "TachometerUI",
		Parent = PlayerGui,
		[Children] = UI(props),
	})

	local self = setmetatable({
		chassis = chassis,
		props = props,
		ui = ui,
	} :: PluginProto, plugin)

	return self
end

function plugin.step(self: plugin, state: types.ChassisState, _dt: number)
	local props = self.props

	local vehicleState = state.vehicleState
	local betterGear = if vehicleState == "Forward"
		then tostring(state.gear)
		elseif vehicleState == "Reversing" then "R"
		elseif vehicleState == "Neutral" then "P"
		else tostring(state.gear)

	props.currentGear:set(betterGear)
	props.currentRPM:set(math.floor(state.rpm))
	props.currentSpeed:set(state.speed)
	props.absActive:set(state.isABSActive)
	props.tcsActive:set(state.isTCSActive)
end

function plugin.destroy(self: plugin)
	self.ui:Destroy()
end

return plugin
