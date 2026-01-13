---@class pesto.MockRemoteApisHelpersCommandBuilder: pesto.RemoteApisHelpersCommandBuilder
local MockRemoteApisHelpersCommandBuilder = {}
MockRemoteApisHelpersCommandBuilder.__index = MockRemoteApisHelpersCommandBuilder

function MockRemoteApisHelpersCommandBuilder:new()
	local o = setmetatable({}, MockRemoteApisHelpersCommandBuilder)
	return o
end

---@param options {address: string, log_file?: string|nil}
---@return string[]
function MockRemoteApisHelpersCommandBuilder:get_fetch_byte_streams_command(options)
	local busted_fixtures = require("busted.fixtures")
	local mock_fetch_byte_stream = busted_fixtures.path("./fake_fetch_byte_stream.sh")
	return { mock_fetch_byte_stream }
end

describe("pesto.ByteStreamClient", function()
	it("get_byte_streams fetches byte streams", function()
		local mock_remote_apis_helpers_command_builder = MockRemoteApisHelpersCommandBuilder:new()
		local ByteStreamClient = require("pesto.bazel.byte_stream_client")
		local byte_stream_client = ByteStreamClient:new(mock_remote_apis_helpers_command_builder)

		local byte_stream_service_uri = "grpc://localhost:8980"
		local expected_byte_stream_lines = {
			["bytestream://localhost:8980/blobs/477b2a3983637d7633933691800642a388a38e1dd81ebe12304a603dc3b3dfba/226"] = {
				"main.cc: In function 'int main(int, char**)':",
				"main.cc:5:5: error: 'x' was not declared in this scope",
				"    5 |     x + y;",
				"      |     ^",
				"main.cc:5:9: error: 'y' was not declared in this scope",
				"    5 |     x + y;",
				"      |         ^",
				"",
			},
		}

		---@type boolean
		local finished = false
		---@type {[string]: string[]}
		local responses = {}
		---@type string[]
		local byte_stream_uris = vim.tbl_keys(expected_byte_stream_lines)

		byte_stream_client:get_byte_streams(byte_stream_service_uri, byte_stream_uris, function(lines, uri)
			responses[uri] = lines
		end, function(failed_uris)
			finished = (#failed_uris == 0)
		end)

		vim.wait(200, function()
			return finished
		end)
		assert.is_true(finished)

		assert.are.same(expected_byte_stream_lines, responses)
	end)
end)
