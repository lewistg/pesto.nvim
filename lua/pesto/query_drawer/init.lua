local M = {}

local QueryDrawerManager = require('pesto.query_drawer.query_drawer_manager')
local logger = require('pesto.logger')

---@type QueryDrawerManager?
local bazel_query_drawer_manager = nil

---@param win_id number
---@param buf_nr number
---@param line_range {line1: number, number2: number}
---@param settings Settings
function M.run_query(win_id, buf_nr, line_range, settings)
    bazel_query_drawer_manager = vim.F.if_nil(
        bazel_query_drawer_manager,
        QueryDrawerManager:new(logger, settings)
    )
    bazel_query_drawer_manager:run_query(win_id, buf_nr, line_range)
end

return M
