-- local root: BasePart = workspace:WaitForChild("TestCar").Base
-- local wheels = { "FL", "BL", "FR", "BR" }

-- local wheelRadius = 0.5
-- local stiffness = 100
-- local damping = 5
-- local suspensionMaxLength = 2

-- local suspensionLengthMemory = {}
-- for _, k in wheels do
-- 	suspensionLengthMemory[k] = 0.5
-- end

-- --

-- local params = RaycastParams.new()
-- local ignore = { root.Parent }
-- params.FilterDescendantsInstances = ignore

-- local function raycastWheel(origin: Vector3): (Vector3, RaycastResult)
-- 	local cframe = root.CFrame
-- 	local rayOrigin = cframe:ToWorldSpace(CFrame.new(origin)).Position
-- 	local rayDir = -cframe.UpVector * (suspensionMaxLength + wheelRadius)
-- 	local raycast = workspace:Raycast(rayOrigin, rayDir, params)
-- 	return rayOrigin, raycast
-- end

-- local function updateSpring(name: string, dt: number, rayOrigin: Vector3, raycast: RaycastResult)
-- 	local dist = (raycast.Position - rayOrigin).Magnitude
-- 	local length = math.clamp(dist - wheelRadius, 0, suspensionMaxLength)
-- 	local stiffnessForce = stiffness * (suspensionMaxLength - length)
-- 	local damperForce = damping * ((suspensionLengthMemory[name] - length) / dt)
-- 	local suspensionForce = root.CFrame.UpVector * (stiffnessForce + damperForce)
-- 	suspensionLengthMemory[name] = length

-- 	root:ApplyImpulseAtPosition(suspensionForce, rayOrigin)
-- end

-- -- debug beams
-- local beamAttachments, beams = {}, {}
-- local hitColor, defaultColor =
-- 	ColorSequence.new(Color3.fromRGB(255, 0, 0)), ColorSequence.new(Color3.fromRGB(0, 255, 0))
-- for _, name in wheels do
-- 	local endPoint = Instance.new("Attachment")
-- 	endPoint.Parent = root
-- 	local attachment = root:FindFirstChild(name)

-- 	local origin = attachment.Position
-- 	local cframe = root.CFrame
-- 	local rayDir = -cframe.UpVector * (suspensionMaxLength + wheelRadius)
-- 	endPoint.Position = origin + rayDir

-- 	local beam = Instance.new("Beam")
-- 	beam.Attachment0 = attachment
-- 	beam.Attachment1 = endPoint
-- 	beam.FaceCamera = true
-- 	beam.Width0 = 0.2
-- 	beam.Width1 = 0.2
-- 	beam.Parent = root

-- 	beamAttachments[name] = endPoint
-- 	beams[name] = beam
-- end

-- while true do
-- 	local dt = task.wait()
-- 	root:SetNetworkOwner(nil)

-- 	for _, name in wheels do
-- 		local attachment = root:FindFirstChild(name)
-- 		local cframe = root.CFrame
-- 		local origin = attachment.Position
-- 		local rayOrigin, raycast = raycastWheel(origin)
-- 		local beamAttachment = beamAttachments[name]

-- 		if raycast then
-- 			updateSpring(name, dt, rayOrigin, raycast)

-- 			local rayDir = -cframe.UpVector * (suspensionLengthMemory[name] + wheelRadius)
-- 			beamAttachment.Position = origin + rayDir
-- 			beams[name].Color = hitColor
-- 		else
-- 			local rayDir = -cframe.UpVector * (suspensionMaxLength + wheelRadius)
-- 			beamAttachment.Position = origin + rayDir

-- 			beams[name].Color = defaultColor
-- 		end
-- 	end
-- end
