local M = {}

--- Maps a rule's actions' mnemonics to either a errorformat string or compiler
--- plugin (which should in turn define a errorformat)
---@class pesto.ActionErrorformat
---
--- A lua string pattern
---@field action_mnemonic string
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

---@class pesto.RuleActionErrorformats
---@field rule_kind string A lua string pattern
---@field action_errorformats pesto.ActionErrorformat[]

--- Map from a "query ID" to a method that returns Bazel query
---@alias pesto.BuildQueries {[string]: fun(context: pesto.RunBazelContext): string}

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
--- Name of bazel binary that Pesto invokes. Should be on your $PATH.
---@field bazel_command string
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
--- Maps a (rule kind pattern, action mnemonic pattern)
--- pair to an errorformat string or compiler plugin name. Note that
--- the pesto.RuleActionErrorformats.rule_kind field is interpreted as a lua
--- string pattern.
---@field errorformats pesto.RuleActionErrorformats[]
---
--- See pesto.RuleActionErrorformats and pesto.ActionErrorformat.
---@field bytestream_client "pesto-python-remote-apis-helpers"|pesto.ByteStreamClient|nil
---
--- Configuration for the `:Pesto bazel` subcommand auto-completion
---@field cli_completion pesto.CliCompletionSettings
---
--- Configuration for the `:Pesto build [query_id]` subcommand. Defines the possible pre-defined target queries
---@field build_queries pesto.BuildQueries

---@type string
M.SETTINGS_KEY = 'pesto'

---@type string[]
M.DEFAULT_BASH_COMPLETION_SCRIPTS = {
  vim.fs.joinpath('/etc/bash_completion.d', 'bazel'),
  vim.fs.joinpath('/etc/bash_completion.d', 'bazel-completion'),
}

---@type pesto.BuildQueries
M.DEFAULT_BUILD_QUERIES = {
  ['all'] = function(context)
    return string.format('kind(rule, %s:all)', context.package_label)
  end,
  ['tests'] = function(context)
    return string.format('tests(%s:*)', context.package_label)
  end,
}

---@type pesto.Settings
M.DEFAULT_RAW_SETTINGS = {
  bazel_command = 'bazel',
  bazel_runner = function(opts)
    require('pesto.components').default_runner(opts)
  end,
  log_level = 'info',
  enable_bep_integration = true,
  auto_open_build_term = true,
  errorformats = {
    {
      rule_kind = 'cc_*',
      action_errorformats = {
        {
          action_mnemonic = 'CppCompile',
          compiler = 'gcc',
        },
      },
    },
    {
      rule_kind = 'go_*',
      action_errorformats = {
        {
          action_mnemonic = 'GoCompilePkg',
          compiler = 'go',
        },
      },
    },
    {
      rule_kind = 'java_*',
      action_errorformats = {
        {
          action_mnemonic = 'Javac',
          compiler = 'javac',
        },
      },
    },
    {
      rule_kind = 'rust_*',
      action_errorformats = {
        {
          action_mnemonic = 'Rustc',
          compiler = 'rustc',
          strip_escape_codes = true,
        },
      },
    },
    {
      rule_kind = 'scala_*',
      action_errorformats = {
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
    },
  },
  bytestream_client = nil,
  cli_completion = {
    mode = 'automatic',
    bash_timeout = 15000,
    bash_completion_script = nil,
  },
  build_queries = M.DEFAULT_BUILD_QUERIES,
}

return M
