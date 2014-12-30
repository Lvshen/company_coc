package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;coc/?.lua;coc/protocol/?.lua"

local socket = require "clientsocket"
local p = require "p.core"
require "protocolcmd"

local protobuf = require "protobuf"
addr = io.open("./coc/protocol/protocol.pb","rb")
buffer = addr:read "*a"
addr:close()
protobuf.register(buffer)

local print = print
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local type = type
local pairs = pairs
local tostring = tostring
local next = next


local last = ""
--local fd = assert(socket.connect("192.168.1.250", 8001))

local function print_r(root)
        local cache = {  [root] = "." }
        local function _dump(t,space,name)
                local temp = {}
                for k,v in pairs(t) do
                        local key = tostring(k)
                        if cache[v] then
                                tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
                        elseif type(v) == "table" then
                                local new_key = name .. "." .. key
                                cache[v] = new_key
                                tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
                        else
                                tinsert(temp,"+" .. key .. " [" .. tostring(v).."]")
                        end
                end
                return tconcat(temp,"\n"..space)
        end
        print(_dump(root, "",""))
end

-------connect gameserver------------
local fd = assert(socket.connect("192.168.1.251", 8888))

local function send_package(fd, pack)
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack
	print(bit32.extract(size,8,8))
	print(bit32.extract(size,0,8))
	socket.send(fd, package)
	--print(package)
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

local function print_package(v)
	local data = p.unpack(v)
	if data == nil then
		print("error~~~~~")
		return
	end
	print(data.v, data.p)
	local t
	if data.p == PCMD_LOGIN_RSP then
		t = protobuf.decode("PROTOCOL.login_rsp", string.sub(v, 7))
	elseif data.p == PCMD_CREATEROLE_RSP then
		t = protobuf.decode("PROTOCOL.create_role_rsp", string.sub(v, 7))
	elseif data.p == PCMD_LOADROLE_RSP then
		t = protobuf.decode("PROTOCOL.load_role_rsp", string.sub(v, 7))
	elseif data.p == PCMD_BUILDACTION_RSP then
		t = protobuf.decode("PROTOCOL.buildaction_rsp", string.sub(v, 7))
	elseif data.p == PCMD_HEART then
		--print("Have Receive Heart :", v)
		return
	end
	if t == false then
		print("error :", l_error)
	else
		for k,v in pairs(t) do
			if type(k) == "string" then
				if type(v) == "table" then
					print_r(v)
				else
					print(k,v)
				end
			end
		end
	end
end

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

local req = {
	[0] = {name = "Alice"},
		--[[
		, armys = {{id = 102, count = 5, finish = 1, remain_time = 2352}, {id = 103, count = 5, finish = 1, remain_time = 23552}}, 
		armylvs = {
	        	{ id = 1001, level = 1 }, 
	        	{ id = 1002, level = 1 },
	        	{ id = 1003, level = 1 },
	        	{ id = 1003, level = 1 },
	        	{ id = 1003, level = 1 },
	        	{ id = 1003, level = 1 },
	        }},
	        ]]
	[2] = {type = 0, upgrade = {id = 103, index = 5}},
	[3] = {type = 1, place = {id = 115, x = 30, y = 40}},
	[4] = {type = 2, collect = {id = 103, index = 5}},
	[5] = {type = 3, move = {id = 103, index = 5, x = 10, y = 55}},
	[6] = {type = 4, produce = {id = 1001, count = 5, build_id = 115, index = 6}},--, armys={index=1,id=2,sum_count=3,finish=0}
	[7] = {result=0, roleinfo={name="12442", level = 10, exp = 10, points = 10, gem = 142, goldcoin = 200,max_goldcoin=300,water=23, max_water=5235, build_count =5, armys={index=1,id=2,sum_count=3,finish=0, armys={{id=1,count=3,counting=6,create_time=235235,remain_time=23525}, {index=1,id=2,sum_count=3,finish=0}}}}},
	[8] = {type = 0, servername = "gameserver", user = "robot67597@dh.com", pass = "123456"},
}

--[[
local buffer
local itype = 8
if itype == 0 then
	--print_r(req[itype])
	buffer = protobuf.encode("PROTOCOL.create_role_req", req[itype])
	--local t = protobuf.decode("PROTOCOL.create_role_req", buffer)
	--print("##############################################")
	--print_r(t)
	send_package(fd, p.pack(1,PCMD_CREATEROLE_REQ,buffer))
elseif itype == 1 then
	send_package(fd, p.pack(1,PCMD_LOADROLE_REQ,""))
elseif itype == 8 then
	buffer = protobuf.encode("PROTOCOL.login_req", req[itype])
	local t = protobuf.decode("PROTOCOL.login_req", buffer)
	print("##############################################")
	print_r(t)
	send_package(fd, p.pack(1,PCMD_LOGIN_REQ,buffer))
else
	--buffer = protobuf.encode("PROTOCOL.buildaction_req", req[itype])
	--send_package(fd, p.pack(1,PCMD_BUILDACTION_REQ,buffer))
end
]]


while true do
	dispatch_package()
  	local itype = socket.readstdin()
  	if itype then
  		print("itype : ", itype)
  		local buffer
		if tonumber(itype) == 0 then
			--print_r(req[itype])
			buffer = protobuf.encode("PROTOCOL.create_role_req", req[tonumber(itype)])
			--local t = protobuf.decode("PROTOCOL.create_role_req", buffer)
			--print("##############################################")
			--print_r(t)
			send_package(fd, p.pack(1,PCMD_CREATEROLE_REQ,buffer))
		elseif tonumber(itype) == 1 then
			send_package(fd, p.pack(1,PCMD_LOADROLE_REQ,""))
		elseif tonumber(itype) == 8 then
			buffer = protobuf.encode("PROTOCOL.login_req", req[tonumber(itype)])
			local t = protobuf.decode("PROTOCOL.login_req", buffer)
			print("##############################################")
			print_r(t)
			send_package(fd, p.pack(1,PCMD_LOGIN_REQ,buffer))
		elseif tonumber(itype) == 2 or tonumber(itype) == 3 or tonumber(itype) == 4 or tonumber(itype) == 6 then
			buffer = protobuf.encode("PROTOCOL.buildaction_req", req[tonumber(itype)])
			send_package(fd, p.pack(1,PCMD_BUILDACTION_REQ,buffer))
		end
  	else
  		--send_request("heartbeat")
  		--socket.usleep(5000000)
  		socket.usleep(100)
  	end
  end

