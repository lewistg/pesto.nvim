---@class pesto.BazelBashCompletionClientHealthCheckResult
---@field completion_script string
---@field loads boolean

--- Sends and receives bash command line completion requests to the
--- tools/pesto-bash-helpers/complete-bazel.sh helper script.
---@class pesto.BazelBashCompletionRequestOptions
---@field request string[]
---@field on_response fun(words: string[])
---@field on_error fun(error: string)
---@field timeout number

---@class pesto.BazelBashCompletionClient
---@field private _settings pesto.Settings
---@field private _bash_completion_server_system_object vim.SystemObj|nil
---@field private _current_response_line_handler fun(line: string)|nil
local BazelBashCompletionClient = {}
BazelBashCompletionClient.__index = BazelBashCompletionClient

BazelBashCompletionClient.TIMEOUT_ERROR = {
	message = "bash completion timed out",
}

---@param settings pesto.Settings
---@return pesto.BazelBashCompletionClient
function BazelBashCompletionClient:new(settings)
	local o = setmetatable({}, BazelBashCompletionClient)

	o._settings = settings
	o._bash_completion_server_system_object = nil
	o._current_response_line_handler = nil

	---@type string
	local script_path = "*/pesto-bash-helpers/complete-bazel.sh"
	self._bash_completion_server_script_path = vim.api.nvim_get_runtime_file(script_path, false)[1]
	if not self._bash_completion_server_script_path then
		error("failed to find bazel bash completion script")
	end

	return o
end

function BazelBashCompletionClient:reset()
	if self._bash_completion_server_system_object ~= nil then
		self._bash_completion_server_system_object:write("reset\n")
	end
end

---@param options pesto.BazelBashCompletionRequestOptions
---@return string[] words
function BazelBashCompletionClient:get_completions(options)
	if self:_is_request_in_progress() then
		-- We should only be completing one request at a time. This is because
		-- completions are ultimately tied to the Neovim CLI, and you shouldn't
		-- be able to be in the CLI in more than one window at a time anyways.
		error("request already in progress")
	end

	local logger = require("pesto.logger")

	if self._bash_completion_server_system_object == nil then
		self._bash_completion_server_system_object = self:_start_completion_server()
		logger.info(
			string.format("Started bash completion server. pid=%d", self._bash_completion_server_system_object.pid)
		)
	end

	---@type string[]|nil
	local words = nil
	---@type any
	local err = nil

	self._current_response_line_handler = self:_get_new_response_handler(function(_words)
		words = _words
		self._current_response_line_handler = nil
	end, function(_err)
		err = _err
		self._current_response_line_handler = nil
	end)

	local request_lines = table.concat(options.request, "\\n")

	-- Submit the completion request
	logger.trace(function()
		return "request lines: " .. request_lines
	end)

	self._bash_completion_server_system_object:write(options.request)

	local interval = 64
	vim.wait(options.timeout, function()
		return words ~= nil or err ~= nil
	end, interval)

	if words ~= nil then
		return words
	end

	if err == nil then
		err = BazelBashCompletionClient.TIMEOUT_ERROR
	end

	if self._bash_completion_server_system_object ~= nil then
		logger.trace(
			"killing completion server after timeout pid: " .. tostring(self._bash_completion_server_system_object.pid)
		)
		self._bash_completion_server_system_object:kill(9)
		self._bash_completion_server_system_object = nil
	end

	error(err)
end

---@return vim.SystemObj
function BazelBashCompletionClient:_start_completion_server()
	local logger = require("pesto.logger")

	logger.info("starting bash completion server")

	local cli_options = self._settings:get_cli_completion_settings()

	assert(cli_options.bash_completion_script ~= nil, "bash_completion_script is not defined")

	---@type string[]
	local server_command = {
		self._bash_completion_server_script_path,
		"serve",
		cli_options.bash_completion_script,
	}

	local job_util = require("pesto.util.job_util")
	return vim.system(server_command, {
		text = true,
		stdin = true,
		clear_env = true,
		stdout = job_util.system_get_on_line_completed(function(err, line)
			if err then
				logger.error("bash completion server error: " .. err)
				return
			end
			logger.trace(function()
				return string.format('received line from completion server: "%s"', line)
			end)
			if self._current_response_line_handler and line ~= nil then
				self._current_response_line_handler(line)
			end
		end),
		stderr = function(_, data)
			if data == nil then
				return
			end
			logger.error("stderr output from completion script: " .. data)
		end,
	}, function(system_completed)
		vim.schedule(function()
			logger.info(string.format("bash completion server exited with code %d", system_completed.code))
		end)
		self._current_response_line_handler = nil
	end)
end

---@param on_response fun(words: string[])
---@param on_error fun(error: string)
---@return fun(line: string)
function BazelBashCompletionClient:_get_new_response_handler(on_response, on_error)
	--- The number lines to expect from the completion script
	---@type number|nil
	local compreply_len = nil

	---@type string[]
	local compreply_words = {}

	---@type fun(line: string)
	local on_line = function(line)
		if compreply_len == nil then
			local _, _, raw_len = line:find("^compreply_len:(%d+)$")
			compreply_len = tonumber(raw_len)
			if compreply_len == nil then
				on_error(string.format('failed to parse "%s" as compreply_len', line))
				-- cancel the request
			end
		else
			local _, _, word = line:find("^compreply:(.*)$")
			if word == nil then
				on_error(string.format('failed to parse "%s" as compreply', line))
				-- cancel the request
			end
			table.insert(compreply_words, word)
		end
		if #compreply_words == compreply_len then
			on_response(compreply_words)
		end
	end

	return on_line
end

function BazelBashCompletionClient:_is_request_in_progress()
	return self._current_response_line_handler ~= nil
end

---@return pesto.BazelBashCompletionClientHealthCheckResult
function BazelBashCompletionClient:check_health()
	local cli_options = self._settings:get_cli_completion_settings()

	---@type string[]
	local server_command = {
		self._bash_completion_server_script_path,
		"check-health",
		cli_options.bash_completion_script,
	}

	local system_completed = vim.system(server_command, { text = true, clear_env = true }):wait()
	local loads = system_completed.code == 0

	if not loads then
		local logger = require("pesto.logger")
		if system_completed.stderr == nil or system_completed.stderr == "" then
			logger.error(
				string.format(
					"Completion script did not load and did not emit any stderr output. script: %s",
					self._bash_completion_server_script_path
				)
			)
		else
			logger.error(
				string.format(
					"Completion script failed to load. script: %s, stderr: %s",
					self._bash_completion_server_script_path,
					system_completed.stderr
				)
			)
		end
	end

	return {
		completion_script = cli_options.bash_completion_script,
		loads = loads,
	}
end

return BazelBashCompletionClient
