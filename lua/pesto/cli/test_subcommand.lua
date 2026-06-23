local BazelShortcutSubcommand = require('pesto.cli.bazel_shortcut_subcommand')

---@class pesto.TestSubcommand: pesto.BazelShortcutSubcommand
---@field private _settings pesto.InternalSettings
---@field private _internal_run_bazel_fn pesto.InternalRunBazelFn
local TestSubcommand = setmetatable({}, BazelShortcutSubcommand)
TestSubcommand.__index = TestSubcommand

TestSubcommand.name = 'test'

---@param internal_run_bazel_fn pesto.InternalRunBazelFn
---@param settings pesto.InternalSettings
---@return pesto.TestSubcommand
function TestSubcommand.new(internal_run_bazel_fn, settings)
  local o = {}

  BazelShortcutSubcommand.new(o, 'test', internal_run_bazel_fn, settings)
  o = setmetatable(o, TestSubcommand)

  return o
end

function TestSubcommand:_get_target_resolvers()
  return self._settings:get_build_target_resolvers()
end

function TestSubcommand:_get_default_target_resolver()
  local settings = require('pesto.settings')
  return settings.DEFAULT_TARGET_RESOLVERS[settings.DEFAULT_TEST_TARGET_RESOLVER_ID]
end

return TestSubcommand
