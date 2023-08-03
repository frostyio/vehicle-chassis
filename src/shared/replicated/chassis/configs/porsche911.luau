local chassis = script.Parent.Parent
local types = require(chassis:WaitForChild("types"))

-- local stiff = 9000
-- local loadOnSpring = 172 / 4
-- local damping = 2 * math.sqrt(stiff * loadOnSpring)
-- local damping = 2 * math.sqrt(mass * stiff)
local stiff = 18000
local damping = 80

local frontSpring: types.Spring = { stiffness = stiff, damping = damping, freeLength = 2 }
local backSpring: types.Spring = { stiffness = stiff, damping = damping, freeLength = 2 }
local frontCylindrical: types.Cylindrical = { lowerLimit = -1, upperLimit = -0.2 }
local backCylindrical: types.Cylindrical =
	{ lowerLimit = -1, upperLimit = -0.2, angularActuator = Enum.ActuatorType.Motor }

return {
	crankRange = { min = 0.8, max = 1.4 },

	torqueCurve = {
		-- ["rpm", "torque"]
		{ 0, 0 },
		{ 1000, 205 },
		{ 1500, 310 },
		{ 2000, 360 },
		{ 2500, 400 },
		{ 3000, 425 },
		{ 3500, 430 },
		{ 4000, 445 },
		{ 4500, 455 },
		{ 5000, 460 },
		{ 6500, 460 },
		{ 7000, 450 },
		{ 7500, 425 },
		{ 8000, 400 },
		{ 9000, 350 },
	},
	idleRPM = 1000,
	peakRPM = 7000,
	redlineRPM = 9000,
	redlineKickback = 1000,

	rpmAccel = 60,
	rpmDecay = 15,
	clutchEngangmentRate = 0.9,

	transmissionMode = "Semi",
	autoUpBias = -300,
	autoDownBias = 1300,

	idleThrottle = 15 / 100,

	frontBreakForce = 10_000,
	rearBreakForce = 10_000,
	parkingBreakForce = 7_000,

	tcsThreshold = 15,
	tcsGradient = 1,
	tcsLimit = 10 / 100, -- minimum 10%

	absThreshold = 2,

	-- final drive ratio = 3.09
	finalDriveRatio = 3.09,
	gearRatios = {
		3.75,
		2.38,
		1.72,
		1.34,
		1.08,
		0.88,
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
		-- idle = "coupe_idle",
		crank = { name = "coupe_crank", pitch = { min = 0.8, max = 0.8 }, volume = 0.2 },
		-- { name = "coupe_idle", pitch = { min = 0.9, max = 1.2 } },
		-- { name = "coupe_low", pitch = { min = 0.5, max = 1.2 } },
		-- { name = "coupe_high", pitch = { min = 0.5, max = 1 } },
		idle = "Carrera_S_idle",
		{ name = "Carrera_S_idle" },
		{ name = "Carrera_S_2500" },
		{ name = "Carrera_S_3900" },
		{ name = "Carrera_S_4000" },
		{ name = "Carrera_S_5200" },
	},

	plugins = {
		"tachometer",
		-- "slippageAccessories"
	},
} :: types.VehicleConfig
