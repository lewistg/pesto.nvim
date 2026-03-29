local M = {}

---@type string
local BUILD_EVENT_JSON_FILE_OPTION = "--build_event_json_file"

---@param bazel_command string[]
---@param settings pesto.Settings
function M.inject_bep_option(bazel_command, settings)
	local option_name = BUILD_EVENT_JSON_FILE_OPTION
	for _, arg in ipairs(bazel_command) do
		if vim.startswith(arg, option_name) then
			-- Do not override this option if it's already defined by the user
			return
		end
	end
	local temp_dirs = require("pesto.util.temp_dirs")
	local bep_file = string.format("%s/%d_bep.json", temp_dirs.BEP_DIR, vim.fn.rand())
	table.insert(bazel_command, 3, option_name)
	table.insert(bazel_command, 4, bep_file)
end

---@param bazel_command string[]
---@return string|nil
function M.extract_bep_option(bazel_command)
	---@type number|nil
	for i, value in ipairs(bazel_command) do
		if value == BUILD_EVENT_JSON_FILE_OPTION then
			return bazel_command[i + 1]
		end
	end
end

return M
