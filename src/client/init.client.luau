local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("shared")
local Chassis = require(shared:WaitForChild("chassis"))

local Client = Players.LocalPlayer

local currentChassis: Chassis.Chassis? = nil

local function CharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	humanoid.Seated:Connect(function(active, seat)
		if active == false then
			if currentChassis ~= nil then
				currentChassis:destroy()
			end

			return
		end

		local vehicle = seat:FindFirstAncestorWhichIsA("Model")
		if not vehicle:GetAttribute("isVehicle") then
			return
		end

		currentChassis = Chassis.initialize(vehicle)
	end)
end

Client.CharacterAdded:Connect(CharacterAdded)
