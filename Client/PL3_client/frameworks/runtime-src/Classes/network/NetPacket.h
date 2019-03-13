//
//  NetPacket.h
//  HelloLua
//
//  Created by hankai on 16/3/9.
//
//

#ifndef NetPacket_h
#define NetPacket_h

#include "cocos2d.h"

#pragma pack(push)
#pragma pack(1)

class NetPacket : public cocos2d::Ref{
public:
    NetPacket():proto_buf(nullptr){
        
    }
    struct Head{
        char mark[6] = {'B','I','N','P','R','O'};
        char useOrder = 0;
        int size;
        int cmd;
        int result = 0;
        char userName[32] = {};
    };
    int getProtoSize(){
        return head.size - sizeof(Head);
    }
    Head head;
    char * proto_buf;
};

#pragma pack(pop)

#endif /* NetPacket_h */
