local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local chassis = shared:WaitForChild("chassis")
local remotes = ReplicatedStorage:WaitForChild("remotes")
local configs = chassis:WaitForChild("configs")

local defaultConfig = require(configs:WaitForChild("default"))

local ownershipRemote: RemoteEvent = remotes:WaitForChild("ownership")
local occupantRemote: RemoteEvent = remotes:WaitForChild("occupant")

--

local Forces = require(chassis.forces)
local handledForces: { [Chassis]: Forces.Forces } = {}

task.spawn(function()
	local RunService = game:GetService("RunService")
	while true do
		local dt = RunService.PreSimulation:Wait()

		for _, forces in handledForces do
			forces:step(dt)
		end
	end
end)

--

type ChassisProto = {
	vehicle: Instance,
	root: BasePart,
	lastOwner: Player?,
	raycastParams: RaycastParams,
}

local Chassis = {}
Chassis.__index = Chassis
export type Chassis = typeof(Chassis) & ChassisProto

function Chassis.new(vehicle: Instance): Chassis
	local root = vehicle:WaitForChild("Chassis") :: BasePart

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { root.Parent }

	local self =
		setmetatable({ vehicle = vehicle, root = root, lastOwner = nil, raycastParams = params } :: Chassis, Chassis)

	handledForces[self] = Forces.new(root, defaultConfig, params)
	self:setNetworkOwner(nil)

	return self
end

function Chassis.setNetworkOwner(self: Chassis, player: Player?)
	for _, p in self.vehicle:GetDescendants() do
		if p:IsA("BasePart") then
			p:SetNetworkOwner(player)
		end
	end
	self.root:SetNetworkOwner(player)
end

function Chassis.giveOwnership(self: Chassis, player: Player)
	if player then
		self:setNetworkOwner(player)
		ownershipRemote:FireClient(player, self.vehicle, true)
		handledForces[self]:Destroy()
		handledForces[self] = nil
		self.lastOwner = player

		--
		occupantRemote:FireClient(player, self.vehicle, true)
	else
		local lastOwner = self.lastOwner
		if lastOwner then
			ownershipRemote:FireClient(lastOwner, self.vehicle, false)
		end

		self:setNetworkOwner(nil)
		print("ownership removed")
		handledForces[self] = Forces.new(self.root, defaultConfig, self.raycastParams)
	end
end

return Chassis
