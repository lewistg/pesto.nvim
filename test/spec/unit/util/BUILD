load("//tools/rules_nvim_lua:defs.bzl", "nvim_lua_test")

nvim_lua_test(
    name = "specs",
    srcs = glob([
        "*.lua",
    ]),
    lua_path_roots = [
        "//lua:lua_path_root",
    ],
    deps = [
        "//lua/pesto/util",
    ],
)
