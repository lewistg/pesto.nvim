# pesto.nvim

pesto.nvim integrates Neovim with Bazel to make the edit-build-test cycle more seamless.

## Features

* Construct and execute bazel commands to build the file you're currently editing.
* Quickly navigate to BUILD or BUILD.bazel files.

## Commands

| Command | Description| 
| --- | --- |
| `:Pesto bazel <bazel-subocommand>` | This command is somewhat equivalent to `:!bazel <bazel-subcommand>`. By default the bazel command is run in a terminal buffer. |
| `:Pesto sp-build` | Opens the `BUILD` or `BUILD.bazel` file for the current source file in a horizontal split. |
| `:Pesto vs-build` | The same as the `sp-build` command but splits vertically. |
| `:Pesto yank-package-label` | Yanks the label for the current source file's package. |

## Goals

* A solid (not perfect) command line experience for the `bazel` sub-command.
* Somewhat low-level. Don't hide bazel too much.
* Leverage being bazel-specific.
* Extendable.
