--[[ build_id 
   100  大本营           
   101  圣水收集器     
   102  圣水瓶           
   103  金矿              
   104  储金罐           
   105  建筑工人小屋  
   106  暗黑重油罐     
   107  暗黑重油钻井  
   108  兵营              
   109  训练营           
   110  试验室           
   111  法术工厂        
   112  野蛮人之王     
   113  暗黑训练营     
   114  弓箭女皇        
   115  加农炮           
   116  箭塔              
   117  城墙              
   118  迫击炮           
   119  隐形炸弹        
   120  防空火箭        
   121  隐形弹簧        
   122  法师塔           
   123  空中炸弹        
   124  巨型炸弹        
   125  特斯拉电磁塔  
   126  搜空地雷        
   127  X连弩             
   128  地狱之塔 
]]

local skynet = require "skynet"

local build_config = {
	[100] = {
		[1] = {blood = 80, build_money = 0, build_money_type = 0, max_gold = 1500, max_water = 1500, build_time = 60},
		[2] = {blood = 1600, build_money = 1000, build_money_type = 0, max_gold = 6000, max_water = 6000, build_time = 900},
		[3] = {blood = 1800, build_money = 4000, build_money_type = 0, max_gold = 100000, max_water = 100000, build_time = 7200},
		[4] = {blood = 2000, build_money = 25000, build_money_type = 0, max_gold = 500000, max_water = 500000, build_time = 14400},
		[5] = {blood = 2200, build_money = 150000, build_money_type = 0, max_gold = 1000000, max_water = 1000000, build_time = 36000},
		[6] = {blood = 2400, build_money = 750000, build_money_type = 0, max_gold = 2000000, max_water = 2000000, build_time = 57600},
		[7] = {blood = 2600, build_money = 1200000, build_money_type = 0, max_gold = 4000000, max_water = 4000000, build_time = 86400},
		[8] = {blood = 2800, build_money = 2000000, build_money_type = 0, max_gold = 4000000, max_water = 4000000, build_time = 172800},
		[9] = {blood = 3000, build_money = 4000000, build_money_type = 0, max_gold = 4000000, max_water = 4000000, build_time = 345600},
	},
	[103] = {
		[1] = {blood = 250, build_money = 150, build_money_type = 1, max_value = 500, produce_speed = 200, build_time = 60},
		[2] = {blood = 270, build_money = 300, build_money_type = 1, max_value = 1000, produce_speed = 400, build_time = 300},
		[3] = {blood = 280, build_money = 700, build_money_type = 1, max_value = 1500, produce_speed = 600, build_time = 800},
		[4] = {blood = 290, build_money = 1400, build_money_type = 1, max_value = 2500, produce_speed = 800, build_time = 3600},
		[5] = {blood = 310, build_money = 3000, build_money_type = 1, max_value = 10000, produce_speed = 1000, build_time = 14400},
		[6] = {blood = 320, build_money = 7000, build_money_type = 1, max_value = 20000, produce_speed = 1300, build_time = 43200},
		[7] = {blood = 340, build_money = 14000, build_money_type = 1, max_value = 30000, produce_speed = 1600, build_time = 86400},
		[8] = {blood = 350, build_money = 28000, build_money_type = 1, max_value = 50000, produce_speed = 1900, build_time = 172800},
		[9] = {blood = 390, build_money = 56000, build_money_type = 1, max_value = 75000, produce_speed = 2200, build_time = 259200},
		[10] = {blood = 420, build_money = 84000, build_money_type = 1, max_value = 100000, produce_speed = 2500, build_time = 345600},
		[11] = {blood = 450, build_money = 168000, build_money_type = 1, max_value = 150000, produce_speed = 3000, build_time = 518400},
	},
	[109] = {
		[1] = {blood = 250, build_money = 150, build_money_type = 1, space = 5, build_time = 60},
	},
}

--大本营等级基础限制其他建筑最高等级 
local build_lvlimit = {
	[1] = { [103] = 2, [101] = 2, [107] = 2, [104] = 1, [102] = 1, [106] = 1, [108] = 3, [115] = 2 },
	[2] = { [103] = 4, [101] = 4, [107] = 4, [104] = 3, [102] = 3, [106] = 3, [108] = 4, [115] = 3, [116] = 2, [117] = 2 },
	[3] = { [103] = 6, [101] = 6, [107] = 6, [104] = 6, [102] = 6, [106] = 6, [108] = 5, [110] = 1, [115] = 4, [116] = 3, [117] = 3, [118] = 1 },
	[4] = { [103] = 8, [101] = 8, [107] = 8, [104] = 8, [102] = 8, [106] = 8, [108] = 6, [110] = 2, [115] = 5, [116] = 4, [117] = 4, [118] = 2, [120] = 2, [123] = 2, [126] = 2 },
	[5] = { [103] = 10, [101] = 10, [107] = 10, [104] = 9, [102] = 9, [106] = 9, [108] = 7, [110] = 3, [111] = 1, [115] = 6, [116] = 6, [117] = 5, [118] = 3, [120] = 3, [123] = 3, [126] = 3, [122] = 2 },
	[6] = { [103] = 10, [101] = 10, [107] = 10, [104] = 10, [102] = 10, [106] = 10, [108] = 8, [110] = 4, [111] = 2, [115] = 7, [116] = 7, [117] = 6, [118] = 4, [120] = 4, [123] = 4, [126] = 4, [122] = 3 },
	[7] = { [103] = 11, [101] = 11, [107] = 11, [104] = 11, [102] = 11, [106] = 11, [108] = 9, [110] = 5, [111] = 3, [115] = 8, [116] = 8, [117] = 7, [118] = 5, [120] = 5, [123] = 5, [126] = 5, [122] = 4, [125] = 3 },
	[8] = { [103] = 11, [101] = 11, [107] = 11, [104] = 11, [102] = 11, [106] = 11, [108] = 10, [110] = 6,[111] = 3, [115] = 10, [116] = 10, [117] = 8, [118] = 6, [120] = 6, [123] = 6, [126] = 6, [122] = 6, [125] = 6 },
	[9] = { [103] = 11, [101] = 11, [107] = 11, [104] = 11, [102] = 11, [106] = 11,[108] = 10, [110] = 7, [111] = 4, [115] = 11, [116] = 11, [117] = 10, [118] = 7, [120] = 7, [123] = 7, [126] = 7, [122] = 7, [125] = 6, [127] = 3 },
}

--数目限制
local build_numlimit = {
	[1] = { [103] = 2, [101] = 1, [104] = 1, [102] = 1, [108] = 1, [115] = 2 },
	[2] = { [103] = 2, [101] = 2, [104] = 1, [102] = 1, [108] = 2, [115] = 2, [116] = 1, [117] = 25 },
	[3] = { [103] = 3, [101] = 3, [104] = 2, [102] = 2, [108] = 2, [110] = 1, [115] = 2, [116] = 1, [117] =50, [118] = 1, [119] = 2 },
	[4] = { [103] = 4, [101] = 4, [104] = 2, [102] = 2, [108] = 3, [110] = 1, [115] = 2, [116] = 2, [117] = 75, [118] = 1, [119] = 2, [120] = 1, [121] = 2 },
	[5] = { [103] = 5, [101] = 5, [104] = 2, [102] = 2, [108] = 3, [110] = 1, [111] = 1, [115] = 3, [116] = 3, [117] = 100, [118] = 1, [119] = 4, [120] = 1, [121] = 2, [122] = 1, [123] = 2 },
	[6] = { [103] = 6, [101] = 6, [104] = 2, [102] = 2, [108] = 3, [110] = 1, [111] = 1, [115] = 3, [116] = 3, [117] = 125, [118] = 2, [119] = 4, [120] = 1, [121] = 4, [122] = 2, [123] = 2, [124] = 1 },
	[7] = { [103] = 6, [101] = 6, [104] = 2, [102] = 2, [106] = 1, [108] = 4, [110] = 1, [111] = 1, [115] = 5, [116] = 4, [117] = 150, [118] = 3, [119] = 6, [120] = 2, [121] = 4, [122] = 2, [123] = 2, [124] = 2, [126] = 1, [125] = 2 },
	[8] = { [103] = 6, [101] = 6, [107] = 1, [104] = 3, [102] = 3, [106] = 1, [108] = 4, [110] = 1, [111] = 1, [115] = 5, [116] = 5, [117] = 200, [118] = 3, [119] = 6, [120] = 2, [121] = 6, [122] = 3, [123] = 3, [124] = 3, [126] = 2, [125] = 3 },
	[9] = { [103] = 6, [101] = 6, [107] = 2, [104] = 4, [102] = 4, [106] = 1, [108] = 4, [110] = 1, [111] = 1, [115] = 5, [116] = 5, [117] = 200, [118] = 3, [119] = 6, [120] = 2, [121] = 6, [122] = 3, [123] = 3, [124] = 3, [126] = 3, [125] = 4, [128] = 2 },
}

local army_config = {
	[1001] = {
		[1]= { boold = 140, space = 1, money = 20, time = 60, damage = 30 },
	},
}

local function build_finish(build)
	if build.finish == 0 then
		local now = skynet.time()
		if (now - build.build_time) > build.remain_time then
			build.finish = 1
			build.remain_time = 0
			if build.time_c_type == 1 then
				build.level = build.level + 1
			end
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
	local index = action.upgrade.index
	local build_id = action.upgrade.id
	local build = role_info.build[index]
	print("--------------")
	skynet.print_r(build)
	if build == nil then
		skynet.error(string.format("(role not this build) build id : %d (index=%d)is not exist!", tonumber(build_id)), index)
		return 3
	end
	--assert(build_config[build_id] ~= nil, "build id : "..build_id.." is not exist!")
	if build_config[build_id] == nil then
		skynet.error(string.format("(clent request error) build id : %d is not exist!", tonumber(build_id)))
		return 3
	end

	if build_finish(build) == false then
		skynet.error(string.format("build id : %d at building not finish!", tonumber(build_id)))
		return 6
	end
	
	local build_lv = tonumber(build.level)
	print("--------------",build_lv)
	local lv = build_lv + 1
	local config = build_config[build_id][lv]
	--assert(config ~= nil, "build level is Max")
	if config == nil then
		skynet.error(string.format("(clent request error) build id : %d level is (%d)Max, can't upgrade!", tonumber(build_id), build_lv))
		return 5
	end

	local camp_lv = role_info.build[1].level
	assert(camp_lv ~= nil, "roleinfo error~")
	local limit_config = build_lvlimit[camp_lv]
	assert(limit_config ~= nil, "build_lvlimit config error~"..camp_lv)
	if limit_config[build_id] == nil or build_lv >= limit_config[build_id] then
		skynet.error(string.format("build id : %d level is (%d|%d) Max in allow, can't upgrade!", tonumber(build_id), build_lv, limit_config[build_id]))
		return 5
	end
	
	local changeinfo = {}
	changeinfo["build"] = {}
	local need_money = config.build_money
	local money_type = config.build_money_type
	local have_money = have_money or 0
	if money_type == 0 and tonumber(role_info.goldcoin) >= need_money then
		have_money = tonumber(role_info.goldcoin)
		changeinfo["goldcoin"] = have_money - need_money
	elseif money_type == 1 and tonumber(role_info.water) >= need_money then
		have_money = tonumber(role_info.water)
		changeinfo["water"] = have_money - need_money
	elseif money_type == 2 and tonumber(role_info.gem) >= need_money then
		have_money = tonumber(role_info.gem)
		changeinfo["gem"] = have_money - need_money
	else 
		skynet.error(string.format(" build id : %d  money is not enough!(%d|%d|%d)", tonumber(build_id), money_type, need_monye, have_money))
		return 2
	end
	local now = skynet.time()
	build["build_time"] = now
	build["remain_time"] = config.build_time
	build["time_c_type"] = 1
	if config.build_time == 0 then
		build["finish"] = 1
		build["level"] = build_lv + 1
	else
		build["finish"] = 0
	end
	table.insert(changeinfo.build, build)
	return 0, index, changeinfo
end

local function build_count(build_id, build_t)
	assert(build_t ~= nil, "build table is nil")
	local count = count or 0
	for k, v in pairs(build_t) do
		assert(type(v) == "table", "build table element not all table")
		if build_id == v.id then
			count = count + 1
		end
	end
	return count
end

local function place_build(action, role_info)
	local build_id = action.place.id
	print("build_id : ", build_id)
	local config = build_config[build_id][1]
	if config == nil then
		skynet.error(string.format("(client request error) build id : %d is not exist!", tonumber(build_id)))
		return 3
	end
	skynet.print_r(role_info)
	local camp_lv = role_info.build[1].level
	assert(camp_lv ~= nil, "roleinfo error~")
	local limit_config = build_numlimit[camp_lv]
	assert(limit_config ~= nil, "build_lvlimit config error~"..camp_lv)
	local build_count = build_count(build_id, role_info.build)
	if limit_config[build_id] == nil or build_count >= limit_config[build_id] then
		skynet.error(string.format("build id : %d count(%d|%d) is Max in allow, can't build!", tonumber(build_id), build_count,  limit_config[build_id]))
		return 4
	end
	
	local changeinfo = {}
	changeinfo["build"] = {}
	local need_money = config.build_money
	local money_type = config.build_money_type
	local have_money = have_money or 0
	if money_type == 0 and tonumber(role_info.goldcoin) >= need_money then
		have_money = tonumber(role_info.goldcoin)
		changeinfo["goldcoin"] = have_money - need_money
	elseif money_type == 1 and tonumber(role_info.water) >= need_money then
		have_money = tonumber(role_info.water)
		changeinfo["water"] = have_money - need_money
	elseif money_type == 2 and tonumber(role_info.gem) >= need_money then
		have_money = tonumber(role_info.gem)
		changeinfo["gem"] = have_money - need_money
	else 
		skynet.error(string.format(" build id : %d  money is not enough!(%d|%d|%d)", tonumber(build_id), money_type, need_monye, have_money))
		return 2
	end
	if config.capacity ~= nil then 							--gem do not deal with
		if money_type == 0 then
			changeinfo["max_water"] = tonumber(role_info.max_water) + config.capacity
		elseif money_type == 1 then
			changeinfo["max_goldcoin"] = tonumber(role_info.max_goldcoin) + config.capacity
		end
	end
	local index = tonumber(role_info.build_count) + 1
	changeinfo["build_count"] = index
	local now = skynet.time()
	local build = action.place
	build["build_time"] = now
	build["collect_time"] = now
	build["remain_time"] = config.build_time
	build["level"] = 1
	build["index"] = role_info.build_count + 1
	if config.build_time == 0 then
		build["finish"] = 1
	else
		build["finish"] = 0
	end
	build["time_c_type"] = 0
	table.insert(changeinfo.build, build)
	return 0, index, changeinfo	
end

local function collect_resource(action, role_info)
	local index = action.collect.index
	local build_id = action.collect.id
	local build = role_info.build[index]
	if build == nil then
		skynet.error(string.format("(role not this build) build id : %d is not exist!", tonumber(build_id)))
		return 3
	end
	--assert(build_config[build_id] ~= nil, "build id : "..build_id.." is not exist!")
	if build_config[build_id] == nil then
		skynet.error("(client request error) build id : %d is not exist!", tonumber(build_id))
		return 3
	end
	local build_lv = build.level
	local config = build_config[build_id][build_lv]
	if config == nil or config.produce_speed == nil then
		skynet.error(string.format("(client request error) build id : %d is not valid resouorce build!", tonumber(build_id)))
		return 3
	end
	skynet.print_r(build)
	if build.collect_time == nil then
		skynet.error(string.format("(this is logic error) build id : %d ", tonumber(build_id)))
		return 1
	end
	if build_finish(build) == false then
		skynet.error(string.format("build id : %d at building not finish!", tonumber(build_id)))
		return 6
	end
	local changeinfo = {}
	changeinfo["build"] = {}
	local now = skynet.time()
	local interval_time = now - build.collect_time
	local value = math.floor((interval_time * config.produce_speed) /3600)
	if value > config.max_value then
		value = config.max_value
	end
	local money_type = config.build_money_type
	if money_type == 0  then 								--gem do not deal with
		changeinfo["water"] = tonumber(role_info.water) + value
		if changeinfo["water"] > tonumber(role_info.max_water) then
			changeinfo["water"] = tonumber(role_info.max_water)
		end
	elseif money_type == 1  then
		changeinfo["goldcoin"] = tonumber(role_info.goldcoin) + value
		if changeinfo["goldcoin"] > tonumber(role_info.max_goldcoin) then
			changeinfo["goldcoin"] = tonumber(role_info.max_goldcoin)
		end
	else 
		skynet.error(string.format(" build id : %d  this is logic error", tonumber(build_id)))
		return 1
	end	
	build.collect_time = now
	table.insert(changeinfo.build, build)
	return 0, index, changeinfo, value
end

local function move_build(action, role_info)
	local index = action.move.index
	local build_id = action.move.id
	local build = role_info.build[index]
	if build == nil then
		skynet.error(string.format("(role not this build) build id : %d is not exist!", tonumber(build_id)))
		return 3
	end
	build.x = action.move.x
	build.y = action.move.y
	local changeinfo = {}
	changeinfo["build"] = {}
	table.insert(changeinfo.build, build)
	return 0, index, changeinfo
end

local function produce_armys(action, role_info)
	local index = action.produce.index
	local build_id = action.produce.build_id
	local build = role_info.build[index]
	if build == nil then
		skynet.error(string.format("(role not this build) build id : %d is not exist!", build_id))
		return 3
	end
	local build_lv = build.level
	local config_build = build_config[build_id][build_lv]
	if config_builod.space == nil then
		skynet.error(string.format("(client request error) build id : %d is not valid army build!", build_id))
		return 3
	end
	local army_id = action.produce.id
	local count = action.produce.count
	local army_lv = role_info.armyslv[army_id].level
	if army_lv == nil then
		skynet.error(string.format("(client request error) army id : %d is not valid army !", army_id))
		return -1
	end
	local config_army = army_config[army_id][army_lv]
	if config_army == nil then
		skynet.error(string.format("army id : %d level(%d) is error!", army_id, army_lv))
		return 1
	end
	local role_armys = role_info.armys[index];
	local need_space = count * config_army.space
	if role_armys == nil then
		if need_space > config_builod.space then
			skynet.error(string.format("produce army id : %d need space(%d), but build space(%d) is not enough!", army_id, need_space, config_builod.space))
			return 7
		end
	else
		local role_armys_count = role_armys.sum_count
		if need_space + role_armys_count > config_builod.space then
			skynet.error(string.format("produce army id : %d need space(%d), but build space(%d) is not enough!", army_id, need_space, config_builod.space))
			return 7
		end
	end
	local have_money = tonumber(role_info.goldcoin)
	local need_money = config_army.money * count
	if have_money < need_money then
		skynet.error(string.format(" build id : %d  money is not enough!(%d|%d|%d)", tonumber(build_id), money_type, need_monye, have_money))
		return 2
	end


	
	local changeinfo = {}
	changeinfo["armys"] = {}
	local need_money = config.build_money
	local money_type = config.build_money_type
	local have_money = have_money or 0
	if money_type == 0 and tonumber(role_info.goldcoin) >= need_money then
		have_money = tonumber(role_info.goldcoin)
		changeinfo["goldcoin"] = have_money - need_money
	elseif money_type == 1 and tonumber(role_info.water) >= need_money then
		have_money = tonumber(role_info.water)
		changeinfo["water"] = have_money - need_money
	elseif money_type == 2 and tonumber(role_info.gem) >= need_money then
		have_money = tonumber(role_info.gem)
		changeinfo["gem"] = have_money - need_money
	else 
		skynet.error(string.format(" build id : %d  money is not enough!(%d|%d|%d)", tonumber(build_id), money_type, need_monye, have_money))
		return 2
	end
	local now = skynet.time()
	build["build_time"] = now
	build["remain_time"] = config.build_time
	build["time_c_type"] = 1
	if config.build_time == 0 then
		build["finish"] = 1
		build["level"] = build_lv + 1
	else
		build["finish"] = 0
	end
	table.insert(changeinfo.build, build)
	return 0, index, changeinfo
	
end

--[[
local action = {
	[0] = function(buildaction, roleinfo) upgrade_build (buildaction, roleinfo) end,
	[1] = function(buildaction, roleinfo) place_build(buildaction, roleinfo)  end,
	[2] = function(buildaction, roleinfo) collect_resource(buildaction, roleinfo)  end,
	[3] = function(buildaction, roleinfo) move_build(buildaction, roleinfo)  end,
}
]]

local buildoperate = {}

function buildoperate.build_operate(buildaction, roleinfo)
	--[[
	local f = action[buildaction.type]
	if f then
		return f(buildaction, roleinfo)
	end
	]]

	local type = buildaction.type
	if type == 0 then
		return upgrade_build (buildaction, roleinfo)
	elseif type == 1 then
		return place_build (buildaction, roleinfo)
	elseif type == 2 then
		return collect_resource (buildaction, roleinfo)
	elseif type == 3 then
		return move_build (buildaction, roleinfo)
	elseif type == 4 then
		return 
	else
		skynet.error(string.format("(client request error) type : %d is not valid!", type))
	end
end

return buildoperate
