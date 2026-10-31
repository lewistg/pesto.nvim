load("//tools/rules_nvim_lua:defs.bzl", "nvim_lua_library")

nvim_lua_library(
    name = "util",
    srcs = glob(["*.lua"]),
    visibility = [
        "//test/spec/unit/util:__subpackages__",
    ],
)
