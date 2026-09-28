load("@bazel_skylib//lib:paths.bzl", "paths")

def _bazel_test_repo_fixture_impl(ctx):
    repo_root = ctx.actions.declare_directory(ctx.label.name)

    src_repo_root = paths.join(ctx.label.package, ctx.label.name)
    src_and_dest_paths = []
    for file in ctx.files.srcs:
        if not file.short_path.startswith(src_repo_root):
            fail("{0} is not underneath {1}".format(file.short_path, src_repo_root))
        relative_path = paths.relativize(file.short_path, src_repo_root)

        src_and_dest_paths.append(file.short_path)

        dest_path = paths.join(repo_root.path, relative_path)
        if dest_path.endswith(".test"):
            dest_path = dest_path.replace(".test", "")
        src_and_dest_paths.append(dest_path)

    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [repo_root],
        command = """
        set -x

        repo_root="$1"
        shift

        echo "$repo_root"

        mkdir -p "$repo_root"

        src_and_dest_paths=("$@")
        for ((i = 0; i < ${#src_and_dest_paths[@]}; i += 2)); do
            src_path="${src_and_dest_paths[$i]}"
            dest_path="${src_and_dest_paths[$((i + 1))]}"
            mkdir -p "$(dirname "$dest_path")"
            cp "$src_path" "$dest_path"
        done
        """,
        arguments = [repo_root.basename] + src_and_dest_paths,
    )

    return [
        DefaultInfo(files = depset([repo_root])),
    ]

bazel_test_repo_fixture = rule(
    implementation = _bazel_test_repo_fixture_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            allow_empty = False,
        ),
    },
)
