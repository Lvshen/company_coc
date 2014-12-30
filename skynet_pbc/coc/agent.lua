package.path = "./coc/protocol/?.lua;" .. package.path

local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local bit32 = require "bit32"
local p = require "p.core"
require "protocolcmd"

local CMD = {}
local client_fd
local user_id
local role_info
local user
local gate
local heartbeat_time
local HEART_INTERVALTIME = 60

local function send_package(pack)
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack
	socket.write(client_fd, package)
end

local function login(user_)
	skynet.error(string.format("%s is login", user_.name))
	user = user_
	skynet.error(skynet.print_r(user))
	-- you may load user data from database

end

local function logout(kick_flag)
	if user then
		skynet.error("enter logout :", kick_flag, gate, user.name)
		skynet.call("LOGIN", "lua", "logout", user.name)
		user = nil
	end
	if gate and kick_flag then
		skynet.call(gate, "lua", "kick", client_fd)
	end
	skynet.exit()
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)	
		return skynet.tostring(msg, sz)
	end,
	dispatch = function (session, address, msg)
		data = p.unpack(msg)
		--skynet.error("Receive Head Cmd : ", data.v, data.p)
		heartbeat_time = skynet.time()
		if data.p == PCMD_LOGIN_REQ then
			local result, user_, ret = skynet.call("LOGIN", "lua", "auth", msg)
			if result ~= nil then
				send_package(p.pack(PCMD_HEAD, PCMD_LOGIN_RSP, result))
				if ret == 200 then
					login(user_)
				end
			end
		elseif data.p == PCMD_CREATEROLE_REQ then
			assert(user ~= nil, "user is null, not login!")
			local result, roleinfo = skynet.call("GAMESERVER", "lua", "CreateRole", user.id, msg)
			if result ~= nil then
				role_info = roleinfo
				send_package(p.pack(PCMD_HEAD, PCMD_CREATEROLE_RSP, result))
			end
		elseif data.p == PCMD_LOADROLE_REQ then
			assert(user ~= nil, "user is null, not login!")
			local result, roleinfo = skynet.call("GAMESERVER", "lua", "LoadRoleInfo", user.id, role_info)
			if result ~= nil then
				role_info = roleinfo
				send_package(p.pack(PCMD_HEAD, PCMD_LOADROLE_RSP, result))
			end
		elseif data.p == PCMD_BUILDACTION_REQ then
			assert(user ~= nil, "user is null, not login!")
			local result, roleinfo= skynet.call("GAMESERVER", "lua", "Buildaction", user.id, role_info, msg)
			if result ~= nil then
				if roleinfo ~= nil then
					role_info = roleinfo
				end
				send_package(p.pack(PCMD_HEAD, PCMD_BUILDACTION_RSP, result))
			end
		end
	end
}

function CMD.logout(kick_flag)
	logout(kick_flag)
end

function CMD.start(gate_, fd)
	skynet.error("new client fd = ", fd, gate_)
	gate = gate_
	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
	skynet.fork(function()
		heartbeat_time = skynet.time()
		while true do
			if skynet.time() - heartbeat_time > HEART_INTERVALTIME then
				logout(true)
				break
			end
			send_package(p.pack(PCMD_HEAD, PCMD_HEART, ""))
			skynet.sleep(500)
			--print("Is in online !")
		end
	end)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)