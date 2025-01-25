local BufferUtil = require('pesto.util.buffer')
local WindowUtil = require('pesto.util.window')
local FileTypes = require('pesto.file_types')

---Manages the window and buffers that render the results drawer
---@class QueryDrawerView
---@field private _win_id number Window ID that displays the drawer
---@field private _stdout_buf_nr number Buffer number that displays the bazel query result
---@field private _stderr_buf_nr number Buffer number that displays the bazel query stderr output
---@field private _on_dispose? fun() Callback called when the drawer is closed
local QueryDrawerView = {}
QueryDrawerView.__index = QueryDrawerView

---@class QueryDrawerViewOpts
---@field public query_win_id number
---@field public on_dispose fun()

---@param opts QueryDrawerOpts
---@return QueryDrawerView 
function QueryDrawerView:new(opts)
    local o = {}
    setmetatable(o, self)

    vim.api.nvim_set_current_win(opts.query_win_id)
    vim.cmd("rightbelow new")
    o._win_id = vim.api.nvim_get_current_win()

    o._on_dispose = opts.on_dispose

    o:_set_up_autocommands()

    o._win_id = vim.api.nvim_get_current_win()
    o._stdout_buf_nr = self:_create_output_buf(FileTypes.PESTO_BAZEL_QUERY_RESULTS_FILE_TYPE)
    o._stderr_buf_nr = self:_create_output_buf()
    o._bazel_query_job = nil

    o:show_stderr()

    return o
end

function QueryDrawerView:dispose()
    self:_clear_autocommands()
    for _, buf_nr in ipairs({self._stdout_buf_nr, self._stdout_buf_nr}) do
        if (vim.api.nvim_buf_is_loaded(buf_nr)) then
            vim.api.nvim_buf_delete(buf_nr, {
                force = true
            })
        end
    end
end

function QueryDrawerView:_set_up_autocommands()
    vim.api.nvim_create_autocmd({'WinClosed'}, {
        pattern = {tostring(self._win_id)},
        callback = function()
            self:_dispose()
        end
    })
end

function QueryDrawerView:_clear_autocommands()
    vim.api.nvim_clear_autocmds({
        event = {'WinClosed'},
        pattern = {tostring(self._win_id)},
    })
end

function QueryDrawerView:open()
     -- create a buffer for 
end

---@param filetype string|nil Optional file type of new buffer
function QueryDrawerView:_create_output_buf(filetype)
    local buf_nr = vim.api.nvim_create_buf(false, true)
    vim.bo[buf_nr].buflisted = false
    vim.bo[buf_nr].modifiable = false
    if (filetype ~= nil) then
        vim.bo[buf_nr].filetype = filetype
    end
    return buf_nr
end

---Append line to results buffer
function QueryDrawerView:append_stdout(lines)
    self:_append_buffer(self._stdout_buf_nr, lines)
end

---Append line to stderr buffer
function QueryDrawerView:append_stderr(lines)
    self:_append_buffer(self._stderr_buf_nr, lines)
end

---Appends line to given buffer
---@param buf_nr number
---@param lines string[]
function QueryDrawerView:_append_buffer(buf_nr, lines)
    local temp_buf_options = {
        modifiable = true
    }
    BufferUtil.with_temp_options(buf_nr, temp_buf_options, function ()
        local start_index = -1
        if (BufferUtil.is_empty(buf_nr)) then
            start_index = 0
        end
        vim.print(start_index)
        vim.api.nvim_buf_set_lines(buf_nr, start_index, -1, false, lines)
    end)
end

function QueryDrawerView:clear()
    local temp_buf_options = {
        modifiable = true,
    }
    BufferUtil.with_temp_options(self._stdout_buf_nr, temp_buf_options, function ()
        vim.api.nvim_buf_set_lines(self._stdout_buf_nr, 0, -1, false, {})
    end)
    BufferUtil.with_temp_options(self._stderr_buf_nr, temp_buf_options, function ()
        vim.api.nvim_buf_set_lines(self._stderr_buf_nr, 0, -1, false, {})
    end)
end

---Shows the stderr buffer
function QueryDrawerView:show_stderr()
    WindowUtil.with_window(self._win_id, function()
        vim.api.nvim_set_current_buf(self._stderr_buf_nr)
    end)
end

---Shows the results buffer
function QueryDrawerView:show_results()
    WindowUtil.with_window(self._win_id, function()
        vim.api.nvim_set_current_buf(self._stdout_buf_nr)
    end)
end

---Closes the window
function QueryDrawerView:close()
    self:_dispose()
end

---Clean up resources
function QueryDrawerView:_dispose()
    local curr_buf_nr = nil
    if (vim.api.nvim_win_is_valid(self._win_id)) then
        curr_buf_nr = vim.api.nvim_win_get_buf(self._win_id)
    end
    if (curr_buf_nr ~= self._stdout_buf_nr and curr_buf_nr ~= self._stderr_buf_nr) then
        vim.api.nvim_win_close(self._win_id)
    end
    vim.api.nvim_buf_delete(self._stdout_buf_nr, {force=true})
    vim.api.nvim_buf_delete(self._stderr_buf_nr, {force=true})

    if (self._on_dispose) then
        self._on_dispose()
    end
end

return QueryDrawerView
