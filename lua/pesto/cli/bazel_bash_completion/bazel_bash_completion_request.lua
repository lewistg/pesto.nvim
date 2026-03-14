local M = {}

---@param arg_type string
---@return fun(arg_type: string): string
local function get_arg_factory_fn(arg_type)
	---@param arg string
	local arg_factory_fn = function(arg)
		return arg_type .. ":" .. arg
	end
	return arg_factory_fn
end

local bash_completion_args = {
	cwd = get_arg_factory_fn("cwd"),
	comp_line = get_arg_factory_fn("comp_line"),
	comp_word_len = get_arg_factory_fn("comp_word_len"),
	comp_word = get_arg_factory_fn("comp_word"),
	comp_point = get_arg_factory_fn("comp_point"),
	comp_cword = get_arg_factory_fn("comp_cword"),
}

---@param bash_command_tokens pesto.BashCommandToken[]
---@param cursor_pos number 0-indexed
---@return string[] comp_words
---@return number cword 0-indexed
local function get_comp_words(bash_command_tokens, cursor_pos)
	local bash_command_util = require("pesto.cli.bazel_bash_completion.bash_command_util")
	local _, current_token_index = bash_command_util.find_current_token(bash_command_tokens, cursor_pos)

	---@type string[]
	local comp_words = {}
	---@type number
	local cword = 1

	for i, token in ipairs(bash_command_tokens) do
		if i == current_token_index and token.type == "whitespace" then
			table.insert(comp_words, "")
		elseif token.type == "word" then
			table.insert(comp_words, token.value)
		end
		if i == current_token_index then
			cword = #comp_words - 1
		end
	end

	return comp_words, cword
end

---@param buf_nr number
---@return string cwd
local function get_cwd(buf_nr)
	-- Note: In the unit test context, this vim.fn.getbufinfo will return a nil value
	local buf_info = vim.fn.getbufinfo(buf_nr)[1] or {}
	---@type string
	local buf_path = buf_info.name or ""
	return vim.fs.dirname(buf_path)
end

---@param bash_command_tokens pesto.BashCommandToken[]
---@return string
local function get_comp_line(bash_command_tokens)
	local token_values = vim.tbl_map(function(token)
		return token.value
	end, bash_command_tokens)
	return table.concat(token_values, "")
end

---@param nvim_complete_opts SubcommandCompleteOpts
---@param bash_command_tokens pesto.BashCommandToken[]
function M.get_bazel_bash_completion_request(nvim_complete_opts, bash_command_tokens)
	---See tools/pesto-bash-helpers/pesto-bash-complete-bazel.sh for the
	---protocol here. Order matters.
	---@type string[]
	local completion_request = {}

	local cwd = get_cwd(nvim_complete_opts.buf_nr)
	table.insert(completion_request, bash_completion_args.cwd(cwd))

	local comp_line = get_comp_line(bash_command_tokens)
	table.insert(completion_request, bash_completion_args.comp_line(comp_line))

	local comp_words, cword = get_comp_words(bash_command_tokens, nvim_complete_opts.cursor_pos)

	table.insert(completion_request, bash_completion_args.comp_word_len(tostring(#comp_words)))
	for _, comp_word in ipairs(comp_words) do
		table.insert(completion_request, bash_completion_args.comp_word(comp_word))
	end

	table.insert(completion_request, bash_completion_args.comp_point(tostring(nvim_complete_opts.cursor_pos)))

	table.insert(completion_request, bash_completion_args.comp_cword(tostring(cword)))

	return completion_request
end

return M
