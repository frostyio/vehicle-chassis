local module = {}

function module.toKg(mass: number)
	return mass / 8
end

function module.kgToLbs(kg: number)
	return kg * 2.205
end

function module.getAssemblyMass(assembly: Instance): number
	local sum = 0

	for _, v in assembly:GetDescendants() do
		if v:IsA("BasePart") then
			sum += v.AssemblyMass
		end
	end

	return sum
end

function module.toMPH(velocity: number)
	return (velocity * 3600) * 0.0001739839
end

return module
