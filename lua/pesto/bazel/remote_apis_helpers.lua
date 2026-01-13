---@class pesto.RemoteApisHelpersCommandBuilder
---@field private _remote_apis_helpers_root string|nil
local RemoteApisHelpersCommandBuilder = {}
RemoteApisHelpersCommandBuilder.__index = RemoteApisHelpersCommandBuilder

---@return pesto.RemoteApisHelpersCommandBuilder
function RemoteApisHelpersCommandBuilder:new()
	local o = setmetatable({}, RemoteApisHelpersCommandBuilder)
	return o
end

---@param options {address: string, log_file?: string|nil}
---@return string[]
function RemoteApisHelpersCommandBuilder:get_fetch_byte_streams_command(options)
	if self._remote_apis_helpers_root == nil then
		local remote_apis_helpers_root_name = "pesto-remote-apis-helpers"
		self._remote_apis_helpers_root = vim.api.nvim_get_runtime_file("*/" .. remote_apis_helpers_root_name, false)[1]
		if not self._remote_apis_helpers_root then
			error("failed to find remote helpers root")
		end
	end

	--- Keep in sync with tools/pesto-remote-apis-helpers/pyproject.toml
	local script_name = "pesto-fetch-byte-streams"
	local logger = require("pesto.logger")
	local log_file = logger.log_dir .. "/" .. script_name .. ".log"

	return {
		"uv",
		"run",
		"--directory",
		self._remote_apis_helpers_root,
		script_name,
		"--uri",
		options.address,
		"--log-file",
		log_file,
		"-",
	}
end

return RemoteApisHelpersCommandBuilder
