package.path = "./coc/protocol/?.lua;" .. package.path

local skynet = require "skynet"
local redis = require "redis"
local socket = require "socket"
local bit32 = require "bit32"
local p = require "p.core"
require "protocolcmd"

local function send_package(fd, pack)
	print("")
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack

	socket.write(fd, package)
end

local command = {}
function command.auth(fd, user, password)
	print("auth :", fd, user, password)
	local rsp = {}
	rsp["ret"] = 200
	local result
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
	local t = protobuf.decode("PROTOCOL.login_rsp", result)
	print("##############################################", p.pack)
	skynet.error(skynet.print_r(t))
	send_package(fd, p.pack(1, PCMD_LOGIN_RSP, result))
	skynet.error(skynet.print_r(rsp))
	return result, id
end

function command.register(fd, user, password)
	local rsp = {}
	rsp["ret"] = 200
	local result
	local id = skynet.call("REDISDB", "lua", "UserIdFromEmail", user)
	if id == nil then
		id = skynet.call("REDISDB", "lua", "WriteUserAccount", user, password)
	else
		--user is existed
		rsp["ret"] = 403
	end
	result = protobuf.encode("PROTOCOL.login_rsp", rsp)
	send_package(fd, p.pack(1, PCMD_LOGIN_RSP, result))
	return result, id
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


