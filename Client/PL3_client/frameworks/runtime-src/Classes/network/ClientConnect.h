//
//  ClientConnect.h
//  HelloLua
//
//  Created by hankai on 16/3/9.
//
//

#ifndef ClientConnect_h
#define ClientConnect_h

#include "cocos2d.h"
#include "TCPSession.h"
#include <google/protobuf/message_lite.h>
#include "NetPacket.h"
#define NetOnRecevie "ClientConnect::onReceviePacket"

class ClientConnect : public TCPSession{
public:
    void send(int cmd,const std::string & userName,const google::protobuf::MessageLite & proto);
    void send(int cmd,size_t bufSize,const char * buf);
    
    NetPacket & getRecvProtobuf();
protected:
    virtual bool onRecevie();
    
    virtual void onConnect(bool ret);
    virtual void onError();
    virtual void onHeartbeat();
    
private:
    NetPacket m_netPacket;
};

#endif /* ClientConnect_h */
