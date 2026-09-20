load("//tools/build-rules:nvim_lua_library.bzl", "nvim_lua_library")

nvim_lua_library(
    name = "bazel",
    srcs = glob(["*.lua"]),
    lua_path_root = "//lua",
    visibility = [
        "//lua:__subpackages__",
        "//test:__subpackages__",
    ],
)
