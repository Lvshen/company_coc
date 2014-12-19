
local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local bit32 = require "bit32"
local p = require "p.core"
require "protocolcmd"

local CMD = {}
local client_fd
local user_id
local function send_package(pack)
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack

	socket.write(client_fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)	
		return skynet.tostring(msg, sz)
	end,
	dispatch = function (session, address, msg)
		data = p.unpack(msg)
		skynet.error("receive ok ", data.v, data.p)
		if data.p == PCMD_LOGIN_REQ then
			local result = skynet.call("LOGIN", "lua", "auth", msg)
			if result ~= nil then
				send_package(p.pack(1, PCMD_LOGIN_RSP, result))
			end
		elseif data.p == PCMD_CREATEROLE_REQ then
			local result = skynet.call("GAMESERVER", "lua", "CreateRole", user_id, msg)
			if result ~= nil then
				send_package(p.pack(1, PCMD_CREATEROLE_RSP, result))
			end
		elseif data.p == PCMD_LOADROLE_REQ then
			local result = skynet.call("GAMESERVER", "lua", "LoadRoleInfo", user_id)
			if result ~= nil then
				send_package(p.pack(1, PCMD_LOADROLE_RSP, result))
			end
		elseif data.p == PCMD_BUILDACTION_REQ then
			local result = skynet.call("GAMESERVER", "lua", "Buildaction", user_id, msg)
			if result ~= nil then
				send_package(p.pack(1, PCMD_BUILDACTION_RSP, result))
			end
		end
	end
}

function CMD.start(gate, fd)
	print("new client fd = ", fd)
	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
