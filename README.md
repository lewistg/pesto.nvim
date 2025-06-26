# pesto.nvim

pesto.nvim integrates Neovim with Bazel.

## Usage

pesto.nvim is aware of the package for the source file you're currently editing, and provides auto-completion behavior to quickly build package targets.

## Commands

| Command | Description| 
| --- | --- |
| `Pesto bazel <bazel-subocommand>` | This command is somewhat equivalent to `:!bazel <bazel-subcommand>`. By default the bazel command is run in a terminal buffer. |
| `Pesto sp-build` | Opens the `BUILD` or `BUILD.bazel` file for the current source file in a horizontal split. |
| `Pesto vs-build` | The same as the `sp-build` command but splits vertically. |
| `Pesto yank-package-label` | Yanks the label for the current source file's package. |

## Goals

* A solid (not perfect) command line experience for the `bazel` sub-command.
* Somewhat low-level. Don't hide bazel too much.
* Leverage being bazel-specific.
* Extendable
