--[[
	Top level coroutine override taken from http://www.computercraft.info/forums2/index.php?/topic/14785-a-smaller-top-level-coroutine-override/
]]

os.queueEvent("modem_message")
local r = rednet.run
function rednet.run()
	error("", 0)
end

local p = printError
function _G.printError()
	_G.printError = p
	rednet.run = r
	local ok, err = pcall(function() assert(loadfile("kernel/start.lua"))() end)
	if not ok then printError(err) end
end