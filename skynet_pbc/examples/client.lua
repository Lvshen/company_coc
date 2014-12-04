
package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;examples/?.lua"

local socket = require "clientsocket"
local bit32 = require "bit32"
local proto = require "proto"

local protobuf = require "protobuf"
local p = require "p.core"

addr = io.open("./coc_lua/protocol/protocol.pb","rb")
buffer = addr:read "*a"
addr:close()
protobuf.register(buffer)

local fd = assert(socket.connect("127.0.0.1", 8888))

local function send_package(fd, pack)
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack
	print(bit32.extract(size,8,8))
	print(bit32.extract(size,0,8))
	size = #package
	print(size);
	socket.send(fd, package)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	--print("s~~~~~~~~~~", s, size)
	if size < s+2 then
		return nil, text
	end
	--print(text:sub(3,2+s), text:sub(3+s))
	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end

local function print_package(v)
	local text = p.unpack(v)
	if text == nil then
		print("error~~~~~")
		return
	end
	print(text.v, text.p)
	
	local t = protobuf.decode("PROTOCOL.role_info", string.sub(v, 7))
	--local t = protobuf.decode("PROTOCOL.role_info", text)
	if t == false then
		print("error :", l_error)
	else
		print(t.name)
		for k,v in pairs(t) do
			if type(k) == "string" then
				print(k,v)
			end
		end
	end
end

local last = ""
local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end
		print_package(v)
	end
end

local create_role_req = {
	name = "Alice"
}

local init_role = {
		 name = "testname", level = 1, exp = 0, points = 1, gem = 500, goldcoin = 750, max_goldcoin = 1000, water = 750, max_water = 750, build_count = 4,
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

--local buffer = protobuf.encode("PROTOCOL.create_role_req", create_role_req)
local buffer = protobuf.encode("PROTOCOL.role_info", init_role)

--local t = protobuf.decode("PROTOCOL.create_role_req", buffer)
local t = protobuf.decode("PROTOCOL.role_info", buffer)

print(t.name)
for k,v in pairs(t) do
	if type(k) == "string" then
		print(k,v)
	end
end

send_package(fd, p.pack(0,1002,buffer))
--send_package(fd, buffer)

while true do
	dispatch_package()
	local cmd = socket.readstdin()
	if cmd then
		--send_request("get", { what = cmd })
	else
		socket.usleep(100)
	end
end

