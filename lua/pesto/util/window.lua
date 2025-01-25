local M = {}

function M.with_window(win_id, fn)
    local prev_win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(win_id)
    fn()
    vim.api.nvim_set_current_win(prev_win_id)
end

return M
