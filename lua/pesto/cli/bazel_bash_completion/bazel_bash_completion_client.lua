--- Sends and receives bash command line completion requests to the
--- tools/pesto-bash-helpers/complete-bazel.sh helper script.
---@class pesto.BazelBashCompletionRequestOptions
---@field request string[]
---@field on_response fun(words: string[])
---@field on_error fun(error: string)
---@field timeout number

---@class pesto.BazelBashCompletionClient
---@field private _bash_completion_server_channel number|nil
---@field private _current_response_line_handler fun(line: string)|nil

local BazelBashCompletionClient = {}
BazelBashCompletionClient.__index = BazelBashCompletionClient

BazelBashCompletionClient.TIMEOUT_ERROR = {
	message = "bash completion timed out",
}

---@return pesto.BazelBashCompletionClient
function BazelBashCompletionClient:new()
	local o = setmetatable({}, BazelBashCompletionClient)

	o._bash_completion_server_channel = nil
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
	if self._bash_completion_server_channel ~= nil then
		vim.fn.chansend(self._bash_completion_server_channel, { "reset" })
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

	if self._bash_completion_server_channel == nil then
		self._bash_completion_server_channel = self:_start_completion_server()
		logger.info(string.format("Started bash completion server. channel=%d", self._bash_completion_server_channel))
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

	-- Submit the completion request
	logger.trace(function()
		local lines = table.concat(options.request, "\\n")
		return "request lines: " .. lines
	end)

	vim.fn.chansend(self._bash_completion_server_channel, options.request)

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

	vim.fn.jobstop(self._bash_completion_server_channel)
	self._bash_completion_server_channel = nil

	error(err)
end

---@return number
function BazelBashCompletionClient:_start_completion_server()
	local logger = require("pesto.logger")

	logger.info("starting bash completion server")

	---@type string|nil
	local partial_line = ""

	---@param line string
	local function on_stdout_line(line)
		logger.trace(function()
			return string.format('received line from completion server: "%s"', line)
		end)
		if self._current_response_line_handler then
			self._current_response_line_handler(line)
		end
	end

	return vim.fn.jobstart({
		self._bash_completion_server_script_path,
	}, {
		on_stdout = function(chan_id, chunks)
			if not self:_is_request_in_progress() then
				logger.error("received unprompted output from bash completion server")
				return
			end
			if #chunks > 1 then
				on_stdout_line(partial_line .. chunks[1])
				partial_line = chunks[#chunks]
			end
			for i = 2, #chunks - 1 do
				on_stdout_line(chunks[i])
			end
		end,
		on_stderr = function(chan_id, chunks) end,
		on_exit = function(job_id, code)
			logger.trace(string.format("bash completion server exited with code %d", code))
		end,
	})
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
				on_error("failed to parse response")
				-- cancel the request
			end
		else
			local _, _, word = line:find("^compreply:(.*)$")
			if word == nil then
				on_error("failed to parse response")
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

return BazelBashCompletionClient
