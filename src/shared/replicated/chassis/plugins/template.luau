local types = require(script.Parent.Parent.types)

export type Config = {}

type TemplateProto = { state: types.State }

local Template = {}
Template.__index = Template
type Template = typeof(Template) & TemplateProto

function Template.new(state: types.State): Template
	return setmetatable({ state = state } :: Template, Template)
end
function Template.step(_self: Template, _state: types.State, _dt: number) end
function Template.Destroy(_self: Template) end

return Template
