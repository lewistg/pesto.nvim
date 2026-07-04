local BazelShortcutSubcommand = require('pesto.cli.bazel_shortcut_subcommand')

---@class pesto.BuildSubcommand: pesto.BazelShortcutSubcommand
---@field private _internal_config pesto.InternalConfig
---@field private _internal_run_bazel_fn pesto.InternalRunBazelFn
local BuildSubcommand = setmetatable({}, BazelShortcutSubcommand)
BuildSubcommand.__index = BuildSubcommand

BuildSubcommand.name = 'build'

---@param internal_run_bazel_fn pesto.InternalRunBazelFn
---@param internal_config pesto.InternalConfig
---@return pesto.BuildSubcommand
function BuildSubcommand.new(internal_run_bazel_fn, internal_config)
  local o = {}

  BazelShortcutSubcommand.new(o, 'build', internal_run_bazel_fn, internal_config)
  o = setmetatable(o, BuildSubcommand)

  return o
end

function BuildSubcommand:_get_target_resolvers()
  return self._internal_config:get_build_target_resolvers()
end

function BuildSubcommand:_get_default_target_resolver()
  local config = require('pesto.config')
  return config.DEFAULT_TARGET_RESOLVERS[config.DEFAULT_TARGET_RESOLVER_ID]
end

return BuildSubcommand
