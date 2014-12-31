
package.path = "./coc/protocol/?.lua;" .. package.path

local skynet = require "skynet"
local socket = require "clientsocket"
local p = require "p.core"
require "protocolcmd"


local protobuf
local fd
local robot = { }


local function send_package(fd, pack)
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack
	socket.send(fd, package)
end

local function percent(max)
	local i = math.random(1, max)
	if i == 1 then return true end
end

function robot:create(name, password)
	local o = { name = name, password = password }
	self.__index = self
	setmetatable(o, self)
	return o
end

function robot:connect()
	local fd = socket.connect("192.168.1.251", 8888)
	return fd
end

function robot:register()
	local t = {type = 1, servername = "gameserver", user = self.name, pass = self.password}
	local buffer = protobuf.encode("PROTOCOL.login_req", t )
	send_package(self.fd, p.pack(1,PCMD_LOGIN_REQ,buffer))
end

function robot:login_request()
	local t = {type = 0, servername = "gameserver", user = self.name, pass = self.password}
	local buffer = protobuf.encode("PROTOCOL.login_req", t )
	send_package(self.fd, p.pack(1,PCMD_LOGIN_REQ,buffer))
end

function robot:logout_request()
end

function robot:start()
	self.state = "idle"
	local fd = self:connect()
	if fd < 0 then
		skynet.error(string.format("robot % connect failed!", self.name))
		return
	end
	self.fd = fd
	self:login_request()
	skynet.fork(function()
		while true do
			dispatch_package(fd)
			skynet.sleep(100)
		end
	end)
end

function robot:get_roleinfo(t)
	self.roleinfo = t
	skynet.error(skynet.print_r(t))
end

function robot:create_role()
	local t = {name = self.name}
	local buffer = protobuf.encode("PROTOCOL.create_role_req", t )
	send_package(self.fd, p.pack(1,PCMD_CREATEROLE_REQ,buffer))
end

function robot:load_role()
	send_package(self.fd, p.pack(1,PCMD_LOADROLE_REQ,""))
end

-- ################ robot management ################
local manager = { }

local function get_robot(self, userid)
	for _, onerobot in ipairs(self.robots) do
		if onerobot.userid == userid then
			return onerobot
		end
	end
end

local function get_robot_fd(self, fd)
	for _, onerobot in ipairs(self.robots) do
		if onerobot.fd == fd then
			return onerobot
		end
	end
end

-- ############## message notify from room / user_manager ##############
function manager:startplay_notify(session, room, cards, bigid, smallid, tobet, playmates, userid)
	local onerobot = get_robot(self, userid)
	assert(onerobot, string.format("robot with userid %d not found", userid))
	onerobot:new_game_play(playmates)

	robot_action(userid, tobet)
end

function manager:fold_notify(session, room, playerid, tobet, userid)
	assert(playerid ~= userid)
	robot_action(userid, tobet)
end

function manager:bet_notify(session, room, playerid, money, tobet, userid)
	assert(playerid ~= userid)
	local onerobot = get_robot(self, userid)
	onerobot:someone_bet(money, playerid)

	robot_action(userid, tobet)
end

-- notify { turnid, cards, next-to-bet }
function manager:turnover_notify(session, room, turnid, cards, tobet, userid)
	robot_action(userid, tobet)
end

-- notify => winners { playerid = money, ... }
function manager:gameover_notify(session, room, winners, money_left, userid)
	local onerobot = get_robot(self, userid)
	assert(onerobot)
	onerobot.money = money_left

	-- ? todo => if money < room.max_big_bind_money, then quit the room and reset money
	if onerobot.money < onerobot.room.roominfo.bb then
		onerobot.money = 1000
		onerobot:leave_room_request()
	end
end

-- ################ robot receive package ###################

local last = ""

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

local function recv_package(last, fd)
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

local function un_package(v, fd)
	local data = p.unpack(v)
	if data == nil then
		--skynet.error("error~~~~~")
		return
	end
	--skynet.error("v, p |", data.v, data.p)
	local onerobot = get_robot_fd(manager, fd)
	assert(onerobot, string.format("robot with userid %d not found", fd))
	--skynet.error("get robot name is ", onerobot.name)
	local t, l_error
	if data.p == PCMD_LOGIN_RSP then
		t, l_error= protobuf.decode("PROTOCOL.login_rsp", string.sub(v, 7))
		if t == false then
			skynet.error("login rsp decode error : ", l_error)
		elseif t.ret == 401 then 
			onerobot:register()
		elseif t.ret == 200 then
			onerobot:create_role()
		else
			skynet.error("login rsp ret:", t.ret)
		end
	elseif data.p == PCMD_CREATEROLE_RSP then
		t, l_error = protobuf.decode("PROTOCOL.create_role_rsp", string.sub(v, 7))
		if t == false then
			skynet.error("createrole rsp decode error : ", l_error)
		else
			onerobot:get_roleinfo(t.roleinfo)	
			onerobot:load_role()
		end
	elseif data.p == PCMD_LOADROLE_RSP then
		t, l_error = protobuf.decode("PROTOCOL.load_role_rsp", string.sub(v, 7))
		if t == false then
			skynet.error("loadrole rsp decode error : ", l_error)
		elseif t.result == 0 then
			onerobot:get_roleinfo(t.roleinfo)	
		elseif t.result == 1 then
			onerobot:create_role()
		else
			skynet.error("loadrole rsp result :", t.result)
		end
	elseif data.p == PCMD_BUILDACTION_RSP then
		t, l_error = protobuf.decode("PROTOCOL.buildaction_rsp", string.sub(v, 7))
	elseif data.p == PCMD_HEART then
		--skynet.error("Have Receive Heart fd:", fd)
		send_package(fd, p.pack(PCMD_HEAD, PCMD_HEART, ""))
		return
	end
	if t == false then
		skynet.error("error :", l_error)
	else
		for k,v in pairs(t) do
			if type(k) == "string" then
				if type(v) == "table" then
					skynet.error(skynet.print_r(v))
				else
					skynet.error(k,v)
				end
			end
		end
	end
end

function dispatch_package(fd)
	while true do
		local v
		v, last = recv_package(last, fd)
		if not v then
			break
		end
		un_package(v, fd)
	end
end

-- ################ robot launch ###################
local function genname()
	while true do
		local nameid = math.random(1, 100000)
		local name = "robot"..tostring(nameid).."@dh.com"
		for _, robot in ipairs(manager.robots) do
			if robot.name == name then
				name = nil
				break
			end
		end
		if name then return name end
	end
end

local function create_robots()
	local name = genname()
	local onerobot = robot:create(name, "123456")
	return onerobot
end

local function start_robot(roboti)
	skynet.error(string.format("## Begin start robot %d ##", roboti))

	local maxwait = 600
	local interval = math.random(100, maxwait) -- 1s ~ 60s (10ms as unit)
	skynet.timeout(100, function()
		local onerobot = manager.robots[roboti]
		onerobot:start()
		if roboti < #manager.robots then
			start_robot(roboti + 1)
		end
	end)
end

local function dump_robots()
	for i, onerobot in ipairs(manager.robots) do
		skynet.error(string.format("robot index %d, name %s", i, onerobot.name))
	end
end

local function launch_robots(robot_count)
	manager.robots = { }
	
	skynet.error("########### begin create robots ###########")

	for k = 1, robot_count do
		local onerobot = create_robots()
		table.insert(manager.robots, onerobot)
	end
	
	dump_robots()

	start_robot(1)
	
end


skynet.start(function()	
	skynet.dispatch("lua", function(session, from, cmd, ...)
		if not manager[cmd] then
			skynet.error(string.format("unknown inner command %s to robot manager!", tostring(cmd)))
			skynet.ret(skynet.pack())
			return
		end
		skynet.error(string.format("inner command %s to robot manager!", cmd))
		skynet.ret(skynet.pack(manager[cmd](manager, session, from, ...)))
	end)

	protobuf = require "protobuf"
	addr = io.open("./coc/protocol/protocol.pb","rb")
	buffer = addr:read "*a"
	addr:close()
	protobuf.register(buffer)
	
	math.randomseed(os.time())

	launch_robots(250)
	--[[
	skynet.fork(function()
		while true do
			for i, onerobot in pairs(manager.robots) do
				if onerobot.fd ~= nil then
					dispatch_package(onerobot.fd)
				end
			end
			skynet.sleep(100)
		end
	end)
	]]
end)


