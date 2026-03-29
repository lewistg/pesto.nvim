---@class pesto.TempDirs
---@field BASE_TEMP_DIR string
---@field LOGS_DIR string
---@field BEP_DIR string

local lazy_table = require("pesto.util.lazy_table")

---@type pesto.TempDirs
local M = lazy_table:new() --[[@as pesto.TempDirs]]

local function get_make_dir(base_path, path)
	return function()
		local full_path = vim.fs.joinpath(base_path, path)
		local result = vim.fn.mkdir(full_path, "p")
		assert(result == 1, string.format("failed to create temp dir: %s", full_path))
		return full_path
	end
end

M.BASE_TEMP_DIR = get_make_dir(vim.fn.tempname(), "pesto.nvim") --[[@as string]]
M.LOGS_DIR = get_make_dir(M.BASE_TEMP_DIR, "logs") --[[@as string]]
M.BEP_DIR = get_make_dir(M.BASE_TEMP_DIR, "bep") --[[@as string]]

return M
