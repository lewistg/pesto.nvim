---@class pesto.GetByteStreamsOptions
---@field byte_stream_service_uri string
---@field byte_stream_uris string[]
---@field request_headers string[]|nil
---@field on_download fun(lines: string[], uri: string)
---@field on_done fun(failed_uris: string[])

--- See: https://github.com/googleapis/googleapis/blob/master/google/bytestream/bytestream.proto
---@class pesto.google.bytestream.ReadResponse
---@field data string
--
---@class pesto.ByteStreamLine
---@field uri string
---@field read_response pesto.google.bytestream.ReadResponse|nil

--- The default byte stream client
---@class pesto.ByteStreamClient
---@field private _remote_apis_helpers_command_builder pesto.RemoteApisHelpersCommandBuilder
---@field private _pending_read_job_ids number[]
---@field private _concurrent_downloads number
---@field private _remote_apis_helpers_installed boolean|nil
local ByteStreamClient = {}
ByteStreamClient.__index = ByteStreamClient

ByteStreamClient._CONCURRENT_DOWNLOADS = 3
ByteStreamClient._LINE_PATTERN = "^([^\t]+)\t(.*)$"

---@param remote_apis_helpers_command_builder pesto.RemoteApisHelpersCommandBuilder
function ByteStreamClient:new(remote_apis_helpers_command_builder)
	local o = setmetatable({}, ByteStreamClient)
	o._remote_apis_helpers_command_builder = remote_apis_helpers_command_builder
	return o
end

---@return boolean
function ByteStreamClient:are_remote_apis_helpers_installed()
	if not self._remote_apis_helpers_installed then
		local logger = require("pesto.logger")
		logger.info("Checking Bazel Remote APIs helpers installation")
		local is_installed_command = self._remote_apis_helpers_command_builder:get_is_installed_command()
		local result = vim.system(is_installed_command, {
			clear_env = true,
		}):wait()
		logger.info(
			string.format("is_installed_command='%s', result=%d", table.concat(is_installed_command, " "), result.code)
		)
		local is_installed = result.code == 0
		self._remote_apis_helpers_installed = is_installed
	end
	return self._remote_apis_helpers_installed
end

---@param opts pesto.GetByteStreamsOptions
---@return number Job ID for downloads
function ByteStreamClient:get_byte_streams(opts)
	---@type { [string]: pesto.google.bytestream.ReadResponse[] }
	local byte_stream_read_responses = {}

	local table_util = require("pesto.util.table_util")

	---@type {[string]: boolean}
	local pending_uris_set = table_util.make_set(opts.byte_stream_uris)

	---@type thread|nil
	local enqueue_requests = nil

	---@type string[]
	local command = self._remote_apis_helpers_command_builder:get_fetch_byte_streams_command({
		address = opts.byte_stream_service_uri,
		byte_stream_uris = opts.byte_stream_uris,
		headers = opts.request_headers,
	})
	---@type string[]
	local line_chunks = {}
	local job_id = vim.fn.jobstart(command, {
		on_stdout = function(_, chunks)
			local logger = require("pesto.logger")
			logger.trace(function()
				return string.format("received chunks: %s", vim.inspect(chunks))
			end)

			if #chunks == 1 and chunks[1] == "" and #line_chunks == 0 then
				-- We received an EOF that doesn't terminate any line
				return
			end

			-- If there's more than one chunk, the first chunk will complete
			-- the current line. Afterwards, all chunks before the last chunk
			-- will represent complete lines.
			local i = 1
			while i < #chunks do
				table.insert(line_chunks, chunks[i])
				local uri, read_response = self:_parse_line(line_chunks)
				table.insert(table_util.get_or_set(byte_stream_read_responses, uri, {}), read_response)
				line_chunks = {}
				i = i + 1
			end

			-- The last chunk may represent a partial line. Any empty string,
			-- however, represents a line terminator for the penultimate chunk;
			-- we ignore the empty string terminal.
			if #chunks > 1 and chunks[#chunks] ~= "" then
				table.insert(line_chunks, chunks[i])
			end

			local finished_stream_uris = {}
			for uri_key, responses in pairs(byte_stream_read_responses) do
				if #responses > 0 then
					local data = vim.tbl_get(responses[#responses], "data") or ""
					if data == "" then
						logger.trace(function()
							return string.format("finished downloading byte stream: %s", uri_key)
						end)
						table.insert(finished_stream_uris, uri_key)
					end
				end
			end

			vim.schedule(function()
				for _, uri_key in ipairs(finished_stream_uris) do
					local str = self:_get_compelete_lines(byte_stream_read_responses[uri_key])
					opts.on_download(str, uri_key)
					byte_stream_read_responses[uri_key] = nil
					pending_uris_set[uri_key] = nil
				end
				if enqueue_requests then
					coroutine.resume(enqueue_requests)
				end
			end)
		end,
		on_exit = function(_, exit_code)
			local logger = require("pesto.logger")
			if exit_code ~= 0 then
				local command_str = table.concat(command, " ")
				logger.error(
					string.format('download command failed. exit_code=%d command="%s"', exit_code, command_str)
				)
			else
				logger.error(string.format("successfully finished fetching byte streams", exit_code))
			end

			---@type string[]
			local failed_uris = {}
			for uri, _ in pairs(pending_uris_set) do
				table.insert(failed_uris, uri)
			end
			opts.on_done(failed_uris)
		end,
	})

	---@type string[]
	local byte_stream_uri_buffer = { unpack(opts.byte_stream_uris) }
	---@type number
	local next_uri_index = 1
	enqueue_requests = coroutine.create(function()
		local logger = require("pesto.logger")
		logger.debug(string.format("enqueing byte stream URIs"))

		while next_uri_index <= #byte_stream_uri_buffer do
			---@type number
			local num_active_downloads = #vim.tbl_keys(byte_stream_read_responses)
			if num_active_downloads >= ByteStreamClient._CONCURRENT_DOWNLOADS then
				coroutine.yield()
			end

			local next_uri = byte_stream_uri_buffer[next_uri_index]
			next_uri_index = next_uri_index + 1

			byte_stream_read_responses[next_uri] = {}

			logger.trace(string.format("writing byte stream URI to stdin. uri=%s", next_uri))
			vim.fn.chansend(job_id, next_uri .. "\n")
		end
		-- vim.fn.chansend(job_id, { "" })
		vim.fn.chansend(job_id, { "" })
		vim.fn.chanclose(job_id, "stdin")
		logger.debug("wrote EOF to stdin")
	end)

	if enqueue_requests then
		coroutine.resume(enqueue_requests)
	end

	return job_id
end

---@param job_id number
function ByteStreamClient:abort(job_id) end

---@param read_responses pesto.google.bytestream.ReadResponse[]
---@return string[]
function ByteStreamClient:_get_compelete_lines(read_responses)
	---@type string[]
	local str_parts = {}
	for _, read_response in ipairs(read_responses) do
		local base64 = require("pesto.util.base64")
		if read_response.data ~= vim.NIL then
			table.insert(str_parts, base64.decode(read_response.data))
		end
	end
	local str = table.concat(str_parts)
	return vim.split(str, "\r?\n")
end

---@param line_chunks string[]
---@return string, pesto.google.bytestream.ReadResponse
function ByteStreamClient:_parse_line(line_chunks)
	local raw_line = table.concat(line_chunks)
	local _, _, uri, json_string = raw_line:find(ByteStreamClient._LINE_PATTERN)
	if uri == nil or json_string == nil then
		error(string.format("failed to parse '%s' as byte stream client line", raw_line))
	end
	json_string = vim.trim(json_string)

	if json_string == "" then
		return uri, { data = "" }
	else
		local read_response = vim.json.decode(json_string)
		if type(read_response) ~= "table" then
			error(string.format("failed to parse '%s' as read response", json_string))
		end
		return uri, read_response
	end
end

return ByteStreamClient
