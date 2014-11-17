<<<<<<< HEAD

local skynet = require "skynet"

--local build_id = {[1001] = "Ò°ÂùÈË", [1]}

local build_config = {
	[100] = {
		[1] = {"blood" = 80, "build_money" = 0, "build_money_type" = 0, "max_gold" = 1500, "max_water" = 1500, "build_time" = 60},
		[2] = {"blood" = 1600, "build_money" = 1000, "build_money_type" = 0, "max_gold" = 6000, "max_water" = 6000, "build_time" = 900},
		[3] = {"blood" = 1800, "build_money" = 4000, "build_money_type" = 0, "max_gold" = 100000, "max_water" = 100000, "build_time" = 7200},
		[4] = {"blood" = 2000, "build_money" = 25000, "build_money_type" = 0, "max_gold" = 500000, "max_water" = 500000, "build_time" = 14400},
		[5] = {"blood" = 2200, "build_money" = 150000, "build_money_type" = 0, "max_gold" = 1000000, "max_water" = 1000000, "build_time" = 36000},
		[6] = {"blood" = 2400, "build_money" = 750000, "build_money_type" = 0, "max_gold" = 2000000, "max_water" = 2000000, "build_time" = 57600},
		[7] = {"blood" = 2600, "build_money" = 1200000, "build_money_type" = 0, "max_gold" = 4000000, "max_water" = 4000000, "build_time" = 86400},
		[8] = {"blood" = 2800, "build_money" = 2000000, "build_money_type" = 0, "max_gold" = 4000000, "max_water" = 4000000, "build_time" = 172800},
		[9] = {"blood" = 3000, "build_money" = 4000000, "build_money_type" = 0, "max_gold" = 4000000, "max_water" = 4000000, "build_time" = 345600},
	}
}

function upgrade_build(id, index)
	
end

=======

local skynet = require "skynet"

--local build_id = {[1001] = "Ò°ÂùÈË", [1]}

local build_config = {
	[100] = {
		[1] = {"blood" = 80, "build_money" = 0, "build_money_type" = 0, "max_gold" = 1500, "max_water" = 1500, "build_time" = 60},
		[2] = {"blood" = 1600, "build_money" = 1000, "build_money_type" = 0, "max_gold" = 6000, "max_water" = 6000, "build_time" = 900},
		[3] = {"blood" = 1800, "build_money" = 4000, "build_money_type" = 0, "max_gold" = 100000, "max_water" = 100000, "build_time" = 7200},
		[4] = {"blood" = 2000, "build_money" = 25000, "build_money_type" = 0, "max_gold" = 500000, "max_water" = 500000, "build_time" = 14400},
		[5] = {"blood" = 2200, "build_money" = 150000, "build_money_type" = 0, "max_gold" = 1000000, "max_water" = 1000000, "build_time" = 36000},
		[6] = {"blood" = 2400, "build_money" = 750000, "build_money_type" = 0, "max_gold" = 2000000, "max_water" = 2000000, "build_time" = 57600},
		[7] = {"blood" = 2600, "build_money" = 1200000, "build_money_type" = 0, "max_gold" = 4000000, "max_water" = 4000000, "build_time" = 86400},
		[8] = {"blood" = 2800, "build_money" = 2000000, "build_money_type" = 0, "max_gold" = 4000000, "max_water" = 4000000, "build_time" = 172800},
		[9] = {"blood" = 3000, "build_money" = 4000000, "build_money_type" = 0, "max_gold" = 4000000, "max_water" = 4000000, "build_time" = 345600},
	}
}

local acitont = {
	[0] = function (t)
		
	end,
}

local function upgrade_build()
	local index = buildaction.upgrade_build.index
	local build = roleinfo.build
	if build[index] == nil then
		return 3
	end
end

function build_operate(buildaction, roleinfo)
	action[buildaction.type](buildaction)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register "BUILDOPERATE"
	print("build service start")
end)
>>>>>>> origin/master
