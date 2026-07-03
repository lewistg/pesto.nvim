--- Wraps the "public" config and resolves buffer-local overrides
---@class pesto.InternalConfig
local InternalConfig = {}
InternalConfig.__index = InternalConfig

InternalConfig.CONFIG_KEY = 'pesto'

---@type string[]
InternalConfig.DEFAULT_BASH_COMPLETION_SCRIPTS = {
  vim.fs.joinpath('/etc/bash_completion.d', 'bazel'),
  vim.fs.joinpath('/etc/bash_completion.d', 'bazel-completion'),
}

---@return pesto.InternalConfig
function InternalConfig:new()
  local o = setmetatable({}, InternalConfig)
  return o
end

---@generic T
---@private
---@param key string
---@return `T`
function InternalConfig:_resolve_config(key)
  local config = require('pesto.config')
  local buf_id = vim.api.nvim_get_current_buf()
  return vim.tbl_deep_extend(
    'keep',
    vim.tbl_get(vim.b, buf_id, InternalConfig.CONFIG_KEY) or {},
    vim.tbl_get(vim.g, InternalConfig.CONFIG_KEY) or {},
    config.DEFAULT_RAW_CONFIG
  )[key]
end

--- Note: Generally, the only consumer of this method should be
--- pesto.InternalRunBazelFn. Other consumers should use
--- pesto.InternalRunBazelFn to run Bazel.
---@return pesto.RunBazelFn
function InternalConfig:_get_bazel_runner()
  return self:_resolve_config('bazel_runner')
end

---Indicates whether or not the bep integration is enabled. When enabled, the
---`--build_event_json_file=<string>` bazel flag is automatically injected into
---the bazel command. The argument to `--build_event_json_file` will be a well
---known file that can be loaded post-build.
---@return boolean
function InternalConfig:get_enable_bep_integration()
  return self:_resolve_config('enable_bep_integration')
end

function InternalConfig:get_auto_open_build_term()
  return self:_resolve_config('auto_open_build_term')
end

---@return pesto.ActionErrorformat[]
function InternalConfig:get_errorformats()
  local errorformats = self:_resolve_config('errorformats')
  local default_errorformats = self:_resolve_config('default_errorformats')
  return vim.iter({ errorformats, default_errorformats }):flatten():totable()
end

---@return pesto.CliCompletionConfig
function InternalConfig:get_cli_completion_config()
  return self:_resolve_config('cli_completion')
end

---@return pesto.QuickfixLogSource
function InternalConfig:get_quickfix_log_source()
  return self:_resolve_config('quickfix_log_source')
end

---@return string
function InternalConfig:get_bazel_executable()
  return self:_resolve_config('bazel_executable')
end

---@return pesto.TargetResolvers
function InternalConfig:get_build_target_resolvers()
  return self:_resolve_config('build_target_resolvers')
end

return InternalConfig
