local FILE_SCHEME = "file://"

-- Loads a file referenced in a build events file
---@class pesto.BuildEventFileLoader
local BuildEventFileLoader = {}
BuildEventFileLoader.__index = BuildEventFileLoader

function BuildEventFileLoader:new()
	local o = setmetatable({}, BuildEventFileLoader)
	return o
end

---@param file pesto.File
---@param on_load fun(lines: string[])
---@param on_error fun(error: string)
function BuildEventFileLoader:load_file(file, on_load, on_error)
	local file_protocol = "file://"
	if file.uri and vim.startswith(file.uri, file_protocol) then
		local path = file.uri:sub(string.len(file_protocol) + 1)
		local lines = vim.fn.readfile(path)
		on_load(lines)
	end
end

---@param uri string
---@param on_load fun(file_path: string)
---@param on_error fun(error: string)
function BuildEventFileLoader:maybe_download_file(uri, on_load, on_error)
	if uri and vim.startswith(uri, FILE_SCHEME) then
		local file_path = uri:sub(string.len(FILE_SCHEME) + 1)
		on_load(file_path)
	end
end

return BuildEventFileLoader
