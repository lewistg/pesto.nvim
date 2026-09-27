load("//tools/build-rules:nvim_lua_library.bzl", "nvim_lua_library")

nvim_lua_library(
    name = "pesto",
    srcs = glob(["*.lua"]),
    lua_path_root = "//lua",
    visibility = [
        "//lua:__subpackages__",
        "//plugin:__subpackages__",
        "//test:__subpackages__",
    ],
    deps = [
        "//lua/pesto/bazel",
        "//lua/pesto/cli",
        "//lua/pesto/cli/bazel_bash_completion",
        "//lua/pesto/runner",
        "//lua/pesto/runner/default",
        "//lua/pesto/runner/quickfix",
        "//lua/pesto/test",
        "//lua/pesto/util",
    ],
)
