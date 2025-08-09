local table_util = require("pesto.util.table_util")

---@class pesto.RawSettings
---@field bazel_command string Name of bazel binary
---@field bazel_runner fun() Runs the bazel command
---@field log_level string Logger level

local SETTINGS_KEY = "pesto"

---@param opts RunBazelOpts
local function default_bazel_runner(opts)
	require("pesto.runner.terminal").run(opts)
end

---@type pesto.RawSettings
local default_raw_settings = {
	bazel_command = "bazel",
	bazel_runner = default_bazel_runner,
	log_level = "info",
	use_bep_integration = false,
}

---@class pesto.Settings
local Settings = {}
Settings.__index = Settings

---@return pesto.Settings
function Settings:new()
	local o = setmetatable({}, Settings)
	return o
end

---@generic T
---@private
---@param key string
---@return `T`
function Settings:_resolve_setting(key)
	local buf_id = vim.api.nvim_get_current_buf()
	return table_util.dig(vim.b, { buf_id, SETTINGS_KEY, key })
		or table_util.dig(vim.g, { SETTINGS_KEY, key })
		or default_raw_settings[key]
end

---@return RunBazelFn
function Settings:get_bazel_runner()
	return self:_resolve_setting("bazel_runner")
end

return Settings
