datablock={}
datablock["main_data"] = 1
datablock["user_info"] = 1
datablock["ship_list"] = 2
datablock["knight_bag"] = 2
datablock["item_package"] = 4
datablock["item_list"] = 4
datablock["mail_list"] = 8
datablock["create"] = 512   -- 门派创建时，因为会存在
datablock["lock"] = 1024
datablock["save"] = 2048
datablock["try"] = 4096     --在帮派中，这个标志允许取不到数据，但逻辑继续往下走而不是报错。用于门派查询和创建
datablock["groupid"] = 8192 --如果为true，则后一个参数为groupid。否则为user_name,从userinfo中获取groupid

datablock["group_main"] = 16384

refid = {}
refid["res"] = {3001, 4001, 5001, 6001} --资源ITEM ID
refid["money"] = 7001

GolbalDefine = {}

GolbalDefine.trial_init_ticket_num = 1

GolbalDefine.arena_init_challenge_times = 10

GolbalDefine.arena_init_score = 0

GolbalDefine.friends_max = 30

GolbalDefine.talk_max = 20

GolbalDefine.group_num_in_page = 6

GolbalDefine.group_join_max_today = 3

GolbalDefine.planet_mark_max = 10

GolbalDefine.enum_group_job = {
	leader = 1,
	manager = 2,
	member = 3,
}

GolbalDefine.group_manager_max = 3

GolbalDefine.collect_speed = 10