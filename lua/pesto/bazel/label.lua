local M = {}

local LABEL_PATTERN = "([^/]*)//([^:]*)(:?(.*))"

---Parsed Bazel label (see: https://bazel.build/concepts/labels)
---@class pesto.BazelLabel
---@field repo_name string|nil
---@field package_name string
---@field target_name string|nil

---Parses a label. This method assumes that the label at least consists of a
---fully qualified package name (i.e., //foo/bar/baz). The repo name may be absent.
---@param raw_label string
---@return pesto.BazelLabel|nil
function M.parse_label(raw_label)
	local i, _, repo_name, package_name, _, target_name = string.find(raw_label, LABEL_PATTERN)
	if not i then
		return nil
	end
	return {
		repo_name = repo_name,
		package_name = package_name,
		target_name = target_name,
	}
end

return M
