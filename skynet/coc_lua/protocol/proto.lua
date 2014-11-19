local sprotoparser = require "sprotoparser"

local proto = {} 

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

#建筑信息
.build_info {
	id 0 : integer						#建筑ID				
	level 1 : integer					#建筑等级
	index 2 : integer					#建筑索引
	x 3 : integer						#建筑坐标
	y 4 : integer
}

#角色信息
.role_info {
	name 0 : string 					#角色/村庄名字
	level 1 : integer 					#等级
	exp 2 : integer 					#经验
	points 3 : integer 					#积分
	gem 4 : integer					#宝石
	goldcoin 5 : integer					#拥有的金币
	max_goldcoin 6 : integer			#最大可拥有金币量
	water 7 : integer					#圣水
	max_water 8 : integer				#最大可拥有圣水量
	build_count 9 : integer				#建筑数目(即为建筑索引计数)
	build 10 : *build_info				#建筑
}

heartbeat 0 {
	response {
		ok 0 : integer
	}
}

#创建角色/村庄
create_role 1 {			
	request {
		name 0 : string 				#角色/村庄名字
	}
	response {
		result 0 : integer
		roleinfo 1 : role_info
	}
}

#加载角色信息
load_role 2 {
	response {
		result 0 : integer
		roleinfo 1 : role_info
	}
}

#id(建筑id), index(建筑索引), x/y(建筑横纵坐标) 
#result(返回结果0 成功, 1 系统服务器错误, 2金币或圣水不足, 3建筑不存在, 4 建筑达到上限5 等级达到上限, 6 建筑正在建造中)
.buildaction {
	.upgrade_build {					#升级建筑
		id 0 : integer					
		index 1 : integer
	}
	.place_build {						#建造建筑
		id 0 : integer
		x 1 : integer
		y 2 : integer
	}
	.collect_resource {					#收集资源
		id 0 : integer
		index 1 : integer
	}
	.move_build {						#移动建筑
		id 0 : integer
		index 1 : integer
		x 2 : integer
		y 3 : integer
	}
	type 0 : integer					#0 升级建筑1 建造建筑 2 收集建筑3 移动建筑
	upgrade 1 : upgrade_build
	place 2 : place_build
	collect 3 : collect_resource
	move 4 : move_build
}

#请求与返回要求字段数目都非固定的
#建筑操作
build_action 3 {
	request buildaction
	response {
		result 0 : integer
		index 1 : integer
		value 2 : integer
	}
}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}

]]


return proto
