local bazel_repo = require("pesto.bazel.repo")

local cli = {}

function cli.insert_or_expand_target_labels(args)
	if #args == 0 then
		return
	end

	local expandable_commands = {
		["build"] = true,
		["run"] = true,
		["test"] = true,
	}

	local target_pattern = "^:[^%s]+"

	last_non_target_arg = nil
	for i = 1, #args do
		j = #args - i + 1
		if not string.match(args[j], target_pattern) then
			last_non_target_arg = j
			break
		end
	end

	if last_non_target_arg ~= nil and expandable_commands[args[last_non_target_arg]] then
		package_label = bazel_repo.get_package_label()
		if last_non_target_arg == #args then
			table.insert(args, package_label)
		else
			for i = last_non_target_arg + 1, #args do
				args[i] = package_label .. args[i]
			end
		end
	end
end

-- TODO
--local function run_bazel_complete(ArgLead, CmdLine, CursorPos)
--    return { "build", "run", "test" }
--end

return cli
