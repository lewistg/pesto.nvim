# pesto.nvim

pesto.nvim integrates Neovim with Bazel to make the edit-build-test cycle more seamless.

## Features

* Construct and execute Bazel commands to build the file you're currently editing.
* Quickly navigate to BUILD or BUILD.bazel files.

## Commands

```viml
" This command is somewhat equivalent to `:!bazel <bazel-subcommand> [subcommand-args]`. 
" By default the Bazel command is run in a terminal buffer.
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

* A solid (not perfect) command line experience for the `:Pesto bazel` sub-command.
* Somewhat low-level. Don't hide Bazel too much.
* Leverage being Bazel-specific.
* Extendable.
