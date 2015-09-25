local SocketLib = {
  SocketType = {
    Net   = 0x1;
    Task  = 0x2;
  }
}

local socketCache = {}

local function makeCacheID(device, freq, replyFreq)
  return device.GetName() .. ":" .. freq .. ":" .. (replyFreq or freq)
end

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

  local cacheID = makeCacheID(self.__device, self.__frequency, self.__replyFreq)
  if socketCache[cacheID] ~= nil then
    socketCache[cacheID] = nil
  end
end

function SocketLib.RequestNetSocket(device, freq, replyFreq)
  if device ~= nil then
    local socketID = makeCacheID(device, freq, replyFreq)
    local socket = socketCache[socketID]

    if not socket then
      socketCache[socketID] = NetSocket(device, freq, replyFreq)
      socket = socketCache[socketID]
    end

    return socket
  end
end

--[[function SocketLib.GetSocketCache()
  return socketCache
end]]

function SocketLib.GetFromCacheID(cid)
  return socketCache[cid]
end

System.Events.RegisterTranslator("modem_message", function(side, freq, replyFreq, msg, dist)
  if side ~= nil then
    local device = System.Network[side]
    local sock = System.Socket.RequestNetSocket(device, freq, replyFreq)
    sock.__distance = dist
    os.queueEvent("socket_message", makeCacheID(device, freq, replyFreq), msg)
    return "modem_message", side, freq, replyFreq, msg, dist
  end
end)

return SocketLib
