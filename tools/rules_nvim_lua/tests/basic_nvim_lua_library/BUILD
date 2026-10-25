load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("//tools/rules_nvim_lua:defs.bzl", "nvim_lua_binary", "nvim_lua_path_root")

nvim_lua_path_root(
    name = "lua_path_root",
)

nvim_lua_binary(
    name = "basic_nvim_lua_library",
    entry_point = "main.lua",
    lua_path_roots = [":lua_path_root"],
    deps = [
        "//tools/rules_nvim_lua/tests/basic_nvim_lua_library/lib_a",
        "//tools/rules_nvim_lua/tests/basic_nvim_lua_library/lib_b",
    ],
)

sh_test(
    name = "test",
    srcs = ["test.sh"],
    data = [":basic_nvim_lua_library"],
)
