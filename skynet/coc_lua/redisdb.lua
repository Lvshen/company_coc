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
	local init_role = {
		 name = name, level = 1, exp = 0, points = 0, gem = 500, goldcoin = 750, max_goldcoin = 1000, water = 750, max_water = 750, build_count = 4,
		 build = {
		 	{ id = 100, level = 1, index = 1,  x = 35, y = 20 },
			{ id = 103, level = 1, index = 2,  x = 40, y = 25 },
		 	{ id = 105, level = 1, index = 3,  x = 45, y = 30 },
	        	{ id = 108, level = 1, index = 4,  x = 55, y = 35 },
	        }
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
	return init_role
end

function command.LoadRoleAllInfo(id)
	local data_key = string.format("role:[%d]:data", id)
	local build_key = string.format("role:[%d]:build", id)

	if (exists(data_key)) == 0 then
		return nil
	end
	
	db:multi()
	db:hgetall(data_key)
	db:hgetall(build_key)
	local t = db:exec()
	local r = {}
	r["build"]={}
	for k, v in pairs(t) do
		if k == 1 then
			 for i = 1, #v / 2 do
			       r[v[2*i - 1]] = v[2*i]
			  end			
		else
			for i = 1, #v/2 do
				table.insert(r["build"], table.loadstring(v[2*i]))
			end
		end
	end
	return r
	
end

local function UpdateData(id, tab_data)
	assert(type(tab_data) == "table", "data is error")
	local key = string.format("role:[%d]:data", id)
	assert(db:exists(key) == 1, "key:"..key.."not exists")
	local t = {}
	for k, v in pairs(tab_data) do
		table.insert(t, k)
		table.insert(t, v)		
	end
	table.insert(t, 1, key)
	db:hmset(t)
end

local function UpdateBuild(id, tab_build)
	assert(type(tab_build) == "table", "data is error")
	local key = string.format("role:[%d]:build", id)
	assert(db:exists(key) == 1, "key:"..key.."not exists")
	local t = {}
	for k, v in pairs(tab_build) do
		assert(type(value), "value is not table")
		table.insert(t, value.index)
		table.insert(t, skynet.serialize(value))
	end
end

function command.UpdateRoleInfo(id, tab)
	for k, v in pairs(tab) do
		
	end
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

