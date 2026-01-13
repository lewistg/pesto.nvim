local os = require("pesto.util.os")
local uv = vim.loop

---Note: The log methods accept a log message string or a function that returns
---a log message string. Prefer wrapping log messages that are expensive to
---calculate. The log message functions are only evaluated if permitted by the
---current log-level
---
---@class Logger
---@field trace fun(message: string|fun(): string)
---@field debug fun(message: string|fun(): string)
---@field info fun(message: string|fun(): string)
---@field warn fun(message: string|fun(): string)
---@field error fun(message: string|fun(): string)
local M = {}

local MAX_LOG_SIZE_IN_BYTES = 2 ^ 20 * 10
local LOG_LEVEL = {
	["trace"] = -1,
	["debug"] = 0,
	["info"] = 1,
	["warn"] = 2,
	["error"] = 3,
}

local DEFAULT_LOG_LEVEL = "info"

local log_dir = vim.F.if_nil(vim.F.npcall(vim.fn.stdpath, "log"), vim.fn.stdpath("cache"))
log_dir = vim.fs.normalize(log_dir)
local log_path = log_dir .. "/pesto.nvim.log"
log_path:gsub("/", os.path_sep)

local log_stat = uv.fs_stat(log_path)
if log_stat and log_stat.size > MAX_LOG_SIZE_IN_BYTES then
	uv.fs_rename(log_path, log_path .. ".old")
end

local log_file = uv.fs_open(log_path, "a", 438)

local function get_call_location()
	local info = debug.getinfo(3, "Sl")
	return {
		file = info.source,
		line_nu = info.currentline,
	}
end

for log_level, numeric_log_level in pairs(LOG_LEVEL) do
	---@param message string|fun(): string
	M[log_level] = function(message)
		---@type number
		local log_level_setting = vim.tbl_get(
			LOG_LEVEL,
			vim.tbl_get(vim.g, require("pesto.settings").SETTINGS_KEY, "log_level")
		) or LOG_LEVEL[DEFAULT_LOG_LEVEL]
		if numeric_log_level < log_level_setting then
			return
		end
		---@type string
		local final_message = ""
		if type(message) == "function" then
			final_message = message()
		else
			final_message = message
		end
		local call_location = get_call_location()
		local time = vim.fn.strftime("%c")
		local log_message = string.format(
			"[%s] %s %s:%d: %s\n",
			string.upper(log_level),
			time,
			call_location.file,
			call_location.line_nu,
			final_message
		)
		uv.fs_write(log_file, log_message)
	end
end

M.log_dir = log_dir
M.log_path = log_path

return M
