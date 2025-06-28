local M = {}

local logger = require("pesto.logger")
local table_util = require("pesto.util.table_util")

M.COMMAND_NAME = "Pesto"

---@class PestoCli
---@field run_command
---@field complete

---@param arg_lead string
---@param candidates table[string]
local function get_completion_candidates(arg_lead, candidates)
	local arg_lead_len = string.len(arg_lead)
	if arg_lead_len == 0 then
		return candidates
	end
	local matching_candiates = {}
	for _, candiate in ipairs(candidates) do
		if candiate:sub(1, arg_lead_len) == arg_lead then
			table.insert(matching_candiates, candiate)
		end
	end
	return matching_candiates
end

---@param subcommands {SUBCOMMAND_NAMES: string[], SUBCOMMANDS_BY_NAME: {[string]: Subcommand}}
---@return PestoCli
function M.make_cli(subcommands)
	-- See `:h command-completion-custom`
	---@param arg_lead string
	---@param cmd_line string
	---@param cursor_pos number
	local function complete(arg_lead, cmd_line, cursor_pos)
		local command_start, command_end = cmd_line:find(M.COMMAND_NAME)
		if not command_start then
			return {}
		end

		local subcommand_start, subcommand_end = cmd_line:find("[^%s]+", command_end + 1)
		local one_indexed_cursor_pos = cursor_pos + 1
		if
			subcommand_start == nil
			or (
				subcommand_start
				and one_indexed_cursor_pos >= subcommand_start
				and one_indexed_cursor_pos <= (subcommand_end + 1)
			)
		then
			return get_completion_candidates(arg_lead, subcommands.SUBCOMMAND_NAMES)
		else
			local subcommand_name = cmd_line:sub(subcommand_start, subcommand_end)
			logger.info("parsed subcommand: " .. subcommand_name)
			---@type Subcommand
			local subcommand = subcommands.SUBCOMMANDS_BY_NAME[subcommand_name]
			if subcommand.complete then
				logger.info("parsed completing: " .. subcommand_name)
				local subcmd_line = cmd_line:sub(subcommand_start)
				local subcmd_cursor_pos = cursor_pos - subcommand_start + 1
				local buf_nr = vim.api.nvim_get_current_buf()
				return subcommand.complete({
					subcommand_line = subcmd_line,
					cursor_pos = subcmd_cursor_pos,
					arg_lead = arg_lead,
					buf_nr = buf_nr,
				})
			end
		end
		return {}
	end

	---@param opts table See `:h lua-guide-commands-create`
	local function run_command(opts)
		-- There should be at least one farg value (the name of the subcommand)
		assert(#opts.fargs >= 1)

		local subcommand_name = opts.fargs[1]
		---@type Subcommand|nil
		local subcommand = subcommands.SUBCOMMANDS_BY_NAME[subcommand_name]

		if subcommand then
			subcommand.execute({
				fargs = table_util.slice(opts.fargs, 2),
				buf_nr = vim.api.nvim_get_current_buf(),
			})
		elseif string.len(subcommand_name) > 0 then
			vim.notify(string.format("[%s] Invalid subcommand '%s'", M.COMMAND_NAME, subcommand), vim.log.levels.ERROR)
		end
	end

	return {
		run_command = run_command,
		complete = complete,
	}
end

return M
