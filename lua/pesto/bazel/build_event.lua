local table_util = require("pesto.util.table_util")

-- Types based on protobuf defintions from the official bazel repo [1].
-- [1]: https://github.com/bazelbuild/bazel/blob/7.1.0/src/main/java/com/google/devtools/build/lib/buildeventstream/proto/build_event_stream.proto

-- ===============================================================
-- BuildEventIdIds
-- ===============================================================

---@class pesto.UnknownBuildEventId
---@field details string|nil

---@class pesto.ProgressId
---@field opaque_count number|nil

---@class pesto.BuildStartedId

---@class pesto.UnstructuredCommandLineId

---@class pesto.StructuredCommandLineId
---@field command_line_label string|nil

---@class pesto.WorkspaceStatusId

---@class pesto.OptionsParsedId

---@alias pesto.Downloader 0|1|2

---@class pesto.FetchId
---@field url string|nil
---@field downloader pesto.Downloader|nil

---@class pesto.PatternExpandedId
---@field pattern string|nil

---@class pesto.WorkspaceConfigId

---@class pesto.BuildMetadataId

---@class pesto.TargetConfiguredId
---@field label string|nil
---@field aspect string|nil

---@class pesto.NamedSetOfFilesId

---@class pesto.ConfigurationId
---@field id string

---@class pesto.TargetCompletedId
---@field label string|nil
---@field configuration pesto.ConfigurationId|nil

---@class pesto.ActionCompletedId
---@field primary_output string|nil
---@field label string|nil
---@field configuration pesto.ConfigurationId|nil

---@class pesto.UnconfiguredLabelId
---@field label string|nil

---@class pesto.ConfiguredLabelId
---@field lable string|nil
---@field configuration pesto.ConfigurationId|nil

---@class pesto.TestResultId
---@field label string|nil
---@field configuration pesto.ConfigurationId|nil
---@field run number|nil
---@field shard number|nil
---@field attempt number|nil

---@class pesto.TestProgressId
---@field label string|nil
---@field configuration pesto.ConfigurationId|nil
---@field run number|nil
---@field shard number|nil
---@field attempt number|nil
---@field opaque_count number|nil

---@class pesto.TestSummaryId
---@field label string|nil
---@field configuration pesto.ConfigurationId|nil

---@class pesto.TargetSummaryId
---@field label string|nil
---@field configuration pesto.ConfigurationId|nil

---@class pesto.BuildFinishedId

---@class pesto.BuildToolLogsId

---@class pesto.BuildMetricsId

---@class pesto.ConvenienceSymlinksIdentifiedId

---@class pesto.ExecRequestId

---@alias pesto.SpecificBuildEventId
---| pesto.UnknownBuildEventId
---| pesto.ProgressId

--- The values in this alias should match the possible members of BuildEventId
---@alias pesto.BuildEventKind
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

---@class pesto.BuildEventId
---@field unknown pesto.UnknownBuildEventId|nil
---@field progress pesto.ProgressId|nil
---@field started pesto.BuildStartedId|nil
---@field unstructured_command_line pesto.UnstructuredCommandLineId|nil
---@field structured_command_line pesto.StructuredCommandLineId|nil
---@field workspace_status pesto.WorkspaceStatusId|nil
---@field options_parsed pesto.OptionsParsedId|nil
---@field fetch pesto.FetchId|nil
---@field configuration pesto.ConfigurationId|nil
---@field target_configured pesto.TargetConfiguredId|nil
---@field pattern pesto.PatternExpandedId|nil
---@field pattern_skipped pesto.PatternExpandedId|nil
---@field named_set pesto.NamedSetOfFilesId|nil
---@field target_completed pesto.TargetCompletedId|nil
---@field action_completed pesto.ActionCompletedId|nil
---@field unconfigured_label pesto.UnconfiguredLabelId|nil
---@field configured_label pesto.ConfiguredLabelId|nil
---@field test_result pesto.TestResultId|nil
---@field test_progress pesto.TestProgressId|nil
---@field test_summary pesto.TestSummaryId|nil
---@field target_summary pesto.TargetSummaryId|nil
---@field build_finished pesto.BuildFinishedId|nil
---@field build_tool_logs pesto.BuildToolLogsId|nil
---@field build_metrics pesto.BuildMetricsId|nil
---@field workspace pesto.WorkspaceConfigId|nil
---@field build_metadata pesto.BuildMetadataId|nil
---@field convenience_symlinks_identified pesto.ConvenienceSymlinksIdentifiedId|nil
---@field exec_request pesto.ExecRequestId|nil

-- ===============================================================
-- BuildEvent payloads
-- ===============================================================

---@class pesto.Progress
---@field stdout string
---@field stderr string

---@alias pesto.AbortReason 0|1|2|3|4|5|6|7|8|9|10|11
---@class pesto.Aborted
---@field abort_reason pesto.AbortReason
---@field description string

---@class pesto.BuildStarted
---@field uuid string
---@field start_time number
---@field build_tool_version string
---@field options_description string
---@field command string
---@field working_directory string
---@field workspace_directory string
---@field server_pid number

---@class pesto.WorkspaceConfig
---@field local_exec_root string

---@class pesto.UnstructuredCommandLine
---@field args string

---@class pesto.OptionsParsed
---@field startup_options string[]
---@field cmd_line string[]
---@field explicit_cmd_line string[]
-- TODO
--@field invocation_policy ???
---@field tool_tag string

---@class pesto.Fetch
---@field success boolean

---@class pesto.WorkspaceStatusItem
---@field key string
---@field value string

---@class pesto.WorkspaceStatus
---@field item pesto.WorkspaceStatusItem[]

---@class pesto.BuildMetadata
---@field metdata {[string]: string}

---@class pesto.Configuration
---@field mnemonic string
---@field platform_name string
---@field cpu string
---@field make_variable {[string]: string}
---@field is_tool boolean

---@class pesto.TestSuiteExpansion
---@field suite_label string
---@field test_labels string

---@class pesto.PatternExpanded
---@field test_suite_expansions pesto.TestSuiteExpansion[]

---@alias TestSize 0|1|2|3|4

---@class pesto.TargetConfigured
---@field target_kind string
---@field test_size TestSize

---@class pesto.TestSuiteExpansion
---@field target_kind string
---@field test_size TestSize
---@field tag string

---@class pesto.File
---@field path_prefix string
---@field name string
---@field uri string|nil
---@field contents string|nil
---@field symlink_target_path string|nil
---@field digest string
---@field length number

---@class pesto.NamedSetOfFiles
---@field files pesto.File[]
---@field file_sets pesto.NamedSetOfFilesId[]

---@class pesto.ActionExecuted
---@field success boolean
---@field type string
---@field exit_code number
---@field stdout pesto.File
---@field stderr pesto.File
---@field configuration pesto.ConfigurationId
---@field primary_output pesto.File
---@field command_line string[]
-- TODO
--@field failure_detail FailureDetail
--@field start_time Timestamp
--@field start_time Timestamp
---@field strategy_details any

---@class pesto.OutputGroup
---@field name string
---@field file_sets pesto.NamedSetOfFilesId[]
---@field incomplete boolean
---@field inline_files pesto.File[]

---@class pesto.TargetComplete
---@field success boolean
---@field output_group pesto.OutputGroup
---@field directory_output pesto.File
---@field tag string
--TODO
--@field test_timeout Duration
--@field failure_detail FailureDetail

---@alias TestStatus 0|1|2|3|4|5|6|7|8
--
---@class pesto.ExecutionInfo
---@field strategy string
---@field cached_remotely boolean
---@field exit_code number
---@field hostname string

---@class pesto.TestResult
---@field status TestStatus
---@field status_details string
---@field cached_locally boolean
-- TODO
--@field test_attempt_start Timestamp
--@field test_attempt_duration Duration
---@field warning string[]
---@field execution_info pesto.ExecutionInfo

---@class pesto.TestProgress
---@field uri string

---@class pesto.TestSummary
---@field overall_status TestStatus
---@field total_run_count number
---@field attempt_count number
---@field shard_count number
---@field passed pesto.File
---@field failed pesto.File
---@field total_num_cached number
-- TODO
--@field first_start_time Timestamp
--@field total_run_duration Duration

---@class pesto.ExitCode
---@field name string
---@field code number

---@class pesto.AnomalyReport
---@field was_suspended boolean

---@class pesto.BuildFinished
---@field overall_success boolean
---@field exit_code pesto.ExitCode
--TODO
--@field finish_time Timestamp
---@field anomaly_report pesto.AnomalyReport
--@field failure_detail FailureDetail

---@class pesto.BuildMetrics
-- TODO fields

---@class pesto.TargetSummary
---@field overall_build_success boolean
---@field overall_test_status TestStatus

---@class pesto.BuildToolLogs
---@field log pesto.File[]

---@class pesto.ConvenienceSymlinksIdentified
---@field convenience_symlinks string

---@class pesto.EnvironmentVariable
---@field name string
---@field value string

---@class pesto.ExecRequestConstructed
---@field working_directory string
---@field argv string[]
---@field environment_variable pesto.EnvironmentVariable[]
---@field should_exec boolean

-- ===============================================================
-- BuildEvent payloads
-- ===============================================================

---@class pesto.BuildEvent
---@field id pesto.BuildEventId
---@field children pesto.BuildEventId[]
---@field last_message boolean
-- One of the following fields should be defined
---@field progress pesto.Progress|nil
---@field aborted pesto.Aborted|nil
---@field started pesto.BuildStarted|nil
---@field unstructured_command_line pesto.UnstructuredCommandLine|nil
-- TODO
--@field structured_command_line CommandLine|nil
---@field options_parsed pesto.OptionsParsed|nil
---@field workspace_status pesto.WorkspaceStatus|nil
---@field fetch pesto.Fetch|nil
---@field configuration pesto.Configuration|nil
---@field expanded pesto.PatternExpanded|nil
---@field configured pesto.TargetConfigured|nil
---@field action pesto.ActionExecuted|nil
---@field named_set_of_files pesto.NamedSetOfFiles|nil
---@field completed pesto.TargetComplete|nil
---@field test_result pesto.TestResult|nil
---@field test_progress pesto.TestProgress|nil
---@field test_summary pesto.TestSummary|nil
---@field target_summary pesto.TargetSummary|nil
---@field finished pesto.BuildFinished|nil
---@field build_tool_logs pesto.BuildToolLogs|nil
---@field build_metrics pesto.BuildMetrics|nil
---@field workspace_info pesto.WorkspaceConfig|nil
---@field build_metadata pesto.BuildMetadata|nil
---@field convenience_symlinks_identified pesto.ConvenienceSymlinksIdentified|nil
---@field exec_request pesto.ExecRequestConstructed|nil
---Note: These fields are non-standard fields that we've added for convenience
---@field kind pesto.BuildEventKind
---@field id_key string
local BuildEvent = {}
BuildEvent.__index = BuildEvent

---@param raw_event table
---@return pesto.BuildEvent
function BuildEvent:new(raw_event)
	---@type pesto.BuildEvent
	local o = setmetatable(raw_event, BuildEvent)
	o.kind = table_util.some_key(raw_event.id) --[[@as pesto.BuildEventKind]]
	o.id_key = o.get_id_key(o.id)
	return o
end

--- Gets a unique fingerprint for the build event ID
---@param build_event_id pesto.BuildEventId
---@return string
function BuildEvent.get_id_key(build_event_id)
	local specific_id_type = table_util.some_key(build_event_id)
	if type(specific_id_type) ~= "string" then
		error(string.format('unrecongized id type: "%s"', specific_id_type or "(type not given)"))
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
