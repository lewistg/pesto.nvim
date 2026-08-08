load("//tools/build-rules:nvim_lua_library.bzl", "nvim_lua_library")

nvim_lua_library(
    name = "test_suite",
    srcs = glob(["*.lua"]),
    visibility = [
        "//tools/build-rules/lua/rules_nvim_lua:__subpackages__",
    ],
)
