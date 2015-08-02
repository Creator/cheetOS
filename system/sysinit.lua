local ok, err = pcall(function()
	local cdir = "U:/"

	local path = {
		".";
		"S:/default";
		"U:/global";
		"R:/programs";
		"R:/programs/rednet";
		"R:/programs/fun";
		"R:/programs/fun/advanced";
		"R:/programs/http";
		"R:/programs/advanced";
		"R:/programs/pocket";
		"R:/programs/command";
	}
	
	local aliases = {}
	
	local associations = {
		["ss"] = "sshost.lua"
	}
	
	local shell = {} 	-- Shell API

	shell.exit = function(force)
		__TASK__:SendSignal(force 	and 	System.Tasks.Signal.Kill
									or		System.Tasks.Signal.Terminate)
	end

	shell.dir = function()
		return cdir
	end

	shell.setDir = function(path)
		if not fs.exists(path) then
			error("invalid path!", 2)
		end
		
		cdir = path
	end

	shell.run = function(file, ...)
		local args = {}
		for arg in file:gmatch("[^%s]+") do
			args[#args + 1] = arg
		end
		
		local varargs = { ... }
		for _,v in pairs(varargs) do
			args[#args + 1] = v
		end

		file = shell.resolveProgram(args[1])
	
		if not fs.exists(file) then
			printError("No such program '" .. file .. "'")
			return false
		end
		
		local ext = fs.getName(file):match(".+%.(.+)")
		if ext ~= nil then
			local association = shell.__getAssociatedProgram(ext)
			if association ~= nil then
				association = shell.resolveProgram(association)
				local prog = System.Tasks.NewTask(association)
				prog:Start(file)
				
				System.Tasks.WaitForTask(prog)
				return true
			end
		end
		
		local prog = System.Tasks.NewTask(file)
		prog:Start(select(2, unpack(args)))
		
		System.Tasks.WaitForTask(prog)
		return true
	end
	
	shell.path = function()
		error("shell.path(): not available in basic shell!", 2)
	end
	
	shell.setPath = function(newPath)
		error("shell.path(): not available in basic shell!", 2)
	end
	
	shell.__addToPath = function(dir)
		path[#path + 1] = dir
	end
	
	shell.__removeFromPath = function(dir)
		local index = 0
		
		for i,v in pairs(path) do
			if System.Path.Normalise(v) == System.Path.Normalise(dir) then
				index = i
				break
			end
		end
		
		table.remove(path, index)
	end
	
	shell.setAlias = function(alias, prog)
		aliases[alias] = prog
	end
	
	shell.aliases = function()
		return aliases
	end
	
	shell.clearAlias = function(alias)
		aliases[alias] = nil
	end
	
	shell.__resolveAlias = function(alias)
		return aliases[alias]
	end
	
	shell.programs = function()
		return {}
	end
	
	shell.resolve = function(file)
		local firstChar = file:sub(1, 1)
		if firstChar == "/" or firstChar == "\\" then -- root!
			return System.Path.Combine("", file)
		else
			return System.Path.Combine(cdir, file)
		end
	end
	
	shell.resolveProgram = function(name)
		if aliases[name] ~= nil then
			name = aliases[name]
		end
		
		for _,entry in pairs(path) do
			if fs.exists(entry) and fs.isDir(entry) then
				for _, file in pairs(fs.list(entry)) do
					if fs.getName(name) == fs.getName(file) then
						return System.Path.Normalise(System.Path.Combine(entry, file))
					end
				end
			end
		end
		
		return System.Path.Normalise(shell.resolve(name))
	end
	
	--[[shell.getRunningProgram = function()
		if getfenv then
			return getfenv(2).__FILE__ or "N/A"
		else
			error("shell.getRunningProgram not available in Lua 5.2!", 2)
		end
	end]]
	
	shell.__associate = function(ext, program)
		associations[ext] = program
	end
	
	shell.__clearAssociation = function(ext)
		associations[ext] = nil
	end
	
	shell.__getAssociatedProgram = function(ext)
		return associations[ext]
	end

	System.ShellMgr.SetShell(shell)
	
	local sh = System.Tasks.NewTask("S:/shell.lua")
	sh:Start()
	
	shell.run("U:/start.ss")
end)

if not ok then
	printError(err)
end