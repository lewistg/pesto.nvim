---@class pesto.RemoteApisHelpersCommandBuilder
---@field private _remote_apis_helpers_root string|nil
local RemoteApisHelpersCommandBuilder = {}
RemoteApisHelpersCommandBuilder.__index = RemoteApisHelpersCommandBuilder

---@return pesto.RemoteApisHelpersCommandBuilder
function RemoteApisHelpersCommandBuilder:new()
	local o = setmetatable({}, RemoteApisHelpersCommandBuilder)
	return o
end

---@param options {address: string, headers: string[]|nil, log_file?: string|nil}
---@return string[]
function RemoteApisHelpersCommandBuilder:get_fetch_byte_streams_command(options)
	local remote_apis_helpers_util = require("pesto.bazel.remote_apis_helpers_util")
	local remote_apis_helpers_root = remote_apis_helpers_util.get_remote_apis_helpers_root()

	--- Keep in sync with tools/pesto-remote-apis-helpers/pyproject.toml
	local script_name = "pesto-fetch-byte-streams"
	local logger = require("pesto.logger")
	local log_file = logger.log_dir .. "/" .. script_name .. ".log"

	---@type string[]
	local header_options = vim.iter(options.headers or {})
		:map(function(header)
			return { "-H", header }
		end)
		:flatten()
		:totable()

	return vim.iter({
		"uv",
		"run",
		"--directory",
		remote_apis_helpers_root,
		script_name,
		"--uri",
		options.address,
		header_options,
		"--log-file",
		log_file,
		"-",
	})
		:flatten()
		:totable()
end

function RemoteApisHelpersCommandBuilder:get_install_command()
	local remote_apis_helpers_util = require("pesto.bazel.remote_apis_helpers_util")
	local remote_apis_helpers_root = remote_apis_helpers_util.get_remote_apis_helpers_root()
	return {
		"make",
		"-C",
		remote_apis_helpers_root,
		"-B",
	}
end

function RemoteApisHelpersCommandBuilder:get_is_installed_command()
	local remote_apis_helpers_util = require("pesto.bazel.remote_apis_helpers_util")
	local remote_apis_helpers_root = remote_apis_helpers_util.get_remote_apis_helpers_root()
	return {
		"make",
		"-C",
		remote_apis_helpers_root,
		"-q",
	}
end

return RemoteApisHelpersCommandBuilder
