> [!WARNING]
> **Work in progress**
>
> This plugin is currently under active development.

# pesto.nvim: Neovim Bazel plugin

`pesto.nvim` is a Bazel runner plugin for Neovim.
It aims to make the edit-build-test cycle more seamless.

## Features

* A `bazel` wrapper command with autocomplete support:
  - `:Pesto bazel <bazel-subcommand> [subcommand-args]`
* Integrates with the [Build Event Protocol](https://bazel.build/remote/bep)
  - Failed actions' stderr files are parsed and loaded into the quickfix list
  - A build summary window shows a high-level overview of successful and failed targets
* Quick navigation to BUILD or BUILD.bazel files

## Requirements

* Neovim 0.11.0 or later

## Quick start

This repository includes a few example Bazel repositories in the `./examples` directory. 
You can use them to try out `pesto.nvim`.
Below is a suggested exercise using the example C project.

If you experience an error, try checking `pesto.nvim`'s health (`:checkhealth pesto`).
The health check should also point you to `pesto.nvim`'s log file where you may find lower-level information.

1. Go into `./examples/c-example`
2. Open up `./examples/c-example/src/main.c`
3. Try the `:Pesto compile-one-dep` command
    - You should see a terminal window pop up with Bazel's output.
4. Close the build terminal and go back to `main.c`.
5. Introduce some type of syntax error
6. This time instead of using `compile-one-dep`, let's build using the `bazel` subcommand. Enter the following:
    ```
    :Pesto bazel build :<TAB>
    ```
    Once you hit tab, it should autocomplete to be:
    ```
    :Pesto bazel build :main
    ```
    Press `<ENTER>` to trigger the build
    - This time you'll see the build terminal open, but afterwards the quickfix window should load with the error.

## Configuration

You don't need to call a `setup` function to configure `pesto.nvim`.
You can instead just set `vim.g.pesto`.
Here is the default configuration:

```lua
---@type pesto.Settings
vim.g.pesto = {
    -- Name of bazel binary that Pesto invokes. Should be on your $PATH.
	bazel_command = "bazel",
    -- Callback invoked to run bazel.
	bazel_runner = function(opts)
        require("pesto.components").default_runner(opts)
	end,
    -- Logging level (see `:checkhealth pesto` to get the log file's path)
	log_level = "info",
    --- When set to true, Pesto will inject the `--build_event_json_file=$BEP_FILE`
    --- Bazel command line option. If you use the default runner, then following
    --- the build Pesto will parse the resulting build events tree and the quickfix
    --- list.
	enable_bep_integration = true,
    --- When this option is true and when you are using the default runner, a
    --- terminal buffer will be opened automatically when bazel is invoked.
	auto_open_build_term = true,
    --- Maps a (rule kind pattern, action mnemonic pattern)
    --- pair to an errorformat string or compiler plugin name. Note that
    --- the pesto.RuleActionErrorformats.rule_kind field is interpreted as a lua
    --- string pattern.
    --- See the "Action errorformat" section below for details.
	errorformats = {
       ...
	},
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

### Action errorformat

Following a build, `pesto.nvim` parses the BEP output file, finds the failed build actions, and then uses `vim.fn.setqflist` to parse and load errors from the actions' stderr file into the quickfix list.
As a multi-language build tool, it's possible Bazel will report errors coming from multiple compilers for different languages at once.
How then do we pick which `errorformat` to use with `vim.fn.setqflist`?

In `pesto.nvim`'s configuration we are able to map rule kind and action mnemonic pairs to an `errorformat` configuration (`(rule_kind, action_mnemonic) -> errrorformat`).
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
	errorformats = {
		{
			rule_kind = "java_*",
			action_errorformats = {
				{
					action_mnemonic = "Javac",
					compiler = "javac",
				},
			},
		},
		{
			rule_kind = "cc_*",
			action_errorformats = {
				{
					action_mnemonic = "CppCompile",
					compiler = "gcc",
				},
			},
		},
	},
    ...
}
```

Note how the default mapping already includes mappings for some of Bazel's standard rules (for Java and C/C++).
The Java Bazel rules include the rule kinds `java_binary` and `java_library`.
Note also that our `errorformats` mapping matches on Java rules using a Lua string pattern: `java_*`, which will match with both rules of kind `java_binary` and `java_library`.
Then any failed actions with the mnemonic `Javac` will be parsed and processed by the errorformat defined by Neovim's `javac` compiler plugin (`:help compiler`).

## Commands

```viml
" This command is somewhat equivalent to `:!bazel <bazel-subcommand> [subcommand-args]`. 
" By default the Bazel command is run asyncronously in a terminal buffer.
" It supports auto-completion for targets.
:Pesto bazel <bazel-subcommand> [subcommand-args]

" Runs `bazel build --compile_one_dependency <current-file>`
:Pesto compile-one-dep

" Opens the `BUILD` or `BUILD.bazel` file for the current source file in a horizontal split.
:Pesto sp-build

" The same as the `sp-build` command but splits vertically.
:Pesto vs-build

" Yanks the label for the current source file's package.
:Pesto yank-package-label
```

## Goals

* General purpose. Try to be useful for all Bazel rule sets.
* A solid (not perfect) command line experience for the `:Pesto bazel` sub-command.
* Somewhat low-level. Don't hide Bazel too much.
* Extendable.
