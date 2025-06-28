local M = {}

local bazel_package = require("pesto.bazel").package
local bazel_repo = require("pesto.bazel").repo
local cli_util = require("pesto.util.cli")
local fs_util = require("pesto.util.file_system")
local runner = require("pesto.runner.runner")
local string_util = require("pesto.util.string")
local table_util = require("pesto.util.table_util")
local logger = require("pesto.logger")
local Path = require("pesto.util.path")

---@class BazelSubcommand: Subcommand
---@field private _subcommand_completions {[string]: SubcommandCompleteFn}
---@field private _run_bazel_fn RunBazelFn
local BazelSubcommand = {}
BazelSubcommand.__index = BazelSubcommand

BazelSubcommand.name = "bazel"

---@param run_bazel_fn RunBazelFn
function BazelSubcommand:new(run_bazel_fn)
	local o = setmetatable({}, BazelSubcommand)

	o._subcommand_completions = {
		["build"] = function(opts)
			return o:_complete_build(opts)
		end,
		["test"] = function(opts)
			return {}
		end,
		["run"] = function(opts)
			return {}
		end,
	}

	o._run_bazel_fn = run_bazel_fn

	o.complete = function(opts)
		return o:_complete(opts)
	end
	o.execute = function(opts)
		o:_execute(opts)
	end

	return o
end

---@param opts SubcommandCompleteOpts
---@return string[]
function BazelSubcommand:_complete_build(opts)
	if not bazel_repo.is_in_bazel_repo(opts.buf_nr) then
		return {}
	end
	if opts.arg_lead == "/" then
		return { "//" }
	elseif string_util.starts_with(opts.arg_lead, "//") then
		local label_parts = self:_parse_label(opts.arg_lead)
		if label_parts == nil then
			return {}
		end

		local raw_project_root_dir = bazel_repo.find_project_root_dir(opts.buf_nr)
		if not raw_project_root_dir then
			return {}
		end
		local project_root_dir = Path:new(raw_project_root_dir)

		if label_parts.target_name == nil then
			-- Path part of the label is still incomplete

			-- Strip any trailing wildcard
			if string_util.ends_with(label_parts.path, "*") then
				label_parts.path = label_parts.path:sub(1, label_parts.path:len() - 1)
			end

			---@type Path
			local path_so_far = Path:new(label_parts.path)

			---@type Path
			local base_path
			---@type string|nil
			local dir_name_prefix
			if string_util.ends_with(label_parts.path, "/") then
				base_path = path_so_far
			else
				base_path = path_so_far:get_dirname()
				dir_name_prefix = tostring(path_so_far:get_basename())
			end
			base_path = project_root_dir:join(base_path)

			---@type Path[]
			local dir_candidates = self:_get_dir_completion_candidates(base_path, dir_name_prefix)
			return table_util.flat_map(dir_candidates, function(dir)
				local relative_path = Path.get_relative(project_root_dir, base_path:join(dir))
				return {
					"//" .. tostring(relative_path) .. "/",
					"//" .. tostring(relative_path) .. ":",
				}
			end)
		elseif label_parts.target_name ~= nil then
			-- Working on the target name part
			local target_name_candidates = self:_get_target_name_completion_candidates(label_parts.target_name)
			return table_util.map(target_name_candidates, function(target_name)
				return "//" .. label_parts.path .. ":" .. target_name
			end)
		end
		return {}
	elseif string_util.starts_with(opts.arg_lead, ":") then
		local target_lead = opts.arg_lead:sub(2)
		local target_names = self:_get_target_name_completion_candidates(target_lead)
		return table_util.map(target_names, function(target_name)
			return ":" .. target_name
		end)
	end
	return {}
end

---@param target_name_lead string
function BazelSubcommand:_get_target_name_completion_candidates(target_name_lead)
	local build_file = Path:new(bazel_repo.find_build_file())
	local target_names = bazel_package.guess_target_names(build_file)
	return cli_util.get_completion_candidates(target_name_lead, target_names)
end

---@param base_path Path
---@param dir_name_prefix string|nil
---@return Path[]
function BazelSubcommand:_get_dir_completion_candidates(base_path, dir_name_prefix)
	if string_util.starts_with(dir_name_prefix or "", ".") then
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
	local dirs = fs_util.get_dirs(base_path, name_pattern)
	return table_util.map(dirs, function(dir)
		return Path:new(dir)
	end)
end

---@param label_str string
function BazelSubcommand:_parse_label(label_str)
	local parts = string_util.split(label_str, "//", 1)
	local repo_name = parts[1]
	local path, target_name = unpack(string_util.split(parts[2] or "", ":", 1))
	return {
		repo_name = repo_name,
		path = path or "",
		target_name = target_name,
	}
end

---@param opts SubcommandCompleteOpts
---@return string[]
function BazelSubcommand:_complete(opts)
	local command_start, command_end, command_separator =
		opts.subcommand_line:find("^" .. BazelSubcommand.name .. "(.?)")
	assert(command_start and (command_separator == nil or command_separator:find("%s")))

	-- Note: With this pattern we skip over words beginning with '-'. We assume
	-- these are startup flags.
	local i, j = opts.subcommand_line:find("[^-%s][^%s]*", command_end + 1)
	if not i or (opts.cursor_pos >= i and opts.cursor_pos <= j) then
		local completions =
			cli_util.get_completion_candidates(opts.arg_lead, table_util.get_keys(self._subcommand_completions))
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

---@param opts SubcommandExecuteOpts
function BazelSubcommand:_execute(opts)
	-- There should be at least one farg value (the name of the subcommand)
	assert(#opts.fargs >= 1)

	local context = runner.get_run_bazel_context()
	local bazel_command = table_util.deep_copy(opts.fargs)
	table.insert(bazel_command, 1, "bazel")

	self._run_bazel_fn({
		bazel_command = bazel_command,
		context = context,
	})
end

return BazelSubcommand
