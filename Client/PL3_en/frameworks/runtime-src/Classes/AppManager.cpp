//
//  AppManager.cpp
//  HelloLua
//
//  Created by hankai on 16/3/11.
//
//
#ifdef __cplusplus
extern "C" {
#endif
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
    
#ifdef __cplusplus
}
#endif
#include "CCLuaEngine.h"
#include "AppManager.h"
#include "cmd_define.pb.h"
#include "CmdLogin.pb.h"

AppManager::AppManager(){
    
}

bool AppManager::init(){
    
    
    return true;
}

void AppManager::update(float deltaTime){
    
    m_client.runLoop(deltaTime);
}

bool AppManager::connect(){
    

    // 设置服务器的IP地址，端口号
    // 并连接服务器 Connect
    auto ud = cocos2d::UserDefault::getInstance();
    std::string ip = ud->getStringForKey("server_address");
    int port = ud->getIntegerForKey("server_port");
    if(ip.empty() || port == 0){
        CCLOG("ip error");
        return false;
    }
    bool ret = m_client.connect(ip.c_str(), port);
    if (!ret) {
        CCLOG("connect error");
        return false;
    }
    return true;
}

void AppManager::connectCallback(bool flag){
    
    cocos2d::LuaStack * L = cocos2d::LuaEngine::getInstance()->getLuaStack();
    lua_State* tolua_s = L->getLuaState();
    lua_getglobal(tolua_s, "onConnected");
	lua_pushboolean(tolua_s, flag);
    int iRet = lua_pcall(tolua_s, 1, 0, 0);
    if (iRet)
    {
        const char *pErrorMsg = lua_tostring(tolua_s, -1);
        CCLOG("error-------%s",pErrorMsg);
        return ;
    }
}

void AppManager::connectOnError() {

	cocos2d::LuaStack * L = cocos2d::LuaEngine::getInstance()->getLuaStack();
	lua_State* tolua_s = L->getLuaState();
	lua_getglobal(tolua_s, "onConnectError");
	int iRet = lua_pcall(tolua_s, 0, 0, 0);
	if (iRet)
	{
		const char *pErrorMsg = lua_tostring(tolua_s, -1);
		CCLOG("error-------%s", pErrorMsg);
		return;
	}
}