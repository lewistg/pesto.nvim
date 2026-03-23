local M = {}

--- `pesto.nvim` ships with some helper scripts for interacting with Bazel's
--- remote APIs. (In particular these helpers are used to fetch build logs from
--- the remote cache.) This command is used to install/set up these scripts.
---
--- See: tools/pesto-remote-apis-helpers/README.md
---
---@class pesto.InstallRemoteApisHelpersSubcommand: pesto.Subcommand
---@field private _remote_apis_helpers_command_builder pesto.RemoteApisHelpersCommandBuilder
local InstallRemoteApisHelpersSubcommand = {}
InstallRemoteApisHelpersSubcommand.__index = InstallRemoteApisHelpersSubcommand

InstallRemoteApisHelpersSubcommand.name = "install-remote-apis-helpers"

---@param remote_apis_helpers_command_builder pesto.RemoteApisHelpersCommandBuilder
---@return pesto.InstallRemoteApisHelpersSubcommand
function InstallRemoteApisHelpersSubcommand:new(remote_apis_helpers_command_builder)
	local o = setmetatable({}, InstallRemoteApisHelpersSubcommand)

	self._remote_apis_helpers_command_builder = remote_apis_helpers_command_builder

	o.execute = function(opts)
		o:_execute()
	end

	return o
end

function InstallRemoteApisHelpersSubcommand:_execute()
	if not vim.fn.executable("uv") then
		vim.notify(
			"Pesto: `uv` is required to install the Bazel remote APIs helpers. See https://docs.astral.sh/uv/getting-started/installation/",
			vim.log.levels.ERROR,
			{}
		)
		return
	end

	local install_command = self._remote_apis_helpers_command_builder:get_install_command()
	local make_result = vim.system(install_command, {
		clear_env = true,
	}):wait()

	local logger = require("pesto.logger")
	if make_result.code ~= 0 then
		logger.error("make failed:" .. make_result.stderr)
		error("Error setting up Bazel remote APIs helpers")
	end

	vim.notify("Pesto: Successfully set up Bazel remote APIs helpers")
end

return InstallRemoteApisHelpersSubcommand
