local SandboxLib = {}

local Sandbox = {}
Sandbox.__index = Sandbox

setmetatable(Sandbox, {
	__call = function(self, file, _env)
		local self = setmetatable({}, Sandbox)

		local env = setmetatable({}, { __index = _env })

		if load then
			-- Lua 5.2 (CC1.74+)
			local chunk, msg = loadfile(file, env)
			if chunk == nil then
				self.__func = nil
				error("Failed to create sandbox: " .. msg, 0)
			end

			self.__func = chunk
		else
			-- Lua 5.1
			local chunk, msg = loadfile(file)
			if chunk == nil then
				self.__func = nil
				error("Failed to create sandbox: " .. msg, 0)
			end

			setfenv(chunk, env)
			self.__func = chunk
		end

		return self
	end
})

function Sandbox:GetFunction()
	return self.__func
end

function SandboxLib.NewSandbox(...)
	return Sandbox(...)
end

return SandboxLib
