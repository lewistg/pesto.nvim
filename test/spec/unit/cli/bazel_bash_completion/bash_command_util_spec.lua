describe("bash_command_util.tokenize", function()
	it("tokenizes basic string", function()
		---@type pesto.BashCommandToken[]
		local expected_tokens = {
			{
				type = "word",
				value = "foo",
				indexes = { 1, 3 },
			},
			{
				type = "whitespace",
				value = " ",
				indexes = { 4, 4 },
			},
			{
				type = "word",
				value = "bar",
				indexes = { 5, 7 },
			},
			{
				type = "whitespace",
				value = " ",
				indexes = { 8, 8 },
			},
			{
				type = "word",
				value = "baz",
				indexes = { 9, 11 },
			},
		}
		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")
		local tokens = bash_command_util.tokenize("foo bar baz")
		assert.are.same(expected_tokens, tokens)
	end)

	it("tokenize string with quotes", function()
		---@type pesto.BashCommandToken[]
		local expected_tokens = {
			{
				type = "word",
				value = "foo",
				indexes = { 1, 3 },
			},
			{
				type = "whitespace",
				value = " ",
				indexes = { 4, 4 },
			},
			{
				type = "word",
				value = "bar",
				indexes = { 5, 9 },
			},
			{
				type = "whitespace",
				value = " ",
				indexes = { 10, 10 },
			},
			{
				type = "word",
				value = "baz",
				indexes = { 11, 13 },
			},
		}
		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")
		local tokens = bash_command_util.tokenize('foo "bar" baz')
		assert.are.same(expected_tokens, tokens)
	end)

	it("tokenize string with quotes with space", function()
		---@type pesto.BashCommandToken[]
		local expected_tokens = {
			{
				type = "word",
				value = "foo",
				indexes = { 1, 3 },
			},
			{
				type = "whitespace",
				value = " ",
				indexes = { 4, 4 },
			},
			{
				type = "word",
				value = "bar baz",
				indexes = { 5, 13 },
			},
			{
				type = "whitespace",
				value = " ",
				indexes = { 14, 14 },
			},
			{
				type = "word",
				value = "qux",
				indexes = { 15, 17 },
			},
		}
		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")
		local tokens = bash_command_util.tokenize('foo "bar baz" qux')
		assert.are.same(expected_tokens, tokens)
	end)

	it("tokenize string with escaped spaces", function()
		---@type pesto.BashCommandToken[]
		local expected_tokens = {
			{
				type = "word",
				value = "foo bar",
				indexes = { 1, 8 },
			},
			{
				type = "whitespace",
				value = " ",
				indexes = { 9, 9 },
			},
			{
				type = "word",
				value = "baz qux",
				indexes = { 10, 17 },
			},
		}
		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")
		local tokens = bash_command_util.tokenize("foo\\ bar baz\\ qux")
		assert.are.same(expected_tokens, tokens)
	end)

	it("tokenizes an empty string word", function()
		---@type pesto.BashCommandToken[]
		local expected_tokens = {
			{
				type = "word",
				value = "foo",
				indexes = { 1, 3 },
			},
			{
				type = "whitespace",
				value = " ",
				indexes = { 4, 4 },
			},
			{
				type = "word",
				value = "",
				indexes = { 5, 6 },
			},
			{
				type = "whitespace",
				value = " ",
				indexes = { 7, 7 },
			},
			{
				type = "word",
				value = "bar",
				indexes = { 8, 10 },
			},
		}
		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")
		local tokens = bash_command_util.tokenize('foo "" bar')
		assert.are.same(expected_tokens, tokens)
	end)

	it("tokenizes a string with the \"word-breaking\" ':' character", function()
		---@type pesto.BashCommandToken[]
		local expected_tokens = {
			{
				type = "word",
				value = "foo",
				indexes = { 1, 3 },
			},
			{
				type = "word",
				value = ":",
				indexes = { 4, 4 },
			},
			{
				type = "word",
				value = "bar",
				indexes = { 5, 7 },
			},
		}
		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")
		local tokens = bash_command_util.tokenize("foo:bar")
		assert.are.same(expected_tokens, tokens)
	end)
end)

describe("bash_command_util.find_current_token", function()
	it("basic case: finds word with cursor at the end", function()
		local test_util = require("pesto.cli.bazel_bash_completion.test.test_util")
		local command, cursor_pos = test_util.parse_command_test_case("bazel build| //foo:bar")
		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")

		local tokens = bash_command_util.tokenize(command)
		local current_token, token_index = bash_command_util.find_current_token(tokens, cursor_pos)

		assert.are.same({ type = "word", value = "build", indexes = { 7, 11 } }, current_token)
		assert.are.same(token_index, 3)
	end)

	it("basic case: finds word with cursor at the front", function()
		local test_util = require("pesto.cli.bazel_bash_completion.test.test_util")
		local command, cursor_pos = test_util.parse_command_test_case("bazel |build //foo:bar")
		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")

		local tokens = bash_command_util.tokenize(command)
		local current_token, token_index = bash_command_util.find_current_token(tokens, cursor_pos)

		assert.are.same({ type = "word", value = "build", indexes = { 7, 11 } }, current_token)
		assert.are.same(token_index, 3)
	end)

	it("basic case: finds whitespace token when the cursor is in the middle", function()
		local test_util = require("pesto.cli.bazel_bash_completion.test.test_util")
		local command, cursor_pos = test_util.parse_command_test_case("bazel | build //foo:bar")
		local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")

		local tokens = bash_command_util.tokenize(command)
		local current_token, token_index = bash_command_util.find_current_token(tokens, cursor_pos)

		assert.are.same({ type = "whitespace", value = "  ", indexes = { 6, 7 } }, current_token)
		assert.are.same(token_index, 2)
	end)
end)
