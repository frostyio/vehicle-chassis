export type EngineState = "On" | "Off"
export type VehicleState = "Neutral" | "Forward" | "Reversing"
export type ChassisState = {
	engineState: boolean,
	rpm: number,
	torque: number,
	speed: number,
	gear: number,
	vehicleState: VehicleState,
	isBreaking: boolean,
	isParkingBreak: boolean,
	isTCSActive: boolean,
	isABSActive: boolean,
}

export type Spring = { stiffness: number, damping: number, freeLength: number }
export type Cylindrical = {
	lowerLimit: number,
	upperLimit: number,
	maxTorque: number?,
	angularActuator: Enum.ActuatorType?,
}

export type Range = { min: number, max: number }
export type VehicleSound = {
	name: string,
	pitch: Range?,
	speed: Range?,
	volumeScale: number?,
	volume: number?,
	object: Sound?,
	pitchEffect: PitchShiftSoundEffect?,
}
export type Sounds = { [number | string]: string | VehicleSound }

export type VehicleConfig = {
	crankRange: Range?,

	-- STEERING
	turnSpeed: number,
	turnRadius: number,
	turnForgiveness: number, -- higher number = lower turn speed at high speeds

	-- ENGINE
	torqueCurve: { { number } },
	gearRatios: { number },

	idleThrottle: number,

	idleRPM: number,
	peakRPM: number,
	redlineRPM: number,
	redlineKickback: number, -- keep it away from the redline!

	-- when clutch is disenganged
	rpmAccel: number,
	rpmDecay: number,
	clutchEngangmentRate: number,

	-- transmission
	finalDriveRatio: number?,
	transmissionMode: "Manual" | "Semi",
	autoUpBias: number, -- peakRPM + autoUpBias = rpm to upshift at
	autoDownBias: number, -- peakRPM - autoDownBias = rpm to downshift at
	shiftTime: number,

	-- BREAKING
	frontBreakForce: number,
	rearBreakForce: number,
	parkingBreakForce: number,

	-- TCS
	tcsThreshold: number,
	tcsGradient: number,
	tcsLimit: number,

	-- ABS
	absThreshold: number,

	-- SOUND
	standardVolume: number?,
	pitchScale: number?,
	speedScale: number?,
	engineSounds: Sounds,

	-- CONFIG

	springs: { [string]: Spring },
	cylindrical: { [string]: Cylindrical },

	useConstraints: boolean?,

	plugins: { string }?,
}

return nil
