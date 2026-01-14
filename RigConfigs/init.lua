--!strict

local RigConfigType = require(script.RigConfigType)
local RigConfigs = {} :: {[string]: RigConfigType.RigConfig}

for _, v in script:GetChildren() do
	RigConfigs[v.Name] = require(v) :: any
end

return RigConfigs
