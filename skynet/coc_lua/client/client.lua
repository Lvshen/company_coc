package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;coc_lua/?.lua;coc_lua/protocol/?.lua"

local socket = require "clientsocket"
local crypt = require "crypt"
local bit32 = require "bit32"
local proto = require "proto"
local sproto = require "sproto"
--local skynet = require "skynet"

local print = print
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local type = type
local pairs = pairs
local tostring = tostring
local next = next

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))


local fd = assert(socket.connect("127.0.0.1", 8001))

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

local readline = unpack_f(unpack_line)

local challenge = crypt.base64decode(readline())

local clientkey = crypt.randomkey()
writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)

print("sceret is ", crypt.hexencode(secret))

local hmac = crypt.hmac64(challenge, secret)
writeline(fd, crypt.base64encode(hmac))

--type 0 µÇÂ½1 ×¢²á
local token = { --µÇÂ¼
	type = 0,
	server = "gameserver",
	user = "hello123@163.com",
	pass = "123456",
}

local function encode_token(token)
	return string.format("%s:%s@%s:%s",
		crypt.base64encode(token.type),
		crypt.base64encode(token.user),
		crypt.base64encode(token.server),
		crypt.base64encode(token.pass))
		
end

local etoken = crypt.desencode(secret, encode_token(token))
local b = crypt.base64encode(etoken)
writeline(fd, crypt.base64encode(etoken))

local result = readline()
print(result)
local code = tonumber(string.sub(result, 1, 3))
assert(code == 200)
--writeline(fd, "test~~~~~")
socket.close(fd)

local subid = crypt.base64decode(string.sub(result, 5))

print("~~~login ok, subid=", subid)

-------connect gameserver------------
local fd = assert(socket.connect("127.0.0.1", 8888))

local function send_package(fd, pack)
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack

	socket.send(fd, package)
	print(package)
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

local session = 0

local function send_request(name, args)
	session = session + 1
	local str = request(name, args, session)
	send_package(fd, str)
	print("Request:", session, str)
end

local last = ""

local function print_request(name, args)
	print("REQUEST", name)
	if args then
		print_r(args)
	--[[
		for k,v in pairs(args) do
			print(k,v)	
		end
	]]
	end
end

local function print_response(session, args)
	print("RESPONSE", session)
	if args then
		print_r(args)
	--[[
		for k,v in pairs(args) do
			print(k, v)
		end
	]]
	end
end

local function print_package(t, ...)
	--print("~~~~~~~~~", ...)
	if t == "REQUEST" then
		print_request(...)
	else
		assert(t == "RESPONSE")
		print_response(...)
	end
end

local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end
		print_package(host:dispatch(v))
	end
end

local readpackage = unpack_f(unpack_package)

local index = 1
local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

local result = readpackage()
print(result)
assert(result == "200 OK")
--send_request("handshake", { hmac = handshake .. ":" .. crypt.base64encode(hmac) })
--send_request("handshake", { hmac = "asdf" })



send_request("load_role")
--send_request("create_role", {name = "dh"})
local action = {
		[0] = {type = 0, upgrade = {id = 103, index = 5}},
		[1] = {type = 1, place = {id = 103, x = 20, y = 30}},
		[2] = {type = 2, collect = {id = 103, index = 5}},
		[3] = {type = 3, move = {id = 103, index = 5, x = 10, y = 55}}
}

send_request("build_action", action[2])
--send_request("build_action", action[3])
while true do
	dispatch_package()
  	local cmd = socket.readstdin()
  	if cmd then
  		send_request("build_action", action[2])
  		--send_request("get", { what = cmd })
  		--send_request("set", { what = "hello", value = "world" })
  	else
  		--send_request("heartbeat")
  		--socket.usleep(5000000)
  		--socket.usleep(100)
  	end
  end

