LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := cocos2dlua_shared

LOCAL_MODULE_FILENAME := libcocos2dlua

ifeq ($(USE_ARM_MODE),1)
LOCAL_ARM_MODE := arm
endif

LOCAL_SRC_FILES := hellolua/main.cpp
LOCAL_SRC_FILES += ../../../Classes/AppDelegate.cpp
LOCAL_SRC_FILES += ../../../Classes/AppManager.cpp
LOCAL_SRC_FILES += ../../../Classes/ide-support/lua_debugger.c
LOCAL_SRC_FILES += ../../../Classes/ide-support/RuntimeLuaImpl.cpp
LOCAL_SRC_FILES += ../../../Classes/ide-support/SimpleConfigParser.cpp
LOCAL_SRC_FILES += ../../../Classes/LuaHandler.cpp
LOCAL_SRC_FILES += ../../../Classes/network/ClientConnect.cpp
LOCAL_SRC_FILES += ../../../Classes/network/NetBuffer.cpp
LOCAL_SRC_FILES += ../../../Classes/network/NetPacket.cpp
LOCAL_SRC_FILES += ../../../Classes/network/NetSocket.cpp
LOCAL_SRC_FILES += ../../../Classes/network/proto/AirShip.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Arena.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Building.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Stage.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Activity.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/cmd_define.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/cmd_rank.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdBuilding.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdEquip.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdGroup.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdLogin.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdPve.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdPvp.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdPlanet.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Planet.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdUser.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdHome.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdWeapon.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdTrial.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/config.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/datablock.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Equip.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/FlagShip.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/group.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/heartBeatResp.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Home.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Item.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Mail.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/PveInfo.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/PvpInfo.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/rank.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/UserInfo.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/UserSync.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/worldboss.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Weapon.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Trial.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/Slave.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/CmdSlave.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/proto/OtherInfo.pb.cc
LOCAL_SRC_FILES += ../../../Classes/network/TCPSession.cpp
LOCAL_SRC_FILES += ../../../Classes/pbc/pbc-lua.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/alloc.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/array.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/bootstrap.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/context.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/decode.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/map.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/pattern.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/proto.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/register.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/rmessage.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/stringpool.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/varint.c
LOCAL_SRC_FILES += ../../../Classes/pbc/src/wmessage.c
LOCAL_SRC_FILES += ../../../Classes/purchase/PaymentInterface.cpp
LOCAL_SRC_FILES += ../../../Classes/purchase/PaymentMgr.cpp
LOCAL_SRC_FILES += ../../../Classes/utilities/CCShake.cpp
LOCAL_SRC_FILES += ../../../Classes/utilities/EffectSprite.cpp
LOCAL_SRC_FILES += ../../../Classes/utilities/UVSprite.cpp
LOCAL_SRC_FILES += ../../../Classes/utilities/MatrixView.cpp
LOCAL_SRC_FILES += ../../../Classes/utilities/CCContentSizeTo.cpp
LOCAL_SRC_FILES += ../../../Classes/utilities/UnzipHelper.cpp
LOCAL_SRC_FILES += ../../../../cocos2d-x/cocos/scripting/lua-bindings/auto/lua_myclass_auto.cpp

LOCAL_C_INCLUDES := \
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../../Classes
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../../Classes/ide-support
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../../Classes/network
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../../Classes/network/proto
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../../Classes/pbc
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../../Classes/pbc/src
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../../Classes/purchase
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../../Classes/utilities
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../../../../cocos2d-x/cocos/scripting/lua-bindings/auto/

LOCAL_WHOLE_STATIC_LIBRARIES := cocos2dx_static
LOCAL_WHOLE_STATIC_LIBRARIES += cocos2dx-talkingdata

# _COCOS_HEADER_ANDROID_BEGIN
# _COCOS_HEADER_ANDROID_END

LOCAL_STATIC_LIBRARIES := cocos2d_lua_static
LOCAL_STATIC_LIBRARIES += cocos2d_simulator_static

# _COCOS_LIB_ANDROID_BEGIN
# _COCOS_LIB_ANDROID_END

include $(BUILD_SHARED_LIBRARY)

$(call import-module,scripting/lua-bindings/proj.android)
$(call import-module,tools/simulator/libsimulator/proj.android)
$(call import-module,TalkingDataGameAnalytics/android)

# _COCOS_LIB_IMPORT_ANDROID_BEGIN
# _COCOS_LIB_IMPORT_ANDROID_END
