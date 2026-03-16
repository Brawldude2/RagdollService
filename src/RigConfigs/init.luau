--!strict

local Types = require(script.Parent.Types)
local RigConfigs = {} :: {[string]: Types.RigConfig}

for _, v in script:GetChildren() do
	RigConfigs[v.Name] = require(v) :: any
end

return RigConfigs
