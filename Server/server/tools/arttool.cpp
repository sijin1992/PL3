#include <iostream>
#include <fstream>
#include "main_logic/all_config.h"
using namespace std;

CMainLogicAllConfig gAllConf;
int gDebugFlag=1;

#define CONFIG_DIR "../../tools"

int help_info()
{
	cout << "usage: rolltimes" << endl;
	return 0;
}

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		return help_info();
	}

	int rolltimes = atoi(argv[1]);

	
	if(gAllConf.confGamble.read_from_xml(CONFIG_DIR"/gamble.xml") != 0)
	{
		cout << "read gamble conf fail" << endl;
		return 0;
	}


	srand(time(NULL));
	int goldtotal = 0;
	int crys[]={0,0,0,0,0,0};
	int scores=0;
	int level = 1;
	for(int i=0;i<rolltimes; ++i)
	{
		CConfItemgamble* pconf = gAllConf.confGamble.get_conf(level);
		if(pconf == NULL)
		{
			printf( "no config for gamble level(%d)\r\n", level);
			return -1;
		}

		goldtotal+=pconf->ReqGold;
		scores+=pconf->ReqIntegral;

		//是否晋级
		if(rand()%100 < pconf->ActPercend)
		{
			++level;
		}
		else
		{
			level = 1;
		}

		//随机给品质
		int boxrand = rand()%100;
		if(boxrand < pconf->ActPercend1)
			++crys[pconf->QuaBoxId1-1];
		else if( (boxrand -= pconf->ActPercend1) < pconf->ActPercend2)
			++crys[pconf->QuaBoxId2-1];
		else if( (boxrand -= pconf->ActPercend2) < pconf->ActPercend3)
			++crys[pconf->QuaBoxId3-1];
		else if( (boxrand -= pconf->ActPercend3) < pconf->ActPercend4)
			++crys[pconf->QuaBoxId4-1];
		else if( (boxrand -= pconf->ActPercend4) < pconf->ActPercend5)
			++crys[pconf->QuaBoxId5-1];
		else if( (boxrand -= pconf->ActPercend5) < pconf->ActPercend6)
			++crys[pconf->QuaBoxId6-1];
		else
		{
			printf("config for gamble level(%d) error\r\n", level);
			return -1;
		}
				
	}

	cout << "rolltimes: " << rolltimes << endl;
	cout << "gold: " << goldtotal << endl;
	cout << "score: " << scores << endl;
	for(unsigned int i=0; i<sizeof(crys)/sizeof(crys[0]); ++i)
	{
		cout << "level(" << i+1 << "): " << crys[i] << endl;
	}

	return 0;
}
