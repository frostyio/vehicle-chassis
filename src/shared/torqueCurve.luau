local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage:WaitForChild("packages")

local Graph = require(packages:WaitForChild("graphmodule"))
local util = require(script.Parent.Parent:WaitForChild("util"))

--

local function plotTorqueCurve(frame: Frame, minRPM: number, peakRPM: number, curve: { { number } })
	local handler = Graph.new(frame)

	local data = {}
	for i = minRPM, peakRPM do
		data[i] = util.getTorqueLUT(i, curve)
	end

	handler.Resolution = 20
	handler.BaselineZero = false
	handler.Data = { Torque = data }

	return handler
end

return plotTorqueCurve
