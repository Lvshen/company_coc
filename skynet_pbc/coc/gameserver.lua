package.path = "./coc/build/?.lua;" .. package.path
local skynet = require "skynet"
local redis = require "redis"
local buildoperate = require "buildoperate"

local command = {}

function command.CreateRole(user_id, msg)
	local t , l_error = protobuf.decode("ACTION.create_role_req", string.sub(msg, 7))
	local roleinfo
	local result
	local rsp = {}
	rsp["result"] = 0
	if t == false then
		skynet.error("CreateRole decode error : "..l_error)
	else
		skynet.error("Receive Data :", skynet.print_r(t))
		roleinfo = skynet.call("REDISDB", "lua", "InitUserRole", user_id, t.name)
		if roleinfo == nil then
			rsp["result"] = 1
		end
		rsp["roleinfo"] = roleinfo
		result = protobuf.encode("ACTION.create_role_rsp", rsp)
	end
	if result ~= nil then
		skynet.error("send client msg :", skynet.print_r(rsp))
	end
	return result, roleinfo
end

function command.LoadRoleInfo(user_id, role_info)
	local rsp = {}
	rsp["result"] = 0
	if role_info == nil then
		local r = skynet.call("REDISDB", "lua", "LoadRoleAllInfo", user_id)
		if r == nil then
			rsp["result"] = 1
		end
		rsp["roleinfo"] = r
		role_info = r
	else
		rsp["roleinfo"] = role_info
	end
	local result = protobuf.encode("ACTION.load_role_rsp", rsp)
	if result ~= nil then
		skynet.error("send client msg :", skynet.print_r(rsp))
	end
	return result, role_info
end

function command.Buildaction(user_id, role_info, msg)
	local t , l_error = protobuf.decode("ACTION.buildaction_req", string.sub(msg, 7))
	local roleinfo
	local result
	local rsp = {}
	if t == false then
		skynet.error("Buildaction decode error : "..l_error)
	else
		skynet.error("Receive Data :", skynet.print_r(t))
		local ret, index, changeinfo, value = buildoperate.build_operate(t, role_info)
		if ret == 0 then
			roleinfo = skynet.call("REDISDB", "lua", "UpdateRoleInfo", user_id, changeinfo)	
		end
		rsp["result"] = ret
		rsp["index"] = index
		rsp["value"] = value
		result = protobuf.encode("ACTION.buildaction_rsp", rsp)
	end
	if result ~= nil then
		skynet.error("send client msg :", skynet.print_r(rsp))
	end
	return result, roleinfo
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
	local addr = io.open("./coc/protocol/action.pb","rb")
	local buffer = addr:read "*a"
	addr:close()
	protobuf.register(buffer)
	
	skynet.register "GAMESERVER"
end)
