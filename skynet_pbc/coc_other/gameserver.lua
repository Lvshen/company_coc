
local skynet = require "skynet"
local redis = require "redis"

local command = {}

function command.CreateRole(user_id, msg)
	local t , l_error = protobuf.decode("PROTOCOL.create_role_req", string.sub(msg, 7))
	local result
	local rsp = {}
	rsp["result"] = 0
	if t == false then
		skynet.error("CreateRole decode error : "..l_error)
	else
		local r = skynet.call("REDISDB", "lua", "InitUserRole", user_id, t.name)
		if r == nil then
			rsp["result"] = 1
		end
		rsp["roleinfo"] = r
		result = protobuf.encode("PROTOCOL.create_role_rsp", rsp)
	end
	return result
end

function LoadRoleInfo(user_id)
	local result
	local rsp = {}
	rsp["result"] = 0
	if t == false then
		skynet.error("CreateRole decode error : "..l_error)
	else
		local r = skynet.call("REDISDB", "lua", "LoadRoleAllInfo", user_id)
		if r == nil then
			rsp["result"] = 1
		end
		rsp["roleinfo"] = r
		result = protobuf.encode("PROTOCOL.load_role_rsp", rsp)
	end
	return result
end

function command.Buildaction(user_id, msg)
	local t , l_error = protobuf.decode("PROTOCOL.buildaction_req", string.sub(msg, 7))
	local result
	local rsp = {}
	if t == false then
		skynet.error("Buildaction decode error : "..l_error)
	else
		local result, index, changeinfo, value = buildoperate.build_operate(t, role_info)
		if result == 0 then
			skynet.call("REDISDB", "lua", "UpdateRoleInfo", user_id, changed_info)	
		end
		rsp["result"] = result
		rsp["index"] = index
		rsp["value"] = value
		result = protobuf.encode("PROTOCOL.buildaction_rsp", rsp)
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
	
	skynet.register "GAMESERVER"
end)
