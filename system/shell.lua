local function setColours(fg, bg)
	if fg ~= nil then
		term.setTextColour(term.isColour() and fg or colours.white)
	end
	
	if bg ~= nil then
		term.setBackgroundColour(term.isColour() and bg or colours.black)
	end
end

local function processInput(input)
	shell.run(input)
end

local function runShell()
	setColours(colours.cyan, colours.black)
	term.clear()
	term.setCursorPos(1, 1)
	
	print("Basic Shell for cheetOS " .. System.Version .. " (TID " .. __TID__ .. ")")
	
	local history = {}
	
	while true do
		setColours(colours.cyan, colours.black)
		write(shell.dir() .. "> ")
		
		setColours(colours.white, colours.black)
		local input = read(nil, history)
		processInput(input)
		history[#history + 1] = input
	end
end

runShell()