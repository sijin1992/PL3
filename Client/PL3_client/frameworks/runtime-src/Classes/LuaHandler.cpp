//
//  LuaHandler.cpp
//  HelloLua
//
//  Created by hankai on 16/3/14.
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

#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include "AppManager.h"
#include "CCLuaEngine.h"
#include "extensions/cocos-ext.h"
#include "network/HttpClient.h"

#include "PaymentMgr.h"

#include "UnzipHelper.h"

USING_NS_CC;

static int _LuaHandler_send(lua_State *L)
{
    long cmd = luaL_checkinteger(L, 1);
    
    size_t size = 0;
    const char * buffer = luaL_checklstring(L, 2 , &size);
    
    if(size<1){
        luaL_error(L,"send data size = %d", size);
    }
    
    AppManager::getInstance().getNet().send(cmd,size,buffer);

    return 0;
}

static int _LuaHandler_recvProtobuf(lua_State *L){
    NetPacket & np = AppManager::getInstance().getNet().getRecvProtobuf();
    lua_pushinteger(L, np.head.cmd);
    //lua_pushinteger(L, np.getProtoSize());
    lua_pushlstring(L,(const char *)np.proto_buf,np.getProtoSize());
    return 2;
}

static int _LuaHandler_connect(lua_State *L){

    AppManager::getInstance().connect();

    return 0;
}

static int _bsReadFile(lua_State *L) {
    
    size_t size = 0;
    const char * buffer = luaL_checklstring(L, 1 , &size);
    
    if(size<1){
        luaL_error(L,"file name size = %d", size);
    }
    cocos2d::Data data = cocos2d::FileUtils::getInstance()->getDataFromFile(buffer);
    lua_pushlstring(L, (const char*)data.getBytes(), data.getSize());
    return 1;
}

static int _unzip(lua_State *L) {
	size_t size = 0;
    const char * zipFileName = luaL_checklstring(L, 1 , &size);
    if(size<1){
        luaL_error(L,"zipFileName size = %d", size);
    }
	const char * outFilePath = luaL_checklstring(L, 2, &size);
	if (size<1) {
		luaL_error(L, "outFileName size = %d", size);
	}
	bool flag = UnzipHelper::getInstance().loadZIP(zipFileName, outFilePath, "");
	lua_pushboolean(L, flag);
    return 1;
}

static int _reqPaymentItemInfo(lua_State *L){

	if (!lua_istable(L, 1)) {
		luaL_error(L, "_reqPaymentItemInfo item not is a table");
	}

	lua_pushnil(L);
	std::vector<JSON_ITEMINFO> items;
	int i = 0;
	while (lua_next(L, -2)) {
		JSON_ITEMINFO info;
		if (i % 2 == 0) {
			info.product_id = lua_tostring(L, -1);
			items.push_back(info);
		}
		else {
			items.back().cost = lua_tonumber(L, -1);
		}
		
		lua_pop(L, 1);
		++i;
	}
    
    PaymentMgr::GetInstance()->ReqItemInfo(items, [](bool succeed){
        
        LuaStack * L = LuaEngine::getInstance()->getLuaStack();
        lua_State* tolua_s = L->getLuaState();
        lua_getglobal(tolua_s, "reqPaymentItemCallback");
        lua_pushboolean(tolua_s, succeed);
        int iRet = lua_pcall(tolua_s, 1, 0, 0);
        if (iRet)
        {
            const char *pErrorMsg = lua_tostring(tolua_s, -1);
            CCLOG("error-------%s",pErrorMsg);
            return ;
        }
    });
    
    return 0;
}

static int _payStart(lua_State *L){
    
    size_t size = 0;
    const char * buffer = luaL_checklstring(L, 1 , &size);
    
    if(size<1){
        luaL_error(L,"pszItemTypeId size = %d", size);
    }
    
    PaymentMgr::GetInstance()->PayStart(buffer,[](bool result, const char *productID){
        LuaStack * L = LuaEngine::getInstance()->getLuaStack();
        lua_State* tolua_s = L->getLuaState();
        lua_getglobal(tolua_s, "payCallback");
        lua_pushboolean(tolua_s, result);
        lua_pushstring(tolua_s, productID);
        int iRet = lua_pcall(tolua_s, 2, 0, 0);
        if (iRet)
        {
            const char *pErrorMsg = lua_tostring(tolua_s, -1);
            CCLOG("error-------%s",pErrorMsg);
            return ;
        }
    });
    
    return 0;
}

static int _getUUID(lua_State *L){

    lua_pushstring(L, PaymentMgr::GetInstance()->getUUID().c_str());
    
    return 1;
}

static int _openUrl(lua_State *L) {
	size_t size = 0;
	const char * url = luaL_checklstring(L, 1, &size);

	if (size<1) {
		luaL_error(L, "url size = %d", size);
	}

	Application::getInstance()->openURL(url);
	return 0;
}

static int _adjustTrackEvent(lua_State *L){
    size_t size = 0;
    const char * event = luaL_checklstring(L, 1, &size);
    
    if(size<1){
        luaL_error(L,"event size = %d", size);
    }
    
    PaymentMgr::GetInstance()->adjustTrackEvent(event);
    return 0;
}

static int _flurryLogEvent(lua_State *L){
	
    size_t size = 0;
    const char * event = luaL_checklstring(L, 1, &size);
    
    if(size<1){
        luaL_error(L,"event size = %d", size);
    }

	if (!lua_istable(L, 2)) {
		luaL_error(L, "_flurryLogEvent param  2 not is a table");
	}

	lua_pushnil(L);
	std::map<std::string, std::string> params;
	while (lua_next(L, -2)){
		params[lua_tostring(L, -2)] = lua_tostring(L, -1);
		lua_pop(L, 1);
	}

    PaymentMgr::GetInstance()->flurryLogEvent(event, params);
    return 0;
}

static int _onGAAddResourceEvent(lua_State *L) {

	size_t size = 0;

	const char * eventID = luaL_checklstring(L, 1, &size);

	if (size<1) {
		luaL_error(L, "eventID size = %d", size);
	}

	long eventNum = luaL_checkinteger(L, 2);

	lua_pushnil(L);
	std::vector<std::string> events;
	while (lua_next(L, -2)) {
		events.push_back(lua_tostring(L, -1));
		lua_pop(L, 1);
	}

	PaymentMgr::GetInstance()->onGAAddResourceEvent(eventID, eventNum, events);
	return 0;
}

static int _onGAAddProgressionEvent(lua_State *L) {

	size_t size = 0;
	
	const char * eventID = luaL_checklstring(L, 1, &size);

	if (size<1) {
		luaL_error(L, "eventID size = %d", size);
	}

	lua_pushnil(L);
	std::vector<std::string> events;
	while (lua_next(L, -2)) {
		events.push_back(lua_tostring(L, -1));
		lua_pop(L, 1);
	}

	PaymentMgr::GetInstance()->onGAAddProgressionEvent(eventID, events);
	return 0;
}

static int _onLoginEvent(lua_State *L) {

	size_t size = 0;
	const char * verson = luaL_checklstring(L, 1, &size);
	if (size<1) {
		luaL_error(L, "verson size = %d", size);
	}
	const char * userID = luaL_checklstring(L, 2, &size);
	if (size<1) {
		luaL_error(L, "userID size = %d", size);
	}

	PaymentMgr::GetInstance()->onLoginEvent(verson, userID);
	return 0;
}

static int _RestartAPP(lua_State *L) {

	PaymentMgr::GetInstance()->RestartAPP();
	return 0;
}

static int _reconnect(lua_State *L) {

	AppManager::getInstance().getNet().reconnect();
	return 0;
}

#ifdef __cplusplus
extern "C" {
#endif

static const struct luaL_reg _c_lua_handler [] = {
    {"send", _LuaHandler_send},
    {"recvProtobuf", _LuaHandler_recvProtobuf},
    {"connect",_LuaHandler_connect},
    {"readFile",_bsReadFile},
	{"unzip", _unzip},
    {"reqPaymentItemInfo",_reqPaymentItemInfo},
    {"payStart",_payStart},
	{"reconnect", _reconnect },
    {"adjustTrackEvent", _adjustTrackEvent},
    {"flurryLogEvent", _flurryLogEvent},
	{ "onGAAddResourceEvent", _onGAAddResourceEvent },
	{ "onGAAddProgressionEvent", _onGAAddProgressionEvent },
	{ "onLoginEvent", _onLoginEvent },
	{ "RestartAPP", _RestartAPP },
    {"getUUID", _getUUID},
	{"openUrl", _openUrl},
    {NULL, NULL}
};

int luaopen_luahandler (lua_State *L)
{

    luaL_register(L, "LuaHandler.c", _c_lua_handler);
    return 1;
}

#ifdef __cplusplus
}
#endif
