load("//tools/build-rules:nvim_lua_library.bzl", "nvim_lua_library")

nvim_lua_library(
    name = "test_suite",
    srcs = glob(["*.lua"]),
    lua_path_root = "//tools/build-rules/lua",
    visibility = [
        "//visibility:public",
    ],
)
