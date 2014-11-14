package.path = "./coc_lua/protocol/?.lua;" .. package.path

local skynet = require "skynet"
local socket = require "socket"
local sproto = require "sproto"
local proto = require "proto"


local host = sproto.new(proto.c2s):host "package"
local send_request = host:attach(sproto.new(proto.s2c))

local REQUEST = {}
local client_fd
local heartbeat_time

local uuid
local user_info

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:create_role()
	print("~~~~~~create_role id=", uuid, self.name)
	local r = skynet.call("REDISDB", "lua", "InitUserRole", uuid, self.name)
	return {result = 0, roleinfo = r}
end

function REQUEST:load_role()
	return {result = 0, roleinfo = user_info}
end

local function request(name, args, response)
	print("-------------requies["..name.."]", uuid)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		--return host:dispatch(msg, sz)
		print("agent register_protocol msg=", msg, type(msg))
		--print("----", host:dispatch(msg, sz))
		--return skynet.tostring(msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (_, _, type, name, ...)
		print(type, name, ...)
		if type == "REQUEST" then
			local ok, result  = pcall(request, name, ...)
			if ok then
				if result then
					skynet.ret(result)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}


local gate
local userid, subid

local CMD = {}

local function send_package(pack, fd)
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack

	socket.write(fd, package)
end

function CMD.login(source, uid, sid, secret, id)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
	userid = uid
	subid = sid
	uuid = id
	-- you may load user data from database
	user_info = skynet.call("REDISDB", "lua", "LoadRoleAllInfo", uuid)
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
	heartbeat_time = skynet.time()
	skynet.fork(function()
		while true do
			send_package(send_request "heartbeat", fd)
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
