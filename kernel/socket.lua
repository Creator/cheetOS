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
function Socket:Receive(timeout) end
function Socket:Close() end

local NetSocket = {}
NetSocket.__index = NetSocket

setmetatable(NetSocket, {
  __index = Socket,
  __call = function(cls, device, freq, replyFreq)
    local self = setmetatable({}, NetSocket)
    self.__frequency = freq
    self.__replyFreq = replyFreq or freq

    if device.GetType() ~= "modem" then
      error("NetSocket(): arg #1 must be a modem!!", 2)
      return
    end

    device.open(self.__frequency)
    device.open(self.__replyFreq)

    self.__device = device
    self.__distance = -1
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

function NetSocket:IsWireless()
  return self.__device.isWireless()
end

function NetSocket:EnsureOpen()
  if not self.__device.isOpen(self.__frequency) then
    self.__device.open(self.__frequency)
  end

  if not self.__device.isOpen(self.__replyFreq) then
    self.__device.open(self.__replyFreq)
  end
end

function NetSocket:Transmit(data)
  self:EnsureOpen()
  self.__device.transmit(self.__frequency, self.__replyFreq, data)
end

function NetSocket:Receive(timeout)
  self:EnsureOpen()

  local timerID = nil
  if timeout then
    timerID = os.startTimer(timeout)
  end

  local _data = nil

  while true do
    local e, side, _, _, data, dist = os.pullEvent()

    if e == "modem_message" and side == self.__device.GetName() then
      self.__distance = dist
      _data = data
      break
    elseif e == "timer" and side == timerID then
      _data = nil
      break
    end
  end

  return _data
end

function NetSocket:GetDistance()
  return self.__distance
end

function NetSocket:Close()
  self.__device.close(self.__replyFreq)
  self.__device.close(self.__frequency)
end

function SocketLib.NewNetSocket(...)
  return NetSocket(...)
end

return SocketLib
