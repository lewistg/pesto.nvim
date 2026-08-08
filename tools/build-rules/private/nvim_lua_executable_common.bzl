load("@bazel_skylib//lib:paths.bzl", "paths")
load("//tools/build-rules/private:nvim_lua_info.bzl", "NvimLuaInfo")
load("//tools/build-rules/private:nvim_lua_path_root_info.bzl", "NvimLuaPathRootInfo")

def nvim_lua_executable_rule_impl(
        ctx,
        nvim_bin,
        entry_point,
        entry_point_args,
        lua_path_roots,
        srcs,
        deps,
        run_files_lib):
    nvim_runner_file = ctx.actions.declare_file("nvim_runner.sh")

    nvim_bin_path = ctx.workspace_name + "/" + entry_point.short_path

    all_sources = depset(srcs, transitive = [dep[NvimLuaInfo].sources for dep in deps])

    srcs_by_lua_root_dirs = _get_srcs_by_lua_root_dirs(lua_path_roots, all_sources)
    lua_root_dirs = _create_lua_root_dirs(ctx, srcs_by_lua_root_dirs)

    lua_path_root_dirs = _get_lua_root_dirs(lua_path_roots)

    runfiles = ctx.runfiles([nvim_bin] + all_sources.to_list() + lua_root_dirs + [entry_point])

    # Make the rlocation library available
    runfiles = runfiles.merge(run_files_lib[DefaultInfo].default_runfiles)

    ctx.actions.expand_template(
        output = nvim_runner_file,
        template = ctx.file._nvim_bin_runner_template,
        substitutions = {
            "{{NVIM_BIN_RUNFILE_PATH}}": _get_runfile_path(ctx, nvim_bin),
            "{{ENTRY_POINT_RUNFILE_PATH}}": _get_runfile_path(ctx, entry_point),
            "{{PREDEFINED_ENTRY_POINT_ARGS}}": "\n\t".join(entry_point_args),
            "{{LUA_ROOT_DIRS}}": "\n\t".join(_get_lua_root_dirs(lua_path_roots)),
        },
    )

    return [
        DefaultInfo(
            executable = nvim_runner_file,
            runfiles = runfiles,
        ),
    ]

def _get_lua_root_dirs(lua_path_roots):
    return [
        paths.join(path_root.label.repo_name or "_main", path_root.label.package)
        for path_root in lua_path_roots
    ]

def _create_lua_root_dirs(ctx, srcs_by_lua_path_roots):
    i = 0
    root_dirs = []
    for lua_path_root, srcs in srcs_by_lua_path_roots.items():
        root_dir = ctx.actions.declare_directory("lua_{0}".format(i))

        args = ctx.actions.args()
        args.add(root_dir.path)

        for src in srcs:
            args.add(src)

            rel_path = paths.relativize(src.short_path, lua_path_root.label.package)
            args.add(rel_path)

        ctx.actions.run_shell(
            outputs = [root_dir],
            inputs = srcs,
            arguments = [args],
            command = """
                lib_root="$1"
                mkdir -p "$lib_root"
                shift

                args=("$@")
                i=0
                while [ "$i" -lt "${#args[@]}" ]; do
                    src=${args[$i]}
                    rel_path=${args[$((i + 1))]}
                    dest="${lib_root}/${rel_path}"
                    mkdir -p $(dirname "$dest")
                    cp "$src" "$dest"

                    i=$((i + 2))
                done
            """,
            progress_message = "Creating directory {dir}".format(dir = root_dir.short_path),
        )
        root_dirs.append(root_dir)
        i += 1
    return root_dirs

def _get_srcs_by_lua_root_dirs(lua_path_roots, srcs):
    def LuaPathRootTreeNode():
        return {"children": {}, "lua_path_root": None}

    lua_path_roots_tree = LuaPathRootTreeNode()
    lua_path_roots_tree["name"] = "<root>"

    def get_path(label):
        path = [label.repo_name]
        path += label.package.split("/")
        return path

    def add_path_root(lua_path_root):
        """
        Adds the Lua path root to the path tree
        """

        path = get_path(lua_path_root.label)

        current_node = lua_path_roots_tree
        for segment in path:
            if segment not in current_node["children"]:
                current_node["children"][segment] = LuaPathRootTreeNode()
                current_node["children"][segment]["name"] = segment
            current_node = current_node["children"][segment]
        if current_node["lua_path_root"] != None:
            print("WARNING: Duplicate Lua path root found")
        current_node["lua_path_root"] = lua_path_root

    def get_lua_path_root(src):
        """
        Returns the Lua path root that's the nearest ancestor to the source file
        """
        path = get_path(src.owner)

        lua_path_root = None
        current_node = lua_path_roots_tree

        for segment in path:
            if segment not in current_node["children"]:
                break

            current_node = current_node["children"][segment]
            if current_node == None:
                break

            if current_node["lua_path_root"] != None:
                lua_path_root = current_node["lua_path_root"]

        return lua_path_root

    for lua_path_root in lua_path_roots:
        add_path_root(lua_path_root)

    srcs_by_lua_path_roots = {lua_path_root: [] for lua_path_root in lua_path_roots}
    for src in srcs.to_list():
        lua_path_root = get_lua_path_root(src)
        if lua_path_root != None:
            srcs_by_lua_path_roots[lua_path_root].append(src)

    return srcs_by_lua_path_roots

def _get_runfile_path(ctx, file):
    if file.short_path.startswith("../"):
        return file.short_path[3:]

    root = file.owner.repo_name or ctx.workspace_name
    return root + "/" + file.short_path

def _get_rlocation_call(ctx, file):
    return "$(rlocation {path})".format(path = _get_runfile_path(ctx, file))

def get_runfile_args(ctx, files):
    return [_get_rlocation_call(ctx, file) for file in files]
