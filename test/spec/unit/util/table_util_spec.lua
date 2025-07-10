local table_util = require("pesto.util.table_util")

describe("map", function()
	it("transforms the values of a table", function()
		local mapped = table_util.map({ 0, 1, 2, 3 }, function(x)
			return x * x
		end)
		assert.are.same({ 0, 1, 4, 9 }, mapped)
	end)
end)

describe("filter", function()
	it("returns copy of table with filtered values removed", function()
		local t = { 0, 1, 2, 3, 4, 5, 6, 7, 8 }
		local filtered_t = table_util.filter(t, function(x)
			return x % 2 == 0
		end)
		assert.are.same({ 0, 2, 4, 6, 8 }, filtered_t)
	end)
end)

describe("sorted_insert", function()
	local function compare(a, b)
		return a - b
	end

	---@type {nums: number[], num: number, expected_nums: number[]}[]
	local test_cases = {
		{
			nums = {},
			num = 1,
			expected_nums = { 1 },
		},
		{
			nums = { 2 },
			num = 1,
			expected_nums = { 1, 2 },
		},
		{
			nums = { 1 },
			num = 2,
			expected_nums = { 1, 2 },
		},
		{
			nums = { 1, 3 },
			num = 2,
			expected_nums = { 1, 2, 3 },
		},
		{
			nums = { 1, 2 },
			num = 3,
			expected_nums = { 1, 2, 3 },
		},
		{
			nums = { 2, 3 },
			num = 1,
			expected_nums = { 1, 2, 3 },
		},
		{
			nums = { 1, 2, 3, 4, 6, 7, 8, 9 },
			num = 5,
			expected_nums = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
		},
	}

	for i, test_case in ipairs(test_cases) do
		it(string.format("sorted_insert test case #%d", i), function()
			table_util.sorted_insert(test_case.nums, test_case.num, compare)
			assert.are.same(test_case.expected_nums, test_case.nums)
		end)
	end
end)
