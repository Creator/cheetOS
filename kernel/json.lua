--[[
  Uses ElvishJerricco's JSON Library (http://www.computercraft.info/forums2/index.php?/topic/5854-json-api-v201-for-computercraft/)
  to implement textutils.unserialiseJSON (and textutils.serialiseJSON if necessary).

  As well as that, System.JSON is ElvishJerricco's API itself.
]]

local _json = System.Library.Load("K:/lib/json")

if textutils.serialiseJSON == nil then
  textutils.serialiseJSON = function(input)
    return _json.encode(input)
  end

  textutils.serializeJSON = textutils.serialiseJSON
end

textutils.unserialiseJSON = function(input)
  return _json.decode(input)
end

textutils.unserializeJSON = textutils.unserialiseJSON

return _json
