---@class QuickfixItem

--- Helpers for functional tests.
---@class pesto.FunctionalTestHelper
---@private _build_terminal_manager pesto.BuildTerminalManager

local FunctionalTestHelper = {}
FunctionalTestHelper.__index = FunctionalTestHelper

---@param build_terminal_manager pesto.BuildTerminalManager
function FunctionalTestHelper:new(build_terminal_manager)
	local o = setmetatable({}, FunctionalTestHelper)
	o._build_terminal_manager = build_terminal_manager
	return o
end

---@param tab_id number|nil
---@return number|nil The exit code of the last build in the current tab
function FunctionalTestHelper:get_build_exit_code(tab_id)
	local term_buf_id = self._build_terminal_manager:get_tab_id(tab_id or 0)
	if term_buf_id ~= nil then
		local term_buf_info = require("pesto.runner.default.terminal_buf_info").get_pesto_terminal_info(term_buf_id)
		return vim.tbl_get(term_buf_info or {}, "exit_code")
	end
	return nil
end

---@return number[]|nil
function FunctionalTestHelper:get_quickfix_items()
	return vim.fn.getqflist({ id = 0, items = true }).items
end

---@param quickfix_id number|nil Quickfix ID. nil for the current quickfix list
---@param quickfix_line_index number 0-based index of the line to select (i.e., press <Enter> on this line)
function FunctionalTestHelper:jump_via_quickfix_item(quickfix_id, quickfix_line_index)
	local quickfix_win_id = vim.fn.getqflist({ id = quickfix_id, winid = true }).winid
	vim.api.nvim_set_current_win(quickfix_win_id)
	vim.api.nvim_win_set_cursor(0, { quickfix_line_index, 0 })
	local ENTER_KEY = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
	vim.api.nvim_feedkeys(ENTER_KEY, "t", false)
end

---@param tab_id number|nil When nil, the current tab is used
---@return number|nil
function FunctionalTestHelper:get_quickfix_buf_id(tab_id)
	if tab_id == nil then
		tab_id = vim.api.nvim_get_current_tabpage()
	end
	local win_ids = vim.api.nvim_tabpage_list_wins(tab_id)
	for _, win_id in ipairs(win_ids) do
		local win_nr = vim.api.nvim_win_get_number(win_id)
		local win_info = vim.fn.getwininfo(win_nr)
		if win_info.quickfix == 1 then
			return vim.api.nvim_win_get_buf(win_id)
		end
	end
end

return FunctionalTestHelper
