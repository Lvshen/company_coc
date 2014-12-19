package.path = "./coc/protocol/?.lua;./coc/build/?.lua;" .. package.path

local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
--local sproto = require "sproto"
local bit32 = require "bit32"
local p = require "p.core"
require "protocolcmd"
local protobuf
local CMD = {}
local client_fd

local function send_package(pack)

	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack

	socket.write(client_fd, package)
end

local function CreateRole(msg)
	local t , l_error = protobuf.decode("PROTOCOL.create_role_req", string.sub(msg, 7))
	local rsp = {}
	if t == false then
		skynet.error("CreateRole decode error : "..l_error)
		return
	else
		if role_info.name ~= nil then
			rsp["result"] = 1
			rsp["roleinfo"] = role_info
		else
			local result, r = skynet.call("REDISDB", "lua", "InitUserRole", uuid, t.name)
			rsp["result"] = result
			rsp["roleinfo"] = r
		end
	end
	skynet.error(skynet.print_r(rsp))
	local buffer = protobuf.encode("PROTOCOL.create_role_rsp", rsp)
	send_package(p.pack(1, PCMD_CREATEROLE_RSP, buffer))
end

local function LoadRoleInfo()
	local rsp = {}
	if role_info.name == nil then
		rsp["result"] = 1
	else
		rsp["result"] = 0
		rsp["roleinfo"] = role_info
	end
	skynet.error(skynet.print_r(rsp))
	local buffer = protobuf.encode("PROTOCOL.load_role_rsp", rsp)
	local t = protobuf.decode("PROTOCOL.load_role_rsp", buffer)
	--skynet.error("##############################################")
	--skynet.error(skynet.print_r(t))
	send_package(p.pack(1, PCMD_LOADROLE_RSP, buffer))
end

local function Buildaction(msg)
	local t , l_error = protobuf.decode("PROTOCOL.buildaction_req", string.sub(msg, 7))
	local rsp = {}
	if t == false then
		skynet.error("Buildaction decode error : "..l_error)
		return
	else
		local result, index, changeinfo, value = buildoperate.build_operate(t, role_info)
		if result == 0 then
			UpdateRoleInfo(changeinfo)	
		end
		rsp["result"] = result
		rsp["index"] = index
		rsp["value"] = value
		local buffer = protobuf.encode("PROTOCOL.buildaction_rsp", rsp)
		send_package(p.pack(1, PCMD_BUILDACTION_RSP, buffer))
	end
end

local function Auth(msg)
	local t , l_error = protobuf.decode("PROTOCOL.login_req", string.sub(msg, 7))
	--skynet.error(skynet.print_r(t))
	local rsp = {}
	if t == false then
		skynet.error("login req decode error : ", l_error, msg)
		return
	elseif t.type == 0 then
		result, id = skynet.call("LOGIN", "lua", "auth", client_fd, t.user, t.pass)
	elseif t.type == 1 then
		result, id = skynet.call("LOGIN", "lua", "register", client_fd, t.user, t.pass)
	else
		skynet.error("login req type error !")
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)	
		return skynet.tostring(msg, sz)
	end,
	dispatch = function (session, address, msg)
		data = p.unpack(msg)
		skynet.error("receive ok ", data.v, data.p, msg)
		--[[test
		print("msg size", #string.sub(msg, 7))
		local t , l_error = protobuf.decode("PROTOCOL.role_info", string.sub(msg, 7))
		if t == false then
			skynet.error("test req decode error : ", l_error)
			return
		end
		local rsp = {name = "124", level = 2, exp = 90, points = 23, gem = 3245, goldcoin = 235, max_goldcoin = 2566, water = 235, max_water = 2325, build_count = 34}	
		local buffer = protobuf.encode("PROTOCOL.role_info", rsp)
		send_package(p.pack(1, 1002, buffer))
		skynet.error(skynet.print_r(t))
		--test end]]
		if data.p == PCMD_LOGIN_REQ then
			Auth(msg)
		elseif data.p == PCMD_CREATEROLE_REQ then
			CreateRole(msg)
		elseif data.p == PCMD_LOADROLE_REQ then
			LoadRoleInfo()
		elseif data.p == PCMD_BUILDACTION_REQ then
			Buildaction(msg)
		end
	end
}

--update role_info
function UpdateRoleInfo(changed_info)
	--example : changed_info = {level = 1, ..., build = {{ id = 100, level = 1, index = 1,  x = 35, y = 20 },{...},...}}
	for k, v in pairs(changed_info) do
		if type(v) == "table" then
			if k == "build" then
				local t = role_info.build
				for _k, _v in pairs(v) do
					local index = _v.index
					t["index"] = _v
				end
			end
		else
			role_info[k] = v
		end
	end
	skynet.call("REDISDB", "lua", "UpdateRoleInfo", uuid, changed_info)
end

function CMD.start(gate, fd)
--[[
	skynet.fork(function()
		while true do
			send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)
]]
	print("new client fd = ", fd)
	client_fd = fd
	protobuf = require "protobuf"
	local addr = io.open("./coc/protocol/protocol.pb","rb")
	local buffer = addr:read "*a"
	addr:close()
	protobuf.register(buffer)
	skynet.call(gate, "lua", "forward", fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
