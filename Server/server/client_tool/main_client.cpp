#include "all_client.h"
#include "common/msg_define.h"
#include <map>
#include <iostream>
#include <sstream>
using namespace std;

void help(const char* self, CLIENT_MAP& themap)
{
	cout << self << " [svr_ip] [svr_port] [userName] [userKey] [command] ..." << endl;
	cout << "cmmand(0) interactive mode, type \"exit\" to finish" << endl;
	for(CLIENT_MAP::iterator it=themap.begin(); it!=themap.end(); ++it)
	{
		cout << "command(" << it->first << "): ";
		it->second->help(cout);
		cout << endl;
	}
}

int main(int argc, char** argv)
{
	CLIENT_MAP themap;
	CAllClient::fill_req_map(themap);
	//NEW_CMD_CLIENT_XXX
	
	if(argc < 6)
	{
		help(argv[0], themap);
		return 0;
	}

	CTcpClient tcpClient;
	tcpClient.add_server(argv[1], atoi(argv[2]));
	tcpClient.config()->timeout = 1;
	if(tcpClient.init(false)!=0)
	{
		cout << "tcp(" << argv[1] <<  "," << atoi(argv[2]) << ") init fail "<< tcpClient.errmsg() << endl; 
		return 0;
	}

	string buff;
	string word;
	int thecmd = atoi(argv[5]);
	int cmd = thecmd;
	string strCmd;
	int argcR = argc -6;
	char** argvR = argcR > 0 ? &(argv[6]):NULL;
	while(true)
	{
		do
		{
			if(thecmd == 0)
			{
				istringstream is;
				getline(cin, buff);
				cout << "do cmd line: " << buff << endl;
				is.str(buff);
				is >> strCmd;
				if(strCmd == "exit")
				{
					return 0;
				}
				else
				{
					cmd = atoi(strCmd.c_str());
					// 重写参数
					argcR = 0;
					argvR = new char* [255]; 
					while(is.good() && (unsigned int)argcR < sizeof(argvR)/sizeof(argvR[0]))
					{
						is >> word;
						//cout << "get word: " << word << endl;
						int len = word.length()+1;
						argvR[argcR] = new char[len];
						snprintf(argvR[argcR],len , "%s", word.c_str());
						++argcR;
					}
				}
			}

			if(themap.find(cmd) == themap.end())
			{
				cout << "cmd" << cmd << "(0x" << hex << cmd << dec << ") not found" << endl;
				help(argv[0], themap);
				break;
			}

			CClientInterface* theClient = themap[cmd];
			theClient->set_param(&tcpClient, &cout, argv[3], argv[4]);
			 
			//非交互模式下，非login命令要先login，以通过鉴权
			if(thecmd!=0 && cmd != CMD_LOGIN_REQ)
			{
				CClientInterface* login = new CClientLogin;
				login->set_param(&tcpClient, &cout, argv[3], argv[4]);
				if(!login->run(argcR, argvR))
				{
					cout << "login fail ......" << endl;
					break;
				}
			}
			
			if(!theClient->run(argcR, argvR))
			{
				break;
			}

		}while(false);

		if(thecmd != 0)
		{
			//非交互模式退出
			return 0;
		}
		else
		{
			//删申请的资源
			for(int i=0; i<argcR; ++i)
			{
				delete[] argvR[i];
			}
			delete[] argvR;
		}
	
	}

	return 0;
}


