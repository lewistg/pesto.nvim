local M = {}

local terminal_runner = require("pesto.runner.terminal")

---@class Settings
---@field bazel_command string Name of bazel binary
---@field bazel_runner fun() Runs the bazel command
---@field log_level string Logger level

---@type Settings
M.settings = {
	bazel_command = "bazel",
	bazel_runner = terminal_runner.run,
	log_level = "info",
}

---@param settings_overrides Settings
---@return Settings
function M.setup(settings_overrides)
	M.settings = vim.tbl_deep_extend("force", M.settings, settings_overrides)
end

return M
