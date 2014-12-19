package.path = "./coc/protocol/?.lua;" .. package.path

local skynet = require "skynet"
local redis = require "redis"

local command = {}

function command.auth(token)
	local t , l_error = protobuf.decode("PROTOCOL.login_req", string.sub(token, 7))
	local result
	local rsp = {}
	rsp["ret"] = 200
	if t == false then
		skynet.error("login req decode error : ", l_error)
	elseif t.type == 0 then
		local id = skynet.call("REDISDB", "lua", "UserIdFromEmail", user)
		if id == nil then
			--user not exist
			rsp["ret"] = 401
		else
			local pass = skynet.call("REDISDB", "lua", "UserPassFromId", id)
			if pass ~= password then
				--password is error
				rsp["ret"] = 402
			end
		end
		result = protobuf.encode("PROTOCOL.login_rsp", rsp)
	elseif t.type == 1 then
		local id = skynet.call("REDISDB", "lua", "UserIdFromEmail", user)
		if id == nil then
			id = skynet.call("REDISDB", "lua", "WriteUserAccount", user, password)
		else
			--user is existed
			rsp["ret"] = 403
		end
		result = protobuf.encode("PROTOCOL.login_rsp", rsp)
	else
		skynet.error("login req type error !")
	end
	return result
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
	local addr = io.open("./coc/protocol/protocol.pb","rb")
	local buffer = addr:read "*a"
	addr:close()
	protobuf.register(buffer)
	
	skynet.register "LOGIN"
end)


