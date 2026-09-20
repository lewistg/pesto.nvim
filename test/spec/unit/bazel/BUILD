load("//tools/build-rules:bazel_test_repo_fixture.bzl", "bazel_test_repo_fixture")
load("//tools/build-rules:nvim_lua_test.bzl", "nvim_lua_test")

nvim_lua_test(
    name = "specs",
    srcs = glob([
        "*_spec.lua",
    ]),
    data = [
        ":build_event_tree_spec_fixtures",
        ":package_spec_fixtures",
        ":repo_spec_example_repo_fixture",
    ],
    deps = [
        "//lua/pesto/bazel",
        "//lua/pesto/util",
        "//tools/build-rules/lua/rules_nvim_lua/runfiles",
    ],
)

bazel_test_repo_fixture(
    name = "package_spec_fixtures",
    srcs = glob([
        "package_spec_fixtures/**/*",
    ]),
)

bazel_test_repo_fixture(
    name = "repo_spec_example_repo_fixture",
    srcs = glob([
        "repo_spec_example_repo_fixture/**/*",
    ]),
)

filegroup(
    name = "build_event_tree_spec_fixtures",
    srcs = glob([
        "build_event_tree_spec_fixtures/**/*",
    ]),
)
