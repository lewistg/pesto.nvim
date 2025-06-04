local M = {}

local uv = vim.loop

function M.is_windows()
	uv.os_uname().sysname:find("^windows")
end

if M.is_windows() then
	M.path_sep = "/"
else
	M.path_sep = "\\"
end

setmetatable(M, {
	__newindex = function()
		error("table is readonly")
	end,
})

return M
