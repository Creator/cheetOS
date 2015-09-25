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

  local index = #tbl + 1
  tbl[index] = translator
end

function Events.Translate(event, ...)
  for k,v in pairs(translators) do
    if k == event then
      for _,t in pairs(v) do
        t(...)
      end
    end
  end

  return event, ...
end

os.pullEventRaw = function(...)
  return coroutine.yield(...)
end

return Events
