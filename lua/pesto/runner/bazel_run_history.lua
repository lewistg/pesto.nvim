---@class pesto.BazelRunHistory
---@field private _run_opts pesto.RunBazelOpts[]
local BazelRunHistory = {}
BazelRunHistory.__index = BazelRunHistory

BazelRunHistory.MAX_HISTORY = 100
BazelRunHistory.HISTORY_PRUNE_THRESHOLD = 200

function BazelRunHistory:new()
  local o = setmetatable({}, BazelRunHistory)

  o._run_opts = {}

  return o
end

---@param run_opts pesto.RunBazelOpts
function BazelRunHistory:push_run_opts(run_opts)
  table.insert(self._run_opts, run_opts)
  self:_maybe_prune_history()
end

function BazelRunHistory:_maybe_prune_history()
  if #self._run_opts <= BazelRunHistory.HISTORY_PRUNE_THRESHOLD then
    return
  end
  self._run_opts =
    vim.iter(self._run_opts):slice(BazelRunHistory.MAX_HISTORY, #self._run_opts):totable()
end

---@return pesto.RunBazelOpts|nil
function BazelRunHistory:get_last_run_opts()
  return self._run_opts[#self._run_opts]
end

return BazelRunHistory
