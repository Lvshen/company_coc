

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
	},
	[103] = {
		[1] = {"blood" = 250, "build_money" = 150, "build_money_type" = 1, "max_value" = 500, "produce_speed" = 200, "build_time" = 60},
		[2] = {"blood" = 270, "build_money" = 300, "build_money_type" = 1, "max_value" = 1000, "produce_speed" = 400, "build_time" = 300},
		[3] = {"blood" = 280, "build_money" = 700, "build_money_type" = 1, "max_value" = 1500, "produce_speed" = 600, "build_time" = 800},
		[4] = {"blood" = 290, "build_money" = 1400, "build_money_type" = 1, "max_value" = 2500, "produce_speed" = 800, "build_time" = 3600},
		[5] = {"blood" = 310, "build_money" = 3000, "build_money_type" = 1, "max_value" = 10000, "produce_speed" = 1000, "build_time" = 14400},
		[6] = {"blood" = 320, "build_money" = 7000, "build_money_type" = 1, "max_value" = 20000, "produce_speed" = 1300, "build_time" = 43200},
		[7] = {"blood" = 340, "build_money" = 14000, "build_money_type" = 1, "max_value" = 30000, "produce_speed" = 1600, "build_time" = 86400},
		[8] = {"blood" = 350, "build_money" = 28000, "build_money_type" = 1, "max_value" = 50000, "produce_speed" = 1900, "build_time" = 172800},
		[9] = {"blood" = 390, "build_money" = 56000, "build_money_type" = 1, "max_value" = 75000, "produce_speed" = 2200, "build_time" = 259200},
		[10] = {"blood" = 420, "build_money" = 84000, "build_money_type" = 1, "max_value" = 100000, "produce_speed" = 2500, "build_time" = 345600},
		[11] = {"blood" = 450, "build_money" = 168000, "build_money_type" = 1, "max_value" = 150000, "produce_speed" = 3000, "build_time" = 518400},
	}
}

local buildoperate = {}

local function build_finish(build)
	if build.finish == 0 then
		local now = skynet.time()
		if (now - build.build_time) > build.remain_time then
			build.finish = 1
			build.remain_time = 0
			build.level = build.level + 1
			return true
		else
			build.remain_time = now - build.build_time 
		end
		--skynet.error("build id : %d at building not finish!", tonumber(build_id))
		return false
	end
	return true
end

local function upgrade_build(action, role_info)
	local index = action.upgrade_build.index
	local build_id = action.upgrade_build.id
	local build = role_info.build.index
	if build == nil then
		skynet.error("(role not this build) build id : %d is not exist!", tonumber(build_id))
		return 3
	end
	--assert(build_config[build_id] ~= nil, "build id : "..build_id.." is not exist!")
	if build_config[build_id] == nil then
		skynet.error("(clent request error) build id : %d is not exist!", tonumber(build_id))
		return 3
	end

	if build_finish(build) == false then
		skynet.error("build id : %d at building not finish!", tonumber(build_id))
		return 6
	end
	
	local build_lv = build.level
	local config = buibuild_config[build_id].(build_lv + 1)
	--assert(config ~= nil, "build level is Max")
	if config == nil then
		skynet.error("(clent request error) build id : %d level is (%d)Max, can't upgrade!", tonumber(build_id), build_lv + 1)
		return 5
	end
	local changeinfo = {}
	local need_money = config.build_money
	local money_type = config.build_money_type
	local have_money = have_money or 0
	if build_money_type == 0 and role_info["goldcoin"] >= need_money then
		have_money = role_info["goldcoin"]
		changeinfo["goldcoin"] = have_money - need_money
	else if build_money_type == 1 and role_info["water"] >= need_money then
		have_money = role_info["water"]
		changeinfo["water"] = have_money - need_money
	else if build_money_type == 2 and role_info["gem"] >= need_money then
		have_money = role_info["gem"]
		changeinfo["gem"] = have_money - need_money
	else 
		skynet.error(" build id : %d  money is not enough!(%d/%d/%d)", tonumber(build_id), money_type, need_monye, have_money)
		return 2
	end
	local now = skynet.time()
	build["build_time"] = now
	build["remain_time"] = config.build_time
	if config.build_time == 0 then
		build["finish"] = 1
		build["level"] = build_lv + 1
	else
		build["finish"] = 0
	end
	table.insert(changeinfo, build)
	return 0, index, changeinfo
end

local function place_build(action, role_info)
	local build_id = action.place_build.id
	local config = buibuild_config[build_id].[1]
	if config == nil then
		skynet.error("(client request error) build id : %d is not exist!", tonumber(build_id))
		return 3
	end
	local changeinfo = {}
	local need_money = config.build_money
	local money_type = config.build_money_type
	local have_money = have_money or 0
	if build_money_type == 0 and role_info["goldcoin"] >= need_money then
		have_money = role_info["goldcoin"]
		changeinfo["goldcoin"] = have_money - need_money
	else if build_money_type == 1 and role_info["water"] >= need_money then
		have_money = role_info["water"]
		changeinfo["water"] = have_money - need_money
	else if build_money_type == 2 and role_info["gem"] >= need_money then
		have_money = role_info["gem"]
		changeinfo["gem"] = have_money - need_money
	else 
		skynet.error(" build id : %d  money is not enough!(%d/%d/%d)", tonumber(build_id), money_type, need_monye, have_money)
		return 2
	end
	if config.capacity ~= nil then 							--gem do not deal with
		if config.build_money_type == 0 then
			changeinfo["max_water"] = role_info["max_water"] + config.capacity
		else if config.build_money_type == 1 then
			changeinfo["max_goldcoin"] = role_info["max_goldcoin"] + config.capacity
		end
	end
	changeinfo["build_count"] = role_info["build_count"] + 1
	local now = skynet.time()
	local build = place_build
	build["build_time"] = now
	build["remain_time"] = config.build_time
	build["level"] = 1
	build["index"] = role_info["build_count"] + 1
	if config.build_time == 0 then
		build["finish"] = 1
	else
		build["finish"] = 0
	end
	table.insert(changeinfo, build)
	return 0, index, changeinfo	
end

local function collect_resource(action, role_info)
	local index = action.collect_resource.index
	local build_id = action.collect_resource.id
	local build = role_info.build.index
	if build == nil then
		skynet.error("(role not this build) build id : %d is not exist!", tonumber(build_id))
		return 3
	end
	--assert(build_config[build_id] ~= nil, "build id : "..build_id.." is not exist!")
	if build_config[build_id] == nil then
		skynet.error("(client request error) build id : %d is not exist!", tonumber(build_id))
		return 3
	end
	local build_lv = build.level
	local config = buibuild_config[build_id].build_lv
	if config == nil or config.produce_speed == nil then
		skynet.error("(client request error) build id : %d is not valid resouorce build!", tonumber(build_id))
		return 3
	end
	if build.collect_time == nil then
		skynet.error("(this is logic error) build id : %d ", tonumber(build_id))
		return 1
	end
	if build_finish(build) == false then
		skynet.error("build id : %d at building not finish!", tonumber(build_id))
		return 6
	end
	local changeinfo = {}
	local now = skynet.time()
	local interval_time = now - build.collect_time
	local value = math.floor((interval * config.produce_speed) /3600)
	if value > config.max_value then
		value = config.max_value
	end
	if build_money_type == 0  then 								--gem do not deal with
		changeinfo["water"] = role_info.water + value
		if changeinfo["water"] > role_info.max_water then
			changeinfo["water"] = role_info.max_water
		end
	else if build_money_type == 1  then
		changeinfo["goldcoin"] = role_info.goldcoin + value
		if changeinfo["goldcoin"] > role_info.max_goldcoin then
			changeinfo["goldcoin"] = role_info.max_goldcoin
		end
	else 
		skynet.error(" build id : %d  this is logic error", tonumber(build_id))
		return 1
	end	
	build.collect_time = now
	table.insert(changeinfo, build)
	return 0, index, changeinfo, value
end

local function move_build(action, role_info)
	local index = action.move_build.index
	local build_id = action.move_build.id
	local build = role_info.build.index
	if build == nil then
		skynet.error("(role not this build) build id : %d is not exist!", tonumber(build_id))
		return 3
	end
	build.x = move_build.x
	build.y = move_build.y
	local changeinfo = {}
	table.insert(changeinfo, build)
	return 0, index, changeinfo
end

local acitont = {
	[0] = upgrade_build (buildaction, roleinfo)	end,
	[1] = place_build(buildaction, roleinfo) end,
	[2] = collect_resource(action, roleinfo) end,
	[3] = move_build(action, roleinfo) end,
}

function buildoperate.build_operate(buildaction, roleinfo)
	return action[buildaction.type](buildaction, roleinfo)
end

return buildoperate

