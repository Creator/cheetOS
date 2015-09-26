local Devices = {}
local __devices = {}

function Devices.Register(netName, handle)
  __devices[netName] = setmetatable({}, { __index = handle })

  local dev = __devices[netName]
  local type = peripheral.getType(netName)

  dev.GetType = function()
    return type
  end

  dev.GetName = function()
    return netName
  end

  dev.IsValid = function()
    return peripheral.isPresent(netName)
  end
end

function Devices.Unregister(netName)
  __devices[netName] = nil
end

function Devices.GetAnyOfType(_type, predicate)
  for k,v in pairs(__devices) do
    if Devices.GetDevType(k) == _type then
      if type(predicate) == "function" then
        if predicate(v) then
          return v
        end
      else
        return v
      end
    end
  end

  return nil
end

function Devices.GetHandle(netName)
  return __devices[netName]
end

function Devices.GetDevType(netName)
  return peripheral.getType(netName)
end

function Devices.List()
  return __devices
end

function Devices.Scan()
  for _,v in pairs(peripheral.getNames()) do
    Devices.Register(v, peripheral.wrap(v))
  end
end

Devices.Scan()

setmetatable(Devices, { __index = __devices })
return Devices
