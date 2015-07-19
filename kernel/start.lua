term.clear()
term.setCursorPos(1, 1)

if unpack == nil then
	unpack = table.unpack
end

System = {
	Version = "1.0";
}

local components = {
	{ "Path", "kernel/path.lua" };
	{ "Sandbox", "kernel/sandbox.lua" };
	{ "ShellMgr", "kernel/shellmgr.lua" };
	{ "Tasks", "kernel/tasks.lua"};
}

local function loadComponents(loadCallback)
	for _,v in pairs(components) do
		local chunk, msg = loadfile(v[2], _ENV or getfenv())
		if chunk == nil then
			printError("Syntax error: " .. msg)
		end
	
		local ok, err = pcall(function()
			System[v[1]] = chunk()
		end)
		
		loadCallback(v[1], v[2])
		
		if not ok then
			printError("Failed! Error: " .. err, 0)
		end
	end
end

local function mainLoop(e, p1, p2, p3, p4, p5)
	System.Tasks.KeepAlive({ e, p1, p2, p3, p4, p5 })
end

print("Running cheetOS v" .. System.Version)
print("Loading components...")
loadComponents(function(k, v)
	print(" -> " .. k .. " (" .. v .. ")...")
end)

local sysinit = System.Tasks.NewTask("system/sysinit.lua")
sysinit:Start()

while true do
	mainLoop(os.pullEventRaw())
end