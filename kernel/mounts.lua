do
  local mounts = System.Registry.Get("FileSystem/Mounts")
  for k,v in pairs(mounts) do
    print("Mounting " .. k .. " -> " .. v)
    System.File.RegisterMount(k, System.File.DirMount(v))
  end
end
