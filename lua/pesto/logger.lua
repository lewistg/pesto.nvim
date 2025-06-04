local os = require("pesto.util.os")
local settings = require("pesto.settings").settings
local uv = vim.loop

-- Plenary doesn't have a type annotations for their logger yet
---@class Logger
---@field debug fun(message: string)
---@field info fun(message: string)
---@field warn fun(message: string)
---@field error fun(message: string)
local M = {}

local MAX_LOG_SIZE_IN_BYTES = 2 ^ 20 * 10
local LOG_LEVEL = {
	["debug"] = 0,
	["info"] = 1,
	["warn"] = 2,
	["error"] = 3,
}

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
	M[log_level] = function(message)
		if numeric_log_level < LOG_LEVEL[settings.log_level] then
			return
		end
		local call_location = get_call_location()
		local time = vim.fn.strftime("%c")
		local log_message = string.format(
			"[%s] %s %s:%d: %s\n",
			string.upper(log_level),
			time,
			call_location.file,
			call_location.line_nu,
			message
		)
		uv.fs_write(log_file, log_message)
	end
end

return M
