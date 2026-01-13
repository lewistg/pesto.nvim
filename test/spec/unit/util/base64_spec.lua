describe("base64.decode", function()
	---@type {encoded: string, decoded: string}[]
	local test_cases = {
		{
			encoded = "YQ==",
			decoded = "a",
		},
		{
			encoded = "YWI=",
			decoded = "ab",
		},
		{
			encoded = "YWJj",
			decoded = "abc",
		},
		{
			encoded = "YWJjZA==",
			decoded = "abcd",
		},
		{
			decoded = "hello, world",
			encoded = "aGVsbG8sIHdvcmxk",
		},
		{
			decoded = "four score and seven years ago",
			encoded = "Zm91ciBzY29yZSBhbmQgc2V2ZW4geWVhcnMgYWdv",
		},
	}

	it("decodes various things", function()
		local base64 = require("pesto.util.base64")
		for _, test_case in ipairs(test_cases) do
			assert.are.same(test_case.decoded, base64.decode(test_case.encoded))
		end
	end)
end)
