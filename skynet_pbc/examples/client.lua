
package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;examples/?.lua"

local socket = require "clientsocket"
local bit32 = require "bit32"
local proto = require "proto"

local protobuf = require "protobuf"
local p = require "p.core"

addr = io.open("./coc_lua/protocol/testpbc.pb","rb")
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
	if size < s+2 then
		return nil, text
	end

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

local last = ""



local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end

		--print_package(host:dispatch(v))
	end
end

local create_role_req = {
	name = "Alice"
}

local buffer = protobuf.encode("testpbc.create_role_req", create_role_req)

local t = protobuf.decode("testpbc.create_role_req", buffer)
print(t.name)
for k,v in pairs(t) do
	if type(k) == "string" then
		print(k,v)
	end
end

--send_package(fd, p.pack(1,1002,buffer))
send_package(fd, buffer)

while true do
	dispatch_package()
	local cmd = socket.readstdin()
	if cmd then
		--send_request("get", { what = cmd })
	else
		socket.usleep(100)
	end
end

