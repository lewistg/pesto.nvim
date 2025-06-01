#!/usr/bin/bash

set -euo pipefail

# Ignore local config
export XDG_CONFIG_HOME='test/xdg/config'
export XDG_STATE_HOME='test/xdg/local/state'
export XDG_DATA_HOME='test/xdg/local/share'

# Isolate the plugin
plugin_symlink="$XDG_DATA_HOME/nvim/site/pack/pesto/start/pesto.nvim"
rm -f "$plugin_symlink"
ln -s "$(realpath .)" "$plugin_symlink"

# This makes the busted library importable by the nvim interpreter
# See :help lua-package-path
eval $(luarocks path --lua-version 5.1 --bin)

nvim -l $@ &
wait

rm "$plugin_symlink"
