#include <iostream>
#include <fstream>
#include "main_logic/all_config.h"
#include "ini/ini_file.h"
#include "string/strutil.h"
#define CONFIG_DIR "../../tools"

CMainLogicAllConfig gAllConf;

bool check_npc(int npcid)
{
	if(gAllConf.confNpc.get_conf(npcid) == NULL)
	{
		cout << "ERROR: npc(" << npcid << ") no conifg" << endl;
		return false;
	}

	return true;
}

bool npc_catchable(int npcid)
{
	CConfItemnpc* pconf;
	if((pconf=gAllConf.confNpc.get_conf(npcid)) == NULL)
	{
		cout << "ERROR: npc(" << npcid << ") no conifg" << endl;
		return false;
	}

	if(pconf->CatchPercent == 0 || pconf->SolId == 0)
	{
		cout << "ERROR: hero npc(" << npcid << ") CatchPercent=0 or SolId=0" << endl;
		return false;
	}

	return true;
}

bool check_npclist(string& npcstr)
{
	strutil::Tokenizer thetoken(npcstr, ",");
	while(thetoken.nextToken())
	{
		if(!check_npc(atoi(thetoken.getToken().c_str())))
		{
			return false;
		}
	}

	return true;
}

void check_battle(int startid, int endid)
{
	CConfItembattle* pconf;
	int nowid = startid;
	bool hasend = false;
	while(nowid != 0)
	{
		if((pconf=gAllConf.confBattle.get_conf(nowid)) == NULL)
		{
			cout << "ERROR: no config for id(" << nowid << ")" << endl;
			break;
		}

		if(pconf->HeroID > 0 && !check_npc(pconf->HeroID))
			break;

		if(!check_npclist(pconf->SoldierID))
			break;

		if(pconf->bCatchable && !npc_catchable(pconf->HeroID))
		{
			break;
		}

		if(nowid == endid)
		{
			cout << "id(" << nowid << ")[end] ->" << endl;
			hasend = true;
		}
		else
			cout << "id(" << nowid << ") ->" << endl;
			
		nowid = pconf->NextLevelID;
	}

	if(endid !=0 && !hasend)
	{
		cout << "ERROR: end(" << endid << ") not found" << endl;
	}
}

void check_campaign()
{
	CONF_MAP_campaign& themap = gAllConf.confCampaign.mapcampaign;
	CONF_MAP_campaign::iterator it;
	for(it=themap.begin(); it!=themap.end(); ++it)
	{
		CConfItemcampaign& conf = it->second;
		cout << "------------------campaign(" << conf.StationID << ") level 1------------------" << endl;
		check_battle(conf.InitialLevelID1, conf.EndLevelID1);
		cout << "------------------campaign(" << conf.StationID << ") level 2------------------" << endl;
		check_battle(conf.InitialLevelID2, conf.EndLevelID2);
		cout << "------------------campaign(" << conf.StationID << ") level 3------------------" << endl;
		check_battle(conf.InitialLevelID3, conf.EndLevelID3);
	}
}

void check_build()
{
	CONF_MAP_build& themap = gAllConf.confBuild.mapbuild;
	CONF_MAP_build::iterator it;
	CConfItembuild* pconf;
	for(it=themap.begin(); it!=themap.end(); ++it)
	{
		CConfItembuild& conf = it->second;
		if(conf.PreviousJZId == 0)
		{
			int nowid = conf.JZId;
			cout << "----------------------build start with " << nowid << "-----------------------------" << endl;
			int preid = 0;
			while(nowid != 0)
			{
				if((pconf=gAllConf.confBuild.get_conf(nowid)) == NULL)
				{
					cout << "ERROR: no config for id(" << nowid << ")" << endl;
					break;
				}
				
				if(pconf->PreviousJZId != preid)
				{
					cout << "ERROR: id(" << nowid << ")->preid=" << pconf->PreviousJZId << " not " << preid << endl;
					break;
				}
				cout << "id(" << nowid << ") ->";
				preid = nowid;
				nowid = pconf->NextJZId;
				if(nowid == 0)
					cout << endl;
			}
		}
	}
}

void check_buildtech()
{
	CONF_MAP_buildtech& themap = gAllConf.confBuildTech.mapbuildtech;
	CONF_MAP_buildtech::iterator it;
	CConfItembuildtech* pconf;
	for(it=themap.begin(); it!=themap.end(); ++it)
	{
		CConfItembuildtech& conf = it->second;
		if(conf.PreSkillId == 0)
		{
			int nowid = conf.SkillId;
			cout << "----------------------buildtech start with " << nowid << "-----------------------------" << endl;
			int preid = 0;
			while(nowid != 0)
			{
				if((pconf=gAllConf.confBuildTech.get_conf(nowid)) == NULL)
				{
					cout << "ERROR: no config for id(" << nowid << ")" << endl;
					break;
				}
				
				if(pconf->PreSkillId != preid)
				{
					cout << "ERROR: id(" << nowid << ")->preid=" << pconf->PreSkillId << " not " << preid << endl;
					break;
				}
				cout << "id(" << nowid << ") ->";
				preid = nowid;
				nowid = pconf->NexSkillId;
				if(nowid == 0)
					cout << endl;
			}
		}
	}
}

void check_allnpc()
{
	CONF_MAP_npc& themap = gAllConf.confNpc.mapnpc;
	CONF_MAP_npc::iterator it;
	for(it=themap.begin(); it!=themap.end(); ++it)
	{
		CConfItemnpc& conf = it->second;
		cout << "npc(" << conf.NPCID << ") ok" << endl;		
	}
}

void check_equip()
{
	CONF_MAP_equipitem& themap = gAllConf.confEquipItem.mapequipitem;
	CONF_MAP_equipitem::iterator it;
	CConfItemequipitem* pconf;
	for(it=themap.begin(); it!=themap.end(); ++it)
	{
		CConfItemequipitem& conf = it->second;
		if(conf.PreItemId == 0)
		{
			int nowid = conf.ItemId;
			cout << "----------------------equip start with " << nowid << "-----------------------------" << endl;
			int preid = 0;
			while(nowid != 0)
			{
				if((pconf=gAllConf.confEquipItem.get_conf(nowid)) == NULL)
				{
					cout << "ERROR: no config for id(" << nowid << ")" << endl;
					break;
				}
				
				if(pconf->PreItemId != preid)
				{
					cout << "ERROR: id(" << nowid << ")->preid=" << pconf->PreItemId << " not " << preid << endl;
					break;
				}
				cout << "id(" << nowid << ") ->";
				preid = nowid;
				nowid = pconf->NexItemId;
				if(nowid == 0)
					cout << endl;
			}
		}
	}

}
	

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		cout << argv[0] << " all|build|buildtech|battle|npc|equip [CONFIG_DIR=../../tools]" << endl;
		return 0;
	}

	const char *pconfpath = CONFIG_DIR;
	if(argc > 2)
	{
		pconfpath = argv[2];
	}
	
	char xml[256];

	string cmd = argv[1];

	snprintf(xml,sizeof(xml), "%s/buildtech.xml", pconfpath);
	if(gAllConf.confBuildTech.read_from_xml(xml) != 0)
	{
		cout << "read " << xml << " fail" << endl;
		return 0;
	}

	snprintf(xml,sizeof(xml), "%s/build.xml", pconfpath);
	if(gAllConf.confBuild.read_from_xml(xml) != 0)
	{
		cout << "read " << xml << " fail" << endl;
		return 0;
	}

	snprintf(xml,sizeof(xml), "%s/npc.xml", pconfpath);
	if(gAllConf.confNpc.read_from_xml(xml) != 0)
	{
		cout << "read " << xml << " fail" << endl;
		return 0;
	}

	snprintf(xml,sizeof(xml), "%s/equipitem.xml", pconfpath);
	if(gAllConf.confEquipItem.read_from_xml(xml) != 0)
	{
		cout << "read " << xml << " fail" << endl;
		return 0;
	}

	bool ball = false;
	if(cmd == "all")
	{	
		ball = true;
	}

	if(ball || cmd =="build")
	{
		check_build();
	}

	if(ball || cmd =="buildtech")
	{
		check_buildtech();
	}

	if(ball || cmd =="battle")
	{
		check_campaign();
	}

	if(ball || cmd =="npc")
	{
		check_allnpc();
	}

	if(ball || cmd =="equip")
	{
		check_equip();
	}

	return 0;
}

