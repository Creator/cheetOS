local _fs = {}

local mounts = {}

local function GetFSAPI()
	return setmetatable({}, { __index = fs })
end

local assert = function(cond, err)
	if not cond then
		error(err, 4)
	end
end

do
	for k,v in pairs(_G.fs) do
		if type(k) == "string" then
			_fs[k] = v
		end
	end
end

local function RealToVirtual(path)
	path = System.Path.Normalise(path)
	
	for _,v in pairs(mounts) do
		local real = v.__realPath
		if path:sub(1, #real) == real then
			return System.Path.Normalise(v.__letter .. ":" .. path:sub(#real + 1, #path))
		end
	end
	
	return nil
end

local FS_ARG_PATH = 1
local FS_ARG_OTHER = 2
local FS_ARG_WILDCARD = 4

local fsFunctions = {
	list 			= { FS_ARG_PATH };
	exists 			= { FS_ARG_PATH };
	isDir 			= { FS_ARG_PATH };
	isReadOnly 		= { FS_ARG_PATH };
	getName 		= { FS_ARG_PATH };
	getDrive 		= { FS_ARG_PATH };
	getSize 		= { FS_ARG_PATH };
	getFreeSpace 	= { FS_ARG_PATH };
	makeDir 		= { FS_ARG_PATH };
	move 			= { FS_ARG_PATH, FS_ARG_PATH };
	copy			= { FS_ARG_PATH, FS_ARG_PATH };
	delete			= { FS_ARG_PATH };
	combine			= { FS_ARG_PATH, FS_ARG_PATH };
	open			= { FS_ARG_PATH, FS_ARG_OTHER };
	find			= { FS_ARG_PATH };
	getDir			= { FS_ARG_PATH };
	complete		= { FS_ARG_OTHER, FS_ARG_PATH, FS_ARG_OTHER, FS_ARG_OTHER };
}

_G.fs = {}

local Mount = {}
Mount.__index = Mount

setmetatable(Mount, {
	__call = function(cls)
		local self = setmetatable({}, Mount)
		return self
	end
})

-- Mount events:
function Mount:OnMount() end
function Mount:OnUnmount() end

local DirMount = {}
DirMount.__index = DirMount

setmetatable(DirMount, {
	__index = Mount,

	__call = function(cls, realPath)
		local self = setmetatable({}, DirMount)
		assert(type(realPath == "string"), "DirMount(): arg #1 must be a string")
		self.__realPath = System.Path.Normalise(realPath)
		return self
	end
})

function DirMount:Resolve(path)
	local _, driveless = System.Path.GetDriveAndPath(path)
	return System.Path.Combine(self.__realPath, driveless)
end

function DirMount:list(path)
	if System.Path.Normalise(path) == "S:/default" then
		local files =  _fs.list(self:Resolve(path))
		local idxToRemove = -1
		for i,v in pairs(files) do
			if v == "taft" then
				-- necessary for locking the buffer
				idxToRemove = i
				break
			end
		end
		
		if idxToRemove ~= -1 then
			table.remove(files, idxToRemove)
		end
		
		return files
	else
		return _fs.list(self:Resolve(path))
	end
end

function DirMount:exists(path)
	return _fs.exists(self:Resolve(path))
end

function DirMount:isDir(path)
	return _fs.isDir(self:Resolve(path))
end

function DirMount:isReadOnly(path)
	return _fs.isReadOnly(self:Resolve(path))
end

function DirMount:getName(path)
	return _fs.getName(self:Resolve(path))
end

function DirMount:getDrive(path)
	return _fs.getDrive(self:Resolve(path))
end

function DirMount:getSize(path)
	return _fs.getSize(self:Resolve(path))
end

function DirMount:getFreeSpace(path)
	return _fs.getFreeSpace(self:Resolve(path))
end

function DirMount:makeDir(path)
	return _fs.makeDir(self:Resolve(path))
end

function DirMount:move(from, to)
	return _fs.move(self:Resolve(from), self:Resolve(to))
end

function DirMount:copy(from, to)
	return _fs.copy(self:Resolve(from), self:Resolve(to))
end

function DirMount:delete(path)
	return _fs.delete(self:Resolve(path))
end

function DirMount:combine(base, localPath)
	return System.Path.Combine(base, localPath)
end

function DirMount:open(path, mode)
	return _fs.open(self:Resolve(path), mode)
end

function DirMount:getDir(path)
	return _fs.getDir(self:Resolve(path))
end

function DirMount:find(wildcard)
	local results = _fs.find(self:Resolve(wildcard))

	for k,v in pairs(results) do
		local virtual = RealToVirtual(v)
		results[k] = virtual
	end
	
	return results
end

function DirMount:complete(file, parent, inclFiles, inclSlashes)
	return _fs.complete(file, parent, inclFiles, inclSlashes)
end

local function RegisterMount(letter, mount)
	assert(type(letter == "string"), "RegisterMount(): arg #1 must be a string")
	letter = letter:sub(1, 1)
	
	assert(type(letter == "table"), "RegisterMount(): arg #2 must be a mount")
	
	mount.__letter = letter
	mounts[letter] = mount
end

local function Unmount(letter)
	assert(type(letter == "string"), "Unmount(): arg #1 must be a string")
	letter = letter:sub(1, 1)
	mounts[letter] = nil
end

local function GetMountFromDrive(letter)
	assert(type(letter == "string"), "GetMountFromDrive(): arg #1 must be a string")
	letter = letter:sub(1, 1)
	return mounts[letter]
end

local function IsDrive(letter)
	return mounts[letter] ~= nil
end

local function GetMounts()
	return setmetatable({}, { __index = mounts })
end

do
	RegisterMount("U", DirMount("/user"))
	RegisterMount("R", DirMount("/rom"))
	RegisterMount("S", DirMount("/system"))

	for k,v in pairs(fsFunctions) do
		_G.fs[k] = function(...)
			local args = { ... }
			local pathCount = 0
			local mount = nil
			
			local function GetArg(i, expected)
				local arg = args[i]
				
				if expected ~= nil then
					assert(type(arg) == expected, k .. "(): arg #" .. i .. " must be a " .. expected .. ", got " .. type(arg))
				end
				
				return arg
			end
			
			local newArgs = {}
			
			for i,t in pairs(v) do
				if t == FS_ARG_PATH then
					if pathCount == 0 then
						local primaryPath = GetArg(i, "string")
						local drive, path = System.Path.GetDriveAndPath(primaryPath)
						drive = drive or System.Path.GetDefaultDrive()
						mount = GetMountFromDrive(drive)
					end
					
					pathCount = pathCount + 1
				end
				
				newArgs[#newArgs + 1] = GetArg(i)
			end

			if mount ~= nil then
				local func = mount[k]
				if func == nil then
					error(k .. "(): function unsupported on this drive", 2)
				else
					return func(mount, unpack(newArgs))
				end
			else
				error("couldn't find a drive to call this on", 2)
			end
		end
	end
end

return {
	Mount = Mount,
	DirMount = DirMount,
	
	RealToVirtual = RealToVirtual,
	
	GetMountFromDrive = GetMountFromDrive,
	RegisterMount = RegisterMount,
	Unmount = Unmount,
	GetMounts = GetMounts,
	IsDrive = IsDrive,
	
	GetFSAPI = GetFSAPI
}