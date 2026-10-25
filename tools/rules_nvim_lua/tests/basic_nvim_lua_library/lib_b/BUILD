load("//tools/rules_nvim_lua/private:nvim_lua_library.bzl", "nvim_lua_library")

nvim_lua_library(
    name = "lib_b",
    srcs = ["b.lua"],
    visibility = ["//tools/rules_nvim_lua/tests/basic_nvim_lua_library:__subpackages__"],
    deps = [
        "//tools/rules_nvim_lua/tests/basic_nvim_lua_library/lib_c",
    ],
)
