local M = {}

local MAX_TARGET_CACHE = 100
local build_file_target_cache = {}

local NAME_PATTERN = '^%s*name%s=%s"([^"]*)"%s*,?$'

--- This method extracts the name attribute value in apparent rule calls such as this:
--- ```
--- java_library(
---    name = "LcovMergerTestUtils",
---    srcs = [ ... ],
---    deps = [ ... ],
--- )
--- ```
--- In this case this function returns "LcovMergerTestUtils"
---@param build_file Path
---@return string[]
function M.guess_target_names(build_file)
	local status, lines = pcall(vim.fn.readfile, tostring(build_file))
	if not status then
		return {}
	end
	---@type string[]
	local names = {}
	for _, line in ipairs(lines) do
		local _, _, name = string.find(line, NAME_PATTERN)
		if name then
			table.insert(names, name)
		end
	end
	return names
end

return M
