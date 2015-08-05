local function setColours(fg, bg)
	if fg ~= nil then
		term.setTextColour(term.isColour() and fg or colours.white)
	end

	if bg ~= nil then
		term.setBackgroundColour(term.isColour() and bg or colours.black)
	end
end

local function processInput(input)
	return shell.run(input)
end

local function runShell()
	setColours(colours.cyan, colours.black)
	term.clear()
	term.setCursorPos(1, 1)

	local startupFile = System.Registry.Get("Shell/StartupFile")
	if type(startupFile) == "string" then
		shell.run(startupFile)
	end

	local workingDir = System.Registry.Get("Shell/StartWorkingDir")
	if type(workingDir) == "string" then
		shell.setDir(workingDir)
	end

	local history = {}

	while true do
		local ok, err = pcall(function()
			setColours(colours.cyan, colours.black)
			write(shell.dir() .. "> ")

			setColours(colours.white, colours.black)
			local input = read(nil, history)

			processInput(input)
			history[#history + 1] = input
		end)

		if not ok then
			printError(err)
		end
	end
end

runShell()
