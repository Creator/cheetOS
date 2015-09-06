local Library = {}

function Library.Load(file, ...)
	local task = System.Tasks.NewTask(file, false)
	task:Start(...)

	local env = setmetatable({}, {
		__index = task:GetSandbox():GetEnv(),
		__tostring = function()
			return "Library (" .. System.Path.Normalise(file) .. ")"
		end
	})

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
