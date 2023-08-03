type BeamProto = {
	attachment1: Attachment,
	attachment2: Attachment,
	beam: Beam,
}

local DebugBeam = {}
DebugBeam.__index = DebugBeam
export type DebugBeam = typeof(DebugBeam) & BeamProto

function DebugBeam.new(root: Instance, origin: CFrame, offset: CFrame, color: ColorSequence?): DebugBeam
	local attach1 = Instance.new("Attachment")
	local attach2 = Instance.new("Attachment")
	local beam = Instance.new("Beam")

	beam.FaceCamera = true
	beam.Width0 = 0.2
	beam.Width1 = 0.2
	beam.Color = color or ColorSequence.new(Color3.fromRGB(93, 59, 242))
	beam.Attachment0 = attach1
	beam.Attachment1 = attach2

	attach1.CFrame = origin
	attach2.CFrame = offset

	attach1.Parent = root
	attach2.Parent = root
	beam.Parent = root

	local self = setmetatable({
		attachment1 = attach1,
		attachment2 = attach2,
		beam = beam,
	} :: BeamProto, DebugBeam)

	return self
end

function DebugBeam.update(self: DebugBeam, origin: CFrame, offset: CFrame)
	self.attachment1.CFrame = origin
	self.attachment2.CFrame = offset
end

function DebugBeam.destroy(self: DebugBeam)
	self.attachment1:Destroy()
	self.attachment2:Destroy()
	self.beam:Destroy()
end

return DebugBeam
