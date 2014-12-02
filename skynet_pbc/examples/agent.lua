local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
--local sproto = require "sproto"
local bit32 = require "bit32"
local p = require "p.core"

local protobuf = require "protobuf"

addr = io.open("./coc_lua/protocol/protocol.pb","rb")
buffer = addr:read "*a"
addr:close()
protobuf.register(buffer)

local CMD = {}
local client_fd

local function send_package(pack)

	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack

	socket.write(client_fd, package)
	--socket.write(client_fd, netpack.pack(pack))
end

local function pbc_test()
	local create_role_req = {
	name = "Alice"
	}
	local buffer = protobuf.encode("PROTOCOL.create_role_req", create_role_req)
	send_package(buffer)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return skynet.tostring(msg,sz)
	end,
	dispatch = function (session, address, text)
		print("@@@@@@@@@", text)
		data = p.unpack(text)
		print("receive ok",data.v,data.p, data.msg)
		local t = protobuf.decode("PROTOCOL.create_role_req", data.msg)
		print(t.name)
		pbc_test()
		--[[
		local ok,result
		if data.p == 1001 then
			ok, result = skynet.call("REDISDB", "lua", "InitUserRole", uuid, data.msg)
			print("test~~~",ok, result)
		end
		]]
	end
}

function CMD.start(gate, fd, proto)
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
	skynet.call(gate, "lua", "forward", fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
