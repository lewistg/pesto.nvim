load("//tools/build-rules:nvim_lua_test.bzl", "nvim_lua_test")

nvim_lua_test(
    name = "specs",
    srcs = glob([
        "*_spec.lua",
    ]),
    lua_path_roots = [
        "//lua",
    ],
    deps = [
        "//lua/pesto/util",
    ],
)
