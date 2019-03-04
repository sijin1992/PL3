//
//  TCPSession.cpp
//  hellogame
//
//  Created by hankai on 16/2/26.
//
//

#include "TCPSession.h"

#define HeartbeatSendTime 10//发送心跳时间
#define HeartbeatRecvTime 15//接收超时时间

TCPSession::TCPSession()
:m_state(NET_STATE_ZERO)
,m_connTime(0)
,m_remotePort(0)
,m_recvHeartbeatTime(0)
,m_serverNowTime(0)
{
    
}

TCPSession::~TCPSession(){
    reset();
}


void TCPSession::reset(){
    m_connTime = 0;
    m_state = NET_STATE_ZERO;
    m_socket.Close();
}

void TCPSession::reconnect(){
    if(!connect(m_remoteIp.c_str(),m_remotePort)){
        m_state = NET_STATE_ERROR;
    }
    m_state = NET_STATE_RECONNECTING;
}

bool TCPSession::connect(const char *remote, int port,char *bindIp,int bindPort){
    
    if(!m_socket.Initialize(NETWORK_PROTOCOL_TCP))
        return false;
    if(!m_socket.Bind(bindIp,bindPort))
        return false;
    
    m_remoteIp = remote;
    m_remotePort = port;
    
    if(m_socket.Connect(remote, port)){
        
        m_state = NET_STATE_CONNECTING;
        m_connTime = time(NULL);
        return true;
    }
    return false;
}



void TCPSession::sendData(const char * data,size_t len,bool flush){
    
    m_outputBuffer.append(data, len);
    
    if (flush) {
        flushData();
    }
}



void TCPSession::runLoop(float dt){
    
    if (m_state == NET_STATE_ZERO) {
        return;
    }
    
    processData(dt);
    
    switch (m_state) {
        case NET_STATE_CONNECTED:
            while(onRecevie()){
                
            }
            break;
        case NET_STATE_ERROR:
            reset();
            onError();
            break;
        case NET_STATE_CONNECTING:
        case NET_STATE_RECONNECTING:
            if(m_socket.HasExcept())//socket是否禁止读写
            {
                CCLOGERROR("connecting failed");
                reset();
                onConnect(false);
                break;
            }
            else if( time(NULL) - m_connTime > NET_CONNECT_TIMEOUT)
            {
                CCLOGERROR("connecting timeout");
                reset();
                onConnect(false);
                break;
            }else if(!m_socket.CanWrite()){
                CCLOGERROR("connecting !CanWrite");
                break;
            }
            onConnect(true);
            m_state = NET_STATE_CONNECTED;
            break;
        default:
            break;
    }
}

void TCPSession::processData(float dt){
    
    
    
    
    if(m_state != NET_STATE_CONNECTED) return;
    
    //心跳处理
    static float sendTime = 0;
    sendTime += dt;
    if (sendTime > HeartbeatSendTime) {
        onHeartbeat();
        sendTime = 0;
    }
    m_recvHeartbeatTime += dt;
    if (m_recvHeartbeatTime > HeartbeatRecvTime) {
        m_state = NET_STATE_ERROR;
        return;
    }
    
    flushData();

    readData();
}

char g_extrabuf[65536];
bool TCPSession::readData(){
    
    if (m_state != NET_STATE_CONNECTED) {
        return false;
    }

	const size_t writable = m_inputBuffer.writableBytes();

	// saved an ioctl()/FIONREAD call to tell how much to read
	NetSocket::VBuff vec[2];
	vec[0].buff = m_inputBuffer.beginWrite();
	vec[0].len = writable;
	vec[1].buff = g_extrabuf;
	vec[1].len = sizeof g_extrabuf;
	// when there is enough space in this buffer, don't read into extrabuf.
	// when extrabuf is used, we read 128k-1 bytes at most.
	const int count = (writable < sizeof g_extrabuf) ? 2 : 1;
	const ssize_t ret = m_socket.Readv(vec, count);

    if(ret>0){
        CCLOG("TCPSession::readData %ld",ret);
    }
    
    if (ret < 0) {
        m_state = NET_STATE_ERROR;
        return false;
    }
    
    if (ret <= writable)
    {
        m_inputBuffer.hasWritten(ret);
    }
    else
    {
        m_inputBuffer.hasWritten(writable);
        m_inputBuffer.append(g_extrabuf, ret - writable);
    }
    
    if (ret > 0)
    {
        return true;
    }
    return false;
}

void TCPSession::flushData(){
    if (m_outputBuffer.readableBytes() == 0 || m_state != NET_STATE_CONNECTED) return;
    
    ssize_t ret = m_socket.Send(m_outputBuffer.peek(), m_outputBuffer.readableBytes());
    if (ret > 0){
        m_outputBuffer.retrieve(ret);
        if (m_outputBuffer.readableBytes() == 0) {
            //sendCompleteCallback
        }
    }else if(ret == -1){
        m_state = NET_STATE_ERROR;
        return;
    }else{
        CCASSERT(false, "Warning");
    }
}