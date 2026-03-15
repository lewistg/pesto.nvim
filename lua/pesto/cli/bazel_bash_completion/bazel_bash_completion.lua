---Completes the bazel sub command using the bash completion. Note that this
---lcass is tighltly coupled with tools/complete-bazel.sh.
---@class pesto.BazelBashCompletion: pesto.SubcommandCompletion
---@field private _bazel_bash_completion_client pesto.BazelBashCompletionClient
---@field private _bash_completion_server_channel number|nil
---@field private _enabled boolean
---@field private _bash_completion_server_script_path string
---@field private _settings pesto.Settings
local BazelBashCompletion = {}
BazelBashCompletion.__index = BazelBashCompletion

---@private
BazelBashCompletion.MIN_WAIT = 2 * 1000
---@private
BazelBashCompletion.MAX_WAIT = 30 * 1000

---@param bazel_bash_completion_client pesto.BazelBashCompletionClient
---@param settings pesto.Settings
---@return pesto.BazelBashCompletion
function BazelBashCompletion:new(bazel_bash_completion_client, settings)
	local o = setmetatable({}, BazelBashCompletion)

	o._bazel_bash_completion_client = bazel_bash_completion_client
	o._settings = settings

	o._enabled = true

	return o
end

---@param opts pesto.SubcommandCompleteOpts
---@return string[]
function BazelBashCompletion:complete(opts)
	local logger = require("pesto.logger")
	if not self._enabled then
		logger.info("bash completion not enabled")
		return {}
	end

	local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")

	---@type pesto.BashCommandToken[]
	local bash_command_tokens = bash_command_util.tokenize(opts.subcommand_line)

	local bazel_bash_completion_request = require("pesto.cli.bazel_bash_completion.bazel_bash_completion_request")
	---@type string[]
	local request = bazel_bash_completion_request.get_bazel_bash_completion_request(opts, bash_command_tokens)

	local completion_settings = self._settings:get_cli_completion_settings()
	local timeout = math.min(
		math.max(completion_settings.bash_timeout or 0, BazelBashCompletion.MIN_WAIT),
		BazelBashCompletion.MAX_WAIT
	)

	local status, result =
		pcall(self._bazel_bash_completion_client.get_completions, self._bazel_bash_completion_client, {
			request = request,
			timeout = timeout,
		})

	local BazelBashCompletionClient = require("pesto.cli.bazel_bash_completion.bazel_bash_completion_client")

	if status then
		---@type string[]
		local bash_completions = result
		local nvim_completions = bash_command_util.bash_completions_to_nvim_completions(
			bash_command_tokens,
			opts.cursor_pos,
			bash_completions or {}
		)
		return nvim_completions
	elseif result == BazelBashCompletionClient.TIMEOUT_ERROR then
		logger.warn(string.format("bash completion request timed out"))
		vim.notify("Pesto: bash completion request timed out", vim.log.levels.WARN)
		return {}
	else
		error(result)
	end
end

return BazelBashCompletion
