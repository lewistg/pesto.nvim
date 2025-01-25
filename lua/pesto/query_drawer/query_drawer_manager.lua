local Job = require('plenary.job')
local Settings = require('pesto.settings')
local QueryDrawer = require('pesto.query_drawer.query_drawer')

---Manages bazel query drawers
---@class QueryDrawerManager
---@field private _query_win_to_drawer table<number, QueryDrawer>
---Maps the windo from which the query came to 
local QueryDrawerManager = {}
QueryDrawerManager.__index = QueryDrawerManager

function QueryDrawerManager:new(o)
    o = o or {}
    setmetatable(o, QueryDrawerManager)

    o._query_win_to_drawer = {}

    return o
end

function QueryDrawerManager:run_query(win_id, buf_nr, line_range)
    local lines = vim.api.nvim_buf_get_lines(buf_nr, line_range.line1, line_range.line2, true)
    local query = table.concat(lines, " ")

    local drawer = self:_get_or_create_drawer(win_id)
    drawer:run_query(query)
end

function QueryDrawerManager:_get_or_create_drawer(win_id)
    if (self._query_win_to_drawer[win_id] == nil) then
        self._query_win_to_drawer[win_id] = QueryDrawer:new {
            query_win_id = win_id,
            on_dispose = function()
                vim.print("here")
                self._query_win_to_drawer[win_id] = nil
            end
        }
    end
    return self._query_win_to_drawer[win_id]
end

return QueryDrawerManager
