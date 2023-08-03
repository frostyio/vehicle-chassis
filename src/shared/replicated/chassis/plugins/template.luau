local Chassis = require(script.Parent.Parent) -- oo spooky cyclic
local types = require(script.Parent.Parent:WaitForChild("types"))

type PluginProto = {
	chassis: Chassis.Chassis,
	destroyed: boolean,
}

local plugin = {}
plugin.__index = plugin
type plugin = typeof(plugin) & PluginProto

function plugin.new(chassis: Chassis.Chassis): plugin
	local self = setmetatable({ chassis = chassis, destroyed = false } :: PluginProto, plugin)

	return self
end

function plugin.step(_self: plugin, _state: types.ChassisState, _dt: number) end

function plugin.destroy(_self: plugin) end

return plugin
