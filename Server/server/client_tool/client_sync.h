#ifndef __CLIENT_SYNC_H__
#define __CLIENT_SYNC_H__

#include "client_interface.h"
#include <sstream>

#include "proto/room_sync.pb.h"

class CClientSyncOnLogin: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "sync";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		/*if(argc < 3)
		{
			return false;
		}*/
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_TEST;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_ROOM_SYNC_ON_LOGIN;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	RoomSyncResp resp;
};


class CClientSync: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "sync";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		/*if(argc < 3)
		{
			return false;
		}*/
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_TEST;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_SYNC_ROOM_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	RoomSyncResp resp;
};

class CClientMove: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "client move";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc != 2)
		{
			return false;
		}
		req.set_posi_x(atoi(argv[0]));
		req.set_posi_y(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_MOVE_IN_ROOM_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_SYNC_ROOM_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return NULL;//&resp;
	}

protected:
	PlayerMoveInRoomReq req;
	//RoomSyncResp resp;
};


#endif

