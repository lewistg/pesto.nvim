local bazel_build_event_util = require("pesto.cli.bazel_build_event_util")
local terminal_buf_info = require("pesto.runner.default.terminal_buf_info")

-- The default Pesto bazel runner runs bazel in a terminal buffer. Since tabs
-- are somewhat considered workspaces Pesto dedicates one terminal buffer for
-- builds per tab. This class manages those buffers, including spinning them up
-- when a new bazel command needs to be executed.
--
---@class pesto.BuildTerminalManager
---@field private _terminal_buf_info {[number]: pesto.TerminalBufInfo}
---@field private _build_event_json_loader pesto.BuildEventJsonLoader
local BuildTerminalManager = {}
BuildTerminalManager.__index = BuildTerminalManager

---@param build_event_json_loader pesto.BuildEventJsonLoader
---@return pesto.BuildTerminalManager
function BuildTerminalManager:new(build_event_json_loader)
	local o = setmetatable({}, BuildTerminalManager)

	o._terminal_buf_info = {}
	o._build_event_json_loader = build_event_json_loader

	---@type number
	local autocmd_group = vim.api.nvim_create_augroup("pesto.BuildTerminalManager", { clear = true })
	vim.api.nvim_create_autocmd("TabClosed", {
		group = autocmd_group,
		callback = function(args)
			-- Note: args.file is id of the tab page being closed (see `h: TabClosed`)
			o:_on_tab_closed(args.file)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = autocmd_group,
		callback = function(args)
			o:_on_buf_wipeout(args.buf)
		end,
	})

	return o
end

---@param tab_id number
---@return number|nil
function BuildTerminalManager:get_tab_id(tab_id)
	return self:_find_tab_terminal_buf(tab_id)
end

---@param tab_id number
function BuildTerminalManager:_on_tab_closed(tab_id)
	for buf_id, term_buf_info in pairs(self._terminal_buf_info) do
		if term_buf_info.tab_id == tab_id then
			vim.api.nvim_buf_delete(buf_id, { force = true })
		end
	end
end

---@param buf_id number
function BuildTerminalManager:_on_buf_wipeout(buf_id)
	self._terminal_buf_info[buf_id] = nil
end

---@param run_bazel_opts RunBazelOpts
---@param on_build_finished fun(event: pesto.BuildFinishedEvent)
---@return number
function BuildTerminalManager:run_bazel(run_bazel_opts, on_build_finished)
	---@type number
	local tab_id = vim.api.nvim_get_current_tabpage()

	---@type number|nil
	local prev_term_buf_id = self:_find_tab_terminal_buf(tab_id)

	---@type number
	local new_term_buf_id = self:_create_term_buf(run_bazel_opts, on_build_finished)

	if prev_term_buf_id ~= nil then
		for _, win_id in ipairs(vim.fn.win_findbuf(prev_term_buf_id)) do
			vim.api.nvim_win_set_buf(win_id, new_term_buf_id)
		end
		vim.api.nvim_buf_delete(prev_term_buf_id, {})
	end

	return new_term_buf_id
end

---@param buf_id number
function BuildTerminalManager:close_terminal_buf(buf_id)
	local term_buf_info = self._terminal_buf_info[buf_id]
	if term_buf_info == nil then
		return
	end
	local build_window = require("pesto.runner.default.build_window")
	local win_id = build_window.find_build_window(term_buf_info.tab_id)
	if win_id ~= nil then
		-- make sure it's not the last window that's open
		vim.api.nvim_win_close(win_id, false)
	end
end

---@private
---@param tab_id number|nil
---@return number|nil
function BuildTerminalManager:_find_tab_terminal_buf(tab_id)
	if tab_id == 0 or tab_id == nil then
		tab_id = vim.api.nvim_get_current_tabpage()
	end
	for buf_id, term_buf_info in pairs(self._terminal_buf_info) do
		if term_buf_info.tab_id == tab_id then
			return buf_id
		end
	end
	return nil
end

---@private
---@param run_opts RunBazelOpts
---@param on_build_finished fun(event: pesto.BuildFinishedEvent)
---@return number
function BuildTerminalManager:_create_term_buf(run_opts, on_build_finished)
	local tab_id = vim.api.nvim_get_current_tabpage()
	local buf_id = vim.api.nvim_create_buf(false, true)

	local bazel_command = table.concat(run_opts.bazel_command, " ")
	local command = string.format("(cd %s && %s)", run_opts.context.package_dir, bazel_command)

	self._terminal_buf_info[buf_id] = terminal_buf_info.init_terminal_buf_info(buf_id, tab_id)

	local term_buf_info = self._terminal_buf_info[buf_id]
	vim.api.nvim_buf_call(buf_id, function()
		vim.fn.termopen(command, {
			on_exit = function(job_id, exit_code, event_type)
				term_buf_info.exit_code = exit_code
				term_buf_info.bep_file = bazel_build_event_util.extract_bep_option(run_opts.bazel_command)
				if term_buf_info.exit_code == 0 then
					vim.notify("Pesto: Build succeeded", vim.log.levels.INFO)
				else
					vim.notify("Pesto: Build failed", vim.log.levels.ERROR)
				end
				---@type pesto.BuildFinishedEvent
				local event = require("pesto.runner.default.terminal_buffer_manager_events").BuildFinishedEvent:new(
					exit_code,
					term_buf_info.bep_file,
					self._build_event_json_loader
				)
				on_build_finished(event)
			end,
		})
	end)

	return buf_id
end

return BuildTerminalManager
