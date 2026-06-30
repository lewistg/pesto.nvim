local BazelShortcutSubcommand = require('pesto.cli.bazel_shortcut_subcommand')

---@class pesto.BuildSubcommand: pesto.BazelShortcutSubcommand
---@field private _settings pesto.InternalSettings
---@field private _internal_run_bazel_fn pesto.InternalRunBazelFn
local BuildSubcommand = setmetatable({}, BazelShortcutSubcommand)
BuildSubcommand.__index = BuildSubcommand

BuildSubcommand.name = 'build'

---@param internal_run_bazel_fn pesto.InternalRunBazelFn
---@param settings pesto.InternalSettings
---@return pesto.BuildSubcommand
function BuildSubcommand.new(internal_run_bazel_fn, settings)
  local o = {}

  BazelShortcutSubcommand.new(o, 'build', internal_run_bazel_fn, settings)
  o = setmetatable(o, BuildSubcommand)

  return o
end

function BuildSubcommand:_get_target_resolvers()
  return self._settings:get_build_target_resolvers()
end

function BuildSubcommand:_get_default_target_resolver()
  local settings = require('pesto.settings')
  return settings.DEFAULT_TARGET_RESOLVERS[settings.DEFAULT_TARGET_RESOLVER_ID]
end

return BuildSubcommand
