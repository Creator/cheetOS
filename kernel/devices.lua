local Devices = {}
local __devices = {}

function Devices.Register(netName, handle)
  __devices[netName] = handle
end

function Devices.Unregister(netName)
  __devices[netName] = nil
end

function Devices.GetAnyOfType(type)
  for k,v in pairs(__devices) do
    if Devices.GetDevType(k) == type then
      return v
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
return Devices
