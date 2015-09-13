local registryEntry = {
	StartupFile = "U:/start.ss",
	StartWorkingDir = "U:/",

	TextColour = "cyan",
	BackgroundColour = "black",

	ActiveTextColour = "white",
	ActiveBackgroundColour = "grey",

	InputChar = "$"
}

-- Make sure the shell keys exist
System.Registry.ValidateKey("Shell", registryEntry)

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

local function getColourFromRegistry(key)
	local colour = System.Registry.Get(key)
	if type(colour) == "number" then
		return colour
	elseif type(colour) == "string" then
		return colours[colour]
	end
end

local textColour = getColourFromRegistry("Shell/TextColour")
local backgroundColour = getColourFromRegistry("Shell/BackgroundColour")
local activeTextColour = getColourFromRegistry("Shell/ActiveTextColour")
local activeBackgroundColour = getColourFromRegistry("Shell/ActiveBackgroundColour")

local function runShell()
	setColours(textColour, backgroundColour)
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

	local inputChar = System.Registry.Get("Shell/InputChar")

	local history = {}

	while true do
		local ok, err = pcall(function()
			setColours(textColour, activeBackgroundColour)
			term.clearLine()
			write(shell.dir() .. inputChar .. " ")

			setColours(activeTextColour, activeBackgroundColour)
			local input = read(nil, history)
			history[#history + 1] = input

			setColours(colours.white, backgroundColour)
			term.clearLine()
			processInput(input)
		end)

		if not ok then
			printError(err)
		end
	end
end

runShell()
