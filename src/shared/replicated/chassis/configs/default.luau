local types = require(script.Parent.Parent.types)

local components = script.Parent.Parent.components
local Input = require(components:WaitForChild("input"))
local Engine = require(components:WaitForChild("engine"))
local DriveTrain = require(components:WaitForChild("drivetrain"))
local Steering = require(components:WaitForChild("steer"))

local defaultWheel: types.WheelConfig = {
	---- friction coefficients [0, 1]
	--- u_k = 0 == no kinetic grip, 1 == max kinetic grip
	--- u_s = 0 == no static friction, 1 == max static friction
	grip_u_k = 1, -- lower = more slip, higher = less slip
	grip_u_s = 2,
	rolling_u_k = 0.03, -- lower = less rolling resistence, higher = more rolling resistance
	rolling_u_s = 0,

	----
	wheelRadius = 2.72 / 2,
	wheelMass = 100, -- lower = more slip, higher = less slip

	springStiffness = 1.7,
	springDamper = 12,
	restSuspension = 2.4,
	maxSuspension = 3.5,
}

return {
	---- physics
	wheels = {
		FL = defaultWheel,
		FR = defaultWheel,
		RL = defaultWheel,
		RR = defaultWheel,
	},

	-- 0 - 1
	dragCoefficient = 0.2,
	downforceCoefficient = 1,
	lateralCoefficient = 0.1,

	{ "input", Input, config = {} :: Input.Config },
	{
		"engine",
		Engine,
		config = {
			idleRPM = 1000,
			peakRPM = 7000,
			redlineRPM = 9000,
			redlineKickback = 1000,

			rpmAccel = 60,
			rpmDecay = 15,

			idleThrottle = 0.05,

			torqueCurve = {
				-- rpm, torque
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
		} :: Engine.Config,
	},
	{
		"drivetrain",
		DriveTrain,
		config = {
			wheels = { "FL", "FR" },
			gearRatios = {
				3.75,
				2.38,
				2.1,
				1.72,
				1.46,
				1.3,
			},
			finalDriveRatio = 4.09,
			reverseRatio = 4,
			clutchEngagementRate = 0.9,

			transmissionMode = "Semi",
			shiftTime = 0.2,
		} :: DriveTrain.Config,
	},
	{
		"steering",
		Steering,
		config = { wheels = { "FL", "FR" }, turnForgiveness = 50, turnSpeed = 1.5, turnRadius = 15 } :: Steering.Config,
	},

	---- plugins
	"debug",
	"tachometer",
	"sound",
	----

	engineSounds = {
		-- idle = "coupe_idle",
		crank = { name = "coupe_crank", pitch = { min = 0.8, max = 0.8 }, volume = 0.2 },
		idle = "Carrera_S_idle",
		{ name = "Carrera_S_idle" },
		{ name = "Carrera_S_2500" },
		{ name = "Carrera_S_3900" },
		{ name = "Carrera_S_4000" },
		{ name = "Carrera_S_5200" },
	},
} :: types.VehicleConfig
