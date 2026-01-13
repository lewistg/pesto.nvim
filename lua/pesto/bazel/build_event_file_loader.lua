local SCHEMES = {
	file = "file://",
	bytestream = "bytestream://",
}

-- Loads a file referenced in a build events file
---@class pesto.BuildEventFileLoader
---@field private _byte_stream_client pesto.ByteStreamClient
local BuildEventFileLoader = {}
BuildEventFileLoader.__index = BuildEventFileLoader

function BuildEventFileLoader.is_byte_stream_uri(uri)
	return vim.startswith(uri:lower(), SCHEMES.bytestream)
end

---@param byte_stream_client pesto.ByteStreamClient
function BuildEventFileLoader:new(byte_stream_client)
	local o = setmetatable({}, BuildEventFileLoader)
	o._byte_stream_client = byte_stream_client
	return o
end

---@param file pesto.File
---@param on_load fun(lines: string[])
---@param on_error fun(error: string)
function BuildEventFileLoader:load_file(file, on_load, on_error)
	self:maybe_download_file(file.uri, on_load, on_error)
end

---@param uri string
---@param on_load fun(lines: string[])
---@param on_error fun(error: string)
---@param remote_cache_uri string|nil If the provided uri is a bytestream URI, then you should specify the remote_cache_uri
function BuildEventFileLoader:maybe_download_file(uri, on_load, on_error, remote_cache_uri)
	if uri then
		if vim.startswith(uri:lower(), SCHEMES.file) then
			local file_path = uri:sub(string.len(SCHEMES.file) + 1)
			local lines = vim.fn.readfile(file_path)
			on_load(lines)
		elseif vim.startswith(uri:lower(), SCHEMES.bytestream) then
			if not remote_cache_uri then
				error("must specify remote cache URI when downloading byte streams")
			end
			self._byte_stream_client:get_byte_streams(remote_cache_uri, { uri }, on_load, function(uris)
				on_error(string.format("failed to download uri: %s", uris[1]))
			end)
		end
	end
end

return BuildEventFileLoader
