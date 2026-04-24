load("@rules_scala//scala:scala.bzl", "scala_library")

scala_library(
    name = "routes",
    srcs = glob(["*.scala"]),
    deps = [
        "@maven//:org_http4s_http4s_core_3_0_23_34",
        "@maven//:org_http4s_http4s_dsl_3_0_23_34",
        "@maven//:org_typelevel_cats_core_3_2_13_0",
        "@maven//:org_typelevel_cats_effect_3_3_7_0",
        "@maven//:org_typelevel_cats_effect_kernel_3_3_7_0",
    ],
    visibility = [
        "//src:__subpackages__"
    ]
)
