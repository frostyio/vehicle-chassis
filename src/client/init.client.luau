local ReplicatedStorage = game:GetService("ReplicatedStorage")

--- remotes
local remotes = ReplicatedStorage:WaitForChild("remotes")
local ownershipRemote: RemoteEvent = remotes:WaitForChild("ownership")
local occupantRemote: RemoteEvent = remotes:WaitForChild("occupant")

--- chassis
local shared = ReplicatedStorage:WaitForChild("shared")
local chassisFolder = shared:WaitForChild("chassis")
local Chassis = require(chassisFolder:WaitForChild("client"))
local configs = chassisFolder:WaitForChild("configs")
local defaultConfig = require(configs:WaitForChild("default"))

--

local handledChassis: { [Instance]: Chassis.Chassis } = {}

local function handleOwnership(vehicle: Instance, isOwner: boolean)
	if isOwner then
		handledChassis[vehicle] = Chassis.new(vehicle, defaultConfig)
	elseif handledChassis[vehicle] then
		handledChassis[vehicle]:Destroy()
		handledChassis[vehicle] = nil
	end
end
ownershipRemote.OnClientEvent:Connect(handleOwnership)

local function handleOccupancy(vehicle: Instance, doOccupation: boolean)
	local chassis = handledChassis[vehicle]
	assert(chassis, "chassis not found")

	chassis:occupantChanged(doOccupation)
end

occupantRemote.OnClientEvent:Connect(handleOccupancy)
