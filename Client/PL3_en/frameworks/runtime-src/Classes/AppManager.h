//
//  AppManager.h
//  HelloLua
//
//  Created by hankai on 16/3/11.
//
//

#ifndef AppManager_h
#define AppManager_h

#include "cocos2d.h"
#include "Singleton.h"
#include "ClientConnect.h"



class AppManager : public Singleton<AppManager>{
    friend class ClientConnect;
public:
    AppManager();
    
    bool init();
    
    void update(float deltaTime);
    
    bool connect();
    void connectCallback(bool flag);
	void connectOnError();
    
    ClientConnect & getNet(){
        return m_client;
    }
private:
    ClientConnect m_client;
};

#endif /* AppManager_h */
