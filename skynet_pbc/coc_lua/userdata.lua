local skynet = require "skynet"

local USER_BEGINID = 10000	

local UserData = {}

local function GetUserID(email)
	local key = string.format("account:email:[%s]", email)
	local value = skynet.call("MY_REDIS", "lua", "string_get", key)
	return value
end

local function GetUserPass(id)
	local key = string.format("account:[%d]:password", id)
	return skynet.call("MY_REDIS", "lua", "string_get", key)
end

local function SetUser(email, pass)
	local countkey = "account:count"
	local id = skynet.call("MY_REDIS", "lua", "string_get", countkey)
	local int_id = tonumber(id) or 0
	print("~~~!!!~~~~~", int_id)
	if int_id == 0 then
		int_id = USER_BEGINID
		local bOk = skynet.call("MY_REDIS", "lua", "string_set", countkey, int_id)
		print("setUser", bOk)
		--assert(bOk == "OK")
	else
		int_id = int_id+ 1
		local incrId = skynet.call("MY_REDIS", "lua", "string_incr", countkey)
		assert(int_id == incrId, "id error")
	end
	local key1 = string.format("account:email:[%s]", email)
	local key2 = string.format("account:[%d]:password", int_id)
	local t = {}
	t[key1] = int_id
	t[key2] = pass
	skynet.call("MY_REDIS", "lua", "mset", t)
	return true
end

function UserData.UserRegister(email, pass)
	local r = r or 0
	local value = GetUserID(email)
	if value == nil then
		SetUser(email, pass)
	else
		r = 1 
	end
	return r
end

function UserData.Auth(email, pass)
	print(email, pass)
	local r = r or 0
	local value = GetUserID(email)
	if value == nil then
		r = 1 --user not exist
	else
		value = GetUserPass(value)
		if value ~= pass then
			r = 2 --password is error
		end
	end
	return r
end

return UserData