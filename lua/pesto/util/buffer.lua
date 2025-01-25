local M = {}

function M.with_temp_options(buf_nr, options, fn)
    local prev_option_values = {}
    for option, temp_value in pairs(options) do
        prev_option_values[option] = vim.bo[buf_nr][option]
        vim.bo[buf_nr][option] = temp_value
    end

    fn()

    for option, prev_value in pairs(prev_option_values) do
        vim.bo[buf_nr][option] = prev_value
    end
end

function M.is_empty(buf_nr)
    return vim.api.nvim_buf_line_count(buf_nr) == 1 and
        vim.api.nvim_buf_get_lines(buf_nr, 0, 2, false)[1] == ''
end

return M
