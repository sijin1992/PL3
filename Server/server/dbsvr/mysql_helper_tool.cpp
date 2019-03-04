#include "data_cache/data_cache_api.h"
#include <iostream>
#include <string.h>
#include "lock/lock_sem.h"
#include "logic/msg_queue.h"
#include "logic/toolkit.h"
#include <string>
#include "common/msg_define.h"
#include "time/calculagraph.h"

using namespace std;

CToolkit tool;
string gUserPre;
int gUserMaxCnt;
CMsgQueuePipe* pqueue;
int gSleepus;

int help(char* self)
{
	cout << self << " [pipe_ini] [queue_id] [cmd] [userpre] [usermaxcnt] [usleep ervery 10 req]... " << endl;
	cout << "cmd=get: [colcnt] [loops]" << endl;
	cout << "cmd=set: [colcnt] [colsize] [loops]" << endl;
	cout << "cmd=create: [colcnt] [colsize]" << endl;
	return 0;
}

int fill_set_req(CDataBlockSet& theSet, int colcnt, char* data, int colsize)
{
	DataBlockSet& blockSet = theSet.get_obj();
	for(int i=0; i<colcnt; ++i)
	{
		DataBlock* ptheBlock = blockSet.add_blocks();
		ptheBlock->set_id(i);
		ptheBlock->set_buff(data, colsize);
	}

	return 0;
}

int fill_get_req(CDataBlockSet& theSet, int colcnt)
{
	DataBlockSet& blockSet = theSet.get_obj();
	for(int i=0; i<colcnt; ++i)
	{
		DataBlock* ptheBlock = blockSet.add_blocks();
		ptheBlock->set_id(i);
	}

	return 0;
}


void do_recv(bool silent = true)
{
	int i=0;
	while(true)
	{
		CLogicMsg msg(tool.readBuff, sizeof(tool.readBuff));
		int ret = pqueue->get_msg(msg);
		if(ret == pqueue->OK)
		{
			unsigned int cmd = tool.get_cmd(msg);
			USER_NAME user;
			CDataBlockSet theSet;
			if(tool.parse_protobuf_msg(0, msg, user, theSet.get_obj())!=0)
			{
				cout << "msg(cmd=" <<  cmd << ") not valid" << endl;
				break;
			}

			++i;
		}
		else if(ret != pqueue->EMPTY)
		{
			cout << "get msg fail " << ret << endl;
			break;
		}
		else
		{
			 break;
		}
	}

	if(!silent)
		cout << "recv " << i << " msgs" << endl;
}

void do_send(unsigned int cmd, USER_NAME& user, CDataBlockSet& theSet)
{
	if(tool.send_protobuf_msg(0, theSet.get_obj(), cmd, user, pqueue) != 0)
	{
		cout << "send_bin_msg_to_queue(" << cmd << ") fail" << endl;
	}
}

int do_set(int argc, char** argv)
{
	if(argc < 3)
	{
		return -1;
	}

	int colcnt = atoi(argv[0]);
	int colsize = atoi(argv[1]);
	int loops = atoi(argv[2]);
	char* data = new char[colsize];
	memset(data, 'y', colsize-1);
	data[colsize-1] = 0;
	
	CDataBlockSet theSet;
	if(fill_set_req(theSet, colcnt, data, colsize)!=0)
	{
		return help(argv[0]);
	}

	char namebuf[USER_NAME_BUFF_LEN];
	int namelen;
	CCalculagraph cc(cout);

	cout << "set col[" << colcnt << "*" << colsize << "]" << endl;
	for(int i=0; i<loops; ++i)
	{
		USER_NAME user;
		namelen = snprintf(namebuf, sizeof(namebuf), "%s%d", gUserPre.c_str(), rand()%gUserMaxCnt);
		user.str(namebuf,namelen);

		do_send(CMD_DBCACHE_SET_REQ, user, theSet);

		if(i%10 == 9)		
		{
			usleep(gSleepus);
			do_recv();
		}
	}

	cout << "time:";
	cc.stop();
	cout << endl;

	return 0;
}


int do_create(int argc, char** argv)
{
	if(argc < 2)
	{
		return -1;
	}

	int colcnt = atoi(argv[0]);
	int colsize = atoi(argv[1]);
	char* data = new char[colsize];
	memset(data, 'x', colsize-1);
	data[colsize-1] = 0;
	
	CDataBlockSet theSet;
	if(fill_set_req(theSet, colcnt, data, colsize)!=0)
	{
		return 0;
	}

	char namebuf[USER_NAME_BUFF_LEN];
	int namelen;
	CCalculagraph cc(cout);

	cout << "create col[" << colcnt << "*" << colsize << "]" << endl;
	for(int i=0; i<gUserMaxCnt; ++i)
	{
		USER_NAME user;
		namelen = snprintf(namebuf, sizeof(namebuf), "%s%d", gUserPre.c_str(), i);
		user.str(namebuf,namelen);

		do_send(CMD_DBCACHE_CREATE_REQ, user, theSet);

		if(i%10 == 9)
		{
			usleep(gSleepus);
			do_recv();
		}
	}

	cout << "time:";
	cc.stop();
	cout << endl;

	return 0;
}

int do_get(int argc, char** argv)
{
	if(argc < 2)
	{
		return -1;
	}

	int colcnt = atoi(argv[0]);
	int loops = atoi(argv[1]);
	
	CDataBlockSet theSet;
	if(fill_get_req(theSet, colcnt)!=0)
	{
		return 0;
	}

	char namebuf[USER_NAME_BUFF_LEN];
	int namelen;
	CCalculagraph cc(cout);

	cout << "get col[" << colcnt << "]" << endl;
	for(int i=0; i<loops; ++i)
	{
		USER_NAME user;
		namelen = snprintf(namebuf, sizeof(namebuf), "%s%d", gUserPre.c_str(), rand()%gUserMaxCnt);
		user.str(namebuf,namelen);

		do_send(CMD_DBCACHE_GET_REQ, user, theSet);

		if(i%10 == 9)	
		{
			do_recv();
			usleep(gSleepus);
		}
	}

	cout << "time:";
	cc.stop();
	cout << endl;

	return 0;
}

int main(int argc, char** argv)
{
	if(argc < 7)
	{
		return help(argv[0]);
	}

	int id = atoi(argv[2]);
	string cmd = argv[3];
	gUserPre = argv[4];
	gUserMaxCnt = atoi(argv[5]);
	gSleepus = atoi(argv[6]);
	//queue pipe
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[1])!= 0)
	{
		cout << "parse ini fail " << endl;
		return -1;
	}

	CDequePIPE pipe;
	if(pipe.init(pipeconfig, id, true) != 0)
	{
		cout << "pipe init" << pipe.errmsg() << endl;
		return -1;
	}
	CMsgQueuePipe queue(pipe);
	pqueue = &queue;

	//收光老的
	do_recv(false);

	int newargc = argc-7;
	char** newargv = NULL;
	if(newargc > 0)
	{
		newargv = &argv[7];
	}

	if(cmd == "set")
	{
		if(do_set(newargc, newargv)!=0)
			return help(argv[0]);
	}
	else if(cmd == "create")
	{
		if(do_create(newargc, newargv)!=0)
			return help(argv[0]);
	}
	else if(cmd == "get")
	{
		if(do_get(newargc, newargv)!=0)
			return help(argv[0]);
	}
	else
	{
		cout << "cmd=" << cmd << " not valid" << endl;
		return help(argv[0]);
	}

	//等待一下
	sleep(1);
		do_recv(false);

	return 0;
}

