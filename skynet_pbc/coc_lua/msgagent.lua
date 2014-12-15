package.path = "./coc_lua/protocol/?.lua;./coc_lua/build/?.lua;" .. package.path

local skynet = require "skynet"
local socket = require "socket"
local buildoperate = require "buildoperate"
local p = require "p.core"
local protobuf = require "protobuf"
require "protocolcmd"

addr = io.open("./coc_lua/protocol/protocol.pb","rb")
buffer = addr:read "*a"
addr:close()
protobuf.register(buffer)

local client_fd
local heartbeat_time

local uuid
local role_info = {}

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

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)	
		return skynet.tostring(msg, sz)
	end,
	dispatch = function (session, address, msg)
		data = p.unpack(msg)
		skynet.error("receive ok "..data.v.." "..data.p)
		if data.p == PCMD_CREATEROLE_REQ then
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

local gate
local userid, subid

local CMD = {}

local action = {
	["goldcoin"] = function(value) 
		role_info["goldcoin"] = role_info["goldcoin"] + value
	end,
}

function CMD.update(key, value)
	action[key] (value)
end

function CMD.login(source, uid, sid, secret, id)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
	userid = uid
	subid = sid
	uuid = id
	-- you may load user data from database
	role_info = skynet.call("REDISDB", "lua", "LoadRoleAllInfo", uuid)
end

local function logout()
	print("enter logout", gate, userid, subid)
	if gate then
		skynet.call(gate, "lua", "logout", userid, subid)
	end
	skynet.exit()
end

function CMD.logout(source)
	print("enter logout 1", gate, userid, subid)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", userid))
	logout()
end

function CMD.afk(source)
	-- the connection is broken, but the user may back
	skynet.error(string.format("AFK"))
end

function CMD.heartbeat(source, fd)
	client_fd = fd
	heartbeat_time = skynet.time()
	skynet.fork(function()
	while true do
		if (skynet.time() - heartbeat_time) > 60 then
			logout()
			break
		end
		skynet.sleep(500)
	end
	end)
end

skynet.start(function()
	-- If you want to fork a work thread , you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		print("msgagent cmd=", command)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)
--[[
	skynet.dispatch("client", function(_,_, msg)
		print("msgagent msg=", msg)
		-- the simple ehco service
		skynet.sleep(10)	-- sleep a while
		skynet.ret(msg)
	end)
]]
end)
