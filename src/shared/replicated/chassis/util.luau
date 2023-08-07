local primaryColor = Color3.fromHex("#42f56f")
local secondaryColor = Color3.fromHex("#f54e42")
local tertiaryColor = Color3.fromHex("#f5b642")
local quaternaryColor = Color3.fromHex("#4293f5")
local neutralColor = Color3.fromHex("#93aebf")

local util = {
	colors = {
		primary = primaryColor,
		secondary = secondaryColor,
		tertiary = tertiaryColor,
		quaternary = quaternaryColor,
		neutral = neutralColor,
	},
}

-- debug beam util

type BeamProto = {
	startAttachment: Attachment,
	endAttachment: Attachment,
	beam: Beam,

	color: Color3,
	enabled: boolean,

	destroyed: boolean,
}
local DebugBeam = {}
DebugBeam.__index = DebugBeam
export type DebugBeam = typeof(DebugBeam) & BeamProto

function DebugBeam.new(enabled: boolean?, color: Color3?): DebugBeam
	local startAttachment = Instance.new("Attachment")
	local endAttachment = Instance.new("Attachment")
	local beam = Instance.new("Beam")

	startAttachment.Visible = true

	beam.Attachment0 = startAttachment
	beam.Attachment1 = endAttachment
	beam.Width0 = 0.2
	beam.Width1 = 0.2
	beam.FaceCamera = true
	beam.Enabled = enabled or false

	startAttachment.Parent = workspace.Terrain
	endAttachment.Parent = workspace.Terrain
	beam.Parent = workspace.Terrain

	return setmetatable({
		startAttachment = startAttachment,
		beam = beam,
		endAttachment = endAttachment,

		color = color or neutralColor,
		enabled = enabled or false,

		destroyed = false,
	} :: DebugBeam, DebugBeam)
end

function DebugBeam.updateBeam(self: DebugBeam)
	self.beam.Color = ColorSequence.new(self.color)
	self.beam.Enabled = self.enabled
end

function DebugBeam.dir(self: DebugBeam, origin: Vector3, direction: Vector3)
	self.startAttachment.WorldCFrame = CFrame.lookAt(origin, origin + direction)
	self.endAttachment.WorldCFrame = CFrame.new(origin) * CFrame.new(direction)
	self:updateBeam()
end

function DebugBeam.world(self: DebugBeam, startPt: Vector3, endPt: Vector3)
	self.startAttachment.WorldCFrame = CFrame.lookAt(startPt, endPt)
	self.endAttachment.WorldCFrame = CFrame.lookAt(endPt, startPt)
	self:updateBeam()
end

function DebugBeam.relative(self: DebugBeam, startPt: Vector3, endPt: Vector3)
	self.startAttachment.CFrame = CFrame.lookAt(startPt, endPt)
	self.endAttachment.CFrame = CFrame.lookAt(endPt, startPt)
	self:updateBeam()
end

function DebugBeam.Destroy(self: DebugBeam)
	self.destroyed = true
	self.startAttachment:Destroy()
	self.beam:Destroy()
	self.endAttachment:Destroy()
end

util.DebugBeam = DebugBeam

-- raycasting util

type RaycastProto = {
	origin: Vector3,
	direction: Vector3,
	params: RaycastParams,
	debug: boolean,

	debugBeam: DebugBeam?,
	debugSphere: Part?,

	destroyed: boolean,
}
local Raycast = {}
Raycast.__index = Raycast
export type Raycast = typeof(Raycast) & RaycastProto

function Raycast.new(origin: Vector3?, direction: Vector3?, params: RaycastParams, debug: boolean?): Raycast
	local debugBeam, debugSphere

	if debug then
		debugBeam = DebugBeam.new(false)

		debugSphere = Instance.new("Part")

		debugSphere.Anchored = true
		debugSphere.CanCollide = false
		debugSphere.CanQuery = false
		debugSphere.CanTouch = false
		debugSphere.Transparency = 1
		debugSphere.Shape = "Ball"
		debugSphere.Material = "Neon"

		debugSphere.Parent = workspace.Terrain
	end

	return setmetatable({
		origin = origin or Vector3.zero,
		direction = direction or Vector3.zero,
		params = params or RaycastParams.new(),
		debug = debug or false,

		debugBeam = debugBeam,
		debugSphere = debugSphere,

		destroyed = false,
	} :: Raycast, Raycast)
end

function Raycast.updateDebugBeam(
	self: Raycast,
	raycast: RaycastResult,
	origin: Vector3,
	direction: Vector3,
	radius: number?
)
	if self.debugBeam then
		local originCF = CFrame.new(origin)
		local endCF = originCF * CFrame.new(direction)
		local dist = if raycast then raycast.Distance else (endCF.Position - originCF.Position).Magnitude
		dist += radius or 0
		local unitDir = direction.Unit
		self.debugBeam.enabled = true
		self.debugBeam.color = if raycast then secondaryColor else primaryColor
		self.debugBeam:world(originCF.Position, (originCF * CFrame.new(unitDir * dist)).Position)

		if radius and self.debugSphere then
			local sphere = self.debugSphere
			sphere.Transparency = 0.2
			sphere.CFrame = originCF * CFrame.new(unitDir * (dist - radius / 2))
			sphere.Size = Vector3.one * radius
			sphere.Color = if raycast then secondaryColor else primaryColor
		end
	end
end

function Raycast.line(self: Raycast, origin1: Vector3?, direction1: Vector3?, params1: RaycastParams?): RaycastResult
	local origin = origin1 or self.origin
	local direction = direction1 or self.direction
	local params = params1 or self.params

	local raycast = workspace:Raycast(origin, direction, params)
	self:updateDebugBeam(raycast, origin, direction)

	return raycast
end

function Raycast.sphere(
	self: Raycast,
	radius: number,
	origin1: Vector3?,
	direction1: Vector3?,
	params1: RaycastParams?
): RaycastResult
	local origin = origin1 or self.origin
	local direction = direction1 or self.direction
	local params = params1 or self.params

	local raycast = workspace:Spherecast(origin, radius, direction, params)
	self:updateDebugBeam(raycast, origin, direction, radius)

	return raycast
end

function Raycast.Destroy(self: Raycast)
	self.destroyed = true

	if self.debugBeam and self.debugSphere then
		self.debugBeam:Destroy()
		self.debugSphere:Destroy()
	end
end

util.Raycast = Raycast

return util
