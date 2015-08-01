local __replacements = {}

os.pullEventRaw = function(...)
	return coroutine.yield(...)
end

os.pullEvent = function(...)
	local evtData = { os.pullEventRaw(...) }
	if evtData[1] == "terminate" then
		error()
	end

	return unpack(evtData)
end

local Tasks = {
	Signal = {
		Terminate = 1; 		-- 00000001
		Kill = 2; 			-- 00000010
		Suspend = 4;		-- 00000100
		Resume = 8;			-- 00001000
		RequestExit = 16; 	-- 00010000
	},

	TaskState = {
		Alive = 1;			-- 00000001
		Dead = 2;			-- 00000010
		Error = 4;			-- 00000100
		Idle = 8;			-- 00001000
	}
}

local signalHandlers = {
	[Tasks.Signal.Terminate] = function(self)
		self:QueueEvent("terminate")
	end,

	[Tasks.Signal.RequestExit] = function(self)
		self:QueueEvent("please_exit")
	end,

	[Tasks.Signal.Kill] = function(self)
		self.__state = Tasks.TaskState.Dead
		self.__coro = nil
	end,

	[Tasks.Signal.Resume] = function(self)
		self.__state = Tasks.TaskState.Alive
	end,

	[Tasks.Signal.Suspend] = function(self)
		self.__state = Tasks.TaskState.Idle
	end
}

local Task = {}
Task.__index = Task

setmetatable(Task, {
	__call = function(cls, file, allowYield)
		local self = setmetatable({}, Task)
		self.TID = 0
		
		if allowYield == nil then allowYield = true end

		self.__coro = nil
		self.__lastError = ""
		self.__state = Tasks.TaskState.Idle
		self.__reqEvents = nil
		self.__file = file
		self.__sandbox = nil
		self.__allowYield = allowYield
		self.__libs = {}
		
		self.__libTbl = {}
		setmetatable(self.__libTbl, { __index = _G })
		
		self.Name = fs.getName(self.__file)

		return self
	end
})

function Task:__processYield(yieldData)
	local success = yieldData[1]

	if not success then
		local message = yieldData[2]
		printError(message)
		self.__lastError = message
	else
		local requestedEvents = { select( 2, unpack(yieldData) ) }

		if #requestedEvents == 0 then
			requestedEvents = nil
		end

		self.__reqEvents = requestedEvents
	end

	self:__handleDeath()
end

function Task:__handleDeath()
	if self.__coro == nil or coroutine.status(self.__coro) == "dead" then
		self.__state = Tasks.TaskState.Dead
		self.__coro = nil
		os.queueEvent("task_dead", self.TID)
		return
	end
end

function Task:AddLibrary(lib, name, file)
	self.__libs[name] = {
		File = file,
		Lib = lib
	}
	
	self.__libTbl[name] = lib
end

function Task:GetLibrary(name)
	return self.__libs[name]
end

function Task:Start(...)
	local env = {}
	
	env.__TASK__ 	= self
	env.__TID__ 	= self.TID
	env.__FILE__	= System.Path.Normalise(self.__file)

	env.shell 		= System.ShellMgr.GetShell()
	env.fs 			= System.File.GetFSAPI()
	
	for k,v in pairs(__replacements) do
		local target = nil
		if k == "" then
			target = env
		else
			if env[k] == nil then
				env[k] = {}
				setmetatable(env[k], { __index = _G[k] })
			end
			
			target = env[k]
		end
		
		for fn,f in pairs(v) do
			target[fn] = function(...)
				return f(self, ...)
			end
		end
	end

	setmetatable(env, { __index = self.__libTbl })
	
	self.__sandbox = System.Sandbox.NewSandbox(self.__file, env)
	self.__func = self.__sandbox:GetFunction()
	self.__coro = coroutine.create(self.__func)
	self.__state = Tasks.TaskState.Alive

	if not self.__allowYield then
		self:__handleDeath()
	end

	local yieldData = { coroutine.resume(self.__coro, ...) }
	self:__processYield(yieldData)
end

function Task:HasRequested(event)
	if event == "terminate" then -- always allow terminate to pass through
		return true
	end

	if self.__reqEvents == nil then -- nil = any event
		return true
	end

	for _,v in pairs(self.__reqEvents) do
		if v == event then
			return true
		end
	end

	return false
end

function Task:KeepAlive(evtData)
	if self.__allowYield then
		if self.__state == Tasks.TaskState.Alive then
			local evtName = evtData[1]
			if not self:HasRequested(evtName) then
				return
			end

			local yieldData = { coroutine.resume( self.__coro, unpack(evtData) ) }
			self:__processYield(yieldData)
		end
	end
end

function Task:GetError()
	return self.__lastError
end

function Task:GetState()
	return self.__state
end

function Task:GetFile()
	return self.__file
end

function Task:SendSignal(signal)
	signalHandlers[signal](self)
end

local taskList = {}

function Tasks.NewTask(...)
	local task = Task(...)
	local index = #taskList + 1
	task.TID = index
	taskList[index] = task
	return task, index
end

function Tasks.GetTaskByTID(tid)
	return taskList[tid]
end

function Tasks.KeepAlive(evtData)
	local toRemove = {}
	
	for i,v in pairs(taskList) do
		v:KeepAlive(evtData)
		
		if v:GetState() == Tasks.TaskState.Dead then
			toRemove[#toRemove + 1] = i
		end
	end
	
	for _,v in pairs(toRemove) do
		taskList[v] = nil
	end
end

function Tasks.List()
	return taskList
end

function Tasks.WaitForTask(task)
	if type(task) == "number" then
		task = Tasks.GetTaskByTID(task)
	end

	assert(type(task) == "table")

	while task:GetState() ~= System.Tasks.TaskState.Dead do
		os.pullEvent("task_dead")
	end
end

function Tasks.__replaceNative(api, name, handler)
	if not __replacements[api] then
		__replacements[api] = {}
	end
	
	__replacements[api][name] = handler
end

return Tasks
