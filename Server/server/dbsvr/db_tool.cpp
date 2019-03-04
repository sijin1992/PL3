#include "data_cache/data_cache_api.h"
#include <iostream>
#include <string.h>
#include "process_manager/process_manager.h"
#include "lock/lock_sem.h"
#include "logic/msg_queue.h"
#include "logic/toolkit.h"
#include <string>
#include "common/msg_define.h"

using namespace std;

CToolkit tool;

int help(char* self)
{
	cout << self << " [pipe_ini] [queue_id] [cmd] ... " << endl;
	cout << "cmd=get: [user] [id0] [id1] ..." << endl;
	cout << "cmd=set: [user] [id0] [data0] [id1] [data1] ..." << endl;
	cout << "cmd=create: [user] [id0] [data0] [id1] [data1] ..." << endl;
	cout << "cmd=lockget: [user] [id0] [id1] ..." << endl;
	cout << "cmd=unlockset: [user] [id0] [data0] [id1] [data1]..." << endl;
	cout << "cmd=unlock: [user] [id0]  [id1] ..." << endl;
	return 0;
}

int fill_unlock_req(CDataBlockSet& theSet, int argc, char**argv)
{
	if(argc <= 0)
	{
		return -1;
	}

	DataBlockSet& blockSet = theSet.get_obj();
	for(int i=0; i<argc; ++i)
	{
		DataBlock* ptheBlock = blockSet.add_blocks();
		ptheBlock->set_id(atoi(argv[i]));
		ptheBlock->set_unlock(1);
	}

	return 0;
}

int fill_set_req(CDataBlockSet& theSet, int argc, char**argv, bool unlock)
{
	if(argc%2 !=0 ||  argc<=0)
	{
		return -1;
	}

	DataBlockSet& blockSet = theSet.get_obj();
	for(int i=0; i<argc; ++i)
	{
		DataBlock* ptheBlock = blockSet.add_blocks();
		ptheBlock->set_id(atoi(argv[i++]));
		ptheBlock->set_buff(argv[i]);
		if(unlock)
			ptheBlock->set_unlock(1);
	}

	return 0;
}

int fill_get_req(CDataBlockSet& theSet, int argc, char**argv, bool lock)
{
	if(argc <= 0)
	{
		return -1;
	}

	DataBlockSet& blockSet = theSet.get_obj();
	for(int i=0; i<argc; ++i)
	{
		DataBlock* ptheBlock = blockSet.add_blocks();
		ptheBlock->set_id(atoi(argv[i]));
		if(lock)
			ptheBlock->set_lock(10);
	}

	return 0;
}


void wait_result(CMsgQueuePipe* queue)
{
	int i;
	for(i=0; i<10; ++i)
	{
		usleep(100*1000);
		CLogicMsg msg(tool.readBuff, sizeof(tool.readBuff));
		int ret = queue->get_msg(msg);
		if(ret == queue->OK)
		{
			unsigned int cmd = tool.get_cmd(msg);
			USER_NAME user;
			CDataBlockSet theSet;
			if(tool.parse_protobuf_msg(0, msg, user, theSet.get_obj())!=0)
			{
				cout << "msg(cmd=" <<  cmd << ") not valid" << endl;
				break;
			}

			cout << "cmd=0x" << hex << cmd << dec << endl;
			cout << theSet.get_obj().DebugString() << endl;
			
			break;
		}
		else if(ret != queue->EMPTY)
		{
			cout << "get msg fail " << ret << endl;
			break;
		}
	}

	if(i==10)
		cout << "timeout" << endl;
}

void do_send_wait(unsigned int cmd, USER_NAME& user, CDataBlockSet& theSet, CMsgQueuePipe* queue)
{
	cout << "req: " << endl << theSet.get_obj().DebugString() << endl;
	if(tool.send_protobuf_msg(0, theSet.get_obj(), cmd, user, queue) != 0)
	{
		cout << "send_bin_msg_to_queue(" << cmd << ") fail" << endl;
	}
	else
	{
		wait_result(queue);
	}
}


int main(int argc, char** argv)
{
	if(argc < 5)
	{
		return help(argv[0]);
	}

	int id = atoi(argv[2]);
	string cmd = argv[3];

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

	USER_NAME user;
	user.from_str(argv[4]);
	int newArgc = argc - 5;
	char** newArgv = NULL;
	if(newArgc)
	{
		newArgv = &(argv[5]);
	}
	CDataBlockSet theSet;

	if(cmd == "set")
	{
		if(fill_set_req(theSet, newArgc, newArgv, false)!=0)
		{
			return help(argv[0]);
		}

		do_send_wait(CMD_DBCACHE_SET_REQ, user, theSet, &queue);
	}
	else if(cmd == "create")
	{
		if(fill_set_req(theSet, newArgc, newArgv, false)!=0)
		{
			return help(argv[0]);
		}

		do_send_wait(CMD_DBCACHE_CREATE_REQ, user, theSet, &queue);
	}
	else if(cmd == "unlockset")
	{
		if(fill_set_req(theSet, newArgc, newArgv, true)!=0)
		{
			return help(argv[0]);
		}

		do_send_wait(CMD_DBCACHE_SET_REQ, user, theSet, &queue);
	}
	else if(cmd == "unlock")
	{
		if(fill_unlock_req(theSet, newArgc, newArgv)!=0)
		{
			return help(argv[0]);
		}

		do_send_wait(CMD_DBCACHE_SET_REQ, user, theSet, &queue);
	}
	else if(cmd == "get")
	{
		if(fill_get_req(theSet, newArgc, newArgv, false)!=0)
		{
			return help(argv[0]);
		}
		
		do_send_wait(CMD_DBCACHE_GET_REQ, user, theSet, &queue);
	}
	else if(cmd == "lockget")
	{
		if(fill_get_req(theSet, newArgc, newArgv, true)!=0)
		{
			return help(argv[0]);
		}
		
		do_send_wait(CMD_DBCACHE_GET_REQ, user, theSet, &queue);
	}
	else
	{
		cout << "cmd=" << cmd << " not valid" << endl;
	}

	return 0;
}

