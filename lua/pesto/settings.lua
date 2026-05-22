local M = {}

--- Maps a rule's actions' mnemonics to either a errorformat string or compiler
--- plugin (which should in turn define a errorformat)
---@class pesto.ActionErrorformat
---
--- A lua string pattern
---@field action_mnemonic string|string[]
---
--- The compiler plugin that should define the errorformat to use for parsing
--- the action's stderr output.
---@field compiler string|nil
---
--- Errorformat string (:help errorformat)
---@field errorformat string|nil
---
--- Some compilers produce output with syntax highlighting using ANSI escape
--- codes. When `strip_escape_codes` is set to true, Pesto will strip out the
--- escape codes before parsing the errors for the quickfix window.
---@field strip_escape_codes boolean|nil

---@alias pesto.TargetResolverResult
---| {targets: string[]}
---| {query: string}

---@alias pesto.TargetResolver fun(context: pesto.RunBazelContext): pesto.TargetResolverResult

--- Map from a "target resolver ID" to a method that returns a Bazel target resolver.
---@alias pesto.BuildTargetResolvers {[string]: pesto.TargetResolver}

---@alias pesto.CliCompletionMode
---| "lua"
---| "bash"
---| "automatic"

---@class pesto.CliCompletionSettings
---
--- Completion strategy
---@field mode pesto.CliCompletionMode
---
--- For the "bash" completion strategy, this is the amount of time to wait
--- for the bash completion script to finish before timing out.
---@field bash_timeout number|nil Number of milliseconds to wait for bazel's bash completion script to reply
---
--- Absolute path to the bash completion script. If the setting is not defined,
--- then Pesto falls back to searching for the completion scripts defined in
--- pesto.InternalSettings.DEFAULT_BASH_COMPLETION_SCRIPTS.
---@field bash_completion_script string|nil

---@class pesto.Settings
---
--- Name of bazel binary that Pesto invokes. Should be on your `$PATH` or a
--- path to an executable.
---@field bazel_executable string
---
--- Callback invoked to run bazel.
---@field bazel_runner pesto.RunBazelFn Method invoked to run bazel.
---
-- Logging level (see `:checkhealth pesto` to get the log file's path).
---@field log_level string
---
--- When set to true, Pesto will inject the `--build_event_json_file=$BEP_FILE`
--- Bazel command line option. If you use the default runner, then following
--- the build Pesto will parse the resulting build events tree and the quickfix
--- list.
---@field enable_bep_integration boolean
---
--- When this option is true and when you are using the default runner, a
--- terminal buffer will be opened automatically when bazel is invoked.
---@field auto_open_build_term boolean
---
--- This list is used to determine the errorformat string to use to parse the
--- output of a failed action. It effectively defines a mapping from Bazel
--- action mnemonics to errorformats.
---@field errorformats pesto.ActionErrorformat[]
---
--- The default set of errorformats. Covers some of the major rule sets.
---@field default_errorformats pesto.ActionErrorformat[]
---
--- See pesto.ActionErrorformat.
---@field bytestream_client "pesto-python-remote-apis-helpers"|pesto.ByteStreamClient|nil
---
--- Configuration for the `:Pesto bazel` subcommand auto-completion
---@field cli_completion pesto.CliCompletionSettings
---
--- Configuration for the `:Pesto build [target_resolver]` subcommand. Defines the possible pre-defined target queries
---@field build_target_resolvers pesto.BuildTargetResolvers
---
--- The temporary directory to use. Useful for debugging.
---
--- By default Pesto uses vim.fn.tempname() to create a temporary directory for
--- its logs and working files. As a result, logs are automatically deleted
--- after the neovim closes. You can set this directory to pick a more
--- long-lived location.
---@field temp_dir string|nil

---@type string
M.SETTINGS_KEY = 'pesto'

---@type string[]
M.DEFAULT_BASH_COMPLETION_SCRIPTS = {
  vim.fs.joinpath('/etc/bash_completion.d', 'bazel'),
  vim.fs.joinpath('/etc/bash_completion.d', 'bazel-completion'),
}

---@type pesto.BuildTargetResolvers
M.DEFAULT_TARGET_RESOLVERS = {
  ['all'] = function(context)
    return {
      targets = { string.format('%s:all', context.package_label) },
    }
  end,
  ['tests'] = function(context)
    return {
      query = string.format('tests(%s:*)', context.package_label),
    }
  end,
}

M.DEFAULT_TARGET_RESOLVER_ID = 'all'

---@type pesto.Settings
M.DEFAULT_RAW_SETTINGS = {
  bazel_executable = 'bazel',
  bazel_runner = function(opts)
    require('pesto.components').default_runner(opts)
  end,
  build_target_resolvers = M.DEFAULT_TARGET_RESOLVERS,
  enable_bep_integration = true,
  auto_open_build_term = true,
  errorformats = {},
  default_errorformats = {
    -- rules_cc
    {
      action_mnemonic = 'CppCompile',
      compiler = 'gcc',
    },
    -- rules_go
    {
      action_mnemonic = 'GoCompilePkg',
      compiler = 'go',
    },
    -- rules_java
    {
      action_mnemonic = 'Javac',
      compiler = 'javac',
    },
    {
      action_mnemonic = 'Turbine',
      errorformat = '%f:%l: %m',
    },
    -- rules_rust
    {
      action_mnemonic = 'Rustc',
      compiler = 'rustc',
      strip_escape_codes = true,
    },
    -- rules_scala
    {
      action_mnemonic = 'Scalac',
      errorformat = table.concat({
        -- Scala 2 pattern
        '%f:%l:\\ error:\\ %m',
        -- Scala 3 patterns
        '--\\ [E%n]\\ %m:\\ %f:%l:%c%.%#',
        '--\\ %m:\\ %f:%l:%c%.%#',
      }, ','),
      strip_escape_codes = true,
    },
  },
  -- WIP
  bytestream_client = nil,
  cli_completion = {
    mode = 'automatic',
    bash_timeout = 15000,
    bash_completion_script = nil,
  },
  log_level = 'info',
}

return M
