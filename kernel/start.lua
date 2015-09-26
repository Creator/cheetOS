term.clear()
term.setCursorPos(1, 1)

local _fs = _G.fs

if unpack == nil then
	unpack = table.unpack
end

System = {
	Version = "1.0";
}

local modules = {
	{ "Path", "kernel/path.lua" };
	{ "File", "kernel/filesys.lua" };

	{ "Events", "K:/events.lua" };
	{ "Sandbox", "K:/sandbox.lua" };
	{ "Tasks", "K:/tasks.lua"};
	{ "Library", "K:/library.lua" };
	{ "Security", "K:/security.lua" };
	{ "JSON", "K:/json.lua" };
	{ "Registry", "K:/registry.lua" };
	{ "Mounts", "K:/mounts.lua" };
	{ "ShellMgr", "K:/shellmgr.lua" };
	{ "Network", "K:/devices.lua" };
	{ "Socket", "K:/socket.lua" };
	{ "COPPER", "K:/copper.lua" };
}

local function loadModules(loadCallback)
	for i=1,#modules do
		local v = modules[i]
		local chunk, msg = loadfile(v[2], env)

		loadCallback(v[1], v[2])

		if chunk == nil then
			printError("Syntax error: " .. msg)
		end

		local ok, err = pcall(function()
			local module = chunk()
			if module ~= nil then
				module[1] = function() end -- Make sure the table can't be serialised

				local mt = getmetatable(module)
				if mt == nil then
					mt = setmetatable(module, {})
				end

				mt.__tostring = function()
					return "Kernel Module (" .. v[1] .. ")"
				end

				setmetatable(module, mt)

				System[v[1]] = module
			end
		end)

		if not ok then
			printError("Failed! Error: " .. err)
		end
	end
end

local function mainLoop(...)
	local e, p1, p2, p3, p4, p5 = System.Events.Translate(...)
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
	log = _fs.open("system/boot_log.txt", "w")

	print("Running cheetOS v" .. System.Version)
	print("Loading modules...")
	loadModules(function(k, v)
		print(" -> " .. k .. " (" .. v .. ")...")
	end)

	if System.Tasks.__replaceNative then
		System.Tasks.__replaceNative = nil
	end

	System.File.Unmount("K")

	log.close()
	log = nil

	print = oldPrint

	local sysinit = System.Tasks.NewTask("S:/sysinit.lua")
	sysinit:Start()

	while true do
		mainLoop(os.pullEventRaw())
	end
end
