load("@rules_java//java:java_binary.bzl", "java_binary")

java_binary(
    name = "aoc",
    srcs = glob(["src/main/java/com/example/aoc/*.java"]),
    main_class = "com.example.aoc.Day18",
    deps = [
        "//src/main/java/com/example/grid",
    ]
)
