load("//tools/rules_nvim_lua/private:nvim_lua_binary.bzl", _nvim_lua_binary = "nvim_lua_binary")
load("//tools/rules_nvim_lua/private:nvim_lua_test.bzl", _nvim_lua_test = "nvim_lua_test")

nvim_lua_binary = _nvim_lua_binary

nvim_lua_test = _nvim_lua_test
