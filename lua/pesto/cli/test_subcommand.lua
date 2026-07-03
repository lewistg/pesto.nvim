local BazelShortcutSubcommand = require('pesto.cli.bazel_shortcut_subcommand')

---@class pesto.TestSubcommand: pesto.BazelShortcutSubcommand
---@field private _internal_config pesto.InternalConfig
---@field private _internal_run_bazel_fn pesto.InternalRunBazelFn
local TestSubcommand = setmetatable({}, BazelShortcutSubcommand)
TestSubcommand.__index = TestSubcommand

TestSubcommand.name = 'test'

---@param internal_run_bazel_fn pesto.InternalRunBazelFn
---@param internal_config pesto.InternalConfig
---@return pesto.TestSubcommand
function TestSubcommand.new(internal_run_bazel_fn, internal_config)
  local o = {}

  BazelShortcutSubcommand.new(o, 'test', internal_run_bazel_fn, internal_config)
  o = setmetatable(o, TestSubcommand)

  return o
end

function TestSubcommand:_get_target_resolvers()
  return self._internal_config:get_build_target_resolvers()
end

function TestSubcommand:_get_default_target_resolver()
  local config = require('pesto.config')
  return config.DEFAULT_TARGET_RESOLVERS[config.DEFAULT_TEST_TARGET_RESOLVER_ID]
end

return TestSubcommand
