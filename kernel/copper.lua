--[[
  COPPER - The networking library

  CheetOS Protocol Protection and Encryption Rsomething
]]

local COPPER = {}
local MAGIC_BYTES = "COPPER"

local Packet = {}
Packet.__index = Packet

setmetatable(Packet, {
  __call = function(cls, data)
    local self = setmetatable({}, Packet)
    self.__data = data or {}
    self.__readPtr = 1
    self:WriteChars(MAGIC_BYTES)
    return self
  end
})

function Packet:WriteNumber(num)
  self.__data[#self.__data + 1] = num
end

function Packet:WriteString(str)
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
  return num
end

function Packet:ReadString()
  return self:ReadChars(self:ReadNumber())
end

function Packet:ReadChars(count)
  local str = ""
  for i=1,count do
    str = str .. string.char(self:ReadNumber())
  end
  return str
end

function Packet:GetBytes()
  return { select(#MAGIC_BYTES + 1, unpack(self.__data)) }
end

function Packet:GetReadPosition()
  return self.__readPtr - #MAGIC_BYTES -- subtract the magic bytes
end

function Packet:GetSize()
  return #self.__data - #MAGIC_BYTES
end

COPPER.Packet = Packet

local Socket = {}
Socket.__index = Socket

setmetatable(Socket, {
  __call = function(cls, device, frequency, replyFreq)
    local self = setmetatable({}, Socket)
    if frequency == nil and replyFreq == nil then
      self.__sysSock = device -- A socket was supplied
    else
      self.__sysSock = System.Socket.RequestNetSocket(device, frequency, replyFreq)
    end
    return self
  end
})

function Socket:SendPacket(packet)
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
    local pack = Packet(data)
    if pack:ReadChars(#MAGIC_BYTES) == MAGIC_BYTES then
      return pack
    end
  end
end

COPPER.MakePacketFromData = makePacketFromData

function Socket:ReceivePacket(timeout)
  while true do
    local data = self.__sysSock:Receive(timeout)
    local packet = makePacketFromData(data)
    if packet ~= nil then
      return packet
    end
  end
end

function Socket:Close()
  return self.__sysSock:Close()
end

COPPER.Socket = Socket
return COPPER
