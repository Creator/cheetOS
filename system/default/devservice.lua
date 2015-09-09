while true do
  local e, side = os.pullEvent("peripheral", "peripheral_detach")
  if e == "peripheral" then
    System.Devices.Register(side, peripheral.wrap(side))
  elseif e == "peripheral_detach" then
    System.Devices.Unregister(side)
  end
end
