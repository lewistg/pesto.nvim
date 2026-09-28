load("//tools/build-rules:bazel_test_repo_fixture.bzl", "bazel_test_repo_fixture")
load("//tools/build-rules:nvim_plugin_e2e_test.bzl", "nvim_plugin_e2e_test")

nvim_plugin_e2e_test(
    name = "specs",
    srcs = [
        "bash_mode_cli_completion_spec.lua",
    ],
    data = [
        ":bazel_repo_fixture",
    ],
    plugins = [
        "//:pesto.nvim",
    ],
    deps = [
        "//lua/pesto/test",
        "//tools/build-rules/lua/rules_nvim_lua/runfiles",
    ],
)

bazel_test_repo_fixture(
    name = "bazel_repo_fixture",
    srcs = glob([
        "bazel_repo_fixture/**/*",
    ]),
)
