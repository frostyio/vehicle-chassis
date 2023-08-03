local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage:WaitForChild("packages")

local Fusion = require(packages._Index["elttob_fusion@0.2.0"]["fusion"])
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

local fromScale = UDim2.fromScale

--

export type Props = {
	Name: string?,
	Color: Color3?,
	Size: UDim2?,
	Position: UDim2?,
	DialImage: string,

	CircleStartOffset: number?,
	CircleEndOffset: number?,

	Direction: "Left" | "Right",
	Value: Fusion.Value<number>,
}

return function(props: Props)
	local color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, props.Color or Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, props.Color or Color3.fromRGB(255, 255, 255)),
	})

	local startOffset = props.CircleStartOffset
	local endOffset = props.CircleEndOffset

	local offsetCircle = 360 - startOffset - endOffset

	local value = Computed(function()
		return math.clamp(props.Value:get() * offsetCircle + startOffset, 0, 360)
	end)

	local leftValue = Computed(function()
		if props.Direction == "Right" then
			return math.min(value:get() - 180, 0)
		else
			return math.min(-value:get(), -180)
		end
	end)

	local rightValue = Computed(function()
		if props.Direction == "Right" then
			return math.max(value:get() - 180, 0)
		else
			return math.max(-value:get(), -180)
		end
	end)

	return New("Frame")({
		Name = props.Name or "Dial",
		Size = props.Size or fromScale(1, 1),
		Position = props.Position,
		BackgroundTransparency = 1,

		[Children] = {
			New("Frame")({
				Name = "DialLeft",
				Size = fromScale(0.5, 1),
				BackgroundTransparency = 1,
				ClipsDescendants = true,

				[Children] = New("ImageLabel")({
					Name = "InnerDial",
					Size = fromScale(2, 1),
					BackgroundTransparency = 1,
					Image = props.DialImage,

					[Children] = New("UIGradient")({
						Color = color,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.5, 0),
							NumberSequenceKeypoint.new(0.501, 1),
							NumberSequenceKeypoint.new(1, 1),
						}),
						Rotation = leftValue,
					}),
				}),
			}),
			New("Frame")({
				Name = "DialRight",
				Size = fromScale(0.5, 1),
				Position = fromScale(0.5, 0),
				BackgroundTransparency = 1,
				ClipsDescendants = true,

				[Children] = New("ImageLabel")({
					Name = "InnerDial",
					Size = fromScale(2, 1),
					Position = fromScale(-1, 0),
					BackgroundTransparency = 1,
					Image = props.DialImage,

					[Children] = New("UIGradient")({
						Color = color,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.499, 0),
							NumberSequenceKeypoint.new(0.5, 1),
							NumberSequenceKeypoint.new(1, 1),
						}),
						Rotation = rightValue,
					}),
				}),
			}),
		},
	})
end
