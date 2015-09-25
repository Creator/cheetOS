local Events = {}
local translators = {}
local queue = {}

function Events.RegisterTranslator(event, translator)
  local tbl = nil

  if translators[event] == nil then
    translators[event] = {}
    tbl = translators[event]
  else
    tbl = translators[event]
  end

  tbl[#tbl + 1] = translator
end

function Events.Translate(event, ...)
  for k,v in pairs(translators) do
    if k == event then
      for i=1,#v do
        local t = v[i]
        return t(...)
      end
    end
  end

  return event, ...
end

return Events
