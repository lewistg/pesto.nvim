local M = {}

local BazelQueryResultsDrawerManager = require('pesto.query_drawer.query_drawer_manager')

local bazel_query_drawer_manager = BazelQueryResultsDrawerManager:new()

---@param win_id number
---@param buf_nr number
---@param line_range {line1: number, number2: number}
function M.run_query(win_id, buf_nr, line_range)
    bazel_query_drawer_manager:run_query(win_id, buf_nr, line_range)
end

return M
