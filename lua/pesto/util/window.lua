local M = {}

--- Run a function that may open another window while, but make the current
--- window stays current.
---@param fn fun()
function M.keep_current(fn)
  local prev_win_id = vim.api.nvim_get_current_win()
  fn()
  vim.api.nvim_set_current_win(prev_win_id)
end

return M
