//
//  ClientConnect.cpp
//  HelloLua
//
//  Created by hankai on 16/3/9.
//
//

#include "ClientConnect.h"
#include "CmdLogin.pb.h"
#include "cmd_define.pb.h"
#include "heartBeatResp.pb.h"

#include "AppManager.h"

bool ClientConnect::onRecevie(){
    
    if (m_inputBuffer.readableBytes() < 51) {
        return false;
    }
    const char * p = m_inputBuffer.peek();
    if (std::string(p,6) != "BINPRO") {
        CCLOGERROR("error : BINPRO mark");
        return false;
    }
    
    memcpy(&m_netPacket.head, p, sizeof(NetPacket::Head));
    if (m_netPacket.head.useOrder) {
        m_netPacket.head.size = ntohl(m_netPacket.head.size);
        m_netPacket.head.cmd = ntohl(m_netPacket.head.cmd);
        m_netPacket.head.result = ntohl(m_netPacket.head.result);
    }
    if(m_inputBuffer.readableBytes() < m_netPacket.head.size){
        return false;
    }
    
    m_inputBuffer.retrieve(sizeof(NetPacket::Head));
    
    if (m_netPacket.head.result != 0) {
        
        if(m_netPacket.getProtoSize() > 0){
            m_netPacket.proto_buf = (char *)m_inputBuffer.peek();
            m_inputBuffer.retrieve(m_netPacket.getProtoSize());
        }
        
        CCLOGERROR("error : pkg.head.result != 0");
        return false;
    }

    m_netPacket.proto_buf = (char *)m_inputBuffer.peek();
    
    auto director = cocos2d::Director::getInstance();
    director->getEventDispatcher()->dispatchCustomEvent(NetOnRecevie,&m_netPacket);
    
    director->getEventDispatcher()->dispatchCustomEvent(cocos2d::__String::createWithFormat("%s%d",NetOnRecevie,m_netPacket.head.cmd)->getCString(),&m_netPacket);
    
    //heartbeat
    if(m_netPacket.head.cmd == CMD_HEART_BEAT_RESP){
        HeartBeatResp hb;
        hb.ParseFromArray(m_netPacket.proto_buf, m_netPacket.getProtoSize());
        if (hb.result() == HeartBeatResp::OK) {
            m_recvHeartbeatTime = 0;
            m_serverNowTime = hb.nowtime();
        }
    }
    
    m_inputBuffer.retrieve(m_netPacket.getProtoSize());
    return true;
    
}

NetPacket & ClientConnect::getRecvProtobuf(){
    return m_netPacket;
}

void ClientConnect::onConnect(bool ret){
    
    if(!ret){
        CCLOG("connect server failed!");
		AppManager::getInstance().connectCallback(false);
        return;
    }
    
    CCLOG("connect server success!");
    //if (m_state == NET_STATE_RECONNECTING) {
        m_recvHeartbeatTime = 0;
        AppManager::getInstance().connectCallback(true);
    //}
}

void ClientConnect::onError(){
    
    CCLOG("connect server error!");
	AppManager::getInstance().connectOnError();
    //reconnect();
}

void ClientConnect::onHeartbeat(){
    send(CMD_HEART_BEAT_REQ, 0, 0);
}

void ClientConnect::send(int cmd,const std::string & userName,const google::protobuf::MessageLite & proto){
    
    std::string out = proto.SerializeAsString();
    size_t size = out.length();
    
    NetPacket pkg;

    strcpy(pkg.head.userName, userName.c_str());
    
    if (!CC_HOST_IS_BIG_ENDIAN) {
        pkg.head.useOrder = 1;
        pkg.head.size = htonl(size + sizeof(NetPacket::Head));
        pkg.head.cmd = htonl(cmd);
    }

    sendData((char *)&pkg.head, sizeof(NetPacket::Head),false);
    sendData(out.c_str(), size);
}

void ClientConnect::send(int cmd,size_t bufSize,const char * buf){

    NetPacket pkg;
    
    std::string user_id = cocos2d::UserDefault::getInstance()->getStringForKey("user_id");
    if (user_id.empty()) {
        CCLOG("error: user_id is empty!!!!!!");
        return;
    }
    
    strcpy(pkg.head.userName, user_id.c_str());
    
    if (!CC_HOST_IS_BIG_ENDIAN) {
        pkg.head.useOrder = 1;
        pkg.head.size = htonl(bufSize + sizeof(NetPacket::Head));
        pkg.head.cmd = htonl(cmd);
    }
    
    sendData((char *)&pkg.head, sizeof(NetPacket::Head),false);
    sendData(buf, bufSize);
}