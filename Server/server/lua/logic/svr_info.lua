local kc = require "kyotocabinet"
local db = kc.DB:new()

local gmail_guid = 1
local gmail_list = {}
local total_register = 0



--银两
local YinLiang = 191010001
--花雕
local HuaDiao = 191020214
--女儿红
local NvErHong = 191020213
--玄铁
local XuanTie = 193010004
--进阶丹
local JinJieDan = 193010005
--修炼丹
local XiuLianDan = 191010024
--龙力丹
local LongLiDan = 192010009
--初级秘籍
local ChuJiMiJi = 194803800
--中级秘籍
local ZhongJiMiJi = 194803900
--高级秘籍
local GaoJiMiJi = 194804000
--元宝
local YuanBao = 191010003
--金钥匙
local JinYaoShi = 190110001

local XiuLianDan = 191010024
--试武玉
local ShiWuYu = 191010031
--兵器谱碎片
local SP_BQP = 191010032
--兵器护符
local BQHuFu = 191010033
--紫心破障丹
local ZiXinPoZhangDan = 193010010

--燕南天碎片
local SP_YanNanTian = 190050017
--江小鱼碎片
local SP_JiangXiaoYu = 190050006
--花无缺碎片
local SP_HuaWuQue = 190050007
--石观音碎片
local SP_ShiGuanYin = 190050036
--谢晓峰碎片
local SP_XieXiaoFeng = 190050038
--丁鹏碎片
local SP_DingPeng = 190050041
--沈浪碎片
local SP_ShenLang= 190050011
--柴玉关碎片
local SP_ChaiYuGuan= 190050016
--荆无命碎片
local SP_JingWuMin = 190040010
--逍遥侯碎片
local SP_XiaoYaoHou = 190040022


local cdk_reward_list = {}
if server_platform == 1 then
--台湾的CDKEY数据库
	--50元寶、玄鐵 x 10、進階丹 x 10、花雕 x 1
	local reward_bag_1 = { 
			YuanBao, 50,
			XuanTie, 10,
			JinJieDan, 10,
			HuaDiao, 1
		}
	--玄鐵 x 5、進階丹 x 5、花雕 x 1、5萬銅幣
	local reward_bag_2 = {
		XuanTie, 5,
		JinJieDan, 5,
		HuaDiao, 1,
		YinLiang, 50000
	}
	--100元寶、玄鐵 x 10、進階丹 x 10、女兒紅 x 1
	local reward_bag_3 = {
		YuanBao, 100,
		XuanTie, 10,
		JinJieDan, 10,
		NvErHong, 1
	}
	--100元寶
	local reward_bag_4 = {
		YuanBao, 100
	}
	--進階丹 x 5、龍力丹 x 5、女兒紅 x1 、5萬銅幣
	local reward_bag_5 = {
		JinJieDan, 5,
		LongLiDan, 5,
		NvErHong, 1,
		YinLiang, 50000
	}
	--50元寶、玄鐵 x 5、進階丹 x 5、花雕 x 1
	local reward_bag_6 = { 
			YuanBao, 50,
			XuanTie, 5,
			JinJieDan, 5,
			HuaDiao, 1
		}
	--100元寶、中級經驗秘笈x1、女兒紅 x 1
	local reward_bag_7 = { 
			YuanBao, 100,
			ZhongJiMiJi, 1,
			NvErHong, 1
		}
	--100元寶、女兒紅 x 2、10萬銀兩
	local reward_bag_8 = { 
			YuanBao, 100,
			NvErHong, 2,
			YinLiang, 100000
		}
	cdk_reward_list = {
		--奖励ID1
		[1] = reward_bag_1,
		[2] = reward_bag_2,
		[3] = reward_bag_2,
		[4] = reward_bag_2,
		[5] = reward_bag_3,
		[6] = {SP_YanNanTian, 80},
		[7] = reward_bag_4,
		[8] = reward_bag_4,
		[9] = reward_bag_4,
		[10] = reward_bag_4,
		[11] = reward_bag_4,
		[12] = reward_bag_2,
		[13] = reward_bag_2,
		[14] = reward_bag_3,
		[15] = reward_bag_3,
		[16] = reward_bag_5,
		[17] = reward_bag_5,
		[18] = reward_bag_5,
		[19] = reward_bag_5,
		[20] = reward_bag_3,
		[21] = reward_bag_6,
		[22] = reward_bag_6,
		[23] = reward_bag_6,
		[24] = {JinYaoShi, 2, NvErHong, 1},
		[25] = {ZhongJiMiJi, 1, JinYaoShi, 2},
		[26] = {LongLiDan, 2, NvErHong, 1},
		[27] = reward_bag_7,
		[28] = reward_bag_8,
		[29] = {YuanBao, 50, XuanTie, 100},
		[30] = {YuanBao, 50, JinJieDan, 100},
		[31] = {YuanBao, 50, XiuLianDan, 100},
		[32] = {YuanBao, 200, GaoJiMiJi, 2, YinLiang, 2000000},
		
	}
else
--大陆的CDKEY数据库
	cdk_reward_list = {

	[1] = {193010004,5,191010001,50000},
	[2] = {192010009,5,191010001,50000},
	[3] = {191010008,10,191010001,50000},
	[4] = {191010008,10,193010005,5},
	[5] = {192010009,5,193010004,5},
	[6] = {193010010,1,193010005,5},
	[7] = {193010005,5,193010004,5},
	[8] = {193010005,10,191010001,50000},
	[9] = {191010003,50,191010001,50000},
	[10] = {193010010,1,191010001,50000},
	[11] = {191010001, 100000, 193010005, 10, 193010004, 10},
	[12] = {191010001, 50000, 193010005, 20, 193010004, 20},
	[13] = {191010001, 200000, 193010005, 20, 193010004, 20},
	[14] = {193010005, 30, 193010004, 30},
	[15] = {193010005, 50},
	[16] = {193010005, 100},
	[17] = {191020214, 1,191010001,50000},
	[18] = {190040022, 80},
	[19] = {191010003, 2000},
	[20] = {191010001, 100000, 193010005, 12, 193010004, 12},
	[21] = {191010001, 250000, 193010005, 20, 193010004, 20},
	[22] = {191010001, 500000, 193010005, 50, 193010004, 50},
	[23] = {191010001, 50000, 191020214, 1, 193010004, 10, 191010215, 20},
	[24] = {191010001, 50000, 193010005, 10, 193010004, 10},
	[25] = {192010009, 10, 193010004, 10, 191010001, 50000},
	[26] = {191010008, 5, 193010004, 5, 191010001, 50000},
	[27] = {191010001, 50000, 193010004, 10, 191010215, 10},
	[28] = {192010009, 10, 193010004, 10, 191010215, 10},
	[29] = {191010008, 5, 193010004, 10, 191010215, 20},
	[30] = {191010001, 50000, 191010008, 5, 193010005, 5},
	[31] = {191010001, 100000, 193010005, 10, 193010004, 10},
	[32] = {191010001, 100000, 193010005, 10, 193010004, 10},
	[33] = {191010001, 100000, 193010005, 10, 193010004, 10},
	[34] = {191010001, 100000, 193010005, 10, 193010004, 10},
	[35] = {191010001, 100000, 193010005, 10, 193010004, 10},
	[36] = {191010001, 100000, 193010005, 10, 193010004, 10},
	[37] = {191010001, 100000, 193010005, 10, 193010004, 10},
	[38] = {191010001, 50000, 191020214, 1, 193010005, 20},
	[39] = {191010001, 100000, 191020214, 2, 193010005, 40},
	[40] = {191010001, 200000, 191020214, 4, 193010005, 100},
	[41] = {191010001, 100000, 191020214, 2, 193010005, 50},
	[42] = {191010001, 100000, 191020214, 3, 193010005, 50},
	[43] = {191010001, 100000, 191020214, 4, 193010005, 50},
	[44] = {191010001, 100000, 191020214, 2, 193010004, 50},
	[45] = {191010001, 100000, 191020214, 3, 193010004, 50},
	[46] = {191010003, 100, 191020214, 3, 193010005, 30},
	[47] = {191010001, 700000, 193010005, 70, 193010004, 70, 191020214, 10},
	[48] = {YinLiang, 100000, HuaDiao, 2, ChuJiMiJi, 1},
	[49] = {JinJieDan, 15, XuanTie, 15, YinLiang, 50000},
	[50] = {YinLiang, 250000, HuaDiao, 2, ChuJiMiJi, 3},
	[51] = {YinLiang, 500000, HuaDiao, 2, ChuJiMiJi, 2},
	[52] = {YinLiang, 250000, JinJieDan, 10, XuanTie, 10},
	[53] = {YinLiang, 250000, JinJieDan, 35, ChuJiMiJi, 2},
	[54] = {YinLiang, 250000, XuanTie, 35, ChuJiMiJi, 2},
	[55] = {YinLiang, 50000},
	[56] = {JinJieDan, 10, XuanTie, 10, HuaDiao, 2},
	[57] = {XiuLianDan, 50, YinLiang, 100000, YuanBao, 50},
	[58] = {JinJieDan, 50, XuanTie, 50, YinLiang, 250000, YuanBao, 200},
	[59] = {XiuLianDan, 120, SP_JiangXiaoYu, 5},
	[60] = {ZhongJiMiJi, 4, YuanBao, 500, HuaDiao, 4},
	[61] = {JinJieDan, 150, XuanTie, 150, SP_JiangXiaoYu, 25},
	[62] = {XiuLianDan, 300, ZhongJiMiJi, 1, GaoJiMiJi, 1, HuaDiao, 10},
	[63] = {YinLiang, 50000, XiuLianDan, 10, JinJieDan, 10},
	[64] = {YinLiang, 100000, XiuLianDan, 50},
	[65] = {HuaDiao, 2, XuanTie, 100},
	[66] = {HuaDiao, 2, JinJieDan, 50},
	[67] = {YinLiang, 200000, ChuJiMiJi, 2},
	[68] = {YinLiang, 100000, HuaDiao, 2, JinJieDan, 25},
	[69] = {YinLiang, 200000, HuaDiao, 3, JinJieDan, 50},
	[70] = {YinLiang, 250000, HuaDiao, 3, ShiWuYu, 50},
	[71] = {YinLiang, 100000, HuaDiao, 3, SP_BQP, 50},
	[72] = {YinLiang, 100000, HuaDiao, 2, BQHuFu, 50},
	[73] = {JinJieDan, 100, XuanTie, 100},
	[74] = {HuaDiao, 2, SP_BQP, 10, BQHuFu,10},
	[75] = {ZiXinPoZhangDan, 2, YinLiang, 50000},
}

end

if not db:open("svr_info.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
	error("svr_info.lua open err")
else
	if db:count() == 0 then
		db:set("gmail_guid", 1)
	end
	db:iterate(
		function(k,v)
			if k == "gmail_guid" then gmail_guid = tonumber(v)
			elseif k == "reg" then total_register = tonumber(v)
			elseif k == "gmail_list" then
				local pb = require "protobuf"
				local t_list = pb.decode("MailList", v)
				gmail_list = rawget(t_list, "mail_list")
				if not gmail_list then
					gmail_list = {}
				end
			elseif k == "cdkey_reward" then
				local pb = require "protobuf"
				local t_list = pb.decode("cdkey_reward_list", v)
				cdk_reward_list = {}
				for k,v in ipairs(t_list) do
					local idx = v.reward_id
					local items = v.item_list
					table.insert(cdk_reward_list, idx, items)
				end
			end
		end, false
	)
end

local function get_gmail_list()
	return gmail_list
end

local function add_gmail(mail)

	if mail.reg_time == nil then mail.reg_time = 0 end
	if mail.vip_limit == nil then mail.vip_limit = 0 end
	if mail.lev_limit == nil then mail.lev_limit = 0 end
	mail.tid = gmail_guid
	gmail_guid = gmail_guid + 1
	if mail.buchang and mail.buchang == 1 then
		mail.buchang = 1
	else
		mail.buchang = 0
	end
	table.insert(gmail_list, mail)
	db:set("gmail_guid", gmail_guid)
	local pb = require "protobuf"
	local t = pb.encode("MailList", {mail_list = gmail_list})
	db:set("gmail_list", t)

	return gmail_list
end

local function check_gmail()
	local t = os.time()
	local need_del = {}
	for k,v in ipairs(gmail_list) do
		if v.expiry_stamp < t and v.expiry_stamp > 0 then
			--printtab(v, "need del")
			table.insert(need_del, k)
		end
	end
	local l = rawlen(need_del)
	if l > 0 then
		for k = l, 1, -1 do
			table.remove(gmail_list, need_del[k])
		end
		local pb = require "protobuf"
		local t = pb.encode("MailList", {mail_list = gmail_list})
		db:set("gmail_list", t)
	end
end

local function get_cdk_reward(id)
	return rawget(cdk_reward_list, id)
end

local function add_cdkey_reward(idx, rewards)
	local k = 1
	while rewards[k] do
		local t = Item_conf[rewards[k]]
		assert(t)
		k = k + 2
	end
	rewset(cdk_reward_list, idx, rewards)
	
	local t_list = {}
	for k,v in pairs(cdk_reward_list) do
		table.insert(t_list, {reward_id = k, item_list = v})
	end
	local pb = require "protobuf"
	local t = pb.encode("cdkey_reward_list", {reward_list = t_list})
	db:set("cdkey_reward", t)
end

local function get_reg()
	return total_register
end

local function new_reg()
	total_register = total_register + 1
	db:set("reg", total_register)
end

local svr_info = {
	get_gmail_list = get_gmail_list,
	add_gmail = add_gmail,
	check_gmail = check_gmail,
	get_cdk_reward = get_cdk_reward,
	add_cdkey_reward = add_cdkey_reward,
	get_reg = get_reg,
	new_reg = new_reg,
}

--printtab(gmail_list, "info gmail_list")
return svr_info