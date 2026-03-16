local M = {}

---@class pesto.RemoteApisHelperInstallCommands
---@field compile_protos string[]
---@field create_venv string[]

---@type string|nil
local _remote_apis_helpers_root = nil

---@return string
function M.get_remote_apis_helpers_root()
	if _remote_apis_helpers_root == nil then
		local remote_apis_helpers_root_name = "pesto-remote-apis-helpers"
		_remote_apis_helpers_root = vim.api.nvim_get_runtime_file("*/" .. remote_apis_helpers_root_name, false)[1]
		if not _remote_apis_helpers_root then
			error("failed to find remote helpers root")
		end
	end
	return _remote_apis_helpers_root
end

return M
