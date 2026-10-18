load("//tools/build-rules:bazel_test_repo_fixture.bzl", "bazel_test_repo_fixture")
load("//tools/build-rules:nvim_plugin_e2e_test.bzl", "nvim_plugin_e2e_test")

nvim_plugin_e2e_test(
    name = "specs",
    srcs = [
        "bash_mode_cli_completion_spec.lua",
        "bazel_build_subcommand_spec.lua",
        "build_subcommand_spec.lua",
        "compile_one_dep_subcommand_spec.lua",
        "copy_last_bazel_command_subcommand_spec.lua",
        "default_runner_loader_spec.lua",
        # TODO: Fix this test; need to make uv binary available
        #"install_remote_apis_helpers_subcommand_spec.lua",
        "load_quickfix_subcommand_spec.lua",
        "lua_mode_cli_completion_spec.lua",
        "open_build_subcommands_spec.lua",
        "temp_bep_file_cleanup_spec.lua",
        "test_subcommand_spec.lua",
    ],
    data = [
        ":bazel_repo_fixture",
        "@uv//:uv"
    ],
    plugins = [
        "//:pesto.nvim",
        "//tools/fake-notify.nvim",
    ],
    deps = [
        "//lua/pesto/runner/default",
        "//lua/pesto/test",
        "//lua/pesto/util",
        "//tools/build-rules/lua/rules_nvim_lua/runfiles",
    ],
)

bazel_test_repo_fixture(
    name = "bazel_repo_fixture",
    srcs = glob([
        "bazel_repo_fixture/**/*",
    ]),
)
