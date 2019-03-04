#include "ini/ini_file.h"
#include <iostream>
#include <fstream>
#include "xml_reader/worldevent.h"
#include <time.h>
#include <stdlib.h>
//生成世界事件的ini配置
using namespace std;
int usage(char* argv0)
{
	cout << argv0 << " [days] [input_xml] [output_ini]" << endl;
	return -1;
}

int main(int argc, char** argv)
{
	if(argc < 4)
	{
		return usage(argv[0]);
	}

	int days = atoi(argv[1]); //循环天数
	ofstream output(argv[3]);

	if(!output.good())
	{
		cout << "open file[" << argv[3] << "] fail" << endl;
		return -1; 
	}

	CConfworldevent config;
	if(config.read_from_xml(argv[2]) != 0)
	{
		cout << "read xml[" << argv[2] << "fail" << endl;
		return -1;
	}

	srand(time(NULL));

	CONF_MAP_worldevent::iterator it;
	CConfItemworldevent* pconf;
	int randnum = 0;
	int selectedid = 0;

	int race[1] = {1};
	const int common = 3;
	unsigned int k;
	for(k=0; k<sizeof(race)/sizeof(race[0]); ++k)
	{
		output << "[WORLD_EVENT_" << race[k] << "]" << endl;
		output << "DAYS=" << days << endl;
		for(int i=0; i<days; ++i)
		{
			selectedid = 0;
			randnum = rand()%100;
		//cout << "--------------------------" << randnum <<  endl;
			for(it = config.mapworldevent.begin(); it!=config.mapworldevent.end(); ++it)
			{
				pconf = &(it->second);
				if(pconf->Camp != common && pconf->Camp != race[k])
				{
					continue;
				}
			//cout << "rand=" << randnum << ",chance=" << pconf->Chance << endl;
				if(randnum < pconf->Chance)
				{
					selectedid = pconf->SJEventID;
					break;
				}
				else
				{
					randnum -= pconf->Chance;
				}
			}

			output << "DAY" << i << "=" << selectedid << endl;
		}
	}

	output.close();

	//check it
	CIniFile oini(argv[3]);
	if(!oini.IsValid())
	{
		cout << "open ini[" << argv[3] << "]fail" << endl;
		return -1;
	}

	int total;
	int theevent;
	char temp[16];
	char sector[32];
	
	for(k=0; k<sizeof(race)/sizeof(race[0]); ++k)
	{
		cout << "---------------------------------------------------" << endl;
		snprintf(sector, sizeof(sector), "WORLD_EVENT_%d", race[k]);
		if(oini.GetInt(sector, "DAYS", 0, &total) != 0)
		{
			cout << "get [DAYS] fail" << endl;
			return -1;
		}

		cout << "DAYS=" << total << endl;

		for(int j=0; j<total; ++j)
		{
			snprintf(temp, sizeof(temp), "DAY%d", j);
			if(oini.GetInt(sector, temp, 0, &theevent) !=0)
			{
				cout << "get [DAY" << j << "]" << endl;
				return -1;
			}

			cout << "DAY" << j << "=" << theevent << endl;
		}
	}

	return 0;
}

