--- Wraps the settings and resolves buffer-local overrides
---@class pesto.InternalSettings
local InternalSettings = {}
InternalSettings.__index = InternalSettings

InternalSettings.SETTINGS_KEY = 'pesto'

---@type string[]
InternalSettings.DEFAULT_BASH_COMPLETION_SCRIPTS = {
  vim.fs.joinpath('/etc/bash_completion.d', 'bazel'),
  vim.fs.joinpath('/etc/bash_completion.d', 'bazel-completion'),
}

---@return pesto.InternalSettings
function InternalSettings:new()
  local o = setmetatable({}, InternalSettings)
  return o
end

---@generic T
---@private
---@param key string
---@return `T`
function InternalSettings:_resolve_setting(key)
  local settings = require('pesto.settings')
  local buf_id = vim.api.nvim_get_current_buf()
  return vim.tbl_deep_extend(
    'keep',
    vim.tbl_get(vim.b, buf_id, InternalSettings.SETTINGS_KEY) or {},
    vim.tbl_get(vim.g, InternalSettings.SETTINGS_KEY) or {},
    settings.DEFAULT_RAW_SETTINGS
  )[key]
end

---@return pesto.RunBazelFn
function InternalSettings:get_bazel_runner()
  return self:_resolve_setting('bazel_runner')
end

---Indicates whether or not the bep integration is enabled. When enabled, the
---`--build_event_json_file=<string>` bazel flag is automatically injected into
---the bazel command. The argument to `--build_event_json_file` will be a well
---known file that can be loaded post-build.
---@return boolean
function InternalSettings:get_enable_bep_integration()
  return self:_resolve_setting('enable_bep_integration')
end

function InternalSettings:get_auto_open_build_term()
  return self:_resolve_setting('auto_open_build_term')
end

---@return pesto.ActionErrorformat[]
function InternalSettings:get_errorformats()
  local errorformats = self:_resolve_setting('errorformats')
  local default_errorformats = self:_resolve_setting('default_errorformats')
  return vim.iter({ errorformats, default_errorformats }):flatten():totable()
end

---@return pesto.CliCompletionSettings
function InternalSettings:get_cli_completion_settings()
  return self:_resolve_setting('cli_completion')
end

---@return string
function InternalSettings:get_bazel_executable()
  return self:_resolve_setting('bazel_executable')
end

---@return pesto.BuildTargetResolvers
function InternalSettings:get_build_target_resolvers()
  return self:_resolve_setting('build_target_resolvers')
end

return InternalSettings
