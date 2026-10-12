load("//tools/build-rules:nvim_lua_library.bzl", "nvim_lua_library")

nvim_lua_library(
    name = "test",
    srcs = glob(["*.lua"]),
    lua_path_root = "//lua",
    visibility = [
        "//lua:__subpackages__",
        "//test:__subpackages__",
    ],
    deps = [
        "//lua/pesto/util",
        "//tools/build-rules/lua/rules_nvim_lua/test/test_suite",
    ],
)
