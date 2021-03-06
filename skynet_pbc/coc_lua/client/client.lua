package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;coc_lua/?.lua;coc_lua/protocol/?.lua"

local socket = require "clientsocket"
local crypt = require "crypt"
local bit32 = require "bit32"

local protobuf = require "protobuf"
local p = require "p.core"
require "protocolcmd"
addr = io.open("./coc_lua/protocol/protocol.pb","rb")
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


local function writeline(fd, text)
	socket.send(fd, text .. "\n")
end
local function unpack_line(text)
	--print("unpack_line text=", text)
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end

local last = ""

local function unpack_f(f)
	local function try_recv(fd, last)
		local result
		result, last = f(last)
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
		return f(last .. r)
	end

	return function()
		while true do
			local result
			result, last = try_recv(fd, last)
			if result then
				return result
			end
			socket.usleep(100)
		end
	end
end

--[[
local readline = unpack_f(unpack_line)

local challenge = crypt.base64decode(readline())

local clientkey = crypt.randomkey()
writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)

print("sceret is ", crypt.hexencode(secret))

local hmac = crypt.hmac64(challenge, secret)
writeline(fd, crypt.base64encode(hmac))
]]
--type 0 ��½1 ע��
local token = { --��¼
	type = 0,
	server = "gameserver",
	user = "hello123s@163.com",
	pass = "123456",
}

local function encode_token(token)
	--[[
	return string.format("%s:%s@%s:%s",
		crypt.base64encode(token.type),
		crypt.base64encode(token.user),
		crypt.base64encode(token.server),
		crypt.base64encode(token.pass))
	]]	
	local str = string.format("%s:%s:%s:%s",token.type,token.user,token.server,token.pass)
	local type, user, server, password= str:match("(.+):([^:]+):([^:]+):(.+)")
	print(str)
	print( "rrrrrrrrrrrrrrrrrrrrrrrrrrrrr", type,user,server,password)
	return string.format("%s:%s:%s:%s",token.type,token.user,token.server,token.pass)	
end

--[[
local etoken = crypt.desencode(secret, encode_token(token))
local b = crypt.base64encode(etoken)
writeline(fd, crypt.base64encode(etoken))
]]

--[[
writeline(fd, encode_token(token))
--writeline(fd, "0:hello123@163.com:gameserver:123456")
local readline = unpack_f(unpack_line)
local result = readline()
print(result)
local code = tonumber(string.sub(result, 1, 3))
assert(code == 200)
--writeline(fd, "test~~~~~")
socket.close(fd)

--local subid = crypt.base64decode(string.sub(result, 5))
local subid = string.sub(result, 5)

print("~~~login ok, subid=", subid)
]]
-------connect gameserver------------
local fd = assert(socket.connect("192.168.2.250", 8001))
print(fd)
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
	if data.p == PCMD_CREATEROLE_RSP then
		t = protobuf.decode("PROTOCOL.create_role_rsp", string.sub(v, 7))
	elseif data.p == PCMD_LOADROLE_RSP then
		t = protobuf.decode("PROTOCOL.load_role_rsp", string.sub(v, 7))
	elseif data.p == PCMD_BUILDACTION_RSP then
		t = protobuf.decode("PROTOCOL.buildaction_rsp", string.sub(v, 7))
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

--local readpackage = unpack_f(unpack_package)

--[[
local index = 1
local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)
]]
--[[
local index = 1
local handshake = string.format("%s:%s:%s:%s:%s", token.user, token.server, token.pass, subid, index)
print(handshake)

--send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))
send_package(fd, handshake)

local result = readpackage()
print(result)
assert(result == "200")

]]
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
	[8] = {type = 0, servername = gameserver, user = "hello123s@163.com", pass = "123456"},
}

--[[
print_r(req[7])

local buffer = protobuf.encode("PROTOCOL.create_role_rsp", req[7])

local t = protobuf.decode("PROTOCOL.create_role_rsp", buffer)
]]

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
	send_package(fd, p.pack(1,PCMD_LOGIN_REQ,buffer))
else
	buffer = protobuf.encode("PROTOCOL.buildaction_req", req[itype])
	send_package(fd, p.pack(1,PCMD_BUILDACTION_REQ,buffer))
end

while true do
	dispatch_package()
  	local cmd = socket.readstdin()
  	if cmd then
  		--send_request("build_action", action[2])
  		--send_request("get", { what = cmd })
  		--send_request("set", { what = "hello", value = "world" })
  	else
  		--send_request("heartbeat")
  		--socket.usleep(5000000)
  		--socket.usleep(100)
  	end
  end

