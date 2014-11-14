local sprotoparser = require "sprotoparser"

local proto = {} 

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

.build_info {
	id 0 : integer				
	level 1 : integer			
	index 2 : integer			
	x 3 : integer				
	y 4 : integer
}

.role_info {
	name 0 : string 			
	level 1 : integer 			
	exp 2 : integer 			
	points 3 : integer 			
	gem 4 : integer			
	goldcoin 5 : integer			
	max_goldcoin 6 : integer	
	water 7 : integer			
	max_water 8 : integer		
	build_count 9 : integer		
	build 10 : *build_info		
}

heartbeat 0 {
	response {
		ok 0 : integer
	}
}

create_role 1 {			
	request {
		name 0 : string 		
	}
	response {
		result 0 : integer
		roleinfo 1 : role_info
	}
}

load_role 2 {
	response {
		result 0 : integer
		roleinfo 1 : role_info
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
