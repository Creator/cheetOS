local Library = {}

function Library.Load(file, ...)
	local env = {}
	setmetatable(env, { __index = _G })
	local chunk, err = loadfile(file, env)
	if chunk == nil then
		error("Couldn't load lib " .. fs.getName(file) .. ": " .. err, 2)
		return
	end
	
	local coro = coroutine.create(chunk)
	local success, event = coroutine.resume(coro, ...)
	
	if success then
		if event ~= nil then
			error("Libs are not allowed to yield!", 2)
		end
	else
		error("Error in lib " .. fs.getName(file) .. ": " .. tostring(event), 2)
		return
	end
	
	return env
end

function Library.LoadIntoTask(file, task, ...)
	local lib = Library.Load(file, ...)
	task:AddLibrary(lib, fs.getName(file), file)
end

System.Tasks.__replaceNative("os", "loadAPI", function(task, file, ...)
	local ok, err = pcall(Library.LoadIntoTask, file, task, ...)
	printError(err)
	return ok
end)

return Library