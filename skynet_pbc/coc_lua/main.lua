local skynet = require "skynet"

local max_client = 64

skynet.start(function()
	print("Server start")
	--local console = skynet.newservice("console")
	--skynet.newservice("debug_console",8000)
	skynet.newservice("redisdb")
	local loginserver = skynet.newservice("logind")
	local gate = skynet.newservice("gated", loginserver)
	skynet.call(gate, "lua", "open" , {
		port = 8888,
		maxclient = max_client,
		servername = "gameserver",
	})
	print("gate listen on ", 8888)
	skynet.exit()
end)
