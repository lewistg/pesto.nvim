local M = {}

local PESTO_TERMINAL_BUF_INFO = "PESTO_TERMINAL_BUF_INFO"

---@class pesto.TerminalBufInfo
---@field private _buf_id number
---@field exit_code boolean|nil
---@field bep_file string|nil
---@field tab_id number
local TerminalBufInfo = {}

---@type {[string]: boolean}
local keys = {
	["exit_code"] = true,
	["bep_file"] = true,
	["tab_id"] = true,
}

---@param buf_id number
local function get_raw_terminal_buf_info(buf_id)
	local ok, raw_terminal_buf_info = pcall(vim.api.nvim_buf_get_var, buf_id, PESTO_TERMINAL_BUF_INFO)
	if ok then
		return raw_terminal_buf_info
	else
		vim.api.nvim_buf_set_var(buf_id, PESTO_TERMINAL_BUF_INFO, {})
	end
	return {}
end

TerminalBufInfo.__index = function(tbl, key)
	if keys[key] then
		local buf_id = rawget(tbl, "_buf_id")
		return get_raw_terminal_buf_info(buf_id)[key]
	end
	return nil
end

TerminalBufInfo.__newindex = function(tbl, key, value)
	if keys[key] then
		local buf_id = rawget(tbl, "_buf_id")
		local raw_terminal_buf_info = get_raw_terminal_buf_info(buf_id)
		raw_terminal_buf_info[key] = value
		vim.api.nvim_buf_set_var(buf_id, PESTO_TERMINAL_BUF_INFO, raw_terminal_buf_info)
	end
end

---@param buf_id number
---@param tab_id number
---@return pesto.TerminalBufInfo|nil
function M.init_terminal_buf_info(buf_id, tab_id)
	vim.api.nvim_buf_set_var(buf_id, PESTO_TERMINAL_BUF_INFO, {
		tab_id = tab_id,
	})
	return M.get_pesto_terminal_info(buf_id)
end

---@param buf_id number
---@return pesto.TerminalBufInfo|nil
function M.get_pesto_terminal_info(buf_id)
	local o = setmetatable({}, TerminalBufInfo)
	rawset(o, "_buf_id", buf_id)
	return o
end

---@param buf_id number
---@return boolean
function M.is_terminal_buf(buf_id)
	local ok = pcall(vim.api.nvim_buf_get_var, buf_id, PESTO_TERMINAL_BUF_INFO)
	return ok
end

return M
