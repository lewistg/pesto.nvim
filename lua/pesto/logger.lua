local M = {}

local log = require("plenary.log")
local Path = require("plenary.path")
local uv = vim.loop

-- Plenary doesn't have a type annotations for their logger yet
---@class Logger

local MAX_LOG_SIZE_IN_BYTES = 2 ^ 20 * 10
local PLUGIN_ROOT_DIR_NAME = "pesto.nvim"

local log_dir = vim.F.if_nil(vim.F.npcall(vim.fn.stdpath, "log"), vim.fn.stdpath("cache"))
local log_path = Path:new(log_dir, "pesto.nvim.log")

local log_stat = uv.fs_stat(log_path.filename)
if log_stat and log_stat.size > MAX_LOG_SIZE_IN_BYTES then
	local old_log_path = Path:new(log_path.filename)
	old_log_path.rename(old_log_path .. ".old")
end

---@param log_level string Log level
---@return Logger
function M.get_logger(log_level)
	local config = {
		use_console = false,
		use_file = true,
		outfile = log_path.filename,
		level = log_level,
	}
	return log.new(config, true)
end

return M
