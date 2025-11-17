# pesto.nvim

pesto.nvim is a Bazel runner plugin for Neovim.
It aims to make the edit-build-test cycle more seamless.

## Features

* A bazel wrapper command (`:pesto bazel <bazel-subcommand> [subcommand-args]`) with autocomplete support
* Integrates with the [Build Event Protocol](https://bazel.build/remote/bep) (BEP)
  - Failed actions' stderr files are parsed and loaded into the quickfix list
  - A build summary window shows a high-level overview of successful and failed targets
* Quick navigation to BUILD or BUILD.bazel files

## Configuration

### Action errorformat

Following a build, pesto.nvim parses the BEP output file, finds the failed build actions, and then uses `vim.fn.setqflist` to parse and load errors from the actions' stderr file into the quickfix list.
As a multi-language build tool, it's possible Bazel will report errors coming from multiple compilers for different languages at once.
How then do we pick which `errorformat` to use with `vim.fn.setqflist`?

In pesto.nvim's configuration we are able to map rule kind and action mnemonic pairs to an `errorformat` configuration (`(rule_kind, action_mnemonic) -> errrorformat`).
pesto.nvim will resolve which `errorformat` to use based on this mapping.

> **Note:** This errorformat configuration touches on some Bazel concepts that may be unfamiliar to casual Bazel users. 
> If that's you, then here is a quick rundown:
> * Most of the time a Bazel build involves the execution of rule targets. 
> * Rule targets spawn actions, such as invoking a compiler.
> * A rule target action has a name called the "mnemonic."
> * An action may produce output such as compiler errors written to stderr. Bazel captures this output to stderr and saves it as a build artifact, as a file stored in the build cache.
> * pesto.nvim discovers and processes these stderr files through the BEP output file.

Here is pesto.nvim's default mapping:

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
