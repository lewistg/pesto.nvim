local M = {}

local COMP_WORDBREAKS = {
	[":"] = true,
	["="] = true,
}

---@class pesto.BashCommandToken
---@field type "whitespace"|"word"
---@field value string
---@field indexes [number, number]

---Extracts a word token
---@param line string
---@param curr_index number
---@return pesto.BashCommandToken
local function read_word(line, curr_index)
	assert(string.len(line) > 0)
	assert(not line:sub(curr_index, curr_index):match("%s"))

	---@type string[]
	local chars = {}
	---@type number
	local i = curr_index
	---@type string|nil When this variable is defined, it implies a string is being competed
	local string_quote = nil

	while i <= string.len(line) do
		local c = line:sub(i, i)
		if string_quote and c == string_quote then
			-- Finished an open string
			string_quote = nil
			i = i + 1
		elseif c == "'" or c == '"' then
			string_quote = c
			i = i + 1
		elseif c == "\\" then
			-- Consume the escaped character
			table.insert(chars, line:sub(i + 1, i + 1))
			i = i + 2
		elseif COMP_WORDBREAKS[c] ~= nil and string_quote == nil then
			-- See documentation for COMP_WORDBREAKS; ":" is considered its own word.
			if #chars == 0 then
				table.insert(chars, c)
				i = i + 1
			end
			break
		elseif c:match("%s") and string_quote == nil then
			-- Finished word
			break
		else
			table.insert(chars, c)
			i = i + 1
		end
	end

	return {
		type = "word",
		value = table.concat(chars),
		indexes = { curr_index, math.max(curr_index, i - 1) },
	}
end

---Extracts a whitespace token
---@param line string
---@param curr_index number
---@return pesto.BashCommandToken
local function read_whitespace(line, curr_index)
	assert(string.len(line) > 0)
	assert(line:sub(curr_index, curr_index):match("%s"))

	---@type number
	local i = curr_index
	while i <= string.len(line) do
		if not line:sub(i, i):match("%s") then
			break
		end
		i = i + 1
	end
	local end_index = i - 1
	return {
		type = "whitespace",
		value = line:sub(curr_index, end_index),
		indexes = { curr_index, end_index },
	}
end

---Tokenizes a line. Basic escaping is supported
---@param line string
---@return pesto.BashCommandToken[]
function M.tokenize(line)
	---@type pesto.BashCommandToken[]
	local tokens = {}
	---@type number
	local i = 1
	while i <= string.len(line) do
		---@type fun(line: string, curr_index: number): pesto.BashCommandToken
		local read_token
		if line:sub(i, i):match("%s") then
			read_token = read_whitespace
		else
			read_token = read_word
		end
		local token = read_token(line, i)
		table.insert(tokens, token)
		i = token.indexes[2] + 1
	end

	return tokens
end

--- Finds the "current" token. This is the token the cursor is next to. If it's
--- a word token, it'll be the word that would be subject to completion.
---@param bash_command_tokens pesto.BashCommandToken[]
---@param cursor_pos number 0-indexed
---@return pesto.BashCommandToken
---@return number
function M.find_current_token(bash_command_tokens, cursor_pos)
	---@type number
	local one_indexed_cursor_pos = cursor_pos + 1
	for i, token in ipairs(bash_command_tokens) do
		local m, n = unpack(token.indexes)
		if one_indexed_cursor_pos >= m and one_indexed_cursor_pos <= n then
			if token.type == "word" then
				return token, i
			elseif token.type == "whitespace" then
				---@type pesto.BashCommandToken|nil
				local prev_word
				if i > 1 and bash_command_tokens[i - 1].type == "word" then
					prev_word = bash_command_tokens[i - 1]
				end
				if prev_word and prev_word.indexes[2] + 1 == one_indexed_cursor_pos then
					-- The cursor is abutting the previous word
					return prev_word, i - 1
				else
					return token, i
				end
			else
				assert(false, string.format("unrecognized token type: %s", token.type))
			end
		end
	end
	return bash_command_tokens[#bash_command_tokens], #bash_command_tokens
end

--- Converts completions from a bash command line completions to a Neovim command line completions
---@param bash_command_tokens pesto.BashCommandToken
---@param cursor_pos number 0-indexed
---@param completions string[]
---@return string[] nvim_completions
function M.bash_completions_to_nvim_completions(bash_command_tokens, cursor_pos, completions)
	local current_token, index = M.find_current_token(bash_command_tokens, cursor_pos)
	if current_token.type == "whitespace" then
		return completions
	elseif current_token.type == "word" then
		---@type pesto.BashCommandToken[]
		local prefix_words = {}

		if COMP_WORDBREAKS[current_token.value] then
			table.insert(prefix_words, current_token)
		end

		local i = index - 1
		while i >= 1 and bash_command_tokens[i].type == "word" do
			table.insert(prefix_words, bash_command_tokens[i])
			i = i - 1
		end

		local prefix = table.concat(vim.tbl_map(function(token)
			return token.value
		end, vim.fn.reverse(prefix_words)))

		return vim.tbl_map(function(completion)
			return prefix .. completion
		end, completions)
	else
		assert(false, string.format("unrecognized token type: %s", current_token.type))
	end
	return {}
end

return M
