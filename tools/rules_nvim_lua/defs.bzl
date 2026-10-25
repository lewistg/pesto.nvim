load("//tools/rules_nvim_lua/private:nvim_lua_binary.bzl", _nvim_lua_binary = "nvim_lua_binary")
load("//tools/rules_nvim_lua/private:nvim_lua_test.bzl", _nvim_lua_test = "nvim_lua_test")
load("//tools/rules_nvim_lua/private:nvim_lua_library.bzl", _nvim_lua_library = "nvim_lua_library")
load("//tools/rules_nvim_lua/private:nvim_lua_path_root.bzl", _nvim_lua_path_root = "nvim_lua_path_root")

nvim_lua_binary = _nvim_lua_binary

nvim_lua_test = _nvim_lua_test

nvim_lua_library = _nvim_lua_library

nvim_lua_path_root = _nvim_lua_path_root
