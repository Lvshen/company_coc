package.path = "./my_examples/?.lua;" .. package.path
local login = require "snax.loginserver"
local crypt = require "crypt"
local skynet = require "skynet"
--local logger = require "log"

local server = {
	host = "192.168.2.250",
	port = 8001,
	multilogin = false,	-- disallow multilogin
	name = "login_master",
}

local server_list = {}
local user_online = {}
local user_login = {}


local function auth_from_db(user, password)
	local r = r or 0
	local id = skynet.call("REDISDB", "lua", "UserIdFromEmail", user)
	if id == nil then
		r = 1 --user not exist
	else
		local pass = skynet.call("REDISDB", "lua", "UserPassFromId", id)
		if pass ~= password then
			r = 2  --password is error
		end
	end
	return r, id
end

local function register_to_db(user, password)
	local r = r or 0
	local id = skynet.call("REDISDB", "lua", "UserIdFromEmail", user)
	if id == nil then
		id = skynet.call("REDISDB", "lua", "WriteUserAccount", user, password)
	else
		r = 1 --user is existed
	end
	return r, id
end

function server.auth_handler(token)
	
	local id
	skynet.error(string.format("token  :%s %s %s %s", token.type,token.user,token.server,token.password))
	if tonumber(token.type) == 0 then 					--µÇÂ¼
		local r, _id = auth_from_db(token.user, token.password)	
		id = _id
		assert(r == 0, "user Auth failed r = "..r)
	elseif  tonumber(token.type) == 1 then			 	--×¢²á
		local r, _id = register_to_db(token.user, token.password)	
		id = _id
		assert(r == 0, "user register failed r = "..r)
	else
		skynet.error("type is invalid!")
		return
	end
	return server, user, password, id 
	
end

function server.login_handler(server, uid, secret, id)
	print(string.format("%s@%s is login, secret is %s", uid, server, secret))
	local gameserver = assert(server_list[server], "Unknown server")
	-- only one can login, because disallow multilogin
	local last = user_online[uid]
	if last then
		skynet.call(last.address, "lua", "kick", uid, last.subid)
	end
	if user_online[uid] then
		error(string.format("user %s is already online", uid))
	end
	local subid = tostring(skynet.call(gameserver, "lua", "login", uid, secret, id))
	user_online[uid] = { address = gameserver, subid = subid , server = server}
	--print("subid*********", subid)
	return subid
end

local CMD = {} 

function CMD.register_gate(server, address)
 	server_list[server] = address
end

function CMD.logout(uid, subid)
	local u = user_online[uid]
	if u then
		print(string.format("%s@%s is logout", uid, u.server))
		user_online[uid] = nil
	end
end

function server.command_handler(command, source, ...)
	local f = assert(CMD[command])
	return f(source, ...)
end
login(server)
