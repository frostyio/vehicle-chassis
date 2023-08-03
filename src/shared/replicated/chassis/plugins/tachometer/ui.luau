local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage:WaitForChild("packages")

local Fusion = require(packages._Index["elttob_fusion@0.2.0"]["fusion"])
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring

local label = require(script.Parent.label)
local dial = require(script.Parent.dial)

local fromScale = UDim2.fromScale

local secondaryColor = Color3.fromRGB(204, 204, 204)
local redlineColor = Color3.fromRGB(155, 75, 84)

--

local startRPMLabelPosition = fromScale(0.3, 0.76)
local rpmLabel = label({
	Text = "0",
	Size = fromScale(0.15, 0.15),
	Color = Color3.fromRGB(227, 227, 227),
})
local radius = math.sqrt((startRPMLabelPosition.X.Scale - 0.5) ^ 2 + (startRPMLabelPosition.Y.Scale - 0.5) ^ 2)
local startAngle, endAngle = math.rad(35), math.rad(35)

--

export type TachometerProps = {
	peakRPM: number,
	redlineRPM: number,

	currentGear: Fusion.Value<string>,
	currentRPM: Fusion.Value<number>,
	currentSpeed: Fusion.Value<number>,
	absActive: Fusion.Value<boolean>,
	tcsActive: Fusion.Value<boolean>,

	speedMetric: Fusion.Value<"MPH" | "KPH">,
}

return function(props: TachometerProps)
	local rpm = Spring(Computed(function()
		return props.currentRPM:get()
	end))

	return New("ImageLabel")({
		Name = "Tachometer",
		Position = fromScale(0.95, 0.95),
		SizeConstraint = "RelativeXX",
		AnchorPoint = Vector2.new(1, 1),
		Size = fromScale(0.16, 0.16),
		BackgroundTransparency = 1,
		Image = "rbxassetid://14281649986",

		[Children] = {
			-- current gear
			label({ Text = props.currentGear, Size = fromScale(0.2, 0.2), Position = fromScale(0.5, 0.46) }),

			-- status icons

			-- tcs
			New("ImageLabel")({
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = fromScale(0.7, 0.45),
				Size = fromScale(0.08, 0.08),
				SizeConstraint = "RelativeXX",
				Image = "rbxassetid://14282073264",
				Visible = props.tcsActive,
			}),
			-- abs
			New("ImageLabel")({
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = fromScale(0.68, 0.56),
				Size = fromScale(0.08, 0.08),
				SizeConstraint = "RelativeXX",
				Image = "rbxassetid://14282047611",
				ImageTransparency = 1,
				Visible = props.absActive,
				[Children] = label({ Text = "ABS", Size = fromScale(0.9, 0.9), Position = fromScale(0.5, 0.5) }),
			}),

			-- rpm label
			label({
				Text = props.currentRPM,
				Size = fromScale(0.2, 0.11),
				Position = fromScale(0.5, 0.565),
				Color = secondaryColor,
			}),
			label({
				Text = "RPM",
				Size = fromScale(0.2, 0.09),
				Position = fromScale(0.5, 0.64),
				Color = secondaryColor,
			}),

			-- speed label
			label({
				Text = props.currentSpeed,
				Size = fromScale(0.24, 0.2),
				Position = fromScale(0.5, 0.75),
			}),
			label({
				Text = props.speedMetric,
				Size = fromScale(0.24, 0.12),
				Position = fromScale(0.5, 0.86),
			}),

			-- dials
			dial({
				Name = "RedlineDial",
				CircleStartOffset = 35,
				CircleEndOffset = 35,
				Direction = "Left",
				DialImage = "rbxassetid://14281832169",
				Color = redlineColor,
				Value = Value((props.redlineRPM - props.peakRPM) / props.redlineRPM),
			}),
			dial({
				Name = "RPMDial",
				CircleStartOffset = 30,
				CircleEndOffset = 30,
				Direction = "Right",
				DialImage = "rbxassetid://14281739064",
				Value = Computed(function()
					return rpm:get() / props.redlineRPM
				end),
			}),

			-- rpm labels
			[Children] = Computed(function()
				local container = New("Frame")({ BackgroundTransparency = 1, Size = fromScale(1, 1) })
				local n = math.floor(props.redlineRPM / 1000) + 1

				for i = 0, n - 1 do
					local clone = rpmLabel:Clone() :: TextLabel
					clone.Text = tostring(i)
					local t = i / n * (2 * math.pi - endAngle) + startAngle
					clone.Position = fromScale(math.sin(t) * -radius + 0.5, math.cos(t) * radius + 0.48)
					if i * 1000 > props.peakRPM then
						clone.TextColor3 = redlineColor
					end
					clone.Parent = container
				end
				return container
			end, function(container: Frame?)
				if container then
					container:Destroy()
				end
			end),
		},
	})
end
