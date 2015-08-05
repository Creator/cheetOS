local ShellMgr = {}
local currentShell = nil

local required = {
	"exit";
	"dir", "setDir";
	"path", "setPath";
	"resolve", "resolveProgram";
	"aliases", "setAlias", "clearAlias";
	"programs", "run";
}

local function isRequired(func)
	for _,v in pairs(required) do
		if v == func then
			return true
		end
	end

	return false
end

local function verifyShell(sh)
	local valid = {}

	local function isValid(func)
		for _,v in pairs(valid) do
			if v == func then
				return true
			end
		end

		return false
	end

	for k,v in pairs(sh) do
		if isRequired(k) and type(v) == "function" then
			valid[#valid + 1] = k
		end
	end

	local invalid = {}

	for _,v in pairs(required) do
		if not isValid(v) then
			invalid[#invalid + 1] = v
		end
	end

	return invalid
end

function ShellMgr.SetShell(sh)
	local invalids = verifyShell(sh)
	if #invalids > 0 then
		error("Invalid or missing shell functions: " .. table.concat(invalids, ", "), 2)
		return
	end

	currentShell = sh
end

function ShellMgr.GetShell()
	return currentShell
end

local shellTID = nil

function ShellMgr.SetShellTID(tid)
	shellTID = tid
end

function ShellMgr.GetShellTID()
	return shellTID
end

System.Tasks.__replaceNative("shell", "getRunningProgram", function(task)
	return task.Name
end)

return ShellMgr
