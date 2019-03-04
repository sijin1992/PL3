#include <iostream>
#include <fstream>
//#include "main_logic/fight_old.h"
#include "log/log.h"
#include "time/calculagraph.h"
#include "ini/ini_file.h"
using namespace std;
/*
CFightMain gFight;
CMainLogicAllConfig gAllConf;
int gDebugFlag=1;

#define CONFIG_DIR "../../tools"
#define SELF_SECTOR "SELF_TROOPS"
#define ENEMY_SECTOR "ENEMY_TROOPS"

#define USER_GROUP_FIGHT_ONLY_ONCE    -1
#define USER_GROUP_FIGHT_UNTIL_WIN    0 

int g_user_group_boss_fight_type = USER_GROUP_FIGHT_ONLY_ONCE;

int caculate_attr_bonus(RoleInfo* prole)
{
	const int POS_TOTAL = 4;
	const RoleInfo& roleinfo = *prole;
	int suitids[POS_TOTAL];
	int suitcnt[POS_TOTAL];
	memset(suitids, 0, sizeof(suitids));
	memset(suitcnt, 0, sizeof(suitcnt));
	int equipids[POS_TOTAL];
	equipids[0] = roleinfo.helm();
	equipids[1] = roleinfo.armor();
	equipids[2] = roleinfo.weapon();
	equipids[3] = roleinfo.wings();

	CConfItemequipitem* pitemconf;
	CConfItemequipsuit* psuitconf;

	int hp = 0;
	int atk = 0;
	int def = 0;
	
	for(int i=0; i<POS_TOTAL; ++i)
	{
		if(equipids[i] != 0)
		{
			
			pitemconf = gAllConf.confEquipItem.get_conf(equipids[i], true);
			if(pitemconf == NULL)
			{
				cout << "equip(" << equipids[i] << ") no config" << endl; 
				return -1;
			}

			hp += pitemconf->AddBHp+pitemconf->AddBHpAdd;
			def += pitemconf->AddBDefense+pitemconf->AddBDefenseAdd;
			atk+= pitemconf->AddBAttack+pitemconf->AddBAttackAdd;

			for(int j=0; j<POS_TOTAL; ++j)
			{
				if(suitids[j] ==0 || suitids[j] == pitemconf->SuitType)
				{
					suitids[j] = pitemconf->SuitType;
					++(suitcnt[j]);
					break;
				}
			}
		}
	}


	for(int k=0; k<POS_TOTAL; ++k)
	{
		if(suitids[k] ==0)
		{
			break; //以后都是0 ，break
		}

		if(suitcnt[k] >= 2) // 2以上才有效果
		{
			psuitconf = gAllConf.confEquipSuit.get_conf(suitids[k], true);
			if(psuitconf == NULL)
			{
				cout << "equipsuit(" << suitids[k] << ") no config" << endl; 
				return -1;
			}
			if(suitcnt[k] < 4)
			{
				hp += psuitconf->AddHp2;
				atk += psuitconf->AddAtt2;
				def += psuitconf->AddDef2;
			}
			else
			{
				hp += psuitconf->AddHp4;
				atk += psuitconf->AddAtt4;
				def += psuitconf->AddDef4;
			}
		}
	}

	prole->set_hpbonus(hp);
	prole->set_atkbonus(atk);
	prole->set_defbonus(def);

	return 0;
}

int write_file(FightResp_old& resp, const char* poutputfile)
{
	string respbuff;
	if(!resp.SerializeToString(&respbuff))
	{
		cout << "resp SerializeToString fail" << endl;
		return -1;
	}
	
	ofstream of2(poutputfile, ofstream::binary);
	if(!of2.good())
	{
		cout << "open " << poutputfile << " fail" << endl;
		return -1;
	}
	of2.write(respbuff.data(), respbuff.length());
	of2.close();
	return 0;
}

void inner_print_config(const char* sector, int unitnum)
{
	cout << "[" << sector << "]" << endl;
	cout << ";;0=player 1=npc"<< endl;
	cout << "TYPE=0"<< endl;
	cout << ";;palyer配置"<< endl;
	cout << "TROOPS_UNIT=" << unitnum << ""<< endl;
	for(int i=0; i<unitnum; ++i)
	{
		cout << "UNIT_" << i << "="<< endl;
		
		//cout << "UNIT_ID_" << i << "="<< endl;
		//cout << "UNIT_SKILL_" << i << "="<< endl;
		//cout << "UNIT_POTENTIAL_" << i << "="<< endl;
		//cout << "UNIT_LEVEL_" << i << "="<< endl;
		
	}
	
	cout << "HELM=0"<< endl;
	cout << "ARMOR=0"<< endl;
	cout << "WEAPON=0"<< endl;
	cout << "WINGS=0"<< endl;
	cout << "HERO_BONUS_HP=10"<< endl;
	cout << "HERO_BONUS_ATK=20"<< endl;
	cout << "HERO_BONUS_DEF=20"<< endl;
	cout << "SOL_BONUS_HP=0"<< endl;
	cout << "SOL_BONUS_ATK=0"<< endl;
	cout << "SOL_BONUS_DEF=0"<< endl;
	cout << "BUFF_ATK=0" << endl;
	cout << "BUFF_DEF=0" << endl;
	cout << ";;npc配置"<< endl;
	cout << "NPC_IDS="<< endl;
	cout << "NPC_SKILLS="<< endl;
	cout << "NPC_DIFFICULT="<< endl;
}

void do_print_config(int unitnum)
{
	inner_print_config(SELF_SECTOR, unitnum);
	inner_print_config(ENEMY_SECTOR, unitnum);
}

int inner_create_data(CIniFile& oIni, const char* sector, UserData& data, vector<int>& vnpcs, vector<int>& vnpcskills, int& difficult, int& buffatk, int& buffdef)
{
	difficult = 0;
	int ival;
	int has_super_soldier = 0;
	if(oIni.GetInt(sector, "TYPE", 0, &ival)!=0)
	{
		cout << sector << ".TYPE not found" << endl; 
		return -1;
	}

	if(ival == 0)
	{
		//player
		RoleInfo* prole = data.mutable_roleinfo();
		prole->set_race(1);
		prole->set_sex(1);
		
		if(oIni.GetInt(sector, "TROOPS_UNIT", 0, &ival)!=0)
		{
			cout << sector << ".TROOPS_UNIT not found" << endl; 
			return -1;
		}

		// 是否有神将
		if(oIni.GetInt(sector, "HAVE_SUPER_SOLDIER", 0, &has_super_soldier)!=0)
		{
			cout << sector << ".HAVE_SUPER_SOLDIER not found" << endl; 
			return -1;
		}

		char namebuff[32];

		if (1 == has_super_soldier)
		{
			int unitid;
			int level;
			int potential;
			int ascend;
			string runetypes;
			string groupskills;
			string equips;
			string skills;
			char unitval[512] = {0};

			strcpy (namebuff, "UNIT_s");

			if(oIni.GetString(sector, namebuff, "", unitval, sizeof(unitval))== 0)
			{
				string strunitval = unitval;
				strutil::Tokenizer thetoken(strunitval, "|");

				// id
				if(thetoken.nextToken())
				{
					unitid = atoi(thetoken.getToken().c_str());
				}
				else
				{
					cout << sector << "." << namebuff << " not valid 1" << endl; 
					return -1;
				}

				// 技能
				if(thetoken.nextToken())
				{
					skills = thetoken.getToken();
				}
				else
				{
					cout << sector << "." << namebuff << " not valid 2" << endl; 
					return -1;
				}

				// 潜力 
				if(thetoken.nextToken())
				{
					potential = atoi(thetoken.getToken().c_str());
				}
				else
				{
					cout << sector << "." << namebuff << " not valid 3" << endl; 
					return -1;
				}

				// 等级
				if(thetoken.nextToken())
				{
					level = atoi(thetoken.getToken().c_str());
				}
				else
				{
					cout << sector << "." << namebuff << " not valid 4" << endl; 
					return -1;
				}

				// 阶位
				if(thetoken.nextToken())
				{
					ascend = atoi(thetoken.getToken().c_str());
				}
				else
				{
					cout << sector << "." << namebuff << " not valid 5" << endl; 
					return -1;
				}

				// 装备
				if(thetoken.nextToken())
				{
					equips = thetoken.getToken();
				}

				// 帮会技能
				if(thetoken.nextToken())
				{
					groupskills = thetoken.getToken();
				}
			}

			// 填充神将信息
			SuperSoldiersInfo *soldierinfo = data.mutable_supersoldiersinfo();
			soldierinfo->set_cursoldierid(unitid);
			
			SuperSoldier* soldier = soldierinfo->add_soldiers();
			
			soldier->set_soldierid(unitid);
			soldier->set_potential(potential);
			soldier->set_level(level);
			soldier->set_stage(ascend);

			// 装备
			strutil::Tokenizer equiptoken(equips, ",");
			while(equiptoken.nextToken())
			{
				int equipid = atoi(equiptoken.getToken().c_str());
				if (0 == equipid)
					continue;

				SuperSoldierEquip *pequip = soldier->add_equips();
				pequip->set_equipid(equipid);
			}

			// 技能
			strutil::Tokenizer skilltoken(skills, ",");
			while(skilltoken.nextToken())
			{
				int skillid = atoi(skilltoken.getToken().c_str());
				if (0 == skillid)
					continue;

				SuperSoldierSkill  *pskill= soldier->add_skills();
				pskill->set_skillid(skillid);
			}

			// 帮会技能
			strutil::Tokenizer grouptoken(groupskills, ",");
			UserGroupCache* pgroup = data.mutable_usergroup();

			while(grouptoken.nextToken())
			{
				int id = atoi(grouptoken.getToken().c_str());

				if (0 == id)
					continue;

				int type = gAllConf.confgroupskill.get_conf(id)->SkillType;
				for(int i= pgroup->skills_size(); i <= type - 1; ++i)
				{
					pgroup->add_skills(0);
				}

				pgroup->set_skills(type - 1, id);
			}
		}

		for(int i=0; i<ival; ++i)
		{
			int unitid;
			int level;
			int potential;
			int ascend;
			int actifacttype=0;
			string crystaltypes;
			string runetypes;
			string groupskills;
			bool hasartifact = false;
			bool hascrystal = false;
			bool hasrune = false;
			bool hasgroupskill = false;

			char skills[256]={0};
			char unitval[512] = {0};
			snprintf(namebuff, sizeof(namebuff), "UNIT_%d", i);

			if(oIni.GetString(sector, namebuff, "", unitval, sizeof(unitval))== 0)
			{
				string strunitval = unitval;
				strutil::Tokenizer thetoken(strunitval, "|");
				if(thetoken.nextToken())
				{
					unitid = atoi(thetoken.getToken().c_str());
				}
				else
				{
					cout << sector << "." << namebuff << " not valid 1" << endl; 
					return -1;
				}


				if(thetoken.nextToken())
				{
					snprintf(skills,sizeof(skills), thetoken.getToken().c_str());
				}
				else
				{
					cout << sector << "." << namebuff << " not valid 2" << endl; 
					return -1;
				}


				if(thetoken.nextToken())
				{
					potential = atoi(thetoken.getToken().c_str());
				}
				else
				{
					cout << sector << "." << namebuff << " not valid 3" << endl; 
					return -1;
				}
				
				if(thetoken.nextToken())
				{
					level = atoi(thetoken.getToken().c_str());
				}
				else
				{
					cout << sector << "." << namebuff << " not valid 4" << endl; 
					return -1;
				}

				if(thetoken.nextToken())
				{
					ascend = atoi(thetoken.getToken().c_str());
				}
				else
				{
					cout << sector << "." << namebuff << " not valid 5" << endl; 
					return -1;
				}
				

				//可选
				if(thetoken.nextToken())
				{
					hasartifact = true;
					actifacttype = atoi(thetoken.getToken().c_str());
				}

				if(thetoken.nextToken())
				{	
					hascrystal = true;
					crystaltypes = thetoken.getToken();
				}

				// 可选，添加符文
				if(thetoken.nextToken())
				{
					hasrune = true;
					runetypes = thetoken.getToken();
				}

				if(thetoken.nextToken())
				{
					hasgroupskill = true;
					groupskills = thetoken.getToken();
				}
			}
			else
			{
				snprintf(namebuff, sizeof(namebuff), "UNIT_ID_%d", i);
				if(oIni.GetInt(sector, namebuff, 0, &unitid)!=0)
				{
					cout << sector << "." << namebuff << " not found" << endl; 
					return -1;
				}
				
				snprintf(namebuff, sizeof(namebuff), "UNIT_LEVEL_%d", i);
				if(oIni.GetInt(sector, namebuff, 0, &level)!=0)
				{
					cout << sector << "." << namebuff << " not found" << endl; 
					return -1;
				}
				
				snprintf(namebuff, sizeof(namebuff), "UNIT_POTENTIAL_%d", i);
				if(oIni.GetInt(sector, namebuff, 0, &potential)!=0)
				{
					cout << sector << "." << namebuff << " not found" << endl; 
					return -1;
				}

				snprintf(namebuff, sizeof(namebuff), "UNIT_CRYSTAL_%d", i);
				if(oIni.GetString(sector, namebuff, "", skills, sizeof(skills))==0) //借用一下skills
					crystaltypes = skills;

				snprintf(namebuff, sizeof(namebuff), "UNIT_SKILL_%d", i);
				if(oIni.GetString(sector, namebuff, "", skills, sizeof(skills))!=0)
				{
					cout << sector << "." << namebuff << " not found" << endl; 
					return -1;
				}

				snprintf(namebuff, sizeof(namebuff), "UNIT_ASEND_%d", i);
				if(oIni.GetInt(sector, namebuff, 0, &ascend)!=0)
				{
					cout << sector << "." << namebuff << " not found" << endl; 
					return -1;
				}
				
				snprintf(namebuff, sizeof(namebuff), "UNIT_AMULET_%d", i);
				oIni.GetInt(sector, namebuff, 0, &actifacttype);
				
			}

			
			vector<int> vskills;
			string strskills = skills;
			gFight.parse_npcid(vskills, strskills);

			//神器
			ArtifactItem artitem;
			if (hasartifact)
			{
				artitem.set_id(1);
				artitem.set_type(actifacttype);
				strutil::Tokenizer crytoken(crystaltypes, ",");
				int crystalid = 1;
				while(crytoken.nextToken())
				{
					CrystalItem* pcry = artitem.add_holes();
					pcry->set_id(crystalid);
					pcry->set_type(atoi(crytoken.getToken().c_str()));

					crystalid++;
				}
			}

			// 符文
			FightUnitSetRuneReq runeInfo;
			if (hasrune)
			{
				int runeid = 0;
				int runeSlotIdx = 1; 
				
				strutil::Tokenizer runetoken(runetypes, ",");
				while(runetoken.nextToken())
				{
					RuneInfo* pruneinfo = runeInfo.add_runeinfo();
					runeid = atoi(runetoken.getToken().c_str());

					// 可能只绑定少于6个普通符文，与一个精华符文
					// 所以存在此种情况时，用0代替普通符文，表示没有绑定，保证最后一个是精华符文
					if (0 == runeid)
						continue;

					pruneinfo->set_runeid(runeid);
					pruneinfo->set_slotidx(runeSlotIdx++);
				}
			}

			if (hasgroupskill)
			{
				//帮会
				strutil::Tokenizer grouptoken(groupskills, ",");
				UserGroupCache* pgroup = data.mutable_usergroup();

				while(grouptoken.nextToken())
				{
					int id = atoi(grouptoken.getToken().c_str());
					int type = gAllConf.confgroupskill.get_conf(id)->SkillType;
					for(int i= pgroup->skills_size(); i <= type - 1; ++i)
					{
						pgroup->add_skills(0);
					}

					pgroup->set_skills(type - 1, id);
				}
			}

			if(unitid == 0)
			{
				//主将
				prole->set_level(level);
				prole->set_potential(potential);
				for(unsigned int j=0; j<vskills.size();++j)
				{
					FightSkill* pskill = prole->add_skill();
					pskill->set_skillid(vskills[j]);
				}

				if (hasartifact)
				{
					prole->mutable_artifact()->CopyFrom(artitem);
				}
				
				prole->set_ascension(ascend);

				// 添加符文
				if (hasrune)
				{
					prole->mutable_runeinfo()->CopyFrom(runeInfo.runeinfo());
				}
			}
			else
			{
				//其他
				FightUnit* punit = data.add_fightunit();
				punit->set_level(level);
				punit->set_unitid(unitid);
				punit->set_potential(potential);
				for(unsigned int j=0; j<vskills.size();++j)
				{
					FightSkill* pskill = punit->add_skill();
					pskill->set_skillid(vskills[j]);
				}
				punit->set_ascension(ascend);

				if (hasartifact)
				{
					punit->mutable_artifact()->CopyFrom(artitem);
				}

				// 添加符文
				if (hasrune)
				{
					punit->mutable_runeinfo()->CopyFrom(runeInfo.runeinfo());
				}
			}

			data.add_lastfightseq(unitid);
		}

		int tmp;
		oIni.GetInt(sector, "HELM", 0, &tmp);
		if(tmp > 0)
			prole->set_helm(tmp);

		oIni.GetInt(sector, "ARMOR", 0, &tmp);
		if(tmp > 0)
			prole->set_armor(tmp);

		oIni.GetInt(sector, "WEAPON", 0, &tmp);
		if(tmp > 0)
			prole->set_weapon(tmp);

		oIni.GetInt(sector, "WINGS", 0, &tmp);
		if(tmp > 0)
			prole->set_wings(tmp);

		caculate_attr_bonus(prole);

		oIni.GetInt(sector, "HERO_BONUS_HP", 0, &tmp);
		if(tmp > 0)
			prole->set_wonderhpbonus(tmp);

		oIni.GetInt(sector, "HERO_BONUS_ATK", 0, &tmp);
		if(tmp > 0)
			prole->set_wonderatkbonus(tmp);
		
		oIni.GetInt(sector, "HERO_BONUS_DEF", 0, &tmp);
		if(tmp > 0)
			prole->set_wonderdefbonus(tmp);

		oIni.GetInt(sector, "SOL_BONUS_HP", 0, &tmp);
		if(tmp > 0)
			prole->set_solhpbonus(tmp);

		oIni.GetInt(sector, "SOL_BONUS_ATK", 0, &tmp);
		if(tmp > 0)
			prole->set_solatkbonus(tmp);
		
		oIni.GetInt(sector, "SOL_BONUS_DEF", 0, &tmp);
		if(tmp > 0)
			prole->set_soldefbonus(tmp);

		oIni.GetInt(sector, "BUFF_ATK", 0, &buffatk);
		oIni.GetInt(sector, "BUFF_DEF", 0, &buffdef);

	}
	else
	{
		//npc
		char npcs[256]={0};
		if(oIni.GetString(sector, "NPC_IDS", "", npcs, sizeof(npcs))!=0)
		{
			cout << sector << ".NPC_IDS not found" << endl; 
			return -1;
		}
		string strnpcs = npcs;
		gFight.parse_npcid(vnpcs, strnpcs);

		if(oIni.GetInt(sector, "NPC_DIFFICULT", 0, &difficult)!=0)
		{
			cout << sector << ".NPC_DIFFICULT not found" << endl; 
			return -1;
		}

		char npcskills[256]={0};
		if(oIni.GetString(sector, "NPC_SKILLS", "", npcskills, sizeof(npcskills))!=0)
		{
			cout << sector << ".NPC_SKILLS not found" << endl; 
			return -1;
		}
		string strnpcskills = npcskills;
		gFight.parse_npcid(vnpcskills, strnpcskills);
	}

	return 0;
}

void do_single_fight(CIniFile& oIni, int fighttimes=1, int idx=0, int show=0, int bin=0)
{
	int winnum = 0;
	int fail = 0;
	bool single = false;
	if(fighttimes == 1)
	{
		single = true;
	}

	for(int i=0; i<fighttimes; ++i)
	{
		if(single)
			cout << "---------------------fight " << idx << "------------------------" << endl;

		gFight.reinit();
		FightResp_old resp;
		UserData selfdata;
		UserData enemydata;
		vector<int> vnpcs;
		vector<int> vnpcskills;
		int difficult;
		bool win = false;
		int buffatk;
		int buffdef;
		//左方
		if(inner_create_data(oIni, SELF_SECTOR, selfdata, vnpcs, vnpcskills, difficult,buffatk,buffdef)!=0)
		{
			return;
		}

		if(difficult !=0)
		{
			//自己不能是npc
			cout << "self can't be npc" << endl;
			return;
		}

		if(gFight.set_self_info(NULL, selfdata, selfdata.lastfightseq_size(),
			buffatk, buffdef, buffatk, buffdef) !=0)
		{
			cout << "set_self_info fail" << endl;
			return; 
		}

		//右方
		if(inner_create_data(oIni, ENEMY_SECTOR, enemydata, vnpcs,vnpcskills, difficult, buffatk, buffdef)!=0)
		{
			return;
		}
		

		if(difficult == 0)
		{
			//pvp
			if(gFight.set_player_info(NULL, enemydata, enemydata.lastfightseq_size(),
				buffatk, buffdef, buffatk, buffdef)!=0)
			{
				cout << "set_player_info fail" << endl;
				return; 
			}
		}
		else
		{
			//pve
			if(gFight.set_npc_info(vnpcs, difficult, vnpcskills)!=0)
			{
				cout << "set_npc_info fail" << endl;
				return; 
			}
		}

		//开打
		if(gFight.do_fight(win, resp.mutable_fightbytes()) < 0)
		{
			cout << "fight fail" << endl;
			return;
		}
		
		if(win)
			resp.set_win(1);
		else
			resp.set_win(0);
			
		resp.set_result(resp.OK);				

		//now we got resp
		if(show)
		{
			theWriter.debug(cout);
		}

		if(bin && single)
		{
			write_file(resp, "lastfight.bin");
		}

		//摘要
		if(single)
		{
			gFight.output(cout);
			cout << "result: ";
			if(resp.win())
				cout << "win" << endl;
			else
				cout << "lose" << endl;
		}
		else
		{
			if(resp.win())
				++winnum;
			else
				++fail;
		}
	}

	if(!single)
	{
		cout << "win: " << winnum << endl;
		cout << "lose: " << fail << endl;
	}

}

int ini_fight_info (CIniFile& oIni, int& difficult, int &bossid)
{
	UserData selfdata;
	UserData enemydata;
	vector<int> vnpcs;
	vector<int> vnpcskills;
	int buffatk;
	int buffdef;

	//左方
	if(inner_create_data(oIni, SELF_SECTOR, selfdata, vnpcs, vnpcskills, difficult, buffatk,buffdef)!=0)
	{
		cout << "create self data error" << endl;
		return -1;
	}

	if(difficult !=0)
	{
		//自己不能是npc
		cout << "self can't be npc" << endl;
		return -1;
	}

	// 初始化相关信息
	gFight.reinit();

	if(gFight.set_self_info(NULL, selfdata, selfdata.lastfightseq_size(),
		buffatk, buffdef, buffatk, buffdef) !=0)
	{
		cout << "set_self_info fail" << endl;
		return -1; 
	}

	//右方
	if(inner_create_data(oIni, ENEMY_SECTOR, enemydata, vnpcs,vnpcskills, difficult, buffatk, buffdef)!=0)
	{
		cout << "create enemy data error" << endl;
		return -1;
	}

	//pve

	if (g_user_group_boss_fight_type == USER_GROUP_FIGHT_ONLY_ONCE)
	{
		cout << "bossid: " << vnpcs[0] << endl;
		for (int i = 0; i < vnpcskills.size(); i++)
		{
			cout << "skillid: " << vnpcskills[i] << endl;
		}
		cout << "difficult: " << difficult << endl;
	}

	if(gFight.set_boss_info(vnpcs[0], vnpcskills, difficult)!=0)
	{
		cout << "set_npc_info fail" << endl;
		return -1; 
	}

	bossid = vnpcs[0];

	return 0;
}

int do_boss_fight(CIniFile& oIni, int type, bool& win, int idx=0)
{
	int unitid;
	int bossid = 0;
	int inihp = 0;
	int bosshp = 0;
	int difficult = 0;
	int timesuntilwin = 0;
	
	FightResp_old resp;
	CConfItemnpc* pnpcconf = NULL;

	if (-1 == ini_fight_info (oIni, difficult, bossid))
	{
		cout << "ini fight info error" << endl;
		return -1;
	}

	// 获取初始血量，只有一个BOSS
	pnpcconf = gAllConf.confNpc.get_conf(bossid);
	inihp = bosshp = (long long)(pnpcconf->NPCHp)*difficult/100;

	//cout << "BOSS HP: " << bosshp << endl;

	//仅打一次
	if (USER_GROUP_FIGHT_ONLY_ONCE == type)
	{
		g_user_group_boss_fight_type = USER_GROUP_FIGHT_ONLY_ONCE;

		cout << "fight once" << endl;

		//开打
		if(gFight.do_fight(win, resp.mutable_fightbytes()) < 0)
		{
			cout << "fight fail" << endl;
			return -1;
		}

		// 战斗后获取BOSS的血量
		if(gFight.do_get_unit_hp(false, 1, bosshp, unitid) != 0)
		{
			cout << "get boss hp fail" << endl;
			return -1;
		}

		gFight.output(cout);

		cout << "####################################" << endl;

		if(win)
		{
		cout << "##     result: single fight win   ##" << endl;
		cout << "##     boss hp decrease           ##" << inihp << endl;
		}				
		else
		{
		cout << "##     result: single fight lose  ##" << endl;
		cout << "##     boss hp decrease : " << inihp - bosshp << "    ##" <<endl;
		}

		cout << "####################################" << endl;
	}
	// 打一局直到赢
	else if (USER_GROUP_FIGHT_UNTIL_WIN == type)
	{
		g_user_group_boss_fight_type = USER_GROUP_FIGHT_UNTIL_WIN;

		while(bosshp)
		{
			timesuntilwin++;

			// 每次战斗前都需要初始化
			if (-1 == ini_fight_info (oIni, difficult, bossid))
			{
				cout << "ini fight info error" << endl;
				return -1;
			}

			// 清理战斗数据
			resp.clear_fightbytes();

			// 战斗前修正BOSS的血量
			if(gFight.do_set_unit_hp(false, 1, bosshp) != 0)
			{
				cout << "set boss hp fail" << endl;
				return -1;
			}

			//开打
			if(gFight.do_fight(win, resp.mutable_fightbytes()) < 0)
			{
				cout << "fight fail" << endl;
				return -1;
			}
			
			// 战斗后获取BOSS的血量
			if(gFight.do_get_unit_hp(false, 1, bosshp, unitid) != 0)
			{
				cout << "get boss hp fail" << endl;
				return -1;
			}
		}

		gFight.output(cout);
		cout << "###########################################" << endl;
		cout << "## fight boss until win need times : " << timesuntilwin << " ##" << endl;
		cout << "###########################################" << endl;
	}
	// 设定战斗次数的
	else if (USER_GROUP_FIGHT_UNTIL_WIN < type)
	{
		int wintimes = 0;
		g_user_group_boss_fight_type = type;
		for(int i = 0; i < type; i++)
		{
			wintimes++;

			// 每次战斗前都需要初始化
			if (-1 == ini_fight_info (oIni, difficult, bossid))
			{
				cout << "ini fight info error" <<endl;
				return -1;
			}

			// 战斗前修正BOSS的血量
			if(gFight.do_set_unit_hp(false, 1, bosshp) != 0)
			{
				cout << "set boss hp fail" << endl;
				return -1;
			}

			// 清理战斗数据
			resp.clear_fightbytes();

			//开打
			if(gFight.do_fight(win, resp.mutable_fightbytes()) < 0)
			{
				cout << "fight fail" << endl;
				return -1;
			}
			
			if (win) 
			{
				cout << "win need times: " << wintimes << " | ";
				break;
			}

			// 战斗后获取BOSS的血量
			if(gFight.do_get_unit_hp(false, 1, bosshp, unitid) != 0)
			{
				cout << "get boss hp fail" << endl;
				return -1;
			}
		}
	}
	return 0;
}

void do_show_bin(const  char* binpath)
{
	ifstream is(binpath, ofstream::binary);
	if(!is.good())
	{
		cout << "open " << binpath << " fail" << endl;
		return;
	}
	is.seekg(0, ios::end);
	int length = is.tellg();
	is.seekg(0, ios::beg);
	char* buffer = new char[length];
	is.read(buffer, length);
	is.close();
	FightResp_old resp;
	if(!resp.ParseFromArray(buffer, length))
	{
		cout << "parse fail" << endl;
		delete[] buffer;
		return;
	}

	delete[] buffer;

	const string& bytes= resp.fightbytes();
	int len = bytes.length();
	if(len < theWriter.head_len() || len > (int)sizeof(theWriter.rawbuff))
	{
		cout << "fightbytes len=" << len << " not valid" << endl;
	}
	//逆向bytes->assign(theWriter.rawbuff, theWriter.outputbufflen+theWriter.head_len());
	theWriter.init();
	memcpy(theWriter.rawbuff, bytes.data(), len);
	theWriter.outputbufflen = len - theWriter.head_len();
	theWriter.debug(cout);
}

int help_info()
{
	cout << "usage: " << endl;
	cout << "config example: 0" << endl;
	cout << "single test: 1 config [fighttimes default 1] [ifshow(print to std)] [ifbin(write bin)]" << endl;
	cout << "show bin: 2 binfile" << endl;
	return 0;
}
*/
int main(int argc, char** argv)
{
/*
	if(argc < 2)
	{
		return help_info();
	}

	int cmd = atoi(argv[1]);
	
	LOG_CONFIG theLogConf;
	theLogConf.defaultModule = "test_fight";
	theLogConf.logPath = ".";
	LOG_CONFIG_SET(theLogConf);
	//cout << "open log =" << LOG_OPEN_DEFAULT(NULL) << endl;
	if(cmd == 3)
		cout << "open log =" << LOG_OPEN_DEFAULT(NULL) << endl;

	if(gAllConf.confRoleLevel.read_from_xml(CONFIG_DIR"/rolelevel.xml") != 0)
	{
		cout << "read rolelevel conf fail" << endl;
		return 0;
	}

	if(gAllConf.confFightUnit.read_from_xml(CONFIG_DIR"/fightunit.xml") != 0)
	{
		cout << "read fightunit conf fail" << endl;
		return 0;
	}

	if(gAllConf.confFightSkill.read_from_xml(CONFIG_DIR"/fightskill.xml") != 0)
	{
		cout << "read confUnitSkill conf fail" << endl;
		return 0;
	}

	if(gAllConf.confNpc.read_from_xml(CONFIG_DIR"/npc.xml") != 0)
	{
		cout << "read confNpc conf fail" << endl;
		return 0;
	}
	
	if(gAllConf.confEquipItem.read_from_xml(CONFIG_DIR"/equipitem.xml") != 0)
	{
		cout << "read confEquipItem conf fail" << endl;
		return 0;
	}

	if(gAllConf.confEquipSuit.read_from_xml(CONFIG_DIR"/equipsuit.xml") != 0)
	{
		cout << "read confEquipSuit conf fail" << endl;
		return 0;
	}

	if(gAllConf.confAmulet.read_from_xml(CONFIG_DIR"/amulet.xml") != 0)
	{
		cout << "read confAmulet conf fail" << endl;
		return 0;
	}

	if(gAllConf.confCrystal.read_from_xml(CONFIG_DIR"/crystal.xml") != 0)
	{
		cout << "read confCrystal conf fail" << endl;
		return 0;
	}

	if(gAllConf.confrune.read_from_xml(CONFIG_DIR"/rune.xml") != 0)
	{
		cout << "read confrune conf fail" << endl;
		return 0;
	}

	if(gAllConf.confgroupskill.read_from_xml(CONFIG_DIR"/groupskill.xml") != 0)
	{
		cout << "read groupskill conf fail" << endl;
		return 0;
	}

	if(gAllConf.confunitsuit.read_from_xml(CONFIG_DIR"/unitsuit.xml") != 0)
	{
		cout << "read groupskill conf fail" << endl;
		return 0;
	}

	if(gAllConf.confsupersoldiers.read_from_xml(CONFIG_DIR"/supersoldiers.xml") != 0)
	{
		cout << "read supersoldiers conf fail" << endl;
		return 0;
	}

	//神将技能
	if(gAllConf.confskill_supersoldier.read_from_xml(CONFIG_DIR"/skill_supersoldier.xml") )
	{
		LOG(LOG_ERROR, "confskill_supersoldier.read_from_xml(../conf/skill_supersoldier.xml) fail");
		return -1;
	}

	//神将装备
	if(gAllConf.confequipitem_supersoldier.read_from_xml(CONFIG_DIR"/equipitem_supersoldier.xml") )
	{
		LOG(LOG_ERROR, "confequipitem_supersoldier.read_from_xml(../conf/equipitem_supersoldier.xml) fail");
		return -1;
	}

	srand(time(NULL));
	if(cmd == 0)
	{
		do_print_config(2);
	}
	else if(cmd == 2)
	{
		if(argc < 3)
			return help_info();
		do_show_bin(argv[2]);
	}
	else if(cmd == 1 || cmd == 3)
	{
			
		if(argc < 3)
			return help_info();
			
		CIniFile oIni(argv[2]);
		if(!oIni.IsValid())
		{	
			cout << "read config fail" << endl;
			return -1;
		}
		
		int show =0;
		int bin = 0;
		int fighttimes = 1;
		if(argc > 3)
		{
			fighttimes = atoi(argv[3]);
		}
		
		if(argc > 4 && atoi(argv[4])!=0)
		{
			show = 1;
		}

		if(argc > 5 && atoi(argv[5])!=0)
		{
			bin = 1;
		}
		
		 do_single_fight(oIni, fighttimes, 0, show, bin);
	}
	else if(cmd == 4)
	{
		cout << "----cmd = 4-------" << endl;

		if(argc < 3)
			return help_info();
			
		CIniFile oIni(argv[2]);
		if(!oIni.IsValid())
		{	
			cout << "read config fail" << endl;
			return -1;
		}
		
		bool win = false;
		int type = -1;
		int times = 0;

		if(argc == 4)
		{
			type = atoi(argv[3]);
		}

		if(argc == 5)
		{
			type = atoi(argv[3]);
			times = atoi(argv[4]);
		}
		
		if (argc == 3)
		{
			cout << "---- fight only once begin ----" << endl;
			do_boss_fight(oIni, type, win, 0);
			cout << "---- fight only once end ----" << endl;
		}
		else if (argc == 4)
		{
			cout << "---- fight until win begin ----" << endl;
			do_boss_fight(oIni, type, win, 0);
			cout << "---- fight until win end ----" << endl;
		}
		else if (argc == 5)
		{
			int wintimes = 0;
			
			for (int i = 0; i < times; i++)
			{
				win = false;
				do_boss_fight(oIni, type, win, 0);

				if (win)
					wintimes++;
			}

			gFight.output(cout);

			cout << "###########################################" << endl;
			
			cout << "##    win times: " << wintimes << "                    ###" << endl;
			cout << "##    lose times:  " << times - wintimes << "                    ###" << endl;
			cout << "##    win percent: " << 100*wintimes/times << "%                 ###" << endl;

			cout << "###########################################" << endl;
		}
	}
	else
	{
		help_info();
	}
	*/
	return 0;
}

