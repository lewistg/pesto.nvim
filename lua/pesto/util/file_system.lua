local M = {}

---@param path Path
---@param name_pattern string|nil
---@return string[]
function M.get_dirs(path, name_pattern)
	local iter_util = require("pesto.util.iter_util")
	return iter_util.to_list(M.get_dirs_iter(path, name_pattern))
end

---@param path string
---@param name_pattern string|nil
---@return fun(): string|nil
function M.get_dirs_iter(path, name_pattern)
	if name_pattern == "" then
		name_pattern = nil
	end
	local userdata = vim.uv.fs_scandir(path)
	return function()
		while true do
			local name, type = vim.uv.fs_scandir_next(userdata)
			if not name then
				return nil
			end
			if type == "directory" then
				if not name_pattern or name:find(name_pattern) then
					return name
				end
			end
		end
	end
end

return M
