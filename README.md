> [!WARNING]
> **Work in progress**
>
> This plugin is under active development but stable enough to try. Feel free
> to open an issue if you have feedback or encounter a bug.

# pesto.nvim: Neovim Bazel plugin

`pesto.nvim` is a Bazel runner plugin for Neovim.
It integrates with Bazel through the [Build Event Protocol](https://bazel.build/remote/bep) to support things like loading compilation errors into the quickfix list.

<div align="center">
  <video src="https://github.com/user-attachments/assets/78895432-2730-4e7d-9e96-f028638e4f4a">
</div>

## Features

* A `bazel` wrapper command with autocomplete support:
  - `:Pesto bazel <bazel-subcommand> [subcommand-args]`
* Integrates with the [Build Event Protocol](https://bazel.build/remote/bep)
  - Failed actions' stderr files are parsed and loaded into the quickfix list
  - A build summary window shows a high-level overview of successful and failed targets
* Quick navigation to BUILD or BUILD.bazel files

## Requirements

* Neovim 0.11.0 or later

## Installation

* Neovim's built-in plugin manager
```lua
vim.pack.add({
  'https://github.com/lewistg/pesto.nvim'
})
```
* `lazy.nvim`
```lua
{
  'lewistg/pesto.nvim',
  ---@type pesto.Settings
  opts = {},
  -- Pesto is lazy by default (see :h lua-plugin-lazy)
  lazy = false,
}
```

## Quick start

This repository includes a few example Bazel repositories in the `./examples` directory. 
You can use them to try out `pesto.nvim`.
Below is a suggested exercise using the example C project.

0. Make sure things are properly configured by running a health check on Pesto: `:checkhealth pesto`
    - The first two checks are the most important.
    You must have Neovim version >= 0.11.0, and Pesto needs a valid Bazel executable to run.
1. `cd` into `./examples/c-example`
2. Open up `./src/main.c`
3. Type `:Pesto bazel build :<Tab>`
    - The command should complete to `:Pesto bazel build :main`.
    The `//src` package has a `cc_binary` target named `main`.
4. Now press `<Enter>` to run the command.
    - A terminal buffer should open at the bottom of the window, and Bazel should execute the build.
5. After the build finishes, close the terminal by pressing `<Enter>`.
    - Similar to `:make`, Pesto adds the `<Enter>` keymap to quickly dismiss the build output terminal buffer.
6. Introduce some type of syntax error into `main.c` or some other source file (e.g., `ids.c`).
7. Instead of using the Bazel wrapper command, `:Pesto bazel`, command, this time try using the `:Pesto build` command.
     - For more information about this command see `:h pesto-build-command`

## Configuration

You don't need to call a `setup` function to configure `pesto.nvim`.
You can instead just set `vim.g.pesto`.
Here is the default configuration:

```lua
---@type pesto.Settings
vim.g.pesto = {
    --- Name of bazel binary that Pesto invokes. Should be on your `$PATH` or a
    --- path to an executable.
	bazel_executable = "bazel",
    -- Callback invoked to run bazel.
	bazel_runner = function(opts)
        require("pesto.components").default_runner(opts)
	end,
    --- Configuration for the `:Pesto build [target_resolver]` subcommand. Defines the possible pre-defined target queries
    build_target_resolvers = {
      --- These are the default resolvers. For more information see `:h pesto.Settings.build_target_resolvers`
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
    --- Logging level (see `:checkhealth pesto` to get the log file's path)
	log_level = "info",
    --- When set to true, Pesto will inject the `--build_event_json_file=$BEP_FILE`
    --- Bazel command line option. If you use the default runner, then following
    --- the build Pesto will parse the resulting build events tree and the quickfix
    --- list.
	enable_bep_integration = true,
    --- When this option is true and when you are using the default runner, a
    --- terminal buffer will be opened automatically when bazel is invoked.
	auto_open_build_term = true,
    --- This list is used to determine the errorformat string to use to parse the
    --- output of a failed action. It effectively defines a mapping from Bazel
    --- action mnemonics to errorformats.
    --- See the "Action errorformat" section below for details.
	errorformats = {},
    --- The default set of errorformats. Covers some of the major rule
    --- sets. You shouldn't need to override this.
    default_errorformats = {
      ...
    }
    --- This option is still in development. See the "Note about remote execution/caching" section below
	bytestream_client = nil,
    --- Configuration for the `:Pesto bazel` subcommand auto-completion
	cli_completion = {
        --- Completion strategy. There are three modes:
        --- * "bash": With this mode completion gets powered by the Bazel's own bash completion script (e.g., /etc/bash_completion.d/bazel)
        --- * "lua": A less sophisticated lua implementation of Bazel
        --- * "automatic": With this mode, we attempt to first use the bash completion script. If it's unavailable, then we fallback to the lua implementation.
		mode = "automatic",
        --- For the "bash" completion strategy, this is the amount of time to wait
        --- for the bash completion script to finish before timing out.
		bash_timeout = 15000,
        --- Absolute path to the bash completion script. If the setting is not defined,
        --- then Pesto falls back to searching for the script in `/etc/bash_completion.d/`
		bash_completion_script = nil,
	},
}
```

If you prefer, however, `pesto.nvim` does support a setup function:

```lua
---@type pesto.Settings
local settings = {...}
require("pesto").setup(settings)
```

### Action errorformat

Following a build, `pesto.nvim` parses the BEP output file, finds the failed build actions, and then uses `vim.fn.setqflist` to parse and load errors from the actions' stderr file into the quickfix list.
As a multi-language build tool, it's possible Bazel will report errors coming from multiple compilers for different languages at once.
How then do we pick which `errorformat` to use with `vim.fn.setqflist`?

In `pesto.nvim`'s configuration we we map action mnemonics to an `errorformat` configuration.
`pesto.nvim` will resolve which `errorformat` to use based on this mapping.


> [!NOTE]
>
> This errorformat configuration touches on some Bazel concepts that may be unfamiliar to casual Bazel users. 
> If that's you, then here is a quick rundown:
> * Most of the time a Bazel build involves the execution of rule targets. 
> * Rule targets spawn actions, such as invoking a compiler.
> * A rule target action has a name called the "mnemonic."
> * An action may produce output such as compiler errors written to stderr. Bazel captures this output to stderr and saves it as a build artifact, as a file stored in the build cache.
> * `pesto.nvim` discovers and processes these stderr files through the BEP output file.

Here is `pesto.nvim`'s default mapping:

```lua
vim.g.pesto = {
  ...
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
      errorformat = "%f:%l: %m"
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
  ...
}
```

Note how the default mapping already includes mappings for some of Bazel's standard rules (for Java and C/C++).
Add more as needed.
For a full explanation of the errorformat config and its types please see `:h pesto.Settings.errorformats`

## Commands

```viml
" This command is somewhat equivalent to `:!bazel <bazel-subcommand> [subcommand-args]`. 
" By default the Bazel command is run asyncronously in a terminal buffer.
" It supports auto-completion for targets.
:Pesto bazel <bazel-subcommand> [subcommand-args]

" Provides a way to quickly invoke a Bazel build without typing out a full bazel
" command. "Target resolvers" are user-defined callbacks that return either a
" target query or target pattern. For more info see `:h pesto-build-command`.
:Pesto build [target-resolver-id]

" Runs `bazel build --compile_one_dependency <current-file>`
:Pesto compile-one-dep

" Opens the `BUILD` or `BUILD.bazel` file for the current source file in a horizontal split.
:Pesto sp-build

" The same as the `sp-build` command but splits vertically.
:Pesto vs-build

" Yanks the label for the current source file's package.
:Pesto yank-package-label
```

## Note about remote execution/caching

> [!WARNING]
> **Work in progress**
>
> Pesto's default bytestream client is functional, but support for custom bytestream clients is still in progress.
> This section alludes to how they will work.

Mature Bazel setups will involve remote execution and remote caching.
This means compiler logs will sometimes be stored in a remote cache.
Pesto must fetch these logs in order to parse them and populate the quickfix list.

Remote caching services for Bazel serve assets, like the stderr logs, through gRPC-based APIs.

Since implementing a gRPC client in Lua would be a significant undertaking, Pesto delegates the remote log fetches to the configured "bytestream" client: `vim.g.pesto.bytestream_client`.

Pesto ships with its own [default bytestream client](tools/pesto-remote-apis-helpers/README.md) written in Python.
Pesto will prompt you to set up this client before attempting to use it the first time.

## Goals

* General purpose. Try to be useful for all Bazel rule sets.
* A solid (not perfect) command line experience for the `:Pesto bazel` sub-command.
* Somewhat low-level. Don't hide Bazel too much.
* Extendable.

## Similar plugins

Pesto was inspired by [vim-bazel](https://github.com/bazelbuild/vim-bazel), which has since been archived.
