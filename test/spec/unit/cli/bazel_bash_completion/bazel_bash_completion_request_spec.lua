describe("bazel_bash_completion_request.get_completion_request", function()
	it("builds a completion request (case: cursor at the end)", function()
		local test_util = require("pesto.cli.bazel_bash_completion.test.test_util")
		local subcommand_line, cursor_pos = test_util.parse_command_test_case("bazel build |")

		---@type SubcommandCompleteOpts
		local subcommand_complete_opts = {
			subcommand_line = subcommand_line,
			cursor_pos = cursor_pos,
			arg_lead = "",
			buf_nr = 0,
		}

		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")
		local bash_tokens = bash_command_util.tokenize(subcommand_complete_opts.subcommand_line)

		local bazel_bash_completion_request = require("pesto.cli.bazel_bash_completion.bazel_bash_completion_request")
		local request =
			bazel_bash_completion_request.get_bazel_bash_completion_request(subcommand_complete_opts, bash_tokens)

		---@type string[]
		local expected_request = {
			"cwd:.",
			"comp_line:bazel build ",
			"comp_word_len:3",
			"comp_word:bazel",
			"comp_word:build",
			"comp_word:",
			"comp_point:12",
			"comp_cword:2",
			"",
		}

		assert.are.same(expected_request, request)
	end)

	it("builds a completion request (case: cursor in the middle of the string)", function()
		local test_util = require("pesto.cli.bazel_bash_completion.test.test_util")
		local subcommand_line, cursor_pos = test_util.parse_command_test_case("bazel build| //foo:bar")

		---@type SubcommandCompleteOpts
		local subcommand_complete_opts = {
			subcommand_line = subcommand_line,
			cursor_pos = cursor_pos,
			arg_lead = "",
			buf_nr = 0,
		}

		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")
		local bash_tokens = bash_command_util.tokenize(subcommand_complete_opts.subcommand_line)

		local bazel_bash_completion_request = require("pesto.cli.bazel_bash_completion.bazel_bash_completion_request")
		local request =
			bazel_bash_completion_request.get_bazel_bash_completion_request(subcommand_complete_opts, bash_tokens)

		---@type string[]
		local expected_request = {
			"cwd:.",
			"comp_line:bazel build //foo:bar",
			"comp_word_len:5",
			"comp_word:bazel",
			"comp_word:build",
			"comp_word://foo",
			"comp_word::",
			"comp_word:bar",
			"comp_point:11",
			"comp_cword:1",
			"",
		}

		assert.are.same(expected_request, request)
	end)
end)
