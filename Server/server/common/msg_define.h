#ifndef __MSG_DEFINE_H__
#define __MSG_DEFINE_H__


#include <arpa/inet.h>
#include <string.h>
#include <iostream>
#include "struct/hash_map.h"
#include <string>
#include "binary/binary_util.h"
#include "proto/cmd_define.pb.h"
using namespace std;

#define MSG_BUFF_LIMIT (100*1024)
#define RECV_PACK_SZIE_LIMIT (MSG_BUFF_LIMIT-1024)
//一个用户最多有DATA_BLOCK_ARRAY_MAX个bucketList
#define DATA_BLOCK_ARRAY_MAX 10

#define USER_NAME_LEN 32
#define USER_NAME_BYTE_LEN (USER_NAME_LEN/2)
#define USER_KEY_LEN 128
#define USER_NAME_BUFF_LEN (USER_NAME_LEN+1)
#define USER_KEY_BUFF_LEN (USER_KEY_LEN+1)
#define BIN_PRO_HEADER_MAGIC "BINPRO"
#define BIN_PRO_HEADER_MAGIC_LEN 6

enum ALL_DATA_BLOCK_FLAG
{
	DATA_BLOCK_FLAG_MAIN=1,
	DATA_BLOCK_FLAG_SHIP =(1<<1),
	DATA_BLOCK_FLAG_ITEMS =(1<<2),
	DATA_BLOCK_FLAG_MAIL = (1<<3)
};

enum ALL_MSG_CMD
{
	CMD_BORDER_INNER = 0x0, //内部命令
	CMD_SESSION_REQ /*= 0x1*/,
	CMD_SESSION_RESP /*= 0x2*/,
	
	CMD_AUTH_REQ =0x11, //鉴权服务
	CMD_AUTH_RESP /*=0x12*/,
	CMD_AUTH_TIMEOUT_REQ /*=0x13*/,
	CMD_AUTH_TIMEOUT_RESP /*=0x14*/,
	
	CMD_DBCACHE_GET_REQ = 0x21, //dbcache命令
	CMD_DBCACHE_GET_RESP /*0x22*/, 
	CMD_DBCACHE_SET_REQ /*=0x23*/,
	CMD_DBCACHE_SET_RESP /*=0x24*/,
	CMD_DBCACHE_CREATE_REQ /*=0x25*/,
	CMD_DBCACHE_CREATE_RESP /*=0x26*/,
	CMD_DBCACHE_TIMEOUT_REQ /*=0x27*/,
	CMD_DBCACHE_TIMEOUT_RESP /*=0x28*/,
	CMD_DBCACHE_LOGOUT_REQ	/*=0x29*/,
	CMD_DBCACHE_LOGOUT_RESP /*=0x2A*/,
	CMD_DBCACHE_LOGIN_GET_REQ  /*=0x2B*/,
	ALIAS_LOGIN_GET_TO_GET_RESP  /*=0x2D*/,
	
	CMD_DBCACHE_GET_USERGROUP_REQ = 0x31,
	CMD_DBCACHE_GET_USERGROUP_RESP /*=0x32*/,
	CMD_DBCACHE_SET_USERGROUP_REQ /*=0x33*/,
	CMD_DBCACHE_SET_USERGROUP_RESP /*=0x34*/,
	CMD_DBCACHE_CREATE_USERGROUP_REQ /*=0x35*/,
	CMD_DBCACHE_CREATE_USERGROUP_RESP /*=0x36*/,
	CMD_DBCACHE_TIMEOUT_USERGROUP_REQ /*=0x37*/,
	CMD_DBCACHE_TIMEOUT_USERGROUP_RESP /*=0x38*/,

	CMD_DBCACHE_ADD_ITEM_REQ = 0x51,
	CMD_DBCACHE_ADD_ITEM_RESP /*=0x52*/,

	CMD_DBCACHE_SEND_MAIL_REQ = 0x61,
	//CMD_DBCACHE_ADD_ITEM_RESP /*=0x62*/,
	CMD_DBCACHE_GM_RESP = 0x71,

	CMD_GM_ADD_ITEM_REQ = 0x81,
	CMD_GM_ADD_ITEM_RESP = 0x82,
	CMD_GM_SEND_MAIL_REQ = 0x83,
	CMD_GM_SEND_MAIL_RESP = 0x84,
	CMD_GM_RESP = 0x85,
	CMD_GM_GET_USER_SNAP_REQ = 0x86,
	CMD_GM_GET_USER_SNAP_RESP = 0x87,

	CMD_FLAG_GET_REQ = 0x101, //flag server命令
	CMD_FLAG_GET_RESP /*= 0x102*/,
	CMD_FLAG_SET_REQ /*= 0x103*/,
	CMD_FLAG_SET_RESP /*= 0x104*/,
	CMD_FLAG_ALIVE_REQ /*= 0x105*/,
	CMD_FLAG_ALIVE_RESP /*= 0x106*/,
	CMD_FLAG_TIMEOUT /*= 0x107*/,
	CMD_FLAG_TIMEOUT_RESP /*= 0x108*/,
	CMD_FLAG_RANK_GET_REQ  /*= 0x109*/,
	CMD_FLAG_RANK_GET_RESP /*= 0x10A*/,
	CMD_FLAG_RANK_SET_REQ /*= 0x10B*/,
	CMD_FLAG_RANK_SET_RESP /*= 0x10C*/,
	//排名更新通知
	CMD_FLAG_RANK_CALLBACK_REQ /*= 0x10D*/,
	CMD_FLAG_USER_RANK_GET_RESP /*= 0x10E*/,

	//cdkey
	CMD_FLAG_CDKEY_GET_REQ = 0x111,
	CMD_FLAG_CDKEY_GET_RESP /*= 0x112*/,
	CMD_FLAG_CDKEY_SET_REQ /*= 0x113*/,
	CMD_FLAG_CDKEY_SET_RESP /*= 0x114*/,

	CMD_HTTPCB_ADDMONEY_REQ = 0x201, //http回调命令
	CMD_HTTPCB_ADDMONEY_RESP /*= 0x202*/,
	CMD_HTTPCB_GM_REQ /*= 0x203*/,
	CMD_HTTPCB_GM_RESP /*= 0x204*/,
	CMD_HTTPCB_BROADCAST_REQ /*= 0x205*/,
	CMD_HTTPCB_BROADCAST_RESP /*= 0x206*/,

	CMD_NOTIFY_LOGIC_INFO_REQ = 0x251,	//像选服服务器通报当前状况
	CMD_NOTIFY_LOGIC_INFO_RESP = 0x252,
	CMD_NOTIFY_GLOBALCB_REQ = 0x253,
	CMD_NOTIFY_GLOBALCB_RESP = 0x254,

	CMD_GATEWAY_LOG_REPORT_REQ = 0x301, //上报日志
	CMD_GATEWAY_LOG_REPORT_RESP  /*= 0x302*/,
	CMD_GATEWAY_USERINFO_REPORT_REQ  /*= 0x303*/, //向GAMESDK 上报
	CMD_GATEWAY_USERINFO_REPORT_RESP  /*= 0x304*/,

	CMD_GAME_LOG_REPORT_REQ = 0x311, //上报统计日志

	CMD_LOGIC_CHECKONLINE_REQ = 0x901, //logic内部循环的命令
	CMD_LOGIC_CHECKONLINE_RESP /*= 0x902*/,
	CMD_LOGIC_TOOL_MODIFY_ROLEINFO_REQ /*= 0x903*/,
	CMD_LOGIC_TOOL_MODIFY_RESP /*= 0x904*/,
	CMD_LOGIC_TOOL_MODIFY_ITEMS_REQ /*= 0x905*/,
	ALIAS_TO_MODIFY_RESP/*= 0x906*/,

/*add new CMD here*/
	CMD_TEST = 0x5001,
	CMD_CHANNEL_CMD = 0x5101,
	CMD_SYNC_ROOM_RESP = 0x7000,
	CMD_BORDER_END,
// new system cmd
	CMD_LOGIC_SHIFT_MAP = 0x9001,

};

enum SESSION_FLAG
{
	SESSION_FLAG_ZERO=0,
	SESSION_FLAG_CLOSE=1,
	SESSION_FLAG_CHANNEL=2,
	SESSION_FLAG_ADD=3,		// 将socket加入指定列表供批量发送
	SESSION_FLAG_REMOVE=4,	// 将socket从指定列表移除
	SESSION_FLAG_SYNC=5,
	SESSION_FLAG_BROADCAST=6,
};

enum COMMON_RESULT
{
	COMMON_RESULT_OK=0,
	COMMON_RESULT_FAIL=-1
};


#pragma pack(push)
#pragma pack(1)

struct USER_NAME_BYTE
{
	unsigned char val[USER_NAME_BYTE_LEN];
	
	inline bool operator == (const USER_NAME_BYTE& other)
	{
		return memcmp(val, other.val, sizeof(val))==0;
	}

	inline bool operator != (const USER_NAME_BYTE& other)
	{
		return memcmp(val, other.val, sizeof(val))!=0;
	}
};

struct USER_NAME
{
	char val[USER_NAME_LEN];
	static char tmpval[USER_NAME_BUFF_LEN];
	USER_NAME()
	{
		memset(val, 0, sizeof(val));
	}

	//user_name是16进制数时，用来压缩
	//len为输入输出参数
	inline void tobyte(USER_NAME_BYTE& byte)  const
	{
		char c1,c2;
		int pos = 0;
		unsigned int i = 0;
		for(; i<USER_NAME_BYTE_LEN; ++i)
		{
			c1 = CBinaryUtil::char_val(val[pos++]);
			c2 = CBinaryUtil::char_val(val[pos++]);
//#ifdef __TEST__
			if(c1==-1 || c2==-1)
			{
				//含有非16进制数据，直接截断
				byte.val[0] = 0xFF;
				memcpy(byte.val+1,  val, sizeof(byte.val)-1);
				break;
			}
//#endif
			byte.val[i] = (c1<<4)+c2;
		}
	}

	//从byte获取16进制字符串
	inline void frombyte(const USER_NAME_BYTE& byte)
	{
		const char* convert = {"0123456789ABCDEF"};
		unsigned int pos = 0;
		
//#ifdef __TEST__
		if(byte.val[0] == 0xFF)
		{
			//含有非16进制数据，直接截断
			memcpy(val,	byte.val+1, sizeof(byte.val)-1);

			pos = sizeof(byte.val)-1;
			for(; pos<USER_NAME_LEN; ++pos)
			{
				val[pos] = 0;
			}

			return;
		}
//#endif
				

		
		for(unsigned int i=0; i<USER_NAME_BYTE_LEN; ++i)
		{
			val[pos++] = convert[byte.val[i] >>4];
			val[pos++] = convert[byte.val[i] & 0x0F];
		}

		for(; pos<USER_NAME_LEN; ++pos)
		{
			val[pos] = 0;
		}
	}
	
	inline const char* str(char* buff = NULL) const
	{
		if(buff == NULL)
		{
			strncpy(tmpval, val, USER_NAME_LEN);
			tmpval[sizeof(val)] = 0;
			return tmpval;
		}
		else
		{
			strncpy(buff, val, USER_NAME_LEN);
			buff[USER_NAME_LEN] = 0;
			return buff;
		}
	}

	inline int str(const char* cstr, int cstrlen)
	{
		if(cstrlen < USER_NAME_LEN)
		{
			memset(val, 0, USER_NAME_LEN);
		}
		strncpy(val, cstr, USER_NAME_LEN);
		return 0;
	}

	inline string to_str()  const
	{
		string ret(val, USER_NAME_LEN);
		return ret;
	}
	
	inline void from_str(const string& userStr)
	{
		if(userStr.length() < USER_NAME_LEN )
		{
			memset(val, 0, USER_NAME_LEN);
			memcpy(val, userStr.data(), userStr.length());
		}
		else
		{
			memcpy(val, userStr.data(), USER_NAME_LEN);
		}
	}

	inline void toNet() {}
	inline void toHost() {}
	inline bool operator == (const USER_NAME& other) const
	{
		return memcmp(val, other.val, sizeof(val))==0;
	}

	inline bool operator != (const USER_NAME& other) const
	{
		return memcmp(val, other.val, sizeof(val))!=0;
	}

};

struct UserHashType
{
	unsigned int do_hash(const USER_NAME& key) {return steal_stl_hash_string(key.val, sizeof(key.val));}
};

struct UserByteHashType
{
	unsigned int do_hash(const USER_NAME_BYTE& key) {return steal_stl_hash_string((char*)key.val, sizeof(key.val));}
};


struct USER_KEY
{
	char val[USER_KEY_BUFF_LEN];
	USER_KEY()
	{
		memset(val, 0, sizeof(val));
	}

	inline void from_str(const string& key)
	{
		snprintf(val,sizeof(val), "%s", key.c_str());
	}
	
	inline string to_str()
	{
		return val;
	}

	inline const char* str()
	{
		val[USER_KEY_BUFF_LEN-1] = 0;
		return val;
	}
};


struct BIN_PRO_HEADER
{
	char magic[BIN_PRO_HEADER_MAGIC_LEN];
	char useNetOrder;
	unsigned int packetLen;
	unsigned int cmd;
	int result;
	USER_NAME userName;

	void debug(ostream& os)
	{
		os << "BIN_PRO_HEADER{" << endl;
		os << "useNetOrder|" << (int)net_order() << endl;
		os << "packetLen|" << parse_len() << endl;
		os << "cmd|" << parse_cmd() << endl;
		os << "result|" << parse_result() << endl;
		os << "userName|" << userName.str() << endl;
		os << "} end BIN_PRO_HEADER" << endl;
	}

	inline bool valid()
	{
		return memcmp(magic, BIN_PRO_HEADER_MAGIC, BIN_PRO_HEADER_MAGIC_LEN)==0;
	}

	inline void set_cmd(unsigned int thecmd)
	{
		if(useNetOrder)
			cmd = ntohl(thecmd);
		else
			cmd = thecmd;
	}

	inline void format_fail(USER_NAME& theUserName, unsigned int thecmd,  bool buseNetOrder = true)
	{
		memcpy(magic, BIN_PRO_HEADER_MAGIC, BIN_PRO_HEADER_MAGIC_LEN);
		userName = theUserName;
		if(buseNetOrder)
		{
			useNetOrder = 1;
			packetLen = htonl(sizeof(BIN_PRO_HEADER));
			cmd = htonl(thecmd);
			result = htonl(COMMON_RESULT_FAIL);
			userName.toNet();
		}
		else
		{
			useNetOrder = 0;
			packetLen = sizeof(BIN_PRO_HEADER);
			cmd = thecmd;
			result = COMMON_RESULT_FAIL;
		}
	}

	inline void format(USER_NAME& theUserName, unsigned int thecmd, unsigned int thepacketLen, int theResult = COMMON_RESULT_OK, bool buseNetOrder = true)
	{
		memcpy(magic, BIN_PRO_HEADER_MAGIC, BIN_PRO_HEADER_MAGIC_LEN);
		userName = theUserName;
		if(buseNetOrder)
		{
			useNetOrder = 1;
			packetLen = htonl(thepacketLen);
			cmd = htonl(thecmd);
			result = htonl(theResult);
			userName.toNet();
		}
		else
		{
			useNetOrder = 0;
			packetLen = thepacketLen;
			cmd = thecmd;
			result = theResult;
		}
	}

	inline unsigned int parse_len()
	{
		if(useNetOrder)
			return ntohl(packetLen);
		else
			return packetLen;
	}

	inline unsigned int parse_cmd()
	{
		if(useNetOrder)
			return ntohl(cmd);
		else
			return cmd;
	}

	inline int parse_result()
	{
		if(useNetOrder)
			return ntohl(result);
		else
			return result;
	}

	inline bool net_order()
	{
		return useNetOrder!=0;
	}

	inline USER_NAME parse_name()
	{
		USER_NAME tmp = userName;
		if(useNetOrder)
		{
			tmp.toHost();
		}

		return tmp;
	}

	inline void reset_name(USER_NAME& theUserName)
	{
		userName = theUserName;
		if(useNetOrder == 1)
		{
			userName.toNet();
		}
	}

};


struct MSG_SESSION
{
	unsigned long long id;
	int fd;
	int flag; //控制信息
	int channel_id;	// 对于频道控制消息(加入，移除，同步等)有意义
};

enum CHANNEL_CMD
{
	CHANNEL_ADD=1,		// 将socket加入指定列表供批量发送
	CHANNEL_REMOVE=2,	// 将socket从指定列表移除
	CHANNEL_SYNC=3,
};

struct CHANNEL_CTRL
{
	int cmd;
	int channel_id;
};

struct MSG_COMMON_RESP
{
	int retCode;
	USER_NAME userName;
};

#pragma pack(pop)

#endif

