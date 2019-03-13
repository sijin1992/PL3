//
//  TCPSession.h
//  hellogame
//
//  Created by hankai on 16/2/26.
//
//

#ifndef TCPSession_h
#define TCPSession_h

#include "NetSocket.h"
#include "NetBuffer.h"

enum ENetState
{
    NET_STATE_ZERO = 0,
    NET_STATE_CONNECTING,
    NET_STATE_RECONNECTING,
    NET_STATE_CONNECTED,
    NET_STATE_ERROR,
};

const unsigned int NET_CONNECT_TIMEOUT = 10;

class TCPSession {
public:
    TCPSession();
    ~TCPSession();
    
    bool connect(const char *remote, int port, char *bindIp = 0, int bindPort = 0);
    void runLoop(float dt);
    
    void reset();
    
    void sendData(const char * data,size_t len,bool flush = true);

    void reconnect();
    
    time_t getServerNowTime(){ return m_serverNowTime;}
protected:
    virtual bool onRecevie() = 0;
    
    virtual void onConnect(bool ret) = 0;
    virtual void onError() = 0;
    virtual void onHeartbeat() = 0;
    bool readData();
    void flushData();
    
    void processData(float dt);//消息循环函数//state已经连接该函数才有效
    
    time_t m_connTime;
    time_t m_serverNowTime;//use time(NULL);
    float m_recvHeartbeatTime;
    
    std::string m_remoteIp;
    int m_remotePort;
    
    ENetState m_state;
    
    NetSocket m_socket;
    
    NetBuffer m_inputBuffer,m_outputBuffer;
};



#endif /* TCPSession_h */
