---@class pesto.BuildWindowManager.NewBuildOptions
---@field term_command string[]
---@field cwd string
---@field auto_open boolean
---@field get_build_event_tree (fun(): pesto.BuildEventTree|nil)|nil
---@field on_exit fun(is_current: boolean)|nil

---@class pesto.BuildWindowManager.BuildInfo
---@field term_buf_id number
---@field job_id number|nil
---@field exit_code number|nil
---@field build_summary_buf_id number|nil
---@field new_build_options pesto.BuildWindowManager.NewBuildOptions

---@alias pesto.BuildWindowManager.GetBuildSummaryBufError
---| 'not_available'
---| 'build_not_finished'

---@class pesto.BuildWindowManager
---@field private _current_build_info pesto.BuildWindowManager.BuildInfo|nil
---@field private _build_event_file_loader pesto.BuildEventFileLoader
local BuildWindowManager = {}
BuildWindowManager.__index = BuildWindowManager

--- We use this ID to mark/tag buffers as belonging to the pesto build window.
--- Windows that display - one of these marked buffers are considered build windows.
BuildWindowManager.PESTO_BUILD_WIN_BUFFER = 'pesto_build_win_buffer'

BuildWindowManager.AUTOCOMMAND_GROUP = 'pesto.default.buildWindowManager'

--- The build window may display two different types of buffers:
--- 1. A terminal buffer created by vim.fn.termopen
--- 2. The build summary buffer, which shows the high-level overview of the successful/failed targets
--- There should be only one build window per Neovim session
---@param build_event_file_loader pesto.BuildEventFileLoader
---@return pesto.BuildWindowManager
function BuildWindowManager:new(build_event_file_loader)
  local o = setmetatable({}, BuildWindowManager)

  o._current_build_info = nil
  o._build_event_file_loader = build_event_file_loader

  vim.api.nvim_create_augroup(BuildWindowManager.AUTOCOMMAND_GROUP, {})

  return o
end

---@private
BuildWindowManager._phrases = {
  no_available_build_summary = 'Pesto: No available build summary',
  build_not_finished = 'Pesto: Current build has not finished',
}

---@param opts pesto.BuildWindowManager.NewBuildOptions
function BuildWindowManager:start_new_build(opts)
  local term_buf_id = vim.api.nvim_create_buf(false, true)

  ---@type pesto.BuildWindowManager.BuildInfo
  local build_info = {
    term_buf_id = term_buf_id,
    new_build_options = opts,
  }
  self._current_build_info = build_info

  self:_mark_buffer_as_build_win_buf(build_info.term_buf_id)

  ---@type boolean
  local scrolled_to_bottom = false

  build_info.job_id = vim.api.nvim_buf_call(build_info.term_buf_id, function()
    local job_id = vim.fn.jobstart(opts.term_command, {
      cwd = opts.cwd,
      on_stdout = function(_, chunks)
        if scrolled_to_bottom then
          return
        end
        for _, win_id in ipairs(self:find_build_windows(0)) do
          vim.api.nvim_win_call(win_id, function()
            -- Move the cursor to the bottom. Doing this one time
            -- should cause the buffer to tail the output
            vim.cmd.normal('G')
          end)
        end
        scrolled_to_bottom = true
      end,
      on_exit = function(_, exit_code)
        build_info.exit_code = exit_code
        ---@diagnostic disable-next-line: invisible
        if opts.on_exit ~= nil then
          opts.on_exit(build_info == self._current_build_info)
        end

        if build_info ~= self._current_build_info then
          vim.api.nvim_buf_delete(term_buf_id, { force = true })
        end

        self:_set_quick_exit_keymaps(term_buf_id)

        -- Wrapping these vim.notify calls in a vim.schedule seems to
        -- prevent (perhaps) a textlock issue that blocks us from
        -- immediately opening the quickfix window.
        if exit_code == 0 then
          vim.schedule(function()
            vim.notify('Pesto: Build succeeded', vim.log.levels.INFO)
          end)
        else
          vim.schedule(function()
            vim.notify('Pesto: Build failed', vim.log.levels.ERROR)
          end)
        end
      end,
      term = true,
    })
    return job_id
  end)

  local logger = require('pesto.logger')
  logger.debug(
    string.format(
      "Started new terminal buffer for bazel. buf_id=%d, command='%s'",
      term_buf_id,
      table.concat(opts.term_command, ' ')
    )
  )

  if opts.auto_open then
    self:_get_or_create_tab_build_window(0, build_info.term_buf_id)
  end
  self:_set_status_lines(build_info.term_buf_id)
  self:view_build_term()

  self:_clean_up_old_bufs()
end

---@private
---@param buf_id number
function BuildWindowManager:_set_quick_exit_keymaps(buf_id)
  vim.api.nvim_buf_set_keymap(buf_id, 'n', '<CR>', ':q<CR>', {
    desc = 'Quit this Bazel output window',
    silent = true,
  })
end

---@return number|nil exit_code If the build is still ongoing, will return nil
function BuildWindowManager:get_build_exit_code()
  return self._current_build_info and self._current_build_info.exit_code
end

function BuildWindowManager:is_build_win_current()
  local buf_id = vim.api.nvim_win_get_buf(0)
  if vim.b[buf_id][BuildWindowManager.PESTO_BUILD_WIN_BUFFER] then
    return vim.bo[buf_id].buftype == 'terminal'
  end
  return false
end

function BuildWindowManager:_clean_up_old_bufs()
  local logger = require('pesto.logger')
  if self._current_build_info == nil then
    logger.debug('No current build. There should be no old windows to clean up')
    return
  end
  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[buf_id][BuildWindowManager.PESTO_BUILD_WIN_BUFFER] then
      if
        vim.bo[buf_id].buftype == 'terminal' and buf_id ~= self._current_build_info.term_buf_id
      then
        if vim.fn.jobwait({ vim.bo[buf_id].channel }, 0)[1] < 0 then
          -- Buffer will get cleaned up in the job's on_exit. See start_new_build method
          logger.debug(
            string.format(string.format('Stopping previous build terminal buffer %d', buf_id))
          )
          vim.fn.jobstop(vim.bo[buf_id].channel)
        else
          vim.api.nvim_buf_delete(buf_id, { force = true })
        end
      elseif
        vim.bo[buf_id].buftype ~= 'terminal'
        and (
          self._current_build_info.build_summary_buf_id == nil
          or self._current_build_info.build_summary_buf_id ~= buf_id
        )
      then
        logger.debug(
          string.format(string.format('Deleting previous build summary window %d', buf_id))
        )
        vim.api.nvim_buf_delete(buf_id, { force = true })
      end
    end
  end
end

---@private
---@param term_buf_id number
function BuildWindowManager:_set_status_lines(term_buf_id)
  ---@param win_id number|nil
  local function set_statusline(win_id)
    vim.wo[win_id or 0][0].statusline = '[Pesto: Bazel] (Press ENTER to close) %F'
  end

  vim.api.nvim_clear_autocmds({
    buffer = term_buf_id,
    group = BuildWindowManager.AUTOCOMMAND_GROUP,
  })

  vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
    buffer = term_buf_id,
    callback = function()
      local win_id = vim.api.nvim_get_current_win()
      set_statusline(win_id)
    end,
    group = BuildWindowManager.AUTOCOMMAND_GROUP,
  })

  vim.iter(self:find_build_windows()):each(function(win_id)
    vim.api.nvim_win_call(win_id, set_statusline)
  end)
end

function BuildWindowManager:open_build_term()
  if self._current_build_info == nil then
    return nil
  end
  self:_get_or_create_tab_build_window(0, self._current_build_info.term_buf_id)
  return self._current_build_info.term_buf_id
end

function BuildWindowManager:view_build_term()
  if self._current_build_info ~= nil then
    self:_view_buf(self._current_build_info.term_buf_id)
  end
end

function BuildWindowManager:open_build_summary()
  local buf_id, error_id = self:_get_or_create_build_summary_buf()
  if buf_id ~= nil then
    self:_get_or_create_tab_build_window(0, buf_id)
    self:view_build_summary()
  elseif error_id then
    self:_notify_build_summary_error(error_id)
  end
end

function BuildWindowManager:view_build_summary()
  local buf_id, error_id = self:_get_or_create_build_summary_buf()
  if buf_id ~= nil then
    self:_view_buf(buf_id)
  elseif error_id then
    self:_notify_build_summary_error(error_id)
  end
end

---@param error_id pesto.BuildWindowManager.GetBuildSummaryBufError
function BuildWindowManager:_notify_build_summary_error(error_id)
  if error_id == 'not_available' then
    vim.notify(BuildWindowManager._phrases.no_available_build_summary, vim.log.levels.INFO)
  elseif error_id == 'build_not_finished' then
    vim.notify(BuildWindowManager._phrases.build_not_finished, vim.log.levels.INFO)
  end
end

---@private
---@return number|nil
---@return pesto.BuildWindowManager.GetBuildSummaryBufError|nil
function BuildWindowManager:_get_or_create_build_summary_buf()
  local build_summary_buf_id
  if self._current_build_info == nil then
    return nil, 'not_available'
  elseif self._current_build_info.new_build_options.get_build_event_tree == nil then
    return nil, 'not_available'
  elseif self._current_build_info.exit_code == nil then
    return nil, 'build_not_finished'
  elseif self._current_build_info.build_summary_buf_id == nil then
    local build_event_tree = self._current_build_info.new_build_options.get_build_event_tree()
    if not build_event_tree then
      return
    end
    local BuildEventsBuffer = require('pesto.ui.build_events_buffer.build_events_buffer')
    local build_events_buffer =
      BuildEventsBuffer:new(build_event_tree, self._build_event_file_loader)
    build_summary_buf_id = build_events_buffer:get_buf_id()
    self:_mark_buffer_as_build_win_buf(build_summary_buf_id)
    self._current_build_info.build_summary_buf_id = build_summary_buf_id
  end
  return self._current_build_info.build_summary_buf_id
end

---@param buf_id number
function BuildWindowManager:_view_buf(buf_id)
  local build_win_ids = self:find_build_windows()
  for _, win_id in pairs(build_win_ids) do
    vim.api.nvim_win_set_buf(win_id, buf_id)
  end
end

--- Finds pesto.nvim's "build windows"
---@param tabpage number|nil
---@private
---@return {[number]: any} win_ids
function BuildWindowManager:find_build_windows(tabpage)
  ---@type number[]
  local tabpages = {}
  if tabpage ~= nil then
    tabpages = { tabpage }
  else
    tabpages = vim.api.nvim_list_tabpages()
  end

  ---@type number[]
  local win_ids = {}

  for _, tabpg in ipairs(tabpages) do
    for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(tabpg)) do
      local buf_id = vim.api.nvim_win_get_buf(win_id)
      if vim.b[buf_id][BuildWindowManager.PESTO_BUILD_WIN_BUFFER] ~= nil then
        table.insert(win_ids, win_id)
      end
    end
  end

  return win_ids
end

---@param tabpage number
---@param buf_id number If we're creating a new build window, then we'll display this buffer in the new window
---@return number[] win_ids The window handles for the build windows in the given tab
function BuildWindowManager:_get_or_create_tab_build_window(tabpage, buf_id)
  local build_win_ids = self:find_build_windows(tabpage)
  if #build_win_ids == 0 then
    vim.cmd('botright below new')
    local new_win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(new_win_id, buf_id)
    return { new_win_id }
  else
    return build_win_ids
  end
end

---@param buf_id number
function BuildWindowManager:_mark_buffer_as_build_win_buf(buf_id)
  vim.b[buf_id][BuildWindowManager.PESTO_BUILD_WIN_BUFFER] = true
end

return BuildWindowManager
