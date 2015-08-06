local Registry = {}

local REGISTRY_FILE = "S:/registry.dat"
local REGENTRY_KEY = 0xFF
local REGENTRY_DIR = 0xFE

local __registry = {
  FileSystem = {
    Mounts = {
      U = "/user"
    }
  }
}

local function explodeKey(key)
  local elements = {}
  for elem in key:gmatch("[^/\\]+") do
    elements[#elements + 1] = elem
  end
  return elements
end

function Registry.Set(key, value)
  local elems = explodeKey(key)

  if #elems == 0 then
    error("can't set the root dir", 2)
  end

  local dir = nil
  local last = __registry

  local _key = nil

  for i,v in ipairs(elems) do
    dir = last[v]
    if i == #elems then
      _key = v
      break
    end

    last = dir
  end

  last[_key] = value
end

function Registry.Get(key)
  local elems = explodeKey(key)

  if #elems == 0 then
    return __registry
  end

  local dir = nil
  local last = __registry

  for _,v in pairs(elems) do
    dir = last[v]
    if dir == nil then
      return nil, v
    end

    last = dir
  end

  return dir
end

function Registry.ValidateKey(key, tbl)
  local dir = System.Registry.Get(key)
  if dir == nil then
    dir = {}
    System.Registry.Set(key, dir)
  end

  for k,v in pairs(tbl) do
    if dir[k] == nil then
      dir[k] = v
    end
  end
end

function Registry.Delete(key)
  Registry.Set(key, nil)
end

function Registry.Save()
  local file = fs.open(REGISTRY_FILE, "w")
  file.write(textutils.serialiseJSON(__registry))
  file.close()
end

function Registry.Load()
  local file = fs.open(REGISTRY_FILE, "r")
  if file then
    __registry = textutils.unserialiseJSON(file.readAll())
    file.close()
  else
    Registry.Save()
  end
end

Registry.Load()

return Registry
