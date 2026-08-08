load("//tools/build-rules:nvim_lua_library.bzl", "nvim_lua_library")

nvim_lua_library(
    name = "runner",
    srcs = ["init.lua"],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        "//tools/build-rules/lua/rules_nvim_lua/test/test_suite",
    ],
)

exports_files(["init.lua"])
