local Chassis = require(script.Parent.Parent.client)

export type Config = {}

type TemplateProto = {
	chassis: Chassis.Chassis,
	config: Config,
	state: {},
}

local Template = {}
Template.__index = Template
type Template = typeof(Template) & TemplateProto

function Template.new(chassis: Chassis.Chassis, config: Config): Template
	return setmetatable({ chassis = chassis, config = config, state = {} } :: Template, Template)
end
function Template.step(_self: Template, _dt: number) end
function Template.Destroy(_self: Template) end

return Template
