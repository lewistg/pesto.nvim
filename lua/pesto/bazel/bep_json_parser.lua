local table_util = require("pesto.util.table_util")

---@class BepJsonParser
local BepJsonParser = {}

---@return BepJsonParser
function BepJsonParser:new()
	local o = setmetatable({}, BepJsonParser)
	return o
end

---@param bep_json_file string
function BepJsonParser:parse(bep_json_file)
	local lines = vim.fn.readfile(bep_json_file)
	for _, line in ipairs(lines) do
		local raw_event = vim.json.decode(line)
		raw_event = self:_normalize_keys(raw_event)
	end
end

function BepJsonParser:_parse_event(raw_event)
	local raw_id = raw_event.id
end

---@return string
function BepJsonParser:_get_id_key(raw_id)
	local id_type = table_util.some_key(raw_id)
	if id_type == "unknown" then
		local id_key = id_type .. "_" .. raw_id.details
		return id_key
	elseif id_type == "progress" then
		local id_key = "progress"
		if raw_id.opaque_count ~= nil then
			id_key = id_key .. "_" .. raw_id.opaque_count
		end
		return id_key
	elseif id_type == "started" then
		return id_type
	elseif id_type == "unstructured_command_line" then
		return raw_id
	elseif id_type == "structured_command_line" then
		local id_key = id_type .. "_" .. raw_id.command_line_label
		return id_key
	elseif id_type == "workspace_status" then
		return id_type
	elseif id_type == "options_parsed" then
		return id_type
	elseif id_type == "fetch" then
		local id_key = table.concat({ id_type, raw_id.fetch, raw_id.downloader }, "_")
		return id_key
	elseif id_type == "configuration" then
		local id_key = id_type .. "_" .. raw_id.id
		return id_key
	elseif id_type == "target_configured" then
		local id_key = id_type .. "_" .. raw_id.id
		return id_key
	elseif id_type == "pattern" then
		local id_key = id_type .. "_" .. raw_id.pattern
		return id_key
	elseif id_type == "pattern_skipped" then
		local id_key = id_type .. "_" .. raw_id.pattern
		return id_key
	elseif id_type == "named_set" then
		local id_key = id_type .. "_" .. raw_id.id
		return id_key
	elseif id_type == "target_completed" then
		local id_key = table.concat(
			{ id_type, raw_id.label, self:_get_id_key(raw_id.configuration), tostring(raw_id.aspect) },
			"_"
		)
		return id_key
	elseif id_type == "action_completed" then
		local id_key =
			table.concat({ id_type, raw_id.primary_output, raw_id.lable, self:_get_id_key(raw_id.configuration) }, "_")
		return id_key
	elseif id_type == "test_result" then
		local id_key = table.concat(
			{ id_type, raw_id.label, self:_get_id_key(raw_id.configuration), raw_id.run, raw_id.shard, raw_id.attempt },
			"_"
		)
		return id_key
	elseif id_type == "test_progress" then
		local id_key = table.concat({
			id_type,
			raw_id.label,
			self:_get_id_key(raw_id.configuration),
			raw_id.run,
			raw_id.shard,
			raw_id.attempt,
			raw_id.opaque_count,
		}, "_")
		return id_key
	elseif id_type == "test_summary" then
		local id_key = table.concat({ id_type, raw_id.label, self:_get_id_key(raw_id.configuration) }, "_")
		return id_key
	elseif id_type == "target_summary" then
		local id_key = table.concat({ id_type, raw_id.label, self:_get_id_key(raw_id.configuration) }, "_")
		return id_key
	elseif id_type == "build_finished" then
		return id_type
	elseif id_type == "build_tool_logs" then
		return id_type
	elseif id_type == "build_metrics" then
		return id_type
	elseif id_type == "workspace" then
		return id_type
	elseif id_type == "build_metadata" then
		return id_type
	elseif id_type == "convenience_symlinks_identified" then
		return id_type
	elseif id_type == "exec_request" then
		return id_type
	elseif id_type == nil then
		error(string.format("Invalid build event ID"))
	else
		error(string.format(""))
	end
end

local function camel_case_to_snake_case(camel_case_key)
	return string.gsub(camel_case_key, "(%l)(%u)", function(lower_case, upper_case)
		return lower_case .. "_" .. string.lower(upper_case)
	end)
end

function BepJsonParser:_normalize_keys(dict)
	if type(dict) ~= "table" then
		return dict
	end
	local ret = {}
	for key, value in pairs(dict) do
		local normalized_key = camel_case_to_snake_case(key)
		ret[normalized_key] = self:_normalize_keys(value)
	end
	return ret
end
