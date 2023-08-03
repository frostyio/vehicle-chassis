local ServerStorage = game:GetService("ServerStorage")
local serverShared = ServerStorage:WaitForChild("shared")
local Chassis = require(serverShared:WaitForChild("chassis"))

for _, vehicle in workspace:GetChildren() do
	if vehicle:GetAttribute("isVehicle") then
		Chassis.new(vehicle)
	end
end
