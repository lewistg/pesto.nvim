local table_util = require("pesto.util.table_util")

---@class Path
---@field private _segments string[]
---@field private _is_absolute boolean
local Path = {}
Path.__index = Path

---@return string
function Path.get_root_dir()
	-- TODO: Support windows
	return "/"
end

---@param path Path
Path.__tostring = function(path)
	if path._is_absolute and path._segments[1] == Path.SEPARATOR then
		-- avoid a leading "//"
		return Path.SEPARATOR .. table.concat(table_util.slice(path._segments, 2), Path.SEPARATOR)
	else
		return table.concat(path._segments, Path.SEPARATOR)
	end
end

Path.SEPARATOR = "/"

---@param opts (string|{segments: string[], is_absolute: boolean})
function Path:new(opts)
	local o = setmetatable({}, Path)
	if type(opts) == "string" then
		o._segments, o._is_absolute = o:_parse_segments(opts)
	else
		o._segments = opts.segments
		o._is_absolute = opts.is_absolute
	end
	return o
end

---@param relative_path string|Path
---@return Path
function Path:join(relative_path)
	if type(relative_path) == "string" then
		relative_path = Path:new(relative_path)
	end
	if relative_path:is_absolute() then
		return relative_path
	end
	local segments = table_util.concat(self._segments, relative_path._segments)
	return Path:new({ segments = segments, is_absolute = self:is_absolute() })
end

---@return Path
function Path:resolve()
	local resolved_path = vim.fn.resolve(table.concat(self._segments, Path.SEPARATOR))
	return Path:new(resolved_path)
end

---@param raw_path string
---@return string[], boolean
function Path:_parse_segments(raw_path)
	local pattern = "\\(.\\{-}\\)" .. "\\(" .. Path.SEPARATOR .. "\\|$\\)"
	local i = 0
	local segments = {}
	--- TODO: Windows absolute path support
	local is_absolute = raw_path:sub(1, 1) == "/"
	if is_absolute then
		table.insert(segments, "/")
	end
	while true do
		-- note: matchlist uses 0-based indexes
		local match = vim.fn.matchlist(raw_path, pattern, i)
		if #match == 0 then
			break
		end
		local segment = match[2]
		if string.len(segment) > 0 and segment ~= "." then
			table.insert(segments, segment)
		end
		i = i + string.len(segment) + 1
	end
	return segments, is_absolute
end

---@return boolean
function Path:is_absolute()
	return self._is_absolute
end

---@return boolean
function Path:is_file()
	return vim.fn.filereadable(tostring(self)) == 1
end

---@return boolean
function Path:is_dir()
	return vim.fn.isdirectory(tostring(self)) == 1
end

---@return Path
function Path:get_basename()
	return Path:new({
		segments = {
			self._segments[#self._segments],
		},
		is_absolute = false,
	})
end

---@return Path
function Path:get_dirname()
	if #self._segments <= 1 then
		if self._is_absolute then
			return Path:new(Path.get_root_dir())
		else
			return Path:new(".")
		end
	else
		local segments = table_util.slice(self._segments, 1, #self._segments - 1)
		local ret = Path:new({
			segments = segments,
			is_absolute = self._is_absolute,
		})
		return ret
	end
end

---@param path_1 Path
---@param path_2 Path
---@return Path Returns path of path_2 relative to path_1. In other words the path from path_1 to path_2
function Path.get_relative(path_1, path_2)
	local absolute_path_1 = path_1.is_absolute and path_1 or path_1:resolve()
	if absolute_path_1:is_file() then
		absolute_path_1 = absolute_path_1:get_dirname()
	end
	local absolute_path_2 = path_2.is_absolute and path_2 or path_2:resolve()

	---@type string[]
	local deepest_common_ancestor_segments = {}
	for i, segment_1 in ipairs(absolute_path_1._segments) do
		if i > #absolute_path_2._segments then
			break
		end
		local segment_2 = absolute_path_2._segments[i]
		if segment_1 ~= segment_2 then
			break
		end
		table.insert(deepest_common_ancestor_segments, segment_1)
	end

	local num_upward_navigations = #absolute_path_1._segments - #deepest_common_ancestor_segments

	local segments = {}
	local i = 1
	while i <= num_upward_navigations do
		table.insert(segments, "..")
		i = i + 1
	end

	for segment in table_util.slice_iter(absolute_path_2._segments, #deepest_common_ancestor_segments + 1) do
		table.insert(segments, segment)
	end

	return Path:new({
		segments = segments,
		is_absolute = false,
	})
end

return Path
