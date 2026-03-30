---@class pesto.BuildEventFileLoader.FetchFileOptions
---@field uri string The currently supported file schemes are `file` and `bytestream` (e.g., `file://...`, `bytestream://...`)
---@field on_load fun(lines: string[]) Callback with the log lines
---@field on_error fun(error: string|table) Callback if there was an error downloading the file
---@field remote_cache_uri string|nil Will likely be of the form `grpc(s?)://...`. This parameter is required if the `uri` is a bytestream.
---@field remote_headers string[]|nil

local SCHEMES = {
	file = "file://",
	bytestream = "bytestream://",
}

-- Loads a file referenced in a build events file
---@class pesto.BuildEventFileLoader
---@field private _byte_stream_client pesto.ByteStreamClient
local BuildEventFileLoader = {}
BuildEventFileLoader.__index = BuildEventFileLoader

---@type table
BuildEventFileLoader.BazelRemoteHelpersNotSetupError = {}

function BuildEventFileLoader.is_byte_stream_uri(uri)
	return vim.startswith(uri:lower(), SCHEMES.bytestream)
end

---@param byte_stream_client pesto.ByteStreamClient
function BuildEventFileLoader:new(byte_stream_client)
	local o = setmetatable({}, BuildEventFileLoader)
	o._byte_stream_client = byte_stream_client
	return o
end

---@param file pesto.bep.File
---@param on_load fun(lines: string[])
---@param on_error fun(error: string)
function BuildEventFileLoader:load_file(file, on_load, on_error)
	self:fetch_file({
		uri = file.uri,
		on_load = on_load,
		on_error = on_error,
	})
end

---@param opts pesto.BuildEventFileLoader.FetchFileOptions
function BuildEventFileLoader:fetch_file(opts)
	if opts.uri then
		if vim.startswith(opts.uri:lower(), SCHEMES.file) then
			local file_path = opts.uri:sub(string.len(SCHEMES.file) + 1)
			local lines = vim.fn.readfile(file_path)
			opts.on_load(lines)
		elseif vim.startswith(opts.uri:lower(), SCHEMES.bytestream) then
			if not self._byte_stream_client:are_remote_apis_helpers_installed() then
				local logger = require("pesto.logger")
				logger.warn(string.format("No remote cache client. Cannot download logs. uri=%s.", opts.uri))
				opts.on_error(BuildEventFileLoader.BazelRemoteHelpersNotSetupError)
				return
			elseif not opts.remote_cache_uri then
				error("must specify remote cache URI when downloading byte streams")
			end
			self._byte_stream_client:get_byte_streams({
				byte_stream_service_uri = opts.remote_cache_uri,
				byte_stream_uris = { opts.uri },
				on_download = opts.on_load,
				on_done = function(uris)
					opts.on_error(string.format("failed to download uri: %s", uris[1]))
				end,
				request_headers = opts.remote_headers or {},
			})
		end
	end
end

return BuildEventFileLoader
