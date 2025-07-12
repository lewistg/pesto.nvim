local table_util = require("pesto.util.table_util")

-- Types based on protobuf defintions from the official bazel repo [1].
-- [1]: https://github.com/bazelbuild/bazel/blob/7.1.0/src/main/java/com/google/devtools/build/lib/buildeventstream/proto/build_event_stream.proto

-- ===============================================================
-- BuildEventIdIds
-- ===============================================================

---@class UnknownBuildEventId
---@field details string|nil

---@class ProgressId
---@field opaque_count number|nil

---@class BuildStartedId

---@class UnstructuredCommandLineId

---@class StructuredCommandLineId
---@field command_line_label string|nil

---@class WorkspaceStatusId

---@class OptionsParsedId

---@alias Downloader 0|1|2

---@class FetchId
---@field url string|nil
---@field downloader Downloader|nil

---@class PatternExpandedId
---@field pattern string|nil

---@class WorkspaceConfigId

---@class BuildMetadataId

---@class TargetConfiguredId

---@class NamedSetOfFilesId

---@class ConfigurationId
---@field id string

---@class TargetCompletedId
---@field label string|nil
---@field configuration ConfigurationId|nil

---@class ActionCompletedId
---@field primary_output string|nil
---@field label string|nil
---@field configuration ConfigurationId|nil

---@class UnconfiguredLabelId
---@field label string|nil

---@class ConfiguredLabelId
---@field lable string|nil
---@field configuration ConfigurationId|nil

---@class TestResultId
---@field label string|nil
---@field configuration ConfigurationId|nil
---@field run number|nil
---@field shard number|nil
---@field attempt number|nil

---@class TestProgressId
---@field label string|nil
---@field configuration ConfigurationId|nil
---@field run number|nil
---@field shard number|nil
---@field attempt number|nil
---@field opaque_count number|nil

---@class TestSummaryId
---@field label string|nil
---@field configuration ConfigurationId|nil

---@class TargetSummaryId
---@field label string|nil
---@field configuration ConfigurationId|nil

---@class BuildFinishedId

---@class BuildToolLogsId

---@class BuildMetricsId

---@class ConvenienceSymlinksIdentifiedId

---@class ExecRequestId

---@alias SpecificBuildEventId
---| UnknownBuildEventId
---| ProgressId

--- The values in this alias should match the possible members of BuildEventId
---@alias BuildEventKind
---| "unknown"
---| "progress"
---| "started"
---| "unstructured_command_line"
---| "structured_command_line"
---| "workspace_status"
---| "options_parsed"
---| "fetch"
---| "configuration"
---| "target_configured"
---| "pattern"
---| "pattern_skipped"
---| "named_set"
---| "target_completed"
---| "action_completed"
---| "unconfigured_label"
---| "configured_label"
---| "test_result"
---| "test_progress"
---| "test_summary"
---| "target_summary"
---| "build_finished"
---| "build_tool_logs"
---| "build_metrics"
---| "workspace"
---| "build_metadata"
---| "convenience_symlinks_identified"
---| "exec_request"

---@class BuildEventId
---@field unknown UnknownBuildEventId|nil
---@field progress ProgressId|nil
---@field started BuildStartedId|nil
---@field unstructured_command_line UnstructuredCommandLineId|nil
---@field structured_command_line StructuredCommandLineId|nil
---@field workspace_status WorkspaceStatusId|nil
---@field options_parsed OptionsParsedId|nil
---@field fetch FetchId|nil
---@field configuration ConfigurationId|nil
---@field target_configured TargetConfiguredId|nil
---@field pattern PatternExpandedId|nil
---@field pattern_skipped PatternExpandedId|nil
---@field named_set NamedSetOfFilesId|nil
---@field target_completed TargetCompletedId|nil
---@field action_completed ActionCompletedId|nil
---@field unconfigured_label UnconfiguredLabelId|nil
---@field configured_label ConfiguredLabelId|nil
---@field test_result TestResultId|nil
---@field test_progress TestProgressId|nil
---@field test_summary TestSummaryId|nil
---@field target_summary TargetSummaryId|nil
---@field build_finished BuildFinishedId|nil
---@field build_tool_logs BuildToolLogsId|nil
---@field build_metrics BuildMetricsId|nil
---@field workspace WorkspaceConfigId|nil
---@field build_metadata BuildMetadataId|nil
---@field convenience_symlinks_identified ConvenienceSymlinksIdentifiedId|nil
---@field exec_request ExecRequestId|nil
-- Note this is an extra non-standard field which acts as a fingerprint for the ID object
---@field id_key string

-- ===============================================================
-- BuildEvent payloads
-- ===============================================================

---@class Progress
---@field stdout string
---@field stderr string

---@alias AbortReason 0|1|2|3|4|5|6|7|8|9|10|11
---@class Aborted
---@field abort_reason AbortReason
---@field description string

---@class BuildStarted
---@field uuid string
---@field start_time number
---@field build_tool_version string
---@field options_description string
---@field command string
---@field working_directory string
---@field workspace_directory string
---@field server_pid number

---@class WorkspaceConfig
---@field local_exec_root string

---@class UnstructuredCommandLine
---@field args string

---@class OptionsParsed
---@field startup_options string[]
---@field cmd_line string[]
---@field explicit_cmd_line string[]
-- TODO
--@field invocation_policy ???
---@field tool_tag string

---@class Fetch
---@field success boolean

---@class WorkspaceStatusItem
---@field key string
---@field value string

---@class WorkspaceStatus
---@field item WorkspaceStatusItem[]

---@class BuildMetadata
---@field metdata {[string]: string}

---@class Configuration
---@field mnemonic string
---@field platform_name string
---@field cpu string
---@field make_variable {[string]: string}
---@field is_tool boolean

---@class TestSuiteExpansion
---@field suite_label string
---@field test_labels string

---@class PatternExpanded
---@field test_suite_expansions TestSuiteExpansion[]

---@alias TestSize 0|1|2|3|4

---@class TargetConfigured
---@field target_kind string
---@field test_size TestSize

---@class TestSuiteExpansion
---@field target_kind string
---@field test_size TestSize
---@field tag string

---@class File
---@field path_prefix string
---@field name string
---@field uri string|nil
---@field contents string|nil
---@field symlink_target_path string|nil
---@field digest string
---@field length number

---@class NamedSetOfFiles
---@field files File[]
---@field file_sets NamedSetOfFilesId[]

---@class ActionExecuted
---@field success boolean
---@field type string
---@field exit_code number
---@field stdout File
---@field stderr File
---@field configuration ConfigurationId
---@field primary_output File
---@field command_line string[]
-- TODO
--@field failure_detail FailureDetail
--@field start_time Timestamp
--@field start_time Timestamp
---@field strategy_details any

---@class OutputGroup
---@field name string
---@field file_sets NamedSetOfFilesId[]
---@field incomplete boolean
---@field inline_files File[]

---@class TargetComplete
---@field success boolean
---@field output_group OutputGroup
---@field directory_output File
---@field tag string
--TODO
--@field test_timeout Duration
--@field failure_detail FailureDetail

---@alias TestStatus 0|1|2|3|4|5|6|7|8
--
---@class ExecutionInfo
---@field strategy string
---@field cached_remotely boolean
---@field exit_code number
---@field hostname string

---@class TestResult
---@field status TestStatus
---@field status_details string
---@field cached_locally boolean
-- TODO
--@field test_attempt_start Timestamp
--@field test_attempt_duration Duration
---@field warning string[]
---@field execution_info ExecutionInfo

---@class TestProgress
---@field uri string

---@class TestSummary
---@field overall_status TestStatus
---@field total_run_count number
---@field attempt_count number
---@field shard_count number
---@field passed File
---@field failed File
---@field total_num_cached number
-- TODO
--@field first_start_time Timestamp
--@field total_run_duration Duration

---@class ExitCode
---@field name string
---@field code number

---@class AnomalyReport
---@field was_suspended boolean

---@class BuildFinished
---@field overall_success boolean
---@field exit_code ExitCode
--TODO
--@field finish_time Timestamp
---@field anomaly_report AnomalyReport
--@field failure_detail FailureDetail

---@class BuildMetrics
-- TODO fields

---@class TargetSummary
---@field overall_build_success boolean
---@field overall_test_status TestStatus

---@class BuildToolLogs
---@field log File[]

---@class ConvenienceSymlinksIdentified
---@field convenience_symlinks string

---@class EnvironmentVariable
---@field name string
---@field value string

---@class ExecRequestConstructed
---@field working_directory string
---@field argv string[]
---@field environment_variable EnvironmentVariable[]
---@field should_exec boolean

-- ===============================================================
-- BuildEvent payloads
-- ===============================================================

---@class BuildEvent
---@field id BuildEventId
---@field children BuildEventId[]
---@field last_message boolean
-- One of the following fields should be defined
---@field progress Progress|nil
---@field aborted Aborted|nil
---@field started BuildStarted|nil
---@field unstructured_command_line UnstructuredCommandLine|nil
-- TODO
--@field structured_command_line CommandLine|nil
---@field options_parsed OptionsParsed|nil
---@field workspace_status WorkspaceStatus|nil
---@field fetch Fetch|nil
---@field configuration Configuration|nil
---@field expanded PatternExpanded|nil
---@field configured TargetConfigured|nil
---@field action ActionExecuted|nil
---@field named_set_of_files NamedSetOfFiles|nil
---@field completed TargetComplete|nil
---@field test_result TestResult|nil
---@field test_progress TestProgress|nil
---@field test_summary TestSummary|nil
---@field target_summary TargetSummary|nil
---@field finished BuildFinished|nil
---@field build_tool_logs BuildToolLogs|nil
---@field build_metrics BuildMetrics|nil
---@field workspace_info WorkspaceConfig|nil
---@field build_metadata BuildMetadata|nil
---@field convenience_symlinks_identified ConvenienceSymlinksIdentified|nil
---@field exec_request ExecRequestConstructed|nil
---Note: These fields are non-standard fields that we've added for convenience
---@field kind BuildEventKind
---@field id_key string
local BuildEvent = {}
BuildEvent.__index = BuildEvent

---@param raw_event table
---@return BuildEvent
function BuildEvent:new(raw_event)
	---@type BuildEvent
	local o = setmetatable(raw_event, BuildEvent)
	o.kind = table_util.some_key(raw_event.id) --[[@as BuildEventKind]]
	o.id_key = o.get_id_key(o.id)
	return o
end

--- Gets a unique fingerprint for the build event ID
---@param build_event_id BuildEventId
---@return string
function BuildEvent.get_id_key(build_event_id)
	local specific_id_type = table_util.some_key(build_event_id)
	if type(specific_id_type) ~= "string" then
		error(string.format('unrecongized id type: "%s"', specific_id_type or ""))
	end
	---@param value table
	local function get_key(value)
		local sorted_keys = table_util.get_keys(value)
		table.sort(sorted_keys)
		local values = table_util.map(sorted_keys, function(k)
			local v = value[k]
			if type(v) == "table" then
				return get_key(v)
			else
				return tostring(v)
			end
		end)
		return table.concat(values, "_")
	end
	return specific_id_type .. ":" .. get_key(build_event_id)
end

return BuildEvent
