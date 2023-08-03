local chassis = script.Parent.Parent
local types = require(chassis:WaitForChild("types"))

local frontSpring: types.Spring = { stiffness = 16_000, damping = 1000, freeLength = 2.3 }
local backSpring: types.Spring = { stiffness = 16_000, damping = 5000, freeLength = 2.3 }
local frontCylindrical: types.Cylindrical = { lowerLimit = -1, upperLimit = -0.2 }
local backCylindrical: types.Cylindrical =
	{ lowerLimit = -1, upperLimit = -0.2, angularActuator = Enum.ActuatorType.Motor }

return {
	torqueCurve = {
		-- ["rpm", "torque"]
		{ 0, 0 },
		{ 500, 165 },
		{ 1000, 295 },
		{ 2000, 396 },
		{ 3000, 435 },
		{ 4000, 395 },
		{ 5000, 338 },
		{ 6000, 257 },
		{ 8000, 85 },
	},
	idleRPM = 500,
	peakRPM = 7000,
	redlineRPM = 8000,
	redlineKickback = 1000,

	rpmAccel = 150,
	rpmDecay = 75,
	clutchEngangmentRate = 0.9,

	transmissionMode = "Manuel",
	autoUpBias = -300,
	autoDownBias = 1300,

	idleThrottle = 15 / 100,

	frontBreakForce = 20_000,
	rearBreakForce = 15_000,
	parkingBreakForce = 40_000,

	tcsThreshold = 15,
	tcsGradient = 1,
	tcsLimit = 10 / 100, -- minimum 10%

	absThreshold = 10,

	maxAngularAcceleration = 100000,

	gearRatios = {
		4.056,
		2.301,
		1.595,
		1.248,
	},

	turnRadius = 20,
	turnSpeed = 3,
	turnForgiveness = 100,

	springs = {
		BL = backSpring,
		BR = backSpring,
		FL = frontSpring,
		FR = frontSpring,
	},
	cylindrical = {
		BL = backCylindrical,
		BR = backCylindrical,
		FL = frontCylindrical,
		FR = frontCylindrical,
	},

	engineSounds = {
		idle = "xedos_idle",
		{ name = "xedos_idle", pitch = { min = 0.7, max = 1 }, speed = { min = 0.5, max = 1.2 } },
		{ name = "xedos_mid", pitch = { min = 0.7, max = 1 }, speed = { min = 0.5, max = 1.2 } },
		{ name = "xedos_high", pitch = { min = 0.7, max = 1 }, speed = { min = 0.5, max = 1.2 } },
	},

	plugins = { "tachometer" },
} :: types.VehicleConfig
