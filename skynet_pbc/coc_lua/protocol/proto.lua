local sprotoparser = require "sprotoparser"

local proto = {} 

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

#������Ϣ
.build_info {
	id 0 : integer						#����ID				
	level 1 : integer					#�����ȼ�
	index 2 : integer					#��������
	x 3 : integer						#��������
	y 4 : integer
	finish 5 : integer					#�����������ɱ�־0δ��� 1���
	remain_time 6 : integer				#finish=0ʱ���������ʣ��ʱ��
	time_c_type 7 : integer				#finish=0ʱ�жϴ���ʲô״̬0���� 1���� 
}

#����
.army {
	id 0 : integer						#����id
	count 1 : integer					#������
	finish 2 : integer					#0δ��� 1���
	remain_time 3 : integer				#finish=0 ʱʣ��ʱ��
}

.army_info {
	index 0 : integer					#��������
	id 1 : integer						#����id
	sum_count 2 : integer				# (��ѡ)�ܱ�ռ�õ�λ= �����ֵ�λ* ���������� + ...
	armys 3 : *army
}

.army_lv {
	id 0 : integer
	level 1 : integer
}

#��ɫ��Ϣ
.role_info {
	name 0 : string 					#��ɫ/��ׯ����
	level 1 : integer 					#�ȼ�
	exp 2 : integer 					#����
	points 3 : integer 					#����
	gem 4 : integer					#��ʯ
	goldcoin 5 : integer					#ӵ�еĽ��
	max_goldcoin 6 : integer			#����ӵ�н����
	water 7 : integer					#ʥˮ
	max_water 8 : integer				#����ӵ��ʥˮ��
	build_count 9 : integer				#������Ŀ(��Ϊ������������)
	build 10 : *build_info				#����
	armys_info 11 : *army_info			#����
	armys_lv 12 : *army_lv			       #�����ֵȼ�
}

heartbeat 0 {
	response {
		ok 0 : integer
	}
}

#������ɫ/��ׯ
create_role 1 {			
	request {
		name 0 : string 				#��ɫ/��ׯ����
	}
	response {
		result 0 : integer				# 0 �ɹ� 1 ������
		roleinfo 1 : role_info
	}
}

#���ؽ�ɫ��Ϣ
load_role 2 {
	response {
		result 0 : integer    			#0 �ɹ� 1 �½�ɫ���Ͽ�
		roleinfo 1 : role_info
	}
}

#id(����id), index(��������), x/y(������������) 
#result(���ؽ��-1������� 0 �ɹ�, 1 ϵͳ����������, 2��һ�ʥˮ����, 3����������, 4 �����ﵽ����5 �ȼ��ﵽ����, 6 �������ڽ�����
#		7 ����ռ䲻��)
.buildaction {
	.upgrade_build {					#��������
		id 0 : integer					
		index 1 : integer
	}
	.place_build {						#���콨��
		id 0 : integer
		x 1 : integer
		y 2 : integer
	}
	.collect_resource {					#�ռ���Դ
		id 0 : integer
		index 1 : integer
	}
	.move_build {						#�ƶ�����
		id 0 : integer
		index 1 : integer
		x 2 : integer
		y 3 : integer
	}
	.produce_armys {
		id 0 : integer
		count 1 : integer
		build_id 2 : integer
		index 3 : integer
	}
	type 0 : integer					#0 ��������1 ���콨�� 2 �ռ�����3 �ƶ�����4 ���
	upgrade 1 : upgrade_build
	place 2 : place_build
	collect 3 : collect_resource
	move 4 : move_build
	produce 5 : produce_armys
}

#�����뷵��Ҫ���ֶ���Ŀ���ǹ̶���
#��������
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