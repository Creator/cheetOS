do
  local mounts = System.Registry.Get("FileSystem/Mounts")
  for k,v in pairs(mounts) do
    if k == "K" then
      print("Drive K:/ can't be mounted at boot!! You must mount it yourself later.")
    else
      print("Mounting " .. k .. " -> " .. v)
      System.File.RegisterMount(k, System.File.DirMount(v))
    end
  end
end
