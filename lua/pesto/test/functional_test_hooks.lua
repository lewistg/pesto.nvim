---@class QuickfixItem

--- Helpers for functional tests. In functional tests, the test interacts with
--- another instance of Neovim via the Neovim RPC API. This hooks class is run
--- in the remote instance.
---@class pesto.FunctionalTestHooks
---@field private _build_window_manager pesto.BuildWindowManager

local FunctionalTestHooks = {}
FunctionalTestHooks.__index = FunctionalTestHooks

---@param build_window_manager pesto.BuildWindowManager
---@return pesto.FunctionalTestHooks
function FunctionalTestHooks:new(build_window_manager)
	local o = setmetatable({}, FunctionalTestHooks)
	o._build_window_manager = build_window_manager
	return o
end

---@return number|nil The exit code of the last build in the current tab
function FunctionalTestHooks:get_build_exit_code()
	return self._build_window_manager:get_build_exit_code()
end

---@return number[]
function FunctionalTestHooks:find_build_windows(tab_id)
	return self._build_window_manager:find_build_windows(tab_id)
end

---@return number[]|nil
function FunctionalTestHooks:get_quickfix_items()
	return vim.fn.getqflist({ id = 0, items = true }).items
end

---@param quickfix_id number|nil Quickfix ID. nil for the current quickfix list
---@param quickfix_line_index number 0-based index of the line to select (i.e., press <Enter> on this line)
function FunctionalTestHooks:jump_via_quickfix_item(quickfix_id, quickfix_line_index)
	local quickfix_win_id = vim.fn.getqflist({ id = quickfix_id, winid = true }).winid
	vim.api.nvim_set_current_win(quickfix_win_id)
	vim.api.nvim_win_set_cursor(0, { quickfix_line_index, 0 })
	local ENTER_KEY = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
	vim.api.nvim_feedkeys(ENTER_KEY, "t", false)
end

---@param tab_id number|nil When nil, the current tab is used
---@return number|nil
function FunctionalTestHooks:get_quickfix_buf_id(tab_id)
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

---@param global_var string
---@param tbl table
function FunctionalTestHooks:extend_global_table(global_var, tbl)
	if vim.g[global_var] == nil then
		vim.g[global_var] = {}
	end
	vim.g[global_var] = vim.tbl_deep_extend("force", vim.g[global_var], tbl)
end

return FunctionalTestHooks
