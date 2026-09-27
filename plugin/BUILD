load("//tools/build-rules:nvim_lua_library.bzl", "nvim_lua_library")
load("//tools/build-rules:nvim_lua_path_root.bzl", "nvim_lua_path_root")

nvim_lua_library(
    name = "plugin",
    srcs = glob(["*.lua"]),
    lua_path_root = ":dummy_root",
    visibility = [
        "//visibility:public",
    ],
    deps = [
        "//lua/pesto",
    ],
)

nvim_lua_path_root(
    name = "dummy_root",
    visibility = [
        "//visibility:public",
    ],
)
