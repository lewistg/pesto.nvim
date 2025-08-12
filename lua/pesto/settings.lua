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
	enable_bep_integration = false,
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

---@return string Directory where temp files may be written
function Settings:get_temp_dir()
	return vim.fn.stdpath("run") .. "/pesto.nvim"
end

---@return string Temporary directory where build event files are written
function Settings:get_bep_temp_dir()
	return self:get_temp_dir() .. "/bep"
end

---Indicates whether or not the bep integration is enabled. When enabled, the
---`--build_event_json_file=<string>` bazel flag is automatically injected into
---the bazel command. The argument to `--build_event_json_file` will be a well
---known file that can be loaded post-build.
---@return boolean
function Settings:get_enable_bep_integration()
	return self:_resolve_setting("enable_bep_integration")
end

return Settings
