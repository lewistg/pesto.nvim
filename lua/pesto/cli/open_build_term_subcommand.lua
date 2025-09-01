local M = {}

---@class pesto.OpenBuildTermSubcommand: Subcommand
---@field private _build_terminal_manager pesto.BuildTerminalManager
local OpenBuildTermSubcommand = {}
OpenBuildTermSubcommand.__index = OpenBuildTermSubcommand

OpenBuildTermSubcommand.name = "open-build-term"

---@param build_terminal_manager pesto.BuildTerminalManager
---@return pesto.OpenBuildTermSubcommand
function OpenBuildTermSubcommand:new(build_terminal_manager)
	local o = setmetatable({}, OpenBuildTermSubcommand)

	o._build_terminal_manager = build_terminal_manager
	o.execute = function(opts)
		o:_execute(opts)
	end

	return o
end

---@param opts SubcommandExecuteOpts
function OpenBuildTermSubcommand:_execute(opts)
	---@type number|nil
	local buf_id = self._build_terminal_manager:get_tab_id(0)
	if buf_id ~= nil then
		local win_id = require("pesto.runner.default.build_window").get_or_create_tab_build_window(0)
		vim.api.nvim_win_set_buf(win_id, buf_id)
	else
		vim.notify(
			"Pesto: No build terminal to open. One way to trigger a build is with `:Pesto compile-one-dep`.",
			vim.log.levels.WARN
		)
	end
end

return OpenBuildTermSubcommand
