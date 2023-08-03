local ReplicatedStorage = game:GetService("ReplicatedStorage")

local soundsFolder = ReplicatedStorage:WaitForChild("sounds")
local engineSounds = soundsFolder:WaitForChild("engine")

local types = require(script.Parent:WaitForChild("types"))

local random = Random.new()

--

type SoundProto = {
	config: types.VehicleConfig,
	root: Instance,
	sounds: types.Sounds,
	standardVolume: number,
}

local SoundPanel = {}
SoundPanel.__index = SoundPanel
export type SoundPanel = typeof(SoundPanel) & SoundProto

function SoundPanel.new(root: Instance, config: types.VehicleConfig): SoundPanel
	local self = setmetatable({
		config = config,
		root = root,
		sounds = {},
		standardVolume = config.standardVolume or 0.9,
	} :: SoundProto, SoundPanel)

	-- blending zones
	local numberOfSounds = #self.sounds
	local peakRPM = config.peakRPM

	local rpmZone = peakRPM / numberOfSounds

	local zones = {}
	for i = 1, numberOfSounds do
		table.insert(zones, (i - 1) * rpmZone)
	end

	self.rpmZones = zones

	--

	self:loadEngineSounds()
	self:adjustAllVolumes(0)
	self:playAll()

	return self
end

function SoundPanel.loadSound(self: SoundPanel, key: string | number, data: string | types.VehicleSound)
	local newData: types.VehicleSound

	-- handle loading only the name vs with config data
	if typeof(data) == "string" then
		local sound = engineSounds:FindFirstChild(data)
		assert(sound, `Could not find sound named '{data}'`)

		local clone = sound:Clone()
		clone.Parent = self.root

		newData = { name = data, object = clone }
	else
		data = data :: types.VehicleSound

		local sound = data.object or engineSounds:FindFirstChild(data.name)
		assert(sound, `Could not find sound named '{data.name}'`)

		local clone = sound:Clone()
		clone.Parent = self.root

		newData = table.clone(data)
		newData.object = clone
	end

	local pitchEffect = Instance.new("PitchShiftSoundEffect")
	pitchEffect.Parent = newData.object
	newData.pitchEffect = pitchEffect

	self.sounds[key] = newData
	print(`loading sound '{key}'`)
end

function SoundPanel.loadEngineSounds(self: SoundPanel)
	for key, data in self.config.engineSounds do
		self:loadSound(key, data)
	end
end

--

function SoundPanel.getSound(self: SoundPanel, key: string | number): types.VehicleSound
	return self.sounds[key] :: types.VehicleSound
end

function SoundPanel.playSound(self: SoundPanel, key: string | number)
	local sound = self:getSound(key)
	assert(sound, `Could not find sound '{key}'`)
	sound.object:Play()
end

function SoundPanel.stopSound(self: SoundPanel, key: string | number)
	local sound = self:getSound(key)
	assert(sound, `Could not find sound '{key}'`)
	sound.object:Stop()
end

function SoundPanel.playAll(self: SoundPanel)
	for _, sound in self.sounds do
		sound.object:Play()
	end
end

function SoundPanel.stopAll(self: SoundPanel)
	for _, sound in self.sounds do
		sound.object:Stop()
	end
end

function SoundPanel.adjustVolume(self: SoundPanel, soundIndex: number | string, volume: number?)
	local sound = self.sounds[soundIndex]
	assert(sound, `Could not find sound at index '{soundIndex}'`)

	sound.object.Volume = (volume or sound.volume or self.standardVolume) * (sound.volumeScale or 1)
end

function SoundPanel.adjustAllVolumes(self: SoundPanel, volume: number?)
	for key in self.sounds do
		self:adjustVolume(key, volume)
	end
end

function SoundPanel.adjustOtherVolumes(self: SoundPanel, index: number | string, volume: number?)
	for key in self.sounds do
		if key == index then
			continue
		end

		self:adjustVolume(key, volume)
	end
end

function SoundPanel.adjustPitch(self: SoundPanel, soundIndex: number | string, pitchN: number?)
	local sound = self.sounds[soundIndex]
	assert(sound, `Could not find sound at index '{soundIndex}'`)

	local pitch = pitchN or if sound.pitch then random:NextNumber(sound.pitch.min, sound.pitch.max) else 1
	sound.pitchEffect.Octave = pitch * (self.config.pitchScale or 1)
end

function SoundPanel.adjustSpeed(self: SoundPanel, soundIndex: number | string, speedN: number)
	local sound = self.sounds[soundIndex]
	assert(sound, `Could not find sound at index '{soundIndex}'`)

	local speed = speedN or if sound.speed then random:NextNumber(sound.speed.min, sound.speed.max) else 1
	sound.object.PlaybackSpeed = speed * (self.config.speedScale or 1)
end

local function calculateFromRPM(normalizedRPM: number, min: number, max: number): number
	local range = max - min
	local value = min + normalizedRPM * range

	return value
end

function SoundPanel.update(self: SoundPanel, state: types.ChassisState)
	if not state.engineState then
		self:adjustAllVolumes(0)
		return
	end

	-- forward sound blending
	local rpm = state.rpm
	local config = self.config
	local numSounds = #self.sounds

	local normalizedRPM = (math.clamp(rpm, config.idleRPM, config.peakRPM) - config.idleRPM)
		/ (config.peakRPM - config.idleRPM)
	local blendWeights = table.create(numSounds, 0)

	if normalizedRPM ~= 0 then
		local interval = 1 / (numSounds - 1)

		local idx1 = math.floor(normalizedRPM / interval) + 1
		local idx2 = idx1 + 1

		blendWeights[idx1] = 1 - (normalizedRPM - (idx1 - 1) * interval) / interval
		blendWeights[idx2] = 1 - blendWeights[idx1]

		for i = 1, numSounds do
			if i ~= idx1 and i ~= idx2 then
				blendWeights[i] = 0
			end
		end
	else
		blendWeights[1] = 1
	end

	for i = 1, numSounds do
		local sound = self:getSound(i)
		self:adjustVolume(i, blendWeights[i] * self.standardVolume)

		if sound.pitch then
			self:adjustPitch(i, calculateFromRPM(normalizedRPM, sound.pitch.min, sound.pitch.max))
		else
			self:adjustPitch(i, 1)
		end

		if sound.speed then
			self:adjustSpeed(i, calculateFromRPM(normalizedRPM, sound.speed.min, sound.speed.max))
		else
			self:adjustSpeed(i, 1)
		end
	end
end

function SoundPanel.destroy(self: SoundPanel)
	for _, sound in self.sounds do
		sound.object:Destroy()
	end
	self.sounds = {}
end

return SoundPanel
