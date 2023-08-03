local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage:WaitForChild("packages")

local Fusion = require(packages._Index["elttob_fusion@0.2.0"]["fusion"])
local New = Fusion.New

local fromScale = UDim2.fromScale

--

export type Props = {
	Text: string,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,

	Color: Color3?,
	Font: Enum.Font?,
}

return function(props: Props)
	return New("TextLabel")({
		Name = "Label",
		Text = props.Text,
		FontFace = props.Font or Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold),
		TextScaled = true,
		TextColor3 = props.Color or Color3.fromRGB(255, 255, 255),
		Position = props.Position,
		Size = props.Size or fromScale(1, 1),
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	})
end
