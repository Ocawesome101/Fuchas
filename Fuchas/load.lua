-- Bootstrap for Fuchas interface.

local c = require("OCX/ConsoleUI")
local fs = require("filesystem")
c.clear(0x000000)

-- Bootstrap routine
dofile("A:/Fuchas/autorun.lua") -- system variables autorun


local drv = require("driver")

local function httpDownload(url, dest)
	local h = component.getPrimary("internet").request(url)
	h:finishConnect()
	local file = require("filesystem").open(dest, "w")
	local data = ""
	while data ~= nil do
		file:write(tostring(h:read()))
	end
	file:close()
	h:close()
end

if fs.exists("A:/installing") then
	c.clear(0xAAAAAA)
	p = c.progressBar(100)
	pu.background = 0xAAAAAA
	p.background = 0xAAAAAA
	p.progress = 20
	p.x = 55
	p.y = 45
	p.width = 50
	p.height = 2
	pu.text = "Installing Shindows.."
	pu.y = 40
	local det = c.label("Loading network driver..")
	det.x = 68
	det.background = 0xAAAAAA
	det.y = 42
	det.render()
	pu.render()
	p.dirty = true
	p.render()
	--if drv.isDriverAvailable("internet") or true then
	--	drv.changeDriver("internet", "internet")
	--	local int = drv.getDriver("internet")
	--	httpDownload("https://raw.githubusercontent.com/zenith391/Shindows_OC/master/Fuchas/Libraries/filesystem.lua", "/test.lua")
	--end
	--print(tostring(drv.isDriverAvailable("internet")))
	return
end
y = 1
shin32.newProcess("System", function()
	local f, err = xpcall(function()
		local l, err = loadfile("A:/Fuchas/DOE/sh.lua")
		if l == nil then
			error(err)
		end
		return l()
	end, function(err)
		print(err)
		print(debug.traceback(" ", 1))
	end)
	if f == false then
		print("Error:", 0xFF0000)
		print(err, 0xFF0000)
	else
		computer.shutdown() -- main interface exit
	end
end)

while true do
	shin32.scheduler()
end