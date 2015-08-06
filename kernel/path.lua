local fscombine = fs.combine

local function GetDriveAndPath(path)
	if path == "" then return nil, "/" end
	if path == "/" or path == "\\" then return nil, "/" end

	if path == nil then error("path can't be nil", 2) end

	local drive = path:match("([A-Z])[%:%%]")
	if drive == "" then drive = nil end

	local filePattern = "[A-Z][%:%%](.*)"
	if drive == nil then filePattern = "(.*)" end

	local filePath = path:match(filePattern)
	return drive, filePath
end

local function GetPathWithoutDrive(path)
	return path:match("[A-Z][%:%%](.*)") or "/"
end

local function GetDefaultDrive()
	return "U"
end

local function GetRootElement(path)
	local name = ""
	local drive, filePath = GetDriveAndPath(path)

	if drive ~= nil then
		path = filePath
	end

	for i=1,#path do
		local c = path:sub(i, i)

		if i > 1 and (c == "/" or c == "\\") then
			break
		end

		name = name .. c
	end

	return name, drive
end

local function GetRootElementWithDrive(path)
	local name, drive = GetRootElement(path)
	return drive .. name
end

local function Normalise(path, driveSep)
	driveSep = driveSep or ":"

	if path == nil then error("path can't be nil", 2) end
	local drive, fullPath = GetDriveAndPath(path)

	if fullPath ~= nil then
		local continue = true

		if fullPath == "" then fullPath = "/"; continue = false end
		if fullPath == "/" or fullPath == "\\" then fullPath = "/"; continue = false end

		if continue then
			fullPath = fullPath:gsub("\\", "/")
			if fullPath:sub(1, 1) ~= "/" then
				fullPath = "/" .. fullPath
			end

			if fullPath:sub(#fullPath, #fullPath) == "/" then
				fullPath = fullPath:sub(1, #fullPath - 1)
			end
		end
	end

	if drive ~= nil then
		fullPath = drive .. driveSep .. (fullPath or "/")
	end

	return fullPath
end

local function Combine(path1, path2, driveSep)
	driveSep = driveSep or ":"

	local d1, p1 = GetDriveAndPath(path1)
	local d2, p2 = GetDriveAndPath(path2)

	local combined = Normalise(fscombine(p1, p2))
	if d1 ~= nil and d2 ~= nil then
		if d1 ~= d2 then
			error("paths have differing drives!", 2)
		end

		return d1 .. driveSep .. combined
	elseif (d1 ~= nil and d2 == nil) or (d1 == nil and d2 ~= nil) then
		return (d1 or d2) .. driveSep .. combined
	elseif d1 == nil and d2 == nil then
		return combined
	end
end

return {
	GetDrive = GetDrive,
	GetRootElement = GetRootElement,
	GetRootElementWithDrive = GetRootElementWithDrive,
	GetPathWithoutDrive = GetPathWithoutDrive,
	GetDriveAndPath = GetDriveAndPath,
	GetDefaultDrive = GetDefaultDrive,

	Combine = Combine,
	Normalise = Normalise,
	Normalize = Normalise
}
