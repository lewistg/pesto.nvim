local M = {}

---@class pesto.OpenBuildTermSubcommand: pesto.Subcommand
---@field private _build_window_manager pesto.BuildWindowManager
local OpenBuildTermSubcommand = {}
OpenBuildTermSubcommand.__index = OpenBuildTermSubcommand

OpenBuildTermSubcommand.name = "open-build-term"

---@param build_build_manager pesto.BuildWindowManager
---@return pesto.OpenBuildTermSubcommand
function OpenBuildTermSubcommand:new(build_build_manager)
	local o = setmetatable({}, OpenBuildTermSubcommand)

	o._build_window_manager = build_build_manager
	o.execute = function(opts)
		o:_execute(opts)
	end

	return o
end

---@param opts pesto.SubcommandExecuteOpts
function OpenBuildTermSubcommand:_execute(opts)
	---@type number|nil
	local buf_id = self._build_window_manager:open_build_term()
	if buf_id == nil then
		vim.notify(
			"Pesto: No build terminal to open. One way to trigger a build is with `:Pesto compile-one-dep`.",
			vim.log.levels.WARN
		)
	end
end

return OpenBuildTermSubcommand
