local M = {}

---@param arg_lead string
---@param candidates table[string]
---@return string[]
function M.get_completion_candidates(arg_lead, candidates)
	local arg_lead_len = string.len(arg_lead)
	--@type string[]
	local matching_candidates
	if arg_lead_len == 0 then
		matching_candidates = candidates
	else
		matching_candidates = {}
		for _, candiate in ipairs(candidates) do
			if candiate:sub(1, arg_lead_len) == arg_lead then
				table.insert(matching_candidates, candiate)
			end
		end
	end
	table.sort(matching_candidates)
	return matching_candidates
end

return M
