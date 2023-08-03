local chassis = script.Parent.Parent
local types = require(chassis:WaitForChild("types"))

local stiffness = 528 * workspace.Gravity

local frontSpring: types.Spring = { stiffness = stiffness, damping = 5000, freeLength = 2.3 }
local backSpring: types.Spring = { stiffness = stiffness, damping = 5000, freeLength = 2.3 }
local frontCylindrical: types.Cylindrical = { lowerLimit = -1, upperLimit = -0.2 }
local backCylindrical: types.Cylindrical =
	{ lowerLimit = -1, upperLimit = -0.2, angularActuator = Enum.ActuatorType.Motor }

return {
	crankRange = { min = 0.8, max = 1.4 },

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
	peakRPM = 5500,
	redlineRPM = 7000,
	redlineKickback = 1000,

	rpmAccel = 60,
	rpmDecay = 15,
	clutchEngangmentRate = 0.9,

	transmissionMode = "Semi",
	autoUpBias = -300,
	autoDownBias = 1300,

	idleThrottle = 15 / 100,

	frontBreakForce = 20_000,
	rearBreakForce = 15_000,
	parkingBreakForce = 10_000,

	tcsThreshold = 15,
	tcsGradient = 1,
	tcsLimit = 10 / 100, -- minimum 10%

	absThreshold = 10,

	gearRatios = {
		4.056,
		2.301,
		1.595,
		1.248,
		1.212,
	},

	turnSpeed = 2,
	turnRadius = 20,
	turnForgiveness = 50,

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

	-- sounds
	engineSounds = {
		idle = "coupe_idle",
		crank = { name = "coupe_crank", pitch = { min = 0.8, max = 0.8 }, volume = 0.2 },
		{ name = "coupe_idle", pitch = { min = 0.9, max = 1.2 } },
		{ name = "coupe_low", pitch = { min = 0.5, max = 1.2 } },
		{ name = "coupe_high", pitch = { min = 0.5, max = 1 } },
	},

	plugins = { "slippageAccessories", "tachometer" },
} :: types.VehicleConfig
