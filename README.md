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
* Quality of life commands:
  - Open split to BUILD or BUILD.bazel files
  - Yank label for the current source file's Bazel package

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
    --- Please see `:help pesto.Settings.build_target_resolvers` for more details.
    build_target_resolvers = {
      ...
    }
    --- Logging level (see `:checkhealth pesto` to get the log file's path)
	log_level = "info",
    --- Indicates which logs Pesto should use to populate the quickfix window
    --- following a build.
    quickfix_log_source = "bep",
    --- When set to true, Pesto will inject the `--build_event_json_file=$BEP_FILE`
    --- Bazel command line option. If you use the default runner, then following
    --- the build Pesto will parse the resulting build events tree and the quickfix
    --- list.
	enable_bep_integration = true,
    --- When this option is true and when you are using the default runner, a
    --- terminal buffer will be opened automatically when bazel is invoked.
	auto_open_build_term = true,
    --- This list is used to determine the errorformat string used to parse the
    --- output of a failed action. It effectively defines a mapping from Bazel
    --- action mnemonics to errorformats.
    --- See the "Quickfix integration" section below for details.
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

### Quickfix integration

One of `pesto.nvim`'s key features is loading build errors into the quickfix list.

Here's how it works at a high-level:

1. Following a build, `pesto.nvim` finds the logs for failed build actions.
2. To load the errors into the quickfix list, `pesto.nvim` needs an `errorformat` string to parse the logs.
`pesto.nvim` handles this by defining a mapping from action mnemonic to `errorformat` string.
    - `pesto.nvim` comes with a default mapping for some of the more popular rule sets (`:help pesto.Settings.default_errorformats`) but also lets users extend this mapping through the `pesto.Settings.errorformats` config setting.

If you're new to Bazel and the terms "action" and "action mnemonic" are new to you, please see `:help pesto-bazel-concepts` for a quick primer on these Bazel concepts.

## Commands

This list shows a subset of the commands. For a full list see `:help pesto-commands`.

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

" Commands to open the `BUILD` or `BUILD.bazel` file for the current source
" file in a horizontal or vertical split.
:Pesto sp-build
:Pesto vs-build

" Yanks the label for the current source file's package.
:Pesto yank-package-label

" Load the quickfix list using a BEP JSON file generated elsewhere (perhaps by
" your CI/CD pipeline).
:Pesto load-quickfix <bep-json-file>
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
