package.path = "./coc_lua/protocol/?.lua;./coc_lua/build/?.lua;" .. package.path

local skynet = require "skynet"
local socket = require "socket"
local sproto = require "sproto"
local proto = require "proto"
local buildoperate = require "buildoperate"

local host = sproto.new(proto.c2s):host "package"
local send_request = host:attach(sproto.new(proto.s2c))

local REQUEST = {}
local client_fd
local heartbeat_time

local uuid
local role_info

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:create_role()
	print("~~~~~~create_role id=", uuid, self.name)
	if role_info.name ~= nil then
		return {result = 1}
	end
	local r = skynet.call("REDISDB", "lua", "InitUserRole", uuid, self.name)
	return {result = 0, roleinfo = r}
end

function REQUEST:load_role()
	if role_info.name == nil then
		return {result = 1, roleinfo = {}}
	end
	return {result = 0, roleinfo = role_info}  
end

function REQUEST:heartbeat()
	heartbeat_time = skynet.time()
	return {ok = 0}
end

function REQUEST:build_action()
	local result, index, changeinfo, value = buildoperate.build_operate(self, role_info)
	print("build_action response ~~", result, index, changeinfo, value )
	if result == 0 then
		UpdateRoleInfo(changeinfo)	
	end
	return {result = result, index = index, value = value}
end

local function request(name, args, response)
	print("-------------requies["..name.."]", uuid, args)
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

--update role_info
function UpdateRoleInfo(changed_info)
	--example : changed_info = {level = 1, ..., build = {{ id = 100, level = 1, index = 1,  x = 35, y = 20 },{...},...}}
	for k, v in pairs(changed_info) do
		if type(v) == "table" then
			if k == "build" then
				local t = role_info.build
				for _k, _v in pairs(v) do
					local index = _v.index
					t["index"] = _v
				end
			end
		else
			role_info[k] = v
		end
	end
	skynet.call("REDISDB", "lua", "UpdateRoleInfo", uuid, changed_info)
end

local gate
local userid, subid

local CMD = {}

local function send_package(fd, pack)
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack

	socket.write(fd, package)
end

local action = {
	["goldcoin"] = function(value) 
		role_info["goldcoin"] = role_info["goldcoin"] + value
	end,
}

function CMD.update(key, value)
	action[key] (value)
end

function CMD.login(source, uid, sid, secret, id)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
	userid = uid
	subid = sid
	uuid = id
	-- you may load user data from database
	role_info = skynet.call("REDISDB", "lua", "LoadRoleAllInfo", uuid)
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
	print("fd = ", fd, heartbeat_time)
	skynet.fork(function()
	while true do
		if (skynet.time() - heartbeat_time) > 60 then
			logout()
			break
		end
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
