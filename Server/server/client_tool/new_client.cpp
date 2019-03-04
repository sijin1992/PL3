#include "all_client.h"
#include "common/msg_define.h"
#include "cmd_reader.h"
#include <map>
#include <iostream>
#include <sstream>
#include <pthread.h>
using namespace std;

void help(const char* self, CLIENT_MAP& themap)
{
	cout << self << " [svr_ip] [svr_port] [userName] [userKey]  ..." << endl;
	for(CLIENT_MAP::iterator it=themap.begin(); it!=themap.end(); ++it)
	{
		cout << "command(" << it->first << "): ";
		it->second->help(cout);
		cout << endl;
	}
}


CLIENT_MAP theReqMap;
CLIENT_MAP theRespMap;
CTcpClient tcpClient;
CCmdReader *pCmdReader= NULL;
void * recv_thread_main(void* x)
{
	char buffer[100*1024];
	CBinProtocol binpro;
	binpro.bind(buffer, sizeof(buffer));
	int err = 0;
	while(true)
	{
		if(err)
		{
			sleep(1);
			err = 0;
		}

		if(tcpClient.recieve(binpro.buff(), binpro.total_len(0)) < 0)
		{
			pCmdReader->close();
			cout << "recv head fail|" << tcpClient.errmsg() << endl;
			err++;
			if(tcpClient.init(true)!=0)
			{
				cout << "client reconnected init fail "<< tcpClient.errmsg() << endl; 
				continue;
			}
			else
			{
				cout << "client reconnected. " << endl; 
				err = 0;
			}
			continue;
		}
		if(binpro.head()->parse_result() != COMMON_RESULT_OK)
		{
			cout << "result from head=" << binpro.head()->parse_result() << endl;
			continue;
		}
		pCmdReader->close();
		int len = binpro.head()->parse_len();
		unsigned int cmd = binpro.head()->parse_cmd();

		cout << "recved cmd=" << hex << "(0x" << hex << cmd  << dec << ") msg_len=" << len << " proto_len=" << len - binpro.total_len(0) << endl;
		
		if(tcpClient.recieve(binpro.packet(), len - binpro.total_len(0)) < 0)
		{
			cout << "recv packet fail|" << tcpClient.errmsg() << endl;
			continue;
		}

		if(theRespMap.find(cmd) == theRespMap.end())
		{
			cout << "cmd" << cmd << "(0x" << hex << cmd << dec << ") not in resp map" << endl;
		}
		else
		{
			binpro.bind(buffer, len);
			theRespMap[cmd]->on_recv(binpro, cout); 
		}
		pCmdReader->open();
	}
}

int main(int argc, char** argv)
{
	CAllClient::fill_req_map(theReqMap);
	CAllClient::fill_resp_map(theRespMap);

	//NEW_CMD_CLIENT_XXX
	if(argc < 4)
	{
		help(argv[0], theReqMap);
		return 0;
	}
	bool useCurses = true;
	if( argc > 5 )
	{
		useCurses = atoi(argv[5]) != 0;
	}
	
	cout << "type \"exit\" to finish" << endl;

	tcpClient.add_server(argv[1], atoi(argv[2]));
	tcpClient.config()->timeout = 0;
	if(tcpClient.init(true)!=0)
	{
		cout << "tcp(" << argv[1] <<  "," << atoi(argv[2]) << ") init fail "<< tcpClient.errmsg() << endl; 
		return 0;
	}
	
	CCmdReader cmdReader(cin, cout);
	cmdReader.setUseCurses(useCurses);
	pCmdReader = &cmdReader;
	//start read thread
	pthread_t tid;
	int ret = pthread_create(&tid, NULL, recv_thread_main, NULL);
	if(ret != 0)
	{
		cout << "pthread_create = " << ret << endl;
	}

	int cmd = 0;
	int argcR = 0;
	char** argvR = NULL;
	while(true)
	{
		istringstream is;
		string strCmd;
		//getline(cin, buff);
		strCmd = cmdReader.readCmd();
		if(strCmd == "exit")
		{
			pthread_cancel(tid);
			return 0;
		}
		else if(strCmd == "ignore")
		{
			continue;
		}
		else
		{
			cout << "do cmd line: " << strCmd << endl;
			if(strCmd.find("0x") != string::npos)
			{
				cmd = strtoul(strCmd.c_str(), NULL, 16);
			}
			else
			{
				cmd = atoi(strCmd.c_str());
			}
			// 重写参数
			is.str(strCmd);
			is >> strCmd; //去掉命令ID
			argcR = 0;
			argvR = new char* [255]; 
			while(!is.eof())
			{
				string word;
				is >> word;
				//cout << "get word: " << word << "good=" << is.good() << "fail=" << is.fail()
					//<< "eof=" << is.eof() << endl;
				int len = word.length()+1; 
				argvR[argcR] = new char[len];
				snprintf(argvR[argcR],len , "%s", word.c_str());
				++argcR;
			}
		}

		if(theReqMap.find(cmd) == theReqMap.end())
		{
			cout << "cmd:" << cmd << "(0x" << hex << cmd << dec << ") not found" << endl;
			help(argv[0], theReqMap);
			continue;
		}

		CClientInterface* theClient = theReqMap[cmd];
		string sUserKey(argv[3]);
		theClient->set_param(&tcpClient, &cout, argv[3], sUserKey.c_str());
		if(!theClient->send(argcR, argvR))
		{
			continue;
		}
		//删申请的资源
		for(int i=0; i<argcR; ++i)
		{
			delete[] argvR[i];
		}
		delete[] argvR;
	}

	return 0;
}


