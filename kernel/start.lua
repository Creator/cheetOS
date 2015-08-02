term.clear()
term.setCursorPos(1, 1)

local _loadfile = _G.loadfile

if unpack == nil then
	unpack = table.unpack
end

System = {
	Version = "1.0";
}

local components = {
	{ "Path", "kernel/path.lua" };
	{ "Sandbox", "kernel/sandbox.lua" };
	{ "Tasks", "kernel/tasks.lua"};
	{ "ShellMgr", "kernel/shellmgr.lua" };
	{ "Library", "kernel/library.lua" };
	
	--[[ 
		File must be loaded last because 
		kernel files are no longer accessible
		after it is loaded!
	]]
	{ "File", "kernel/filesys.lua" };
}

local function loadComponents(loadCallback)
	for _,v in pairs(components) do
		local chunk, msg = _loadfile(v[2], _ENV or getfenv())
		
		loadCallback(v[1], v[2])
		
		if chunk == nil then
			printError("Syntax error: " .. msg)
		end
	
		local ok, err = pcall(function()
			System[v[1]] = chunk()
		end)
		
		if not ok then
			printError("Failed! Error: " .. err, 0)
		end
	end
end

local function mainLoop(e, p1, p2, p3, p4, p5)
	System.Tasks.KeepAlive({ e, p1, p2, p3, p4, p5 })
end

local log = nil

local oldPrint = print
print = function(...)
	local str = table.concat({ ... })
	if log ~= nil then
		log.writeLine(str)
	end
	return oldPrint(str)
end

do
	log = fs.open("system/boot_log.txt", "w")
	
	print("Running cheetOS v" .. System.Version)
	print("Loading components...")
	loadComponents(function(k, v)
		print(" -> " .. k .. " (" .. v .. ")...")
	end)
	
	if System.Tasks.__replaceNative then
		System.Tasks.__replaceNative = nil
	end

	log.close()
	log = nil
	
	print = oldPrint
	
	local sysinit = System.Tasks.NewTask("S:/sysinit.lua")
	sysinit:Start()

	while true do
		mainLoop(os.pullEventRaw())
	end
end