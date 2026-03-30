-- Types based on protobuf defintions from the official bazel repo [1].
-- [1]: https://github.com/bazelbuild/bazel/blob/7.1.0/src/main/java/com/google/devtools/build/lib/buildeventstream/proto/build_event_stream.proto

-- ===============================================================
-- BuildEventIdIds
-- ===============================================================

---@class pesto.bep.UnknownBuildEventId
---@field details string|nil

---@class pesto.bep.ProgressId
---@field opaque_count number|nil

---@class pesto.bep.BuildStartedId

---@class pesto.bep.UnstructuredCommandLineId

---@class pesto.bep.StructuredCommandLineId
---@field command_line_label string|nil

---@class pesto.bep.WorkspaceStatusId

---@class pesto.bep.OptionsParsedId

---@alias pesto.bep.Downloader 0|1|2

---@class pesto.bep.FetchId
---@field url string|nil
---@field downloader pesto.bep.Downloader|nil

---@class pesto.bep.PatternExpandedId
---@field pattern string|nil

---@class pesto.bep.WorkspaceConfigId

---@class pesto.bep.BuildMetadataId

---@class pesto.bep.TargetConfiguredId
---@field label string|nil
---@field aspect string|nil

---@class pesto.bep.NamedSetOfFilesId

---@class pesto.bep.ConfigurationId
---@field id string

---@class pesto.bep.TargetCompletedId
---@field label string|nil
---@field configuration pesto.bep.ConfigurationId|nil

---@class pesto.bep.ActionCompletedId
---@field primary_output string|nil
---@field label string|nil
---@field configuration pesto.bep.ConfigurationId|nil

---@class pesto.bep.UnconfiguredLabelId
---@field label string|nil

---@class pesto.bep.ConfiguredLabelId
---@field lable string|nil
---@field configuration pesto.bep.ConfigurationId|nil

---@class pesto.bep.TestResultId
---@field label string|nil
---@field configuration pesto.bep.ConfigurationId|nil
---@field run number|nil
---@field shard number|nil
---@field attempt number|nil

---@class pesto.bep.TestProgressId
---@field label string|nil
---@field configuration pesto.bep.ConfigurationId|nil
---@field run number|nil
---@field shard number|nil
---@field attempt number|nil
---@field opaque_count number|nil

---@class pesto.bep.TestSummaryId
---@field label string|nil
---@field configuration pesto.bep.ConfigurationId|nil

---@class pesto.bep.TargetSummaryId
---@field label string|nil
---@field configuration pesto.bep.ConfigurationId|nil

---@class pesto.bep.BuildFinishedId

---@class pesto.bep.BuildToolLogsId

---@class pesto.bep.BuildMetricsId

---@class pesto.bep.ConvenienceSymlinksIdentifiedId

---@class pesto.bep.ExecRequestId

---@alias pesto.SpecificBuildEventId
---| pesto.bep.UnknownBuildEventId
---| pesto.bep.ProgressId

--- The values in this alias should match the possible members of BuildEventId
---@alias pesto.bep.BuildEventKind
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

---@class pesto.bep.BuildEventId
---@field unknown pesto.bep.UnknownBuildEventId|nil
---@field progress pesto.bep.ProgressId|nil
---@field started pesto.bep.BuildStartedId|nil
---@field unstructured_command_line pesto.bep.UnstructuredCommandLineId|nil
---@field structured_command_line pesto.bep.StructuredCommandLineId|nil
---@field workspace_status pesto.bep.WorkspaceStatusId|nil
---@field options_parsed pesto.bep.OptionsParsedId|nil
---@field fetch pesto.bep.FetchId|nil
---@field configuration pesto.bep.ConfigurationId|nil
---@field target_configured pesto.bep.TargetConfiguredId|nil
---@field pattern pesto.bep.PatternExpandedId|nil
---@field pattern_skipped pesto.bep.PatternExpandedId|nil
---@field named_set pesto.bep.NamedSetOfFilesId|nil
---@field target_completed pesto.bep.TargetCompletedId|nil
---@field action_completed pesto.bep.ActionCompletedId|nil
---@field unconfigured_label pesto.bep.UnconfiguredLabelId|nil
---@field configured_label pesto.bep.ConfiguredLabelId|nil
---@field test_result pesto.bep.TestResultId|nil
---@field test_progress pesto.bep.TestProgressId|nil
---@field test_summary pesto.bep.TestSummaryId|nil
---@field target_summary pesto.bep.TargetSummaryId|nil
---@field build_finished pesto.bep.BuildFinishedId|nil
---@field build_tool_logs pesto.bep.BuildToolLogsId|nil
---@field build_metrics pesto.bep.BuildMetricsId|nil
---@field workspace pesto.bep.WorkspaceConfigId|nil
---@field build_metadata pesto.bep.BuildMetadataId|nil
---@field convenience_symlinks_identified pesto.bep.ConvenienceSymlinksIdentifiedId|nil
---@field exec_request pesto.bep.ExecRequestId|nil

-- ===============================================================
-- CommandLine
-- See: https://github.com/bazelbuild/bazel/blob/master/src/main/protobuf/command_line.proto
-- ===============================================================
---@class pesto.bep.Option
---@field combined_form string
---@field option_name string
---@field option_value string

---@class pesto.bep.OptionList
---@field option pesto.bep.Option[]

---@class pesto.bep.CommandLineSection
---@field chunk_list string[]
---@field option_list pesto.bep.OptionList

---@class pesto.bep.CommandLine
---@field command_line_label string
---@field sections pesto.bep.CommandLineSection[]

-- ===============================================================
-- BuildEvent payloads
-- ===============================================================

---@class pesto.bep.Progress
---@field stdout string
---@field stderr string

---@alias pesto.AbortReason 0|1|2|3|4|5|6|7|8|9|10|11
---@class pesto.bep.Aborted
---@field abort_reason pesto.AbortReason
---@field description string

---@class pesto.bep.BuildStarted
---@field uuid string
---@field start_time number
---@field build_tool_version string
---@field options_description string
---@field command string
---@field working_directory string
---@field workspace_directory string
---@field server_pid number

---@class pesto.bep.WorkspaceConfig
---@field local_exec_root string

---@class pesto.bep.UnstructuredCommandLine
---@field args string

---@class pesto.bep.OptionsParsed
---@field startup_options string[]
---@field cmd_line string[]
---@field explicit_cmd_line string[]
-- TODO
--@field invocation_policy ???
---@field tool_tag string

---@class pesto.bep.Fetch
---@field success boolean

---@class pesto.bep.WorkspaceStatusItem
---@field key string
---@field value string

---@class pesto.bep.WorkspaceStatus
---@field item pesto.bep.WorkspaceStatusItem[]

---@class pesto.bep.BuildMetadata
---@field metdata {[string]: string}

---@class pesto.bep.Configuration
---@field mnemonic string
---@field platform_name string
---@field cpu string
---@field make_variable {[string]: string}
---@field is_tool boolean

---@class pesto.bep.TestSuiteExpansion
---@field suite_label string
---@field test_labels string

---@class pesto.bep.PatternExpanded
---@field test_suite_expansions pesto.bep.TestSuiteExpansion[]

---@alias TestSize 0|1|2|3|4

---@class pesto.bep.TargetConfigured
---@field target_kind string
---@field test_size TestSize

---@class pesto.bep.TestSuiteExpansion
---@field target_kind string
---@field test_size TestSize
---@field tag string

---@class pesto.bep.File
---@field path_prefix string
---@field name string
---@field uri string|nil
---@field contents string|nil
---@field symlink_target_path string|nil
---@field digest string
---@field length number

---@class pesto.bep.NamedSetOfFiles
---@field files pesto.bep.File[]
---@field file_sets pesto.bep.NamedSetOfFilesId[]

---@class pesto.bep.ActionExecuted
---@field success boolean
---@field type string
---@field exit_code number
---@field stdout pesto.bep.File
---@field stderr pesto.bep.File
---@field configuration pesto.bep.ConfigurationId
---@field primary_output pesto.bep.File
---@field command_line string[]
-- TODO
--@field failure_detail FailureDetail
--@field start_time Timestamp
--@field start_time Timestamp
---@field strategy_details any

---@class pesto.bep.OutputGroup
---@field name string
---@field file_sets pesto.bep.NamedSetOfFilesId[]
---@field incomplete boolean
---@field inline_files pesto.bep.File[]

---@class pesto.bep.TargetComplete
---@field success boolean
---@field output_group pesto.bep.OutputGroup
---@field directory_output pesto.bep.File
---@field tag string
--TODO
--@field test_timeout Duration
--@field failure_detail FailureDetail

---@alias TestStatus 0|1|2|3|4|5|6|7|8
--
---@class pesto.bep.ExecutionInfo
---@field strategy string
---@field cached_remotely boolean
---@field exit_code number
---@field hostname string

---@class pesto.bep.TestResult
---@field status TestStatus
---@field status_details string
---@field cached_locally boolean
-- TODO
--@field test_attempt_start Timestamp
--@field test_attempt_duration Duration
---@field warning string[]
---@field execution_info pesto.bep.ExecutionInfo

---@class pesto.bep.TestProgress
---@field uri string

---@class pesto.bep.TestSummary
---@field overall_status TestStatus
---@field total_run_count number
---@field attempt_count number
---@field shard_count number
---@field passed pesto.bep.File
---@field failed pesto.bep.File
---@field total_num_cached number
-- TODO
--@field first_start_time Timestamp
--@field total_run_duration Duration

---@class pesto.bep.ExitCode
---@field name string
---@field code number

---@class pesto.bep.AnomalyReport
---@field was_suspended boolean

---@class pesto.bep.BuildFinished
---@field overall_success boolean
---@field exit_code pesto.bep.ExitCode
--TODO
--@field finish_time Timestamp
---@field anomaly_report pesto.bep.AnomalyReport
--@field failure_detail FailureDetail

---@class pesto.bep.BuildMetrics
-- TODO fields

---@class pesto.bep.TargetSummary
---@field overall_build_success boolean
---@field overall_test_status TestStatus

---@class pesto.bep.BuildToolLogs
---@field log pesto.bep.File[]

---@class pesto.bep.ConvenienceSymlinksIdentified
---@field convenience_symlinks string

---@class pesto.bep.EnvironmentVariable
---@field name string
---@field value string

---@class pesto.bep.ExecRequestConstructed
---@field working_directory string
---@field argv string[]
---@field environment_variable pesto.bep.EnvironmentVariable[]
---@field should_exec boolean

-- ===============================================================
-- BuildEvent payloads
-- ===============================================================

---@class pesto.bep.BuildEvent
---@field id pesto.bep.BuildEventId
---@field children pesto.bep.BuildEventId[]
---@field last_message boolean
-- One of the following fields should be defined
---@field progress pesto.bep.Progress|nil
---@field aborted pesto.bep.Aborted|nil
---@field started pesto.bep.BuildStarted|nil
---@field unstructured_command_line pesto.bep.UnstructuredCommandLine|nil
---@field structured_command_line pesto.bep.CommandLine|nil
---@field options_parsed pesto.bep.OptionsParsed|nil
---@field workspace_status pesto.bep.WorkspaceStatus|nil
---@field fetch pesto.bep.Fetch|nil
---@field configuration pesto.bep.Configuration|nil
---@field expanded pesto.bep.PatternExpanded|nil
---@field configured pesto.bep.TargetConfigured|nil
---@field action pesto.bep.ActionExecuted|nil
---@field named_set_of_files pesto.bep.NamedSetOfFiles|nil
---@field completed pesto.bep.TargetComplete|nil
---@field test_result pesto.bep.TestResult|nil
---@field test_progress pesto.bep.TestProgress|nil
---@field test_summary pesto.bep.TestSummary|nil
---@field target_summary pesto.bep.TargetSummary|nil
---@field finished pesto.bep.BuildFinished|nil
---@field build_tool_logs pesto.bep.BuildToolLogs|nil
---@field build_metrics pesto.bep.BuildMetrics|nil
---@field workspace_info pesto.bep.WorkspaceConfig|nil
---@field build_metadata pesto.bep.BuildMetadata|nil
---@field convenience_symlinks_identified pesto.bep.ConvenienceSymlinksIdentified|nil
---@field exec_request pesto.bep.ExecRequestConstructed|nil
---Note: These fields are non-standard fields that we've added for convenience
---@field kind pesto.bep.BuildEventKind
---@field id_key string
local BuildEvent = {}
BuildEvent.__index = BuildEvent

---@param raw_event table
---@return pesto.bep.BuildEvent
function BuildEvent:new(raw_event)
	---@type pesto.bep.BuildEvent
	local o = setmetatable(raw_event, BuildEvent)
	local table_util = require("pesto.util.table_util")
	o.kind = table_util.some_key(raw_event.id) --[[@as pesto.bep.BuildEventKind]]
	o.id_key = o.get_id_key(o.id)
	return o
end

--- Gets a unique fingerprint for the build event ID
---@param build_event_id pesto.bep.BuildEventId
---@return string
function BuildEvent.get_id_key(build_event_id)
	local table_util = require("pesto.util.table_util")
	local specific_id_type = table_util.some_key(build_event_id)
	if type(specific_id_type) ~= "string" then
		error(string.format('unrecongized id type: "%s"', specific_id_type or "(type not given)"))
	end
	---@param value table
	local function get_key(value)
		local sorted_keys = vim.tbl_keys(value)
		table.sort(sorted_keys)
		local values = vim.tbl_map(function(k)
			local v = value[k]
			if type(v) == "table" then
				return get_key(v)
			else
				return tostring(v)
			end
		end, sorted_keys)
		return table.concat(values, "_")
	end
	return specific_id_type .. ":" .. get_key(build_event_id)
end

return BuildEvent
