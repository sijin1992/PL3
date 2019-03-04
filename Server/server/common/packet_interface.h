#ifndef __PACTET_INTERFACE_H__
#define __PACTET_INTERFACE_H__

#include "net/epoll_wrap.h"
#include "msg_define.h"
#include <arpa/inet.h>
#include <string.h>
#include <iostream>
using namespace std;

#define PROTOCOL_TYPE_RAW 0
#define PROTOCOL_TYPE_BIN 1 
#define PROTOCOL_TYPE_END 2
//��Ѷtgw��Ҫ�Զ���Э��tcp���Ӻ��һ������httpͷ
//�ͻ��˷��͵�����һ��http��������˺���֮
#define TWG_HTTP_HEAD "GET / HTTP/1.1"
#define TWG_HTTP_HEAD_LEN 14


class CBinPackInterface: public CPacketInterface
{
public:
	CBinPackInterface();

	void bind_flag(int* flag);

	virtual int get_packet_len(const char* buff, unsigned int buffLen, unsigned int& packetLen) ;
	
protected:
	BIN_PRO_HEADER *m_phead;
	int* m_bindFlag;
};

class CBinPackInterfaceNormal: public CBinPackInterface
{
public:
	virtual int get_packet_len(const char* buff, unsigned int buffLen, unsigned int& packetLen) ;
};


/**
*end�ǰ��Ľ�β
*/
class CEndPackInterface: public CPacketInterface
{
public:
	CEndPackInterface(const char* endFlag, unsigned int endFlagLen);

	~CEndPackInterface();

	virtual int get_packet_len(const char* buff, unsigned int buffLen, unsigned int& packetLen) ;
	
protected:
	char* m_endFlag;
	unsigned int m_endLen;
};

/**
*�ֽ�����
*/
class CRawPackInterface: public CPacketInterface
{
public:
	virtual int get_packet_len(const char* buff, unsigned int buffLen, unsigned int& packetLen) ;

};

#endif

