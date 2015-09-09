local EXIT_SUCCESS = 0
local EXIT_FAILURE = 1

local function runShellScript(file)
	local fhandle = fs.open(file, "r")

	local lineNum = 0
	for line in fhandle.readLine do
		lineNum = lineNum + 1
		if line:match("^%s-$") == nil and line:match("^[/%-][/%-].-$") == nil then
			shell.run(line)
		end
	end
end

local file = ...
if not file then
	printError("No file specified.")
	return EXIT_FAILURE
else
	if not fs.exists(file) then
		printError("The specified file doesn't exist!")
		return EXIT_FAILURE
	end

	runShellScript(file)
	return EXIT_SUCCESS
end
