--!strict
--!optimize 2

local InstanceQuery = {}

type QueryPath = {string}

function InstanceQuery:GetAsync(parent: Instance, query_path: QueryPath): any
	local query_result = parent
	for _, path in query_path do
		query_result = query_result:WaitForChild(path)
	end
	return query_result
end

function InstanceQuery:Get(parent: Instance, query_path: QueryPath): any?
	local query_result = parent
	for _, path in query_path do
		query_result = (query_result :: any):FindFirstChild(path)
		if query_result == nil then return nil end
	end
	return query_result
end

return InstanceQuery