-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local RunService = game:GetService("RunService")
-- local TweenService = game:GetService("TweenService")
-- local Players = game:GetService("Players")

-- local client = Players.LocalPlayer
-- local clientGui = client:WaitForChild("PlayerGui")
-- local rainGui = clientGui:WaitForChild("RainGui")
-- local cacheCount = rainGui:WaitForChild("CacheCount")
-- local dropletCount = rainGui:WaitForChild("DropletCount")
-- local dropletRate = rainGui:WaitForChild("DropletRate")

-- local octoTree = require(ReplicatedStorage.packages:WaitForChild("octo-tree"))

-- local List = {}
-- List.__index = List
-- function List.new()
-- 	return setmetatable({ first = 0, last = -1 }, List)
-- end

-- function List.pushleft(list, value)
-- 	local first = list.first - 1
-- 	list.first = first
-- 	list[first] = value
-- end

-- function List.pushright(list, value)
-- 	local last = list.last + 1
-- 	list.last = last
-- 	list[last] = value
-- end

-- function List.popleft(list)
-- 	local first = list.first
-- 	if first > list.last then
-- 		error("list is empty")
-- 	end
-- 	local value = list[first]
-- 	list[first] = nil -- to allow garbage collection
-- 	list.first = first + 1
-- 	return value
-- end

-- function List.popright(list)
-- 	local last = list.last
-- 	if list.first > last then
-- 		error("list is empty")
-- 	end
-- 	local value = list[last]
-- 	list[last] = nil -- to allow garbage collection
-- 	list.last = last - 1
-- 	return value
-- end

-- local queue = List

-- local droplet = ReplicatedStorage:WaitForChild("Droplet")

-- local camera = workspace.CurrentCamera

-- local DEBUG = false
-- local GRID_SIZE = 25 -- studs
-- local RAYCASTS_PER_CHUNK = 100
-- local RAIN_DISTANCE = 200
-- local RAIN_HEIGHT = 200
-- local DROP_RATE = 10
-- local AREA = 75
-- local RAIN_DROP_TIME = 0.7
-- local MARGIN = 10

-- local RAYCAST_PARAMS = RaycastParams.new()
-- RAYCAST_PARAMS.RespectCanCollide = true

-- local gridDebugPart
-- if DEBUG then
-- 	gridDebugPart = Instance.new("Part")
-- 	gridDebugPart.Anchored = true
-- 	gridDebugPart.CanCollide = false
-- 	gridDebugPart.Size = Vector3.new(GRID_SIZE, 1, GRID_SIZE)
-- 	gridDebugPart.Parent = workspace
-- end

-- -- chunk
-- local Chunk = {}
-- Chunk.__index = Chunk
-- do
-- 	local function getRandomPosition(xSize: number, zSize: number): Vector3
-- 		return Vector3.new(math.random(1, xSize), 0, math.random(1, zSize))
-- 	end

-- 	function Chunk.new(pos: Vector3): typeof(Chunk)
-- 		local self = setmetatable({ _origin = pos, paths = {} }, Chunk)

-- 		if DEBUG then
-- 			local exploredDebugPart = gridDebugPart:Clone()
-- 			exploredDebugPart.CFrame = CFrame.new(pos + Vector3.yAxis * 60)
-- 			exploredDebugPart.Parent = workspace
-- 		end

-- 		self:MapRaycasts(RAYCASTS_PER_CHUNK)

-- 		return self
-- 	end

-- 	function Chunk:MapRaycasts(amount: number)
-- 		for _ = 1, amount do
-- 			local pos = getRandomPosition(GRID_SIZE, GRID_SIZE) + self._origin + Vector3.yAxis * RAIN_HEIGHT

-- 			local result = workspace:Raycast(pos, Vector3.yAxis * -RAIN_DISTANCE, RAYCAST_PARAMS)
-- 			local destination = if result then result.Position else pos - Vector3.yAxis * RAIN_DISTANCE

-- 			table.insert(self.paths, { pos, destination })

-- 			-- if DEBUG then
-- 			-- 	local visual = gridDebugPart:Clone()
-- 			-- 	local dist = (destination - pos).Magnitude
-- 			-- 	visual.Size = Vector3.new(0.1, 0.1, dist)
-- 			-- 	visual.CFrame = CFrame.lookAt(pos, destination) * CFrame.new(0, 0, -dist / 2)
-- 			-- 	visual.Parent = workspace
-- 			-- end
-- 		end
-- 	end

-- 	function Chunk:GetPath(): { Vector3 }
-- 		return self.paths[math.random(1, #self.paths)]
-- 	end
-- end

-- -- chunking
-- local chunking = {}
-- do
-- 	local tree = octoTree.new()

-- 	local exploredChunks = {}

-- 	local function alignToGrid(pos: Vector3)
-- 		return Vector3.new(pos.X - (pos.X % GRID_SIZE) + GRID_SIZE / 2, 0, pos.Z - (pos.Z % GRID_SIZE) + GRID_SIZE / 2)
-- 	end

-- 	function chunking.updateChunks(pos: Vector3)
-- 		local gridPos = alignToGrid(pos)

-- 		for x = -5, 5 do
-- 			for z = -5, 5 do
-- 				local newPos = Vector3.new(x, 0, z) * GRID_SIZE + gridPos

-- 				if exploredChunks[newPos] then
-- 					continue
-- 				end

-- 				exploredChunks[newPos] = true
-- 				tree:CreateNode(newPos, Chunk.new(newPos))
-- 			end
-- 		end
-- 	end

-- 	function chunking.getChunks(pos: Vector3, radius: number)
-- 		return tree:SearchRadius(pos, radius)
-- 	end
-- end

-- local ObjectPool = {}
-- ObjectPool.__index = ObjectPool
-- do
-- 	function ObjectPool.new(template: Instance, initial: number?): typeof(ObjectPool)
-- 		local self = setmetatable(
-- 			{ _template = template, _list = queue.new(), available = initial, total = initial },
-- 			ObjectPool
-- 		)

-- 		for _ = 1, initial or 0 do
-- 			local object = self._template:Clone()
-- 			self._list:pushleft(object)
-- 		end

-- 		return self
-- 	end

-- 	function ObjectPool:Get(): Instance
-- 		if self.available > 0 then
-- 			self.available -= 1
-- 			return self._list:popleft()
-- 		else
-- 			local object = self._template:Clone()
-- 			self.total += 1
-- 			return object
-- 		end
-- 	end

-- 	function ObjectPool:Destroy(object: Instance)
-- 		self._list:pushleft(object)
-- 		self.available += 1
-- 	end
-- end

-- --

-- local function enactDroplet(pool: typeof(ObjectPool), origin: Vector3, goal: Vector3)
-- 	local margin = math.random(1, MARGIN) / 100
-- 	task.delay(margin, function()
-- 		local droplet = pool:Get() :: BasePart
-- 		droplet.Transparency = 0.3
-- 		droplet.CFrame = CFrame.new(origin)
-- 		droplet.Parent = workspace
-- 		local tween = TweenService:Create(droplet, TweenInfo.new(RAIN_DROP_TIME), { CFrame = CFrame.new(goal) })
-- 		tween:Play()

-- 		task.wait(RAIN_DROP_TIME)
-- 		droplet.Transparency = 1
-- 		droplet.Attachment.Ripple:Emit(1)

-- 		task.wait(0.5)
-- 		pool:Destroy(droplet)
-- 	end)
-- end

-- -- main

-- dropletRate.FocusLost:Connect(function()
-- 	local rate = tonumber(dropletRate.Text) or 50
-- 	DROP_RATE = rate
-- end)

-- local function main()
-- 	local pool = ObjectPool.new(droplet, 10000)
-- 	local chunks
-- 	local distributionPerChunk: number

-- 	task.spawn(function()
-- 		while true do
-- 			RunService.RenderStepped:Wait()

-- 			if not chunks then
-- 				continue
-- 			end

-- 			for _, chunkNode in chunks do
-- 				local chunk = chunkNode.Object
-- 				for _ = 1, distributionPerChunk do
-- 					local path = chunk:GetPath()
-- 					enactDroplet(pool, path[1], path[2])
-- 				end
-- 			end
-- 		end
-- 	end)

-- 	while true do
-- 		local pos = camera.CFrame.Position
-- 		chunking.updateChunks(pos)
-- 		chunks = chunking.getChunks(pos, AREA)
-- 		distributionPerChunk = math.ceil(DROP_RATE / #chunks)

-- 		dropletCount.Text = ("Droplets: %d"):format(pool.total - pool.available)
-- 		cacheCount.Text = ("Cache: %d"):format(pool.available)

-- 		task.wait(0.5)
-- 	end
-- end

-- main()
