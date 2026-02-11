--- Basic bazel CLI completion implemented in pure Lua.
---@class pesto.BazelBasicCompletion: pesto.SubcommandCompletion
---@field private _subcommand_completions {[string]: SubcommandCompleteFn}
local BazelBasicCompletion = {}
BazelBasicCompletion.__index = BazelBasicCompletion

BazelBasicCompletion.name = "bazel"

function BazelBasicCompletion:new()
	local o = setmetatable({}, BazelBasicCompletion)

	o._subcommand_completions = {
		["build"] = function(opts)
			return o:complete_subcommand(opts)
		end,
		["test"] = function(opts)
			return o:complete_subcommand(opts)
		end,
		["run"] = function(opts)
			return o:complete_subcommand(opts)
		end,
	}

	return o
end

---@param opts SubcommandCompleteOpts
---@return string[]
function BazelBasicCompletion:complete(opts)
	local command_start, command_end, command_separator =
		opts.subcommand_line:find("^" .. BazelBasicCompletion.name .. "(.?)")
	assert(command_start and (command_separator == nil or command_separator:find("%s")))

	-- Note: With this pattern we skip over words beginning with '-'. We assume
	-- these are startup flags.
	local i, j = opts.subcommand_line:find("[^-%s][^%s]*", command_end + 1)
	if not i or (opts.cursor_pos >= i and opts.cursor_pos <= j) then
		local cli_util = require("pesto.util.cli")
		local completions =
			cli_util.get_completion_candidates(opts.arg_lead, vim.tbl_keys(self._subcommand_completions))
		return completions
	end

	local subcommand_name = opts.subcommand_line:sub(i, j)
	local complete_subcommand = self._subcommand_completions[subcommand_name]
	if complete_subcommand then
		local subcommand_line = opts.subcommand_line:sub(i)
		local cursor_pos = opts.cursor_pos - i
		return complete_subcommand({
			subcommand_line = subcommand_line,
			cursor_pos = cursor_pos,
			arg_lead = opts.arg_lead,
			buf_nr = opts.buf_nr,
		})
	end

	return {}
end

---@param opts SubcommandCompleteOpts
---@return string[]
function BazelBasicCompletion:complete_subcommand(opts)
	local bazel_repo = require("pesto.bazel.repo")
	if not bazel_repo.is_in_bazel_repo(opts.buf_nr) then
		return {}
	end
	if opts.arg_lead == "/" then
		return { "//" }
	elseif vim.startswith(opts.arg_lead, "//") then
		local bazel_label_util = require("pesto.bazel.label")
		local bazel_label = bazel_label_util.parse_label(opts.arg_lead)
		if bazel_label == nil then
			return {}
		end

		local raw_project_root_dir = bazel_repo.find_project_root_dir(opts.buf_nr)
		if not raw_project_root_dir then
			return {}
		end
		local Path = require("pesto.util.path")
		local project_root_dir = Path:new(raw_project_root_dir)

		if bazel_label.target_name == "" then
			-- Path part of the label is still incomplete

			-- Strip any trailing wildcard
			if vim.endswith(bazel_label.package_name, "*") then
				bazel_label.package_name = bazel_label.package_name:sub(1, bazel_label.package_name:len() - 1)
			end

			---@type Path
			local path_so_far = Path:new(bazel_label.package_name)

			---@type Path
			local base_path
			---@type string|nil
			local dir_name_prefix
			if vim.endswith(bazel_label.package_name, "/") then
				base_path = path_so_far
			else
				base_path = path_so_far:get_dirname()
				dir_name_prefix = tostring(path_so_far:get_basename())
			end
			base_path = project_root_dir:join(base_path)

			---@type Path[]
			local dir_candidates = self:_get_dir_completion_candidates(base_path, dir_name_prefix)
			local table_util = require("pesto.util.table_util")
			return table_util.flat_map(function(dir)
				local relative_path = Path.get_relative(project_root_dir, base_path:join(dir))
				return {
					"//" .. tostring(relative_path) .. "/",
					"//" .. tostring(relative_path) .. ":",
				}
			end, dir_candidates)
		elseif bazel_label.target_name ~= nil then
			-- Working on the target name part
			local target_name_candidates = self:_get_target_name_completion_candidates(bazel_label.target_name)
			return vim.tbl_map(function(target_name)
				return "//" .. bazel_label.package_name .. ":" .. target_name
			end, target_name_candidates)
		end
		return {}
	elseif vim.startswith(opts.arg_lead, ":") then
		local target_lead = opts.arg_lead:sub(2)
		local target_names = self:_get_target_name_completion_candidates(target_lead)
		return vim.tbl_map(function(target_name)
			return ":" .. target_name
		end, target_names)
	end
	return {}
end

---@param base_path Path
---@param dir_name_prefix string|nil
---@return Path[]
function BazelBasicCompletion:_get_dir_completion_candidates(base_path, dir_name_prefix)
	if vim.startswith(dir_name_prefix or "", ".") then
		-- dot files are ignored
		return {}
	end

	local name_pattern
	if dir_name_prefix == nil or dir_name_prefix == "" or dir_name_prefix == "*" then
		-- ignore dot files/dirs
		name_pattern = "^[^\\.].*"
	else
		name_pattern = "^" .. dir_name_prefix .. ".*"
	end
	local fs_util = require("pesto.util.file_system")
	local dirs = fs_util.get_dirs(base_path, name_pattern)
	return vim.tbl_map(function(dir)
		local Path = require("pesto.util.path")
		return Path:new(dir)
	end, dirs)
end

---@param target_name_lead string
function BazelBasicCompletion:_get_target_name_completion_candidates(target_name_lead)
	local bazel_repo = require("pesto.bazel.repo")
	local raw_build_file_path = bazel_repo.find_build_file()
	if raw_build_file_path == nil then
		require("pesto.logger").debug("failed to find BUILD or BUILD.bazel file for the current buffer")
		return {}
	end
	local Path = require("pesto.util.path")
	local build_file = Path:new(raw_build_file_path)

	local bazel_package = require("pesto.bazel.package")
	local target_names = bazel_package.guess_target_names(build_file)

	local cli_util = require("pesto.util.cli")
	return cli_util.get_completion_candidates(target_name_lead, target_names)
end

return BazelBasicCompletion
