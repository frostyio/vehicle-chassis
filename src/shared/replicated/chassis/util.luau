local configs = script.Parent:WaitForChild("configs")
local types = require(script.Parent:WaitForChild("types"))

local util = {}

function util.getComponents(vehicle: Instance): (Folder, BasePart, VehicleSeat, types.VehicleConfig)
	return vehicle:WaitForChild("Wheels") :: Folder,
		vehicle:WaitForChild("Base") :: BasePart,
		vehicle:WaitForChild("VehicleSeat") :: VehicleSeat,
		require(configs:WaitForChild(vehicle:GetAttribute("Config") or "default"))
end

function util.getTorqueLUT(rpm: number, curve: { { number } }): number
	local lastRPM, lastTorque = 0, 0

	for _, data in curve do
		local thisRPM, thisTorque = unpack(data)

		if thisRPM > rpm then
			-- simple lerp
			local t = (rpm - lastRPM) / (thisRPM - lastRPM)
			return lastTorque + (thisTorque - lastTorque) * t
		end

		lastRPM, lastTorque = thisRPM, thisTorque
	end

	return lastTorque
end

function util.toMPH(velocity: number)
	return (velocity * 3600) * 0.0001739839
end

function util.setMassless(object: Instance, isMassless: boolean)
	for _, part in object:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		part.Massless = isMassless
	end
end

function util.calculateSlipAngle(velocity: Vector3, forwardVector: Vector3): number
	local forwardVelocity = velocity:Dot(forwardVector)
	local sideVelocity = velocity.Magnitude * forwardVector.Magnitude
	return math.atan2(sideVelocity, forwardVelocity * (180 / math.pi))
end

function util.calculateSlipRatio(tireSpeed: number, vehicleSpeed: number): number
	return (tireSpeed - vehicleSpeed) / tireSpeed
end

return util
