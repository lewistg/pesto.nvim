load("@rules_scala//scala:scala.bzl", "scala_binary")

scala_binary(
    name = "main",
    srcs = ["Main.scala"],
    main_class = "com.example.Main",
    deps = [
        "//src/main/scala/com/example/routes",
        "@maven//:co_fs2_fs2_io_3",
        "@maven//:com_comcast_ip4s_core_3",
        "@maven//:org_http4s_http4s_dsl_3",
        "@maven//:org_http4s_http4s_ember_server_3_0_23_34",
        "@maven//:org_http4s_http4s_server_3",
        "@maven//:org_typelevel_cats_core_3_2_13_0",
        "@maven//:org_typelevel_cats_effect_3_3_7_0",
        "@maven//:org_typelevel_cats_effect_kernel_3",
        "@maven//:org_typelevel_log4cats_core_3_2_8_0",
        "@maven//:org_typelevel_log4cats_slf4j_3",
    ],
)
