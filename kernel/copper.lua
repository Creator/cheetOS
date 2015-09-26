--[[
  COPPER - The networking library

  CheetOS Protocol Protection and Encryption Rsomething
]]

local COPPER = {
    PACKET_CONNECT                  = 0x01;
    PACKET_BROADCAST_SERVER         = 0x02;
    PACKET_REQUEST_SALT             = 0x03;
    PACKET_ACCESS_DENIED            = 0x04;
    PACKET_ACCESS_GRANTED           = 0x05;
    PACKET_SALT                     = 0x06;
    PACKET_LOGOUT                   = 0x07;

    DENY_REASON_ALREADY_LOGGED_IN   = 0x01;
    DENY_REASON_INVALID_CREDENTIALS = 0x02;
}

local Packet = {}
Packet.__index = Packet

setmetatable(Packet, {
  __call = function(cls, data)
    local self = setmetatable({}, Packet)
    self.__data = data or {}
    self.__readPtr = 1
    return self
  end
})

function Packet:WriteNumber(num)
  self.__data[#self.__data + 1] = num
end

function Packet:WriteString(str)
  if type(str) ~= "string" then
    return error("WriteString(): argument #1 must be a string!", 2)
  end

  self:WriteNumber(#str)
  self:WriteChars(str)
end

function Packet:WriteChars(str)
  for i=1,#str do
    self:WriteNumber(string.byte(str:sub(i, i)))
  end
end

function Packet:ReadNumber()
  local i = self.__readPtr
  self.__readPtr = self.__readPtr + 1
  local num = self.__data[i]
  if num == nil then
    error("end of stream", 2)
  end
  return num
end

function Packet:ReadString()
  return self:ReadChars(self:ReadNumber())
end

function Packet:ReadChars(count)
  local str = ""
  for i=1,count do
    local num = self:ReadNumber()
    str = str .. string.char(num)
  end
  return str
end

function Packet:GetBytes()
  return self.__data
end

function Packet:GetReadPosition()
  return self.__readPtr -- subtract the magic bytes
end

function Packet:GetSize()
  return #self.__data
end

COPPER.Packet = Packet

local Socket = {}
Socket.__index = Socket

setmetatable(Socket, {
  __call = function(cls, localhost, serverName, device, frequency, replyFreq)
    local self = setmetatable({}, Socket)
    self.__serverName = serverName
    self.__localhost = localhost

    if serverName == nil and device == nil and frequency == nil then
      self.__sysSock = localhost -- A socket was supplied
    else
      self.__sysSock = System.Socket.RequestNetSocket(device, frequency, replyFreq)
    end
    return self
  end
})

function Socket:SendPacket(packet)
  if type(packet) ~= "table" then
    return error("SendPacket(): argument #1 must be a packet!", 2)
  end
  self.__sysSock:Transmit(packet.__data)
end

local function convertToTable(data)
  local tbl = {}

  if type(data) == "string" then
    for i=1,#data do
      local c = data:sub(i, i)
      tbl[#tbl + 1] = c:byte()
    end
  elseif type(data) == "number" then
    tbl[#tbl + 1] = data
  else
    return nil
  end

  return tbl
end

local function makePacketFromData(data)
  if type(data) ~= "table" then
    data = convertToTable(data)
  end

  if data ~= nil then
    return Packet(data)
  end
end

COPPER.MakePacketFromData = makePacketFromData

function Socket:ReceivePacket(timeout)
  while true do
    local data = self.__sysSock:Receive(timeout)
    return makePacketFromData(data)
  end
end

function Socket:RequestSalt()
  local packet = Packet()
  packet:WriteString(self.__localhost)
  packet:WriteNumber(COPPER.PACKET_REQUEST_SALT)
  packet:WriteString(self.__serverName)
  return self:SendPacket(packet)
end

function Socket:Connect(password, salt)
  local packet = Packet()
  packet:WriteString(self.__localhost)
  packet:WriteNumber(COPPER.PACKET_CONNECT)
  packet:WriteString(self.__serverName)

  local hashedPass = System.Security.Hash(password, salt)
  local encrypted = System.Security.Encrypt(password, hashedPass)

  if encrypted == nil then
    return error("Failed to encrypt.")
  end

  packet:WriteString(encrypted)
  return self:SendPacket(packet)
end

function Socket:Disconnect(key)
  local packet = Packet()
  packet:WriteString(self.__localhost)
  packet:WriteNumber(COPPER.PACKET_LOGOUT)
  packet:WriteString(self.__serverName)
  packet:WriteString(key)
  return self:SendPacket(packet)
end

function Socket:Close()
  return self.__sysSock:Close()
end

COPPER.Socket = Socket
return COPPER
