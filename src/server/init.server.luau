local ServerStorage = game:GetService("ServerStorage")
local serverShared = ServerStorage:WaitForChild("shared")
local Chassis = require(serverShared:WaitForChild("serverChassis"))

local chassis = Chassis.new(workspace.NewVehicle)

-- testing
local Players = game:GetService("Players")

local function PlayerAdded(player: Player)
	local t = 0
	for i = 1, t do
		print(`giving ownership in {t + 1 - i} seconds`)
		task.wait(1)
	end

	chassis:giveOwnership(player)
end

Players.PlayerAdded:Connect(PlayerAdded)
