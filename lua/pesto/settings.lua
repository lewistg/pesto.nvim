local table_util = require("pesto.util.table_util")

--- Maps a rule's actions' mnemonics to either a errorformat string or compiler plugin (which should in turn define a errorformat)
---@class pesto.ActionErrorformat
---@field action_mnemonic string A lua string pattern
---@field compiler string|nil The compiler plugin that should define the errorformat to use for parsing the action's stderr output
---@field errorformat string|nil Errorformat string (:help errorformat)

---@class pesto.RuleActionErrorformats
---@field rule_kind string A lua string pattern
---@field action_errorformats pesto.ActionErrorformat[]

---@class pesto.RawSettings
---@field bazel_command string Name of bazel binary
---@field bazel_runner RunBazelFn Runs the bazel command
---@field log_level string Logger level
---@field enable_bep_integration boolean
---@field auto_open_build_term boolean
---@field errorformats pesto.RuleActionErrorformats[] Maps a (rule kind pattern, action mnemonic pattern)
--- pair to an errorformat string or compiler plugin name. Note that
--- the pesto.RuleActionErrorformats.rule_kind field is interpreted as a lua
--- string pattern.
--See pesto.RuleActionErrorformats and pesto.ActionErrorformat.

---@type pesto.RawSettings
local default_raw_settings = {
	bazel_command = "bazel",
	bazel_runner = function(opts)
		require("pesto.components").default_runner(opts)
	end,
	log_level = "info",
	enable_bep_integration = false,
	auto_open_build_term = true,
	errorformats = {
		{
			rule_kind = "java_*",
			action_errorformats = {
				{
					action_mnemonic = "Javac",
					compiler = "javac",
				},
			},
		},
		{
			rule_kind = "cc_*",
			action_errorformats = {
				{
					action_mnemonic = "CppCompile",
					compiler = "gcc",
				},
			},
		},
	},
}

---@class pesto.Settings
local Settings = {}
Settings.__index = Settings

Settings.SETTINGS_KEY = "pesto"

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
	return table_util.dig(vim.b, { buf_id, Settings.SETTINGS_KEY, key })
		or table_util.dig(vim.g, { Settings.SETTINGS_KEY, key })
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

function Settings:get_auto_open_build_term()
	return self:_resolve_setting("auto_open_build_term")
end

---@return pesto.RuleActionErrorformats
function Settings:get_errorformats(rule_kind, action_mnemonic)
	return self:_resolve_setting("errorformats")
end

return Settings
