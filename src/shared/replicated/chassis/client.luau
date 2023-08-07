-- careful! this script is required on the server through config!

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Client = Players.LocalPlayer

local shared = ReplicatedStorage:WaitForChild("shared")
local packages = ReplicatedStorage:WaitForChild("packages")

local Trove = require(packages:WaitForChild("trove"))
type Trove = typeof(Trove)

-- chassis
local chassisFolder = shared:WaitForChild("chassis")
local types = require(chassisFolder:WaitForChild("types"))
local plugins = chassisFolder:WaitForChild("plugins")
local Forces = require(chassisFolder:WaitForChild("forces"))

-- other
local handledVehicles: { [Instance]: Chassis } = {}
local currentChassis: Chassis = nil

----

type ChassisProto = {
	--- base variables
	vehicle: Instance,
	root: BasePart,
	config: types.VehicleConfig,

	--- objects
	forces: Forces.Forces,
	components: { [string]: types.Object },
	plugins: { [string]: types.Plugin },
	trove: Trove,

	--- state
	state: types.State,
	isDestroyed: boolean,
}

local Chassis = {}
Chassis.__index = Chassis
export type Chassis = typeof(Chassis) & ChassisProto

function Chassis.new(vehicle: Instance, config: types.VehicleConfig): Chassis
	warn("creating client chassis")
	local root = vehicle:WaitForChild("Chassis") :: BasePart

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { vehicle, Client.Character }

	local trove = Trove.new()

	local self = setmetatable({
		--- base variables
		vehicle = vehicle,
		root = root,
		config = config,

		--- objects
		forces = trove:Construct(Forces, root, config, raycastParams),
		trove = trove,

		--- state
		state = { isOccupied = false, speed = 0 },
		isDestroyed = false,
	} :: Chassis, Chassis)

	handledVehicles[vehicle] = self
	self:loadComponents()
	self:loadPlugins()

	return self
end

---- components

function Chassis.loadComponents(self: Chassis)
	local components = {}

	for _, component in ipairs(self.config) do
		if typeof(component) == "string" then
			-- this is a plugin, skip it
			continue
		end

		warn(`loading component '{component[1]}'`)
		components[component[1]] = self.trove:Construct(component[2], self, component.config)
		self.state[component[1]] = components[component[1]].state
	end

	self.components = components
end

function Chassis.getComponent(self: Chassis, component: string): types.Object
	return self.components[component]
end

function Chassis.stepComponents(self: Chassis, dt: number)
	for name, component in self.components do
		component:step(dt)
		self.state[name] = component.state
	end
end

---- plugins

function Chassis.loadPlugins(self: Chassis)
	local state = self.state
	local plugs = {}

	for _, pluginName in ipairs(self.config) do
		if typeof(pluginName) ~= "string" then
			-- this is a component, skip it
			continue
		end

		warn(`loading plugin '{pluginName}'`)
		local plugin = require(plugins:FindFirstChild(pluginName))
		plugs[pluginName] = self.trove:Construct(plugin, state, self)
	end

	self.plugins = plugs
end

function Chassis.stepPlugins(self: Chassis, dt: number)
	local state = self.state
	for _, plug in self.plugins do
		plug:step(state, dt)
	end
end

----

function Chassis.step(self: Chassis, dt: number)
	self.forces:step(dt)
	self:stepComponents(dt)
	self:stepPlugins(dt)

	self.state.speed = self.root.AssemblyLinearVelocity.Magnitude * 3600 * 0.0001739839
end

----

function Chassis.occupantChanged(self: Chassis, isOccupied: boolean)
	warn("given occupancy!")
	self.state.isOccupied = isOccupied
	currentChassis = isOccupied and self or nil
end

function Chassis.Destroy(self: Chassis)
	handledVehicles[self.vehicle] = nil
	self.isDestroyed = true
	currentChassis = nil
	self.trove:Destroy()
end

--- update loop

if RunService:IsClient() then
	task.spawn(function()
		while true do
			local dt = RunService.PreSimulation:Wait()

			for _, chassis in handledVehicles do
				chassis:step(dt)
			end

			--- todo
			local character = Client.Character
			if character and currentChassis then
				local root = character:WaitForChild("HumanoidRootPart")
				root.Anchored = true
				local c = workspace.CurrentCamera
				c.CameraSubject = currentChassis.root
			end
		end
	end)
end

---

return Chassis
