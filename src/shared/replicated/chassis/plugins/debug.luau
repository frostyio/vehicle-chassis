local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage:WaitForChild("packages")

local Iris = require(packages:WaitForChild("iris")).Init()
Iris.TemplateConfig.colorDark.WindowBgTransparency = 0.5
Iris.UpdateGlobalConfig(Iris.TemplateConfig.sizeClear)
Iris.UpdateGlobalConfig(Iris.TemplateConfig.colorDark)

local State = Iris.State

local types = require(script.Parent.Parent.types)
local util = require(script.Parent.Parent.util)

Iris.WidgetConstructor("RichText", {
	hasState = false,
	hasChildren = false,
	Args = {
		["Text"] = 1,
	},
	Events = {},
	Generate = function(thisWidget)
		local Text = Instance.new("TextLabel")
		Text.Size = UDim2.fromOffset(0, 0)
		Text.BackgroundTransparency = 1
		Text.BorderSizePixel = 0
		Text.ZIndex = thisWidget.ZIndex
		Text.LayoutOrder = thisWidget.ZIndex
		Text.AutomaticSize = Enum.AutomaticSize.XY

		Text.FontFace = Font.fromEnum(Iris._config.TextFont)
		Text.TextSize = Iris._config.TextSize
		Text.TextColor3 = Iris._config.TextColor
		Text.TextTransparency = Iris._config.TextTransparency
		Text.TextXAlignment = Enum.TextXAlignment.Left

		Text.AutoLocalize = false
		Text.RichText = true
		local PxPadding = Vector2.new(0, 2)
		local UIPaddingInstance: UIPadding = Instance.new("UIPadding")
		UIPaddingInstance.PaddingLeft = UDim.new(0, PxPadding.X)
		UIPaddingInstance.PaddingRight = UDim.new(0, PxPadding.X)
		UIPaddingInstance.PaddingTop = UDim.new(0, PxPadding.Y)
		UIPaddingInstance.PaddingBottom = UDim.new(0, PxPadding.Y)
		UIPaddingInstance.Parent = Text

		return Text
	end,
	Update = function(thisWidget)
		local Text = thisWidget.Instance
		if thisWidget.arguments.Text == nil then
			error("Iris.Text Text Argument is required", 5)
		end
		Text.Text = thisWidget.arguments.Text
	end,
	Discard = function(thisWidget)
		thisWidget.Instance:Destroy()
	end,
})

Iris.Text = function(...): any
	return Iris._Insert("RichText", ...)
end

local function color3ToRichText(color: Color3, input: any): string
	return `<font color="#{color:ToHex()}">{tostring(input)}</font>`
end

local function prettyToString(value: any): string
	local type = typeof(value)
	if type == "boolean" then
		return color3ToRichText(value and util.colors.primary or util.colors.secondary, value)
	elseif type == "number" then
		return ("%.2f"):format(value)
	end

	return tostring(value)
end

local function showTableRecursive(name: string, data: { [any]: any })
	Iris.Tree({ name }, { isUncollapsed = State(true) })
	Iris.Table({ 2 })
	for input, value in data do
		if type(value) == "table" then
			Iris.End()
			showTableRecursive(input, value)
			Iris.Table({ 2 })
		else
			Iris.Text({ prettyToString(input) })
			Iris.NextColumn()
			Iris.Text({ prettyToString(value) })
			Iris.NextColumn()
		end
	end
	Iris.End()
	Iris.End()
end

-----

export type Config = {}

type DebugProto = { state: types.State }

local Debug = {}
Debug.__index = Debug
type Debug = typeof(Debug) & DebugProto

function Debug.new(state: types.State): Debug
	return setmetatable({ state = state } :: Debug, Debug)
end
function Debug.step(_self: Debug, state: types.State, _dt: number)
	local windowSize = State(Vector2.new(320, 450))
	local windowPosition = State(Vector2.new(50, 50))
	Iris.Window({ "Debug" }, { size = windowSize, position = windowPosition })

	Iris.Text(`Speed: {prettyToString(state.speed)}mph`)
	Iris.Text(`isOccupied: {prettyToString(state.isOccupied)}`)
	showTableRecursive("Input", state.input)
	showTableRecursive("Engine", state.engine)
	showTableRecursive("DriveTrain", state.drivetrain)

	Iris.End()
end
function Debug.Destroy(_self: Debug) end

return Debug
