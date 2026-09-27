load("//tools/build-rules:nvim_lua_library.bzl", "nvim_lua_library")

nvim_lua_library(
    name = "cli",
    srcs = glob(["*.lua"]),
    lua_path_root = "//lua",
    visibility = [
        "//lua:__subpackages__",
        "//test:__subpackages__",
    ],
    deps = [
        "//lua/pesto/bazel",
        "//lua/pesto/config",
        "//lua/pesto/logger",
        "//lua/pesto/runner",
        "//lua/pesto/util",
    ],
)
