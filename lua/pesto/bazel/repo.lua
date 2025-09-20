local M = {}

local PACKAGE_MARKERS = {
	"BUILD.bazel",
	"BUILD",
}

-- Finds the corresponding build file for the source file in the given buffer.
--
---@param buf_nr number|nil
local function get_buffer_dir(buf_nr)
	local buffer_dir = nil
	if buf_nr == nil then
		-- Get the current buffer's path
		buffer_dir = vim.fn.expand("%:p:h")
	else
		local buffers = vim.fn.getbufinfo(buf_nr)
		if #buffers < 1 then
			error("invalid buffer number")
		elseif buffers[1].name == "" then
			buffer_dir = vim.fn.getcwd(buffers[1].windows[1])
		else
			buffer_dir = vim.fn.fnamemodify(buffers[1].name, ":p:h")
		end
	end
	return buffer_dir
end

-- Gets the label for the package that contains the file associated with the
-- given buffer.
--
---@param buf_nr number|nil
---@return string The package label
function M.get_package_label(buf_nr)
	local build_file_path = M.find_build_file(buf_nr)
	local package_dir_path = vim.fn.fnamemodify(build_file_path, ":p:h")
	local root_dir_path = M.find_project_root_dir()
	local package_label = string.gsub(package_dir_path, "^" .. root_dir_path .. "//?", "//")
	return package_label
end

-- Finds the corresponding build file for the source file in the given buffer.
--
---@param buf_nr number|nil
---@return string|nil
function M.find_build_file(buf_nr)
	local buffer_dir = get_buffer_dir(buf_nr)
	-- note: BUILD.repo takes precedence over BUILD [1]
	-- [1]: https://repo.build/concepts/build-files
	for _, filename in ipairs(PACKAGE_MARKERS) do
		local build_file = vim.fn.findfile(filename, buffer_dir .. ";")
		if build_file ~= "" then
			build_file = vim.fn.fnamemodify(build_file, ":p")
			return build_file
		end
	end
end

---@param dir Path
---@return boolean
function M.is_package(dir)
	for _, marker_file in PACKAGE_MARKERS do
		if dir:join(marker_file):is_file() then
			return true
		end
	end
	return false
end

-- Finds the repo's root marker file
--
---@param buf_nr number|nil
function M.find_project_root_dir(buf_nr)
	local root_marker_file = M.find_project_root_marker_file(buf_nr)
	local root_dir = vim.fn.fnamemodify(root_marker_file, ":p:h")
	return root_dir
end

-- Finds the repo's root marker file
--
---@param buf_nr number|nil
---@return string|nil
function M.find_project_root_marker_file(buf_nr)
	local buffer_dir = get_buffer_dir(buf_nr)
	local root_marker_filenames = { "MODULE.bazel", "REPO.bazel", "WORKSPACE", "WORKSPACE.bazel" }
	for _, filename in ipairs(root_marker_filenames) do
		local root_marker_file = vim.fn.findfile(filename, buffer_dir .. ";")
		if root_marker_file and string.len(root_marker_file) > 0 then
			return root_marker_file
		end
	end
	return nil
end

---@param buf_nr number
---@return boolean
function M.is_in_bazel_repo(buf_nr)
	local ret = M.find_project_root_marker_file(buf_nr) ~= nil
	return M.find_project_root_marker_file(buf_nr) ~= nil
end

return M
