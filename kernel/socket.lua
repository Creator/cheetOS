local SocketLib = {
  SocketType = {
    Net   = 0x1;
    Task  = 0x2;
  }
}

local Socket = {}
Socket.__index = Socket

setmetatable(Socket, {
  __call = function(cls)
    error("can't instantiate a socket this way", 2)
  end
})

function Socket:GetSocketType() end
function Socket:Transmit(data) end

local NetSocket = {}
NetSocket.__index = NetSocket

setmetatable(NetSocket, {
  __index = Socket,
  __call = function(cls, freq, replyFreq, wireless)
    local self = setmetatable({}, NetSocket)

    self.__frequency = freq
    self.__replyFreq = replyFreq

    return self
  end
})

function NetSocket:GetSocketType()
  return SocketLib.SocketType.Net
end

function NetSocket:GetReplyFrequency()
  return self.__replyFreq or self.__frequency
end

function NetSocket:GetFrequency()
  return self.__frequency
end

function SocketLib.NewNetSocket(...)
  return NetSocket(...)
end

return SocketLib
