export type State = { [string]: any }

export type Object = {
	new: (...any) -> Object,
	step: (any, number) -> (),
	Destroy: (any) -> (),
	state: { [any]: any },
}

export type VehicleComponent = {
	[number]: Object | string,
	config: any,
}

export type Plugin = {
	new: (State, any) -> Plugin,
	step: (any, State, number) -> (),
	Destroy: (any) -> (),
}

export type WheelConfig = {
	grip_u_k: number,
	grip_u_s: number,

	rolling_u_k: number,
	rolling_u_s: number,

	wheelRadius: number,
	wheelMass: number,

	springStiffness: number,
	springDamper: number,
	restSuspension: number,
	maxSuspension: number,
}

export type VehicleConfig = {
	---- physics
	wheels: { [string]: WheelConfig },
	dragCoefficient: number,
	downforceCoefficient: number,
	lateralCoefficient: number,

	---- drive train
	driveTrainWheels: { string },

	---- steering
	steeringWheels: { string },

	---- components / plugins
	[number]: VehicleComponent | string,

	----
	engineSounds: Sounds,
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

return nil
