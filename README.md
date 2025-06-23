# pesto.nvim

pesto.nvim integrates Neovim with Bazel.

## Design goals

* A solid command line experience for the `bazel` sub-command.
The goal is to facilitate the edit-build-edit cycle for bazel projects.
The non-goal here is achieving complete parity with bazel's native command line interface.
* Provide bazel-specific features.
The goal here is to provide features that take advantage of being bazel-specific.
Neomake is a build-tool agnostic Neovim plugin.
If all plugin user's do is run `bazel build` 
* Extendable.
Especially when it comes to running bazel commands through pesto.nvim's `bazel` subcommand, plugin users should be able to extend or modify the experience provided by pesto.nvim.
