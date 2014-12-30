local skynet = require "skynet"

local max_client = 5000

skynet.start(function()
	print("Server start")
	--local console = skynet.newservice("console")
	--skynet.newservice("debug_console",8000)
	skynet.newservice("redisdb")
	skynet.newservice("login")
	skynet.newservice("gameserver")
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	print("Watchdog listen on ", 8888)
	skynet.exit()
end)
