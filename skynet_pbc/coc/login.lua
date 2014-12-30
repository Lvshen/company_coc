
local skynet = require "skynet"
local redis = require "redis"

local user_login = {}
local command = {}

function command.auth(token)
	local t , l_error = protobuf.decode("LOGIN.login_req", string.sub(token, 7))
	local user = {}
	local result
	local ret = ret or 200
	local rsp = {}
	if t == false then
		skynet.error("login req decode error : ", l_error)
	elseif t.type == 0 then
		skynet.error("Receive Data :", skynet.print_r(t))
		if user_login[t.user] then
			ret = 404
			rsp["ret"] = ret
			result = protobuf.encode("LOGIN.login_rsp", rsp)
			return result, user, ret
		end
		user = {
			name = t.user,
			id = tonumber(skynet.call("REDISDB", "lua", "UserIdFromEmail", t.user))
		}
		if user.id == nil then
			--user not exist
			ret = 401
		else
			local pass = skynet.call("REDISDB", "lua", "UserPassFromId", user.id)
			if pass ~= t.pass then
				--password is error
				ret = 402
			end
			user_login[t.user] = true
		end
		rsp["ret"] = ret
		--rsp["name"] = t.user
		result = protobuf.encode("LOGIN.login_rsp", rsp)
	elseif t.type == 1 then
		skynet.error("Receive Data :", skynet.print_r(t))
		user = {
			name = t.user,
			id = tonumber(skynet.call("REDISDB", "lua", "UserIdFromEmail", t.user))
		}
		if user.id == nil then
			user.id = skynet.call("REDISDB", "lua", "WriteUserAccount", t.user, t.pass)
			user_login[t.user] = true
		else
			--user is existed
			ret = 403
		end
		rsp["ret"] = ret
		--rsp["name"] = t.user
		result = protobuf.encode("LOGIN.login_rsp", rsp)
	else
		skynet.error("login req type error !")
	end
	if result ~= nil then
		skynet.error("send client msg :", skynet.print_r(rsp))
	end
	return result, user, ret
end

function command.logout(name)
	print("name :", name)
	user_login[name] = false
end
skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		--local f = command[string.upper(cmd)]
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	
	protobuf = require "protobuf"
	local addr = io.open("./coc/protocol/login.pb","rb")
	local buffer = addr:read "*a"
	addr:close()
	protobuf.register(buffer)
	
	skynet.register "LOGIN"
end)


