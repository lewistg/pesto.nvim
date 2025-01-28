local Job = require('plenary.job')
local QueryDrawerView = require('pesto.query_drawer.query_drawer_view')

---@class QueryDrawer
---@field private _view QueryDrawerView
---@field private _current_job? Job
---@field private _on_dispose? fun()
---@field private _logger Logger
---@field private _settings Settings
local QueryDrawer = {}
QueryDrawer.__index = QueryDrawer

---@class QueryDrawerOpts
---@field public query_win_id number
---@field public on_dispose? fun()
---@field public logger Logger
---@field public settings Settings

---@param opts QueryDrawerOpts
---@return QueryDrawer
function QueryDrawer:new(opts)
    local o = setmetatable({}, QueryDrawer)

    o._view = QueryDrawerView:new {
        query_win_id = opts.query_win_id,
        on_dispose = function()
            o:_dispose()
        end
    }
    o._current_job = nil
    o._on_dispose = opts.on_dispose
    o._logger = opts.logger
    o._settings = opts.settings

    return o
end

---@param query string
function QueryDrawer:run_query(query)
    if (self._current_job) then
        self._current_job:shutdown()
        self._current_job = nil
    end

    local stdout_lines_buffer = {}
    local stderr_lines_buffer = {}
    local lines_buffer_flush_scheduled = false

    local function schedule_lines_buffer_flush()
        if (lines_buffer_flush_scheduled) then
            return
        end
        vim.schedule(function()
            lines_buffer_flush_scheduled = false
            self._view:append_stdout(stdout_lines_buffer)
            self._view:append_stderr(stderr_lines_buffer)
        end)
        lines_buffer_flush_scheduled = true
    end

    self._current_job = Job:new {
        command = self._settings.bazel_command,
        args = {
            "query",
            query
        },
        on_stdout = function(error, line)
            if (error ~= nil) then
                self._current_job:shutdown(1, nil)
            end
            table.insert(stdout_lines_buffer, line)
            schedule_lines_buffer_flush()
        end,
        on_stderr = function(error, line)
            if (error ~= nil) then
                self._current_job:shutdown(1, nil)
            end
            table.insert(stderr_lines_buffer, line)
            schedule_lines_buffer_flush()
        end,
        on_exit = function(_, code, signal)
            vim.schedule(function()
                if (code ~= 0) then
                    self._view:show_stderr()
                    return
                end
                self._view:show_results()
                stdout_lines_buffer = {}
                stderr_lines_buffer = {}
            end)
        end
    }
    self._view:clear()
    self._view:show_stderr()
    self._current_job:start()
end

---Clase up resources
function QueryDrawer:_dispose()
    if (self._current_job) then
        self._current_job:shutdown()
    end
    if (self._on_dispose) then
        self._on_dispose()
    end
end

return QueryDrawer
