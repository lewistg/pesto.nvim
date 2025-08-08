local table_util = require("pesto.util.table_util")

---@class pesto.BuildEventJsonLoader
local BuildEventJsonLoader = {}
BuildEventJsonLoader.__index = BuildEventJsonLoader

---@return pesto.BuildEventJsonLoader
function BuildEventJsonLoader:new()
	local o = setmetatable({}, BuildEventJsonLoader)
	return o
end

---@param bep_json_file string|Path
---@return table[]
function BuildEventJsonLoader:load(bep_json_file)
	local lines = vim.fn.readfile(tostring(bep_json_file))
	return table_util.map(lines, function(line)
		local raw_event = vim.json.decode(line)
		raw_event = self:_normalize_keys(raw_event)
		return raw_event
	end)
end

local function camel_case_to_snake_case(camel_case_key)
	return string.gsub(camel_case_key, "(%l)(%u)", function(lower_case, upper_case)
		return lower_case .. "_" .. string.lower(upper_case)
	end)
end

function BuildEventJsonLoader:_normalize_keys(dict)
	if type(dict) ~= "table" then
		return dict
	end
	local ret = {}
	for key, value in pairs(dict) do
		local normalized_key
		if type(key) == "string" then
			normalized_key = camel_case_to_snake_case(key)
		else
			normalized_key = key
		end
		ret[normalized_key] = self:_normalize_keys(value)
	end
	return ret
end

return BuildEventJsonLoader
