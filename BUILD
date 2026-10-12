load("//tools/build-rules:nvim_plugin.bzl", "nvim_plugin")

nvim_plugin(
    name = "pesto.nvim",
    lua = [
        "//plugin",
    ],
    support_files = [
        "//tools/pesto-bash-helpers",
        "//tools/pesto-remote-apis-helpers",
    ],
    visibility = [
        "//visibility:public",
    ],
)
