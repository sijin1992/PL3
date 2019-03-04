GBoss_conf = {}
GBoss_conf["index"] = {}
GBoss_conf["index"][1] = 1
GBoss_conf[1] = {}
	GBoss_conf[1]["Index"] = 1
	GBoss_conf[1]["Name"] = 160005403
	GBoss_conf[1]["Stage_ID"] = 59990091
	GBoss_conf[1]["Kill_Reward"] = {}
		GBoss_conf[1]["Kill_Reward"][1] = 191010003
		GBoss_conf[1]["Kill_Reward"][2] = 100
	GBoss_conf[1]["Boss_Life"] = 83508600
	GBoss_conf[1]["real_idx"] = 1

GBoss_conf["index"][2] = 2
GBoss_conf[2] = {}
	GBoss_conf[2]["Index"] = 2
	GBoss_conf[2]["Name"] = 160005404
	GBoss_conf[2]["Stage_ID"] = 59990092
	GBoss_conf[2]["Kill_Reward"] = {}
		GBoss_conf[2]["Kill_Reward"][1] = 191010003
		GBoss_conf[2]["Kill_Reward"][2] = 100
	GBoss_conf[2]["Boss_Life"] = 108288600
	GBoss_conf[2]["real_idx"] = 2

GBoss_conf["index"][3] = 3
GBoss_conf[3] = {}
	GBoss_conf[3]["Index"] = 3
	GBoss_conf[3]["Name"] = 160005405
	GBoss_conf[3]["Stage_ID"] = 59990093
	GBoss_conf[3]["Kill_Reward"] = {}
		GBoss_conf[3]["Kill_Reward"][1] = 191010003
		GBoss_conf[3]["Kill_Reward"][2] = 100
	GBoss_conf[3]["Boss_Life"] = 140007000
	GBoss_conf[3]["real_idx"] = 3

GBoss_conf["index"][4] = 4
GBoss_conf[4] = {}
	GBoss_conf[4]["Index"] = 4
	GBoss_conf[4]["Name"] = 160005406
	GBoss_conf[4]["Stage_ID"] = 59990094
	GBoss_conf[4]["Kill_Reward"] = {}
		GBoss_conf[4]["Kill_Reward"][1] = 191010003
		GBoss_conf[4]["Kill_Reward"][2] = 100
	GBoss_conf[4]["Boss_Life"] = 214347000
	GBoss_conf[4]["real_idx"] = 4

GBoss_conf["index"][5] = 5
GBoss_conf[5] = {}
	GBoss_conf[5]["Index"] = 5
	GBoss_conf[5]["Name"] = 160005407
	GBoss_conf[5]["Stage_ID"] = 59990095
	GBoss_conf[5]["Kill_Reward"] = {}
		GBoss_conf[5]["Kill_Reward"][1] = 191010003
		GBoss_conf[5]["Kill_Reward"][2] = 100
	GBoss_conf[5]["Boss_Life"] = 290669400
	GBoss_conf[5]["real_idx"] = 5

GBoss_conf["index"][6] = 6
GBoss_conf[6] = {}
	GBoss_conf[6]["Index"] = 6
	GBoss_conf[6]["Name"] = 160005408
	GBoss_conf[6]["Stage_ID"] = 59990096
	GBoss_conf[6]["Kill_Reward"] = {}
		GBoss_conf[6]["Kill_Reward"][1] = 191010003
		GBoss_conf[6]["Kill_Reward"][2] = 100
	GBoss_conf[6]["Boss_Life"] = 381859800
	GBoss_conf[6]["real_idx"] = 6

GBoss_conf["index"][7] = 7
GBoss_conf[7] = {}
	GBoss_conf[7]["Index"] = 7
	GBoss_conf[7]["Name"] = 160005409
	GBoss_conf[7]["Stage_ID"] = 59990097
	GBoss_conf[7]["Kill_Reward"] = {}
		GBoss_conf[7]["Kill_Reward"][1] = 191010003
		GBoss_conf[7]["Kill_Reward"][2] = 150
	GBoss_conf[7]["Boss_Life"] = 537478200
	GBoss_conf[7]["real_idx"] = 7

GBoss_conf["index"][8] = 8
GBoss_conf[8] = {}
	GBoss_conf[8]["Index"] = 8
	GBoss_conf[8]["Name"] = 160000939
	GBoss_conf[8]["Stage_ID"] = 59990128
	GBoss_conf[8]["Kill_Reward"] = {}
		GBoss_conf[8]["Kill_Reward"][1] = 191010003
		GBoss_conf[8]["Kill_Reward"][2] = 150
	GBoss_conf[8]["Boss_Life"] = 750000000
	GBoss_conf[8]["real_idx"] = 8

GBoss_conf["index"][9] = 9
GBoss_conf[9] = {}
	GBoss_conf[9]["Index"] = 9
	GBoss_conf[9]["Name"] = 160000139
	GBoss_conf[9]["Stage_ID"] = 59990129
	GBoss_conf[9]["Kill_Reward"] = {}
		GBoss_conf[9]["Kill_Reward"][1] = 191010003
		GBoss_conf[9]["Kill_Reward"][2] = 150
	GBoss_conf[9]["Boss_Life"] = 850000000
	GBoss_conf[9]["real_idx"] = 9

GBoss_conf["index"][10] = 10
GBoss_conf[10] = {}
	GBoss_conf[10]["Index"] = 10
	GBoss_conf[10]["Name"] = 160000570
	GBoss_conf[10]["Stage_ID"] = 59990130
	GBoss_conf[10]["Kill_Reward"] = {}
		GBoss_conf[10]["Kill_Reward"][1] = 191010003
		GBoss_conf[10]["Kill_Reward"][2] = 200
	GBoss_conf[10]["Boss_Life"] = 950000000
	GBoss_conf[10]["real_idx"] = 10


GBoss_conf["len"] = 10

function GBoss_conf.get_data_by_idx(i)
	if GBoss_conf[i] == nil then return nil
	else
		local temp = ""
		temp = temp..GBoss_conf[i].Index
		temp = temp..";"
		temp = temp..GBoss_conf[i].Name
		temp = temp..";"
		temp = temp..GBoss_conf[i].Stage_ID
		temp = temp..";"
		for k,v in ipairs(GBoss_conf[i].Kill_Reward) do temp = temp..v.."," end
			temp = string.sub(temp, 1, -2)
		temp = temp..";"
		temp = temp..GBoss_conf[i].Boss_Life
		temp = temp..";"..GBoss_conf[i].real_idx
		return temp
	end
end

function GBoss_conf.get_data_by_real_idx(i)
	if GBoss_conf.index[i] == nil then return nil
	else
		return GBoss_conf.get_data_by_idx(GBoss_conf.index[i])
	end
end
