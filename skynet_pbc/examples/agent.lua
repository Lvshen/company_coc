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
end

local function pbc_test()
	local init_role = {
		 name = "testname", level = 1, exp = 0, points = 0, gem = 500, goldcoin = 750, max_goldcoin = 1000, water = 750, max_water = 750, build_count = 4,
		 builds = {
		 	{ id = 100, level = 1, index = 1,  x = 35, y = 20, finish = 1 },--build_time , remain_time, collect_time, finish,time_c_type(0 建造1升级2造兵)
			{ id = 103, level = 1, index = 2,  x = 40, y = 25, finish = 1 , collect_time = 123435353},
		 	{ id = 105, level = 1, index = 3,  x = 45, y = 30, finish = 1 },
	        	{ id = 108, level = 1, index = 4,  x = 55, y = 35, finish = 1 },
	        },
	        armylvs = {
	        	[1001] = { id = 1001, level = 1 }, 
	        	[1002] = { id = 1002, level = 1 },
	        	[1003] = { id = 1003, level = 1 },
	        	[1004] = { id = 1004, level = 1 },
	        	[1005] = { id = 1005, level = 1 },
	        	[1006] = { id = 1006, level = 1 },
	        }
	}

	local buffer = protobuf.encode("PROTOCOL.role_info", init_role)
	print("buffer size=", #buffer)
	send_package(p.pack(1, 1002, buffer))
	--send_package(buffer)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return skynet.tostring(msg,sz)
	end,
	dispatch = function (session, address, text)
		--print("@@@@@@@@@", text)
		local test = string.sub(text, 7)
		data = p.unpack(text)
		--print("receive ok",data.v,data.p, data.msg)
		local t , l_error = protobuf.decode("PROTOCOL.role_info", test)
		--local t , l_error = protobuf.decode("PROTOCOL.role_info", text)
		if t == false then
			print("error :", l_error)
			pbc_test()
		else
			for k,v in pairs(t) do
				if type(k) == "string" then
					print(k,v)
				end
			end
			pbc_test()
		end
		--pbc_test()
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
