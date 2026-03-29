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

local LOG_LEVEL = {
	["trace"] = -1,
	["debug"] = 0,
	["info"] = 1,
	["warn"] = 2,
	["error"] = 3,
}

local DEFAULT_LOG_LEVEL = "info"

local temp_dir = require("pesto.util.temp_dirs")
M.LOG_FILE_PATH = vim.fs.joinpath(temp_dir.LOGS_DIR, "pesto.nvim.log")
local LOG_FILE = vim.uv.fs_open(M.LOG_FILE_PATH, "w+", tonumber("644", 8))

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
		local time = os.date()
		local log_message = string.format(
			"[%s] %s %s:%d: %s\n",
			string.upper(log_level),
			time,
			call_location.file,
			call_location.line_nu,
			final_message
		)
		vim.uv.fs_write(LOG_FILE, log_message)
	end
end

return M
