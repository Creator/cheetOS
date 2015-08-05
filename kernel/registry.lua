local Registry = {}

local __registry = {
  Test = {
    Key1 = "Eyy! #1",
    Key2 = "Eyy! #2",
    Key3 = {
      K = "k",
      Ey = "ey"
    }
  }
}

--[[
  Key format:

  Test/Key3/K
]]

local function explodeKey(key)
  local elements = {}
  for elem in key:gmatch("[^/\\]+") do
    elements[#elements + 1] = elem
  end
  return elements
end

function Registry.Set(key, value)
  local elems = explodeKey(key)

  local dir = nil
  local last = __registry

  local _key = nil

  for _,v in pairs(elems) do
    dir = last[v]
    if type(dir) ~= "table" then
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
    last = dir
  end

  return dir
end

return Registry
