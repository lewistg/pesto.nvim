--- Maps a rule's actions' mnemonics to either a errorformat string or compiler plugin (which should in turn define a errorformat)
---@class pesto.ActionErrorformat
---@field action_mnemonic string A lua string pattern
---@field compiler string|nil The compiler plugin that should define the errorformat to use for parsing the action's stderr output
---@field errorformat string|nil Errorformat string (:help errorformat)

---@class pesto.RuleActionErrorformats
---@field rule_kind string A lua string pattern
---@field action_errorformats pesto.ActionErrorformat[]

---@alias pesto.CliCompletionMode
---| "lua"
---| "bash"
---| "automatic"

---@class pesto.CliCompletionSettings
---@field mode pesto.CliCompletionMode
---@field bash_timeout number|nil Number of milliseconds to wait for bazel's bash completion script to reply
---
--- Absolute path to the bash completion script. If the setting is not defined,
--- then Pesto falls back to searching for the completion scripts defined in
--- pesto.InternalSettings.DEFAULT_BASH_COMPLETION_SCRIPTS.
---@field bash_completion_script string|nil

---@class pesto.Settings
---@field bazel_command string Name of bazel binary
---@field bazel_runner RunBazelFn Runs the bazel command
---@field log_level string Logger level
---@field enable_bep_integration boolean
---@field auto_open_build_term boolean
---@field errorformats pesto.RuleActionErrorformats[] Maps a (rule kind pattern, action mnemonic pattern)
--- pair to an errorformat string or compiler plugin name. Note that
--- the pesto.RuleActionErrorformats.rule_kind field is interpreted as a lua
--- string pattern.
--- See pesto.RuleActionErrorformats and pesto.ActionErrorformat.
---@field bytestream_client "pesto-python-remote-apis-helpers"|pesto.ByteStreamClient|nil
---@field cli_completion pesto.CliCompletionSettings

---@type pesto.Settings
local default_raw_settings = {
	bazel_command = "bazel",
	bazel_runner = function(opts)
		require("pesto.components").default_runner(opts)
	end,
	log_level = "info",
	enable_bep_integration = true,
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
	bytestream_client = nil,
	cli_completion = {
		mode = "automatic",
		bash_timeout = 15000,
		bash_completion_script = nil,
	},
}

--- Wraps the settings and resolves buffer-local overrides
---@class pesto.InternalSettings
local InternalSettings = {}
InternalSettings.__index = InternalSettings

InternalSettings.SETTINGS_KEY = "pesto"

---@type string[]
InternalSettings.DEFAULT_BASH_COMPLETION_SCRIPTS = {
	vim.fs.joinpath("/etc/bash_completion.d", "bazel"),
	vim.fs.joinpath("/etc/bash_completion.d", "bazel-completion"),
}

---@return pesto.InternalSettings
function InternalSettings:new()
	local o = setmetatable({}, InternalSettings)
	return o
end

---@generic T
---@private
---@param key string
---@return `T`
function InternalSettings:_resolve_setting(key)
	local buf_id = vim.api.nvim_get_current_buf()
	return vim.tbl_deep_extend(
		"keep",
		vim.tbl_get(vim.b, buf_id, InternalSettings.SETTINGS_KEY) or {},
		vim.tbl_get(vim.g, InternalSettings.SETTINGS_KEY) or {},
		default_raw_settings
	)[key]
end

---@return RunBazelFn
function InternalSettings:get_bazel_runner()
	return self:_resolve_setting("bazel_runner")
end

---Indicates whether or not the bep integration is enabled. When enabled, the
---`--build_event_json_file=<string>` bazel flag is automatically injected into
---the bazel command. The argument to `--build_event_json_file` will be a well
---known file that can be loaded post-build.
---@return boolean
function InternalSettings:get_enable_bep_integration()
	return self:_resolve_setting("enable_bep_integration")
end

function InternalSettings:get_auto_open_build_term()
	return self:_resolve_setting("auto_open_build_term")
end

---@return pesto.RuleActionErrorformats
function InternalSettings:get_errorformats(rule_kind, action_mnemonic)
	return self:_resolve_setting("errorformats")
end

---@return pesto.CliCompletionSettings
function InternalSettings:get_cli_completion_settings()
	return self:_resolve_setting("cli_completion")
end

return InternalSettings
