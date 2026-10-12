local old_notify = vim.notify

--- vim.notify(..., vim.log.levels.ERROR) and vim.fn.wait have a bad
--- interaction. This is problem in tests. We avoid this issue by clipping the
--- log level at WARN.
--- See: https://github.com/neovim/neovim/issues/39816
---
--- @param message string
--- @param level integer|nil
vim.notify = function(message, level)
  if (level == vim.log.levels.ERROR) then
    level = vim.log.levels.WARN
  end
  old_notify(message, level)
end
