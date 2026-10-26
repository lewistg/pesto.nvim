load("//tools/rules_nvim_lua:defs.bzl", "nvim_lua_library")

nvim_lua_library(
    name = "runner",
    srcs = ["init.lua"],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        "//tools/rules_nvim_lua/lua/rlocation",
        "//tools/rules_nvim_lua/lua/rules_nvim_test/suite",
    ],
)

exports_files(["entry_point.lua"])
