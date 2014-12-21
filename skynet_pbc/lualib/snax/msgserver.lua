local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "netpack"
local socketdriver = require "socketdriver"
local assert = assert

local server = {}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local user_online = {}
local handshake = {}
local connection = {}

local function package(pack)
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack
	return package
end

function server.userid(username)
	-- base64(uid)@base64(server)#base64(subid)
	local uid, servername, subid = username:match "([^@]*)@([^#]*)#(.*)"
	return b64decode(uid), b64decode(subid), b64decode(servername)
end

function server.username(uid, subid, servername)
	--return string.format("%s@%s#%s", b64encode(uid), b64encode(servername), b64encode(tostring(subid)))
	return string.format("%s", uid)
end

function server.logout(username)
	local u = user_online[username]
	user_online[username] = nil
	if u.fd then
		gateserver.closeclient(u.fd)
		connection[u.fd] = nil
	end
end

function server.login(username, secret)
	assert(user_online[username] == nil)
	user_online[username] = {
		secret = secret,
		version = 0,
		index = 0,
		username = username,
		response = {},	-- response cache
	}
	skynet.error("**********"..skynet.print_r(user_online))
end

function server.ip(username)
	local u = user_online[username]
	if u and u.fd then
		return u.ip
	end
end

function server.start(conf)
	local expired_number = conf.expired_number or 128

	local handler = {}

	local CMD = {
		login = assert(conf.login_handler),
		logout = assert(conf.logout_handler),
		kick = assert(conf.kick_handler),
	}

	function handler.command(cmd, source, ...)
		local f = assert(CMD[cmd])
		return f(...)
	end

	function handler.open(source, gateconf)
		local servername = assert(gateconf.servername)
		return conf.register_handler(servername)
	end

	function handler.connect(fd, addr)
		handshake[fd] = addr
		gateserver.openclient(fd)
	end

	function handler.disconnect(fd)
		handshake[fd] = nil
		local c = connection[fd]
		if c then
			c.fd = nil
			connection[fd] = nil
			if conf.disconnect_handler then
				conf.disconnect_handler(c.username)
			end
		end
	end

	handler.error = handler.disconnect

	-- atomic , no yield
	local function do_auth(fd, message, addr)
	--[[
		local username, index, hmac = string.match(message, "([^:]*):([^:]*):([^:]*)")
		local u = user_online[username]
		if u == nil then
			return "404 User Not Found"
		end
		local idx = assert(tonumber(index))
		hmac = b64decode(hmac)

		if idx <= u.version then
			return "403 Index Expired"
		end

		local text = string.format("%s:%s", username, index)
		local v = crypt.hmac64(crypt.hashkey(text), u.secret)
		if v ~= hmac then
			return "401 Unauthorized"
		end
	]]
		local username, server, secret, subid, index = string.match(message, "([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")
		print(message,username, server, secret, subid, index)
		local u = user_online[username]
		if u == nil then
			return "404"
		end
		skynet.error(skynet.print_r(u))
		if secret ~= u.secret then
			return "401"
		end
		u.version = idx
		u.fd = fd
		u.ip = addr
		connection[fd] = u
	end

	local function auth(fd, addr, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, result = pcall(do_auth, fd, message, addr)
		if not ok then
			skynet.error(result)
			result = "400"
		end

		local close = result ~= nil

		if result == nil then
			result = "200"
		end

		socketdriver.send(fd, netpack.pack(result))

		--call agent
		if result ==  "200" then
			local u = assert(connection[fd], "invalid fd")
			local ok = pcall(conf.agent_handler, u.username, fd)
			assert(ok, "auth ok call agent failed")
		end

		if close then
			gateserver.closeclient(fd)
		end
	end

	local request_handler = assert(conf.request_handler)

	local function retire_response(u)
		if u.index >= expired_number * 2 then
			local max = 0
			local response = u.response
			for k,p in pairs(response) do
				if p[1] == nil then
					-- request complete, check expired
					if p[4] < expired_number then
						response[k] = nil
					else
						p[4] = p[4] - expired_number
						if p[4] > max then
							max = p[4]
						end
					end
				end
			end
			u.index = max + 1
		end
	end

	local function do_request(fd, msg, sz)
		local u = assert(connection[fd], "invalid fd")
		local msg_sz = sz - 4
		local session = netpack.tostring(msg, sz, msg_sz)
		local p = u.response[session]
		if p then
			-- session can be reuse in the same connection
			if p[3] == u.version then
				local last = u.response[session]
				u.response[session] = nil
				p = nil
				if last[2] == nil then
					local error_msg = string.format("Conflict session %s", crypt.hexencode(session))
					skynet.error(error_msg)
					error(error_msg)
				end
			end
		end

		if p == nil then
			p = { fd }
			u.response[session] = p
			local ok, result = pcall(conf.request_handler, u.username, netpack.tostring(msg, sz), msg_sz)
			result = result or ""
			-- NOTICE: YIELD here, socket may close.
			if not ok then
				skynet.error(result)
				result = "\0" .. session
			else
				--result = result .. '\1' .. session
				--[[
				local size = #result
				result = string.char(bit32.extract(size,8,8)) ..
				string.char(bit32.extract(size,0,8))..
				result
				]]
				result = package(result)
			end

			--p[2] = netpack.pack_string(result)
			p[2] = result
			p[3] = u.version
			p[4] = u.index
		else
			netpack.tostring(msg, sz) -- request before, so free msg
			-- update version/index, change return fd.
			-- resend response.
			p[1] = fd
			p[3] = u.version
			p[4] = u.index
			if p[2] == nil then
				-- already request, but response is not ready
				return
			end
		end
		u.index = u.index + 1
		-- the return fd is p[1] (fd may change by multi request) check connect
		fd = p[1]
		if connection[fd] then
			socketdriver.send(fd, p[2])
		end
		p[1] = nil
		retire_response(u)
	end

	local function request(fd, msg, sz)
		local ok, err = pcall(do_request, fd, msg, sz)
		-- not atomic, may yield
		if not ok then
			skynet.error(string.format("Invalid package %s : %s", err, netpack.tostring(msg, sz)))
			if connection[fd] then
				gateserver.closeclient(fd)
			end
		end
	end
	
	function handler.message(fd, msg, sz)
		local addr = handshake[fd]
		if addr then
			auth(fd,addr,msg,sz)
			handshake[fd] = nil
		else
			request(fd, msg, sz)
		end
	end

	return gateserver.start(handler)
end

return server
