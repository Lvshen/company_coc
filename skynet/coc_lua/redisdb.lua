local skynet = require "skynet"
local redis = require "redis"

local db
local command = {}
local USER_BEGINID = 10000

local function set(key, value)
	db:set(key,value)
end

local function mset(...)
	print(...)
	db:mset(...)
end

local function incr(key)
	return db:incr(key)
end

local function get(key)
	return db:get(key)
end

local function mget(...)
	return db:mget(...)
end

local function sadd(key, value)
	db:sadd(key, value)
end

local function hmset(key, t)
	db:hmset(key, table.unpack(t))
end

local function hmget(key, ...)
	return db:hmget(key, ...)
end

local function exists(key)
	return db:exists(key)
end

function command.UserIdFromEmail(email)
	local key = string.format("account:email:[%s]", email)
	return get(key)
end

function command.UserPassFromId(id)
	local key = string.format("account:[%d]:password", id)
	return get(key)
end

function command.WriteUserAccount(email, password)
	local countkey = "account:count"
	local id = incr(countkey)
	if id == 1 then
		id = USER_BEGINID
		set(countkey, id)
	end
	local key1 = string.format("account:email:[%s]", email)
	local key2 = string.format("account:[%d]:password", id)
	print(key1, id, key2, password)
	mset(key1, id, key2, password)
	return id
end

function command.InitUserRole(id, name)
	local now = skynet.time()
	local init_role = {
		 name = name, level = 1, exp = 0, points = 0, gem = 500, goldcoin = 750, max_goldcoin = 1000, water = 750, max_water = 750, build_count = 4,
		 build = {
		 	{ id = 100, level = 1, index = 1,  x = 35, y = 20, finish = 1 },--build_time , remain_time, collect_time, finish,time_c_type(0 建造1升级2造兵)
			{ id = 103, level = 1, index = 2,  x = 40, y = 25, finish = 1 , collect_time = now},
		 	{ id = 105, level = 1, index = 3,  x = 45, y = 30, finish = 1 },
	        	{ id = 108, level = 1, index = 4,  x = 55, y = 35, finish = 1 },
	        },
	        armys_lv = {
	        	[1001] = { id = 1001, level = 1 }, 
	        	[1002] = { id = 1002, level = 1 },
	        	[1003] = { id = 1003, level = 1 },
	        	[1004] = { id = 1003, level = 1 },
	        	[1005] = { id = 1003, level = 1 },
	        	[1006] = { id = 1003, level = 1 },
	        }
	        armys = {id = 109, index = 9, {id = 1001, count = 5,  remain_time, finish}}
	        --[[
	        armys = {
			{ index = 7, id = 109, sum_count = 5, { id = 1001, level = 1, count = 5 } },
			...,
	        },
	        ]]
	}
	local data_key = string.format("role:[%d]:data", id)
	local build_key = string.format("role:[%d]:build", id)
	local t = {}
	for key, value in pairs(init_role) do
		if type(value) == "table" then
			if key ~= "build" then
				table.insert(t, key)
				table.insert(t, skynet.serialize(value))
			end
		else
			table.insert(t, key)
			table.insert(t, value)
		end		
	end
	table.insert(t, 1, data_key)
	db:multi()
	db:hmset(t)
	t = {}
	for key, value in pairs(init_role.build) do
		if type(value) == "table" then
			table.insert(t, value.index)
			table.insert(t, skynet.serialize(value))
		else
			table.insert(t, key)
			table.insert(t, value)
		end
	end
	table.insert(t, 1, build_key)
	db:hmset(t)
	db:exec()
	return init_role
end

local function re_build_finish(build)
	if build.finish == 0 then
		local now = skynet.time()
		if (now - build.build_time) > build.remain_time then
			build.finish = 1
			build.remain_time = 0
			return true
		else
			build.remain_time = now - build.build_time 
		end
		return true
	end
	return false
end

function command.LoadRoleAllInfo(id)
	local data_key = string.format("role:[%d]:data", id)
	local build_key = string.format("role:[%d]:build", id)
	local armys_key = string.format("role:[%d]:army", id)
	if (exists(data_key)) == 0 then
		return nil
	end
	
	db:multi()
	db:hgetall(data_key) --k = 1
	db:hgetall(build_key) --k = 2
	db:hgetall(armys_key)
	local t = db:exec()
	local r = {}
	r["build"] = {}
	r["armys"] = {}
	for k, v in pairs(t) do
		if k == 1 then
			 for i = 1, #v / 2 do
			       r[v[2*i - 1]] = v[2*i]
			  end			
		else
			local _t = r["build"]
			local tab_build = {}
			local update_flag = false
			for i = 1, #v/2 do
				local temp_t = table.loadstring(v[2*i])
				if temp_t.build_time ~= nil and re_build_finish(temp_t) == true then
					table.insert(tab_build, temp_t)
					update_flag = true
				end
				 _t [tonumber(v[2*i - 1])] = temp_t
				--table.insert(r["build"], _t.index, table.loadstring(v[2*i]))
			end
			if update_flag == true then
				UpdateBuild(id, tab_build)
			end
		end
	end
	return r
	
end

local function UpdateData(id, tab_data)
	assert(type(tab_data) == "table", "data is error")
	local key = string.format("role:[%d]:data", id)
	assert(tonumber(db:exists(key)) == 1, "key:"..key.."not exists")
	local t = {}
	for k, v in pairs(tab_data) do
		table.insert(t, k)
		table.insert(t, v)		
	end
	table.insert(t, 1, key)
	db:hmset(t)
end

function UpdateBuild(id, tab_build)
	assert(type(tab_build) == "table", "data is error")
	local key = string.format("role:[%d]:build", id)
	skynet.print_r(tab_build)
	assert(db:exists(key) == true, "key: "..key.." not exists")
	local t = {}
	for k, v in pairs(tab_build) do
		if type(v) == "table" then 
			table.insert(t, v.index)
			table.insert(t, skynet.serialize(v))
		end
	end
	table.insert(t, 1, key)
	db:hmset(t)
end

function command.UpdateRoleInfo(id, tab)
	assert(type(tab) == "table", "data is error")
	local data_key = string.format("role:[%d]:data", id)
	local build_key = string.format("role:[%d]:build", id)
	local data_t = {}
	local build_t = {}
	local empty_data = true
	local empty_build = true
	for k, v in pairs(tab) do
		if type(v) == "table" then
			if k == "build" then
				for _k, _v in pairs(v) do
					empty_build = false
					table.insert(build_t, _v.index)
					table.insert(build_t, skynet.serialize(_v))
				end
			end
		else
			empty_data = false
			table.insert(data_t, k)
			table.insert(data_t, v)
		end
	end
	table.insert(data_t, 1, data_key)
	table.insert(build_t, 1, build_key)
	db:multi()
	if empty_data == false then
		db:hmset(data_t)
	end
	if empty_build == false then
		db:hmset(build_t)
	end 
	db:exec()
end

skynet.start(function()
	 db = redis.connect {
        host = "127.0.0.1",
        port = 6379,
        db   = 0,
        --auth = "foobared"
    	}
	skynet.dispatch("lua", function(session, address, cmd, ...)
		print("my_redis cmd=", cmd)
		--local f = command[string.upper(cmd)]
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register "REDISDB"
	print("redisdb start")
end)

