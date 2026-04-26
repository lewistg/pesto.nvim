load("@rules_scala//scala:scala_toolchain.bzl", "scala_toolchain")

scala_toolchain(
    name = "pesto_scala_toolchain_impl",
    # See: https://github.com/bazel-contrib/rules_scala/blob/master/docs/dependency-tracking.md
    dependency_mode = "plus-one",
    strict_deps_mode = "error",
    unused_dependency_checker_mode = "error",
    visibility = ["//visibility:public"],
)

toolchain(
    name = "pesto_scala_toolchain",
    toolchain = ":pesto_scala_toolchain_impl",
    toolchain_type = "@rules_scala//scala:toolchain_type",
    visibility = ["//visibility:public"],
)
