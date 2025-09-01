local M = {}

local terminal_buf_info = require("pesto.runner.default.terminal_buf_info")
local BuildEventsBuffer = require("pesto.ui.build_events_buffer.build_events_buffer")

---@param tab_id number|nil
function M.get_or_create_tab_build_window(tab_id)
	---@type number|nil
	local existing_build_win_id = M.find_build_window(tab_id)
	if existing_build_win_id == nil then
		vim.cmd("below new")
		return vim.api.nvim_get_current_win()
	else
		return existing_build_win_id
	end
end

---Returns the ID of the window that is currently displaying a buffer that's
---normally displayed in the build window.
---@param tab_id integer|nil
---@return integer|nil
function M.find_build_window(tab_id)
	for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(tab_id or 0)) do
		local buf_id = vim.api.nvim_win_get_buf(win_id)
		if terminal_buf_info.is_terminal_buf(buf_id) or BuildEventsBuffer.is_build_events_buffer(buf_id) then
			return win_id
		end
	end
	return nil
end

return M
