describe('get_match_captures_by_name', function()
  it('returns mapping from capture names to nodes', function()
    local build_file = [[
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

sh_binary(
    name = "foo1",
    srcs = ["foo1.sh"]
)

sh_test(
    name = "foo1_spec",
    srcs = [
        "foo1_spec.sh"
    ]
)

sh_binary(
    name = "foo2",
    srcs = ["foo2.sh"]
)

sh_binary(
    name = "foo3",
    srcs = ["foo3.sh"]
)
    ]]
  end)
end)
