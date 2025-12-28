local M = {}

--- See: https://datatracker.ietf.org/doc/html/rfc4648#section-4
local BASE64_ALPHABET = {
	["A"] = 0,
	["B"] = 1,
	["C"] = 2,
	["D"] = 3,
	["E"] = 4,
	["F"] = 5,
	["G"] = 6,
	["H"] = 7,
	["I"] = 8,
	["J"] = 9,
	["K"] = 10,
	["L"] = 11,
	["M"] = 12,
	["N"] = 13,
	["O"] = 14,
	["P"] = 15,
	["Q"] = 16,
	["R"] = 17,
	["S"] = 18,
	["T"] = 19,
	["U"] = 20,
	["V"] = 21,
	["W"] = 22,
	["X"] = 23,
	["Y"] = 24,
	["Z"] = 25,
	["a"] = 26,
	["b"] = 27,
	["c"] = 28,
	["d"] = 29,
	["e"] = 30,
	["f"] = 31,
	["g"] = 32,
	["h"] = 33,
	["i"] = 34,
	["j"] = 35,
	["k"] = 36,
	["l"] = 37,
	["m"] = 38,
	["n"] = 39,
	["o"] = 40,
	["p"] = 41,
	["q"] = 42,
	["r"] = 43,
	["s"] = 44,
	["t"] = 45,
	["u"] = 46,
	["v"] = 47,
	["w"] = 48,
	["x"] = 49,
	["y"] = 50,
	["z"] = 51,
	["0"] = 52,
	["1"] = 53,
	["2"] = 54,
	["3"] = 55,
	["4"] = 56,
	["5"] = 57,
	["6"] = 58,
	["7"] = 59,
	["8"] = 60,
	["9"] = 61,
	["+"] = 62,
	["/"] = 63,
	["="] = -1,
}

--- See https://datatracker.ietf.org/doc/html/rfc4648
--- TODO: Replace with vim.base64.decode once Neovim 0.10 is supported
---@param str string Base64-encoded string
---@return string
function M.decode(str)
	local decoded = {}
	local bit = require("bit")
	local i = 1
	while i < #str do
		---@type number[]
		local encoded_group = {}
		for j = i, i + 3 do
			local char = str:sub(j, j)
			local group_char = BASE64_ALPHABET[char]
			if group_char == nil then
				error(string.format("invalid base64 character '%s'", char))
			end
			table.insert(encoded_group, group_char)
		end
		local group_bytes = {}
		group_bytes[1] = bit.bor(bit.lshift(encoded_group[1], 2), bit.rshift(encoded_group[2], 4))
		if encoded_group[3] ~= -1 then
			group_bytes[2] = bit.band(0xff, bit.bor(bit.lshift(encoded_group[2], 4), bit.rshift(encoded_group[3], 2)))
		end
		if encoded_group[4] ~= -1 then
			group_bytes[3] = bit.band(0xff, bit.bor(bit.lshift(encoded_group[3], 6), encoded_group[4]))
		end
		for _, char in ipairs(group_bytes) do
			-- table.insert(decoded, char)
			table.insert(decoded, string.char(char))
		end
		i = i + 4
	end
	return table.concat(decoded)
end

return M
