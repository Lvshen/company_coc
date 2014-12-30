
local skynet = require "skynet"


skynet.start(function()	
	skynet.newservice("robot")
	skynet.exit()
end)


