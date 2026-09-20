load("//tools/build-rules:nvim_lua_test.bzl", "nvim_lua_test")

nvim_lua_test(
    name = "specs",
    srcs = glob([
        "*_spec.lua",
    ]),
    deps = [
        "//lua/pesto/cli/bazel_bash_completion",
        "//lua/pesto/cli/bazel_bash_completion/test",
    ],
)
