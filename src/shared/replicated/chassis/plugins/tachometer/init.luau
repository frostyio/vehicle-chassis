local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Client = Players.LocalPlayer
local PlayerGui = Client:WaitForChild("PlayerGui")

local packages = ReplicatedStorage:WaitForChild("packages")

local Fusion = require(packages:WaitForChild("fusion"))
local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value

local UI = require(script.ui)

local types = require(script.Parent.Parent.types)

type PluginProto = {
	state: types.State,
	ui: ScreenGui,
	props: UI.TachometerProps,
}

local plugin = {}
plugin.__index = plugin
type plugin = typeof(plugin) & PluginProto

function plugin.new(state: types.State, chassis: any): plugin
	local config = chassis:getComponent("engine").config

	local props: UI.TachometerProps = {
		peakRPM = config.peakRPM - 1000,
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
		state = state,
		props = props,
		ui = ui,
	} :: PluginProto, plugin)

	return self
end

function plugin.step(self: plugin, state: types.State, _dt: number)
	local props = self.props
	local drivetrain, engine = state.drivetrain, state.engine

	local gear = drivetrain.currentGear
	local betterGear = if gear == 0 then "N" elseif gear == -1 then "R" else tostring(gear)

	props.currentGear:set(betterGear)
	props.currentRPM:set(math.floor(engine.currentRPM))
	props.currentSpeed:set(math.floor(state.speed))
	-- props.absActive:set(state.isABSActive)
	-- props.tcsActive:set(state.isTCSActive)
end

function plugin.Destroy(self: plugin)
	self.ui:Destroy()
end

return plugin
