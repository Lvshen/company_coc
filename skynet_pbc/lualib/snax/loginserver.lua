package.path = "./coc_lua/protocol/?.lua;" .. package.path

local skynet = require "skynet"
local socket = require "socket"
local netpack = require "netpack"

local p = require "p.core"
local protobuf = require "protobuf"
require "protocolcmd"

addr = io.open("./coc_lua/protocol/protocol.pb","rb")
buffer = addr:read "*a"
addr:close()
protobuf.register(buffer)

local table = table
local string = string
local assert = assert

local socket_error = {}
local function assert_socket(v, fd)
	if v then
		return v
	else
		skynet.error(string.format("auth failed: socket (fd = %d) closed", fd))
		error(socket_error)
	end
end

local function write(fd, text)
	assert_socket(socket.write(fd, text), fd)
end

local function launch_slave(auth_handler)
	local function auth(fd, addr)
		fd = assert(tonumber(fd))
		skynet.error(string.format("connect from %s (fd = %d)", addr, fd))
		socket.start(fd)

		-- set socket buffer limit (8K)
		-- If the attacker send large package, close the socket
		socket.limit(fd, 8192)
		local line = assert_socket(socket.readall(fd),fd)
		skynet.error("Recive Data: ", line, #line)
		local msg = netpack.tostring(line, #line)
		local data = p.unpack(msg)
		skynet.error("receive ok "..data.v.." "..data.p)
		if data.p ~= PCMD_LOGIN_REQ then
			skynet.error("Data Cmd error: ", data.p)	
			error("clinet request error")
		end
		local token , l_error = protobuf.decode("PROTOCOL.login_req", string.sub(msg, 7))
		if token == false then
			skynet.error("login_req decode error : "..l_error)
			return
		end
		local ok, server, uid, secret, id =  pcall(auth_handler,token)
		socket.abandon(fd)
		return ok, server, uid, secret, id
	end

	local function ret_pack(ok, err, ...)
		if ok then
			skynet.ret(skynet.pack(err, ...))
		elseif err ~= socket_error then
			error(err)
		end
	end

	skynet.dispatch("lua", function(_,_,...)
		ret_pack(pcall(auth, ...))
	end)
end

local user_login = {}

local function accept(conf, s, fd, addr)
	-- call slave auth
	local ok, server, uid, secret, id = skynet.call(s, "lua",  fd, addr)
	socket.start(fd)

	if not ok then
		write(fd, "401\n")
		error(server)
	end

	if not conf.multilogin then
		if user_login[uid] then
			write(fd, "406\n")
			error(string.format("User %s is already login", uid))
		end

		user_login[uid] = true
	end

	local ok, err = pcall(conf.login_handler, server, uid, secret, id)
	-- unlock login
	user_login[uid] = nil

	if ok then
		err = err or ""
		--print("err = ^^^^^^", err)
		--write(fd,  "200 "..crypt.base64encode(err).."\n")
		write(fd,  "200 "..err.."\n")
	else
		write(fd,  "403\n")
		error(err)
	end
end

local function launch_master(conf)
	local instance = conf.instance or 8
	assert(instance > 0)
	local host = conf.host or "0.0.0.0"
	local port = assert(tonumber(conf.port))
	local slave = {}
	local balance = 1

	skynet.dispatch("lua", function(_,source,command, ...)
		skynet.ret(skynet.pack(conf.command_handler(command, ...)))
	end)

	for i=1,instance do
		table.insert(slave, skynet.newservice(SERVICE_NAME))
	end

	skynet.error(string.format("login server listen at : %s %d", host, port))
	local id = socket.listen(host, port)
	socket.start(id , function(fd, addr)
		local s = slave[balance]
		balance = balance + 1
		if balance > #slave then
			balance = 1
		end
		local ok, err = pcall(accept, conf, s, fd, addr)
		if not ok then
			if err ~= socket_error then
				skynet.error(string.format("invalid client (fd = %d) error = %s", fd, err))
			end
		end
		socket.close(fd)
	end)
end

local function login(conf)
	local name = "." .. (conf.name or "login")
	skynet.start(function()
		local loginmaster = skynet.localname(name)
		if loginmaster then
			local auth_handler = assert(conf.auth_handler)
			launch_master = nil
			conf = nil
			launch_slave(auth_handler)
		else
			launch_slave = nil
			conf.auth_handler = nil
			assert(conf.login_handler)
			assert(conf.command_handler)
			skynet.register(name)
			launch_master(conf)
		end
	end)
end

return login
