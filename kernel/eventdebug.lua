print("Hello from eventdebug.lua!!")
print("Polling mouse_click, char, key and mouse_scroll")

while true do
	local evt = { os.pullEvent("mouse_click", "char", "key", "mouse_scroll") }
	print(table.concat(evt, ", "))
end