while true do
  local e, side = os.pullEvent("peripheral", "peripheral_detach")
  if e == "peripheral" then
    System.Network.Register(side, peripheral.wrap(side))
  elseif e == "peripheral_detach" then
    local device = System.Network[side]
    local removalList = { side }

    if device.GetType() == "modem" then
      -- check if any other devices were detached consequently

      for k,v in pairs(System.Network.List()) do
        if not v.IsValid() then
          removalList[#removalList + 1] = k
        end
      end
    end

    for i=1,#removalList do
      local item = removalList[i]
      System.Network.Unregister(item)
    end
  end
end
