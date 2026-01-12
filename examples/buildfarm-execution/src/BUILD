cc_binary(
    name = "main",
    srcs = [
        "digit_num.c",
        "digit_num.h",
        "ids.h",
        "ids.c",
        "main.c",
    ],
    args = [
        # "$(rootpath //data:input)"
        "$(rootpath //data:test-input)"
    ],
    data = [
        # "//data:input"
        "//data:test-input"
    ],
    deps = [
        "@bazel_tools//tools/cpp/runfiles",
    ]
)
