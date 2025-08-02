---@class pesto.ViewBuildEventsSummarySubcommand: Subcommand
---@field execute SubcommandExecuteFn
local ViewBuildEventsSummarySubcommand = {}
ViewBuildEventsSummarySubcommand.__index = ViewBuildEventsSummarySubcommand

ViewBuildEventsSummarySubcommand.name = "view-build-events-summary"

---@return pesto.ViewBuildEventsSummarySubcommand
function ViewBuildEventsSummarySubcommand:new()
    local o = setmetatable({}, ViewBuildEventsSummarySubcommand)

    ---@param opts SubcommandExecuteOpts
	o.execute = function(opts)
		o:_execute(opts)
	end

    return o
end

---@param opts SubcommandExecuteOpts
function ViewBuildEventsSummarySubcommand:_execute(opts)
    vim.print("TODO")
end

return ViewBuildEventsSummarySubcommand
