local string_util = require("pesto.util.string")

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
	if file.uri and string_util.starts_with(file.uri, file_protocol) then
		local path = file.uri:sub(string.len(file_protocol) + 1)
		local lines = vim.fn.readfile(path)
		on_load(lines)
	end
end

return BuildEventFileLoader
