package.path = "./my_examples/?.lua;" .. package.path
local login = require "snax.loginserver"
local crypt = require "crypt"
local skynet = require "skynet"
--local logger = require "log"

local server = {
	host = "127.0.0.1",
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

	--[[
	-- the token is base64(user)@base64(server):base64(password)
	local id
	local type, user, server, password= token:match("(.+):([^@]+)@([^:]+):(.+)")
	type = crypt.base64decode(type)
	user = crypt.base64decode(user)
	server = crypt.base64decode(server)
	password = crypt.base64decode(password)
	print( "rrrrrrrrrrrrrrrrrrrrrrrrrrrrr", type,user,server,password)
	if tonumber(type) == 0 then --µÇÂ¼
		local r, _id = auth_from_db(user, password)	
		id = _id
		assert(r == 0, "user Auth failed r = "..r)
	else --×¢²á
		local r, _id = register_to_db(user, password)	
		id = _id
		assert(r == 0, "user register failed r = "..r)
	end
	return server, user, id
	]]

	local id
	local type, user, server, password= token:match("(.+):([^@]+)@([^:]+):(.+)")
	print(token)
	print( "rrrrrrrrrrrrrrrrrrrrrrrrrrrrr", type,user,server,password)
	if tonumber(type) == 0 then --µÇÂ¼
		local r, _id = auth_from_db(user, password)	
		id = _id
		assert(r == 0, "user Auth failed r = "..r)
	else --×¢²á
		local r, _id = register_to_db(user, password)	
		id = _id
		assert(r == 0, "user register failed r = "..r)
	end
	return server, user, id
	
end

function server.login_handler(server, uid, secret, id)
	print(string.format("%s@%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
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
