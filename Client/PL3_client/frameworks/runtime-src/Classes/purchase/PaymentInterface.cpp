//
//  PaymentInterface.cpp
//
//  Created by Ruoqian, Chen on 2014/12/20
//

#include "cocos2d.h"

#include "PaymentInterface.h"
#include "PaymentMgr.h"
#include "spine/Json.h"
#include <map>

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include "platform/android/jni/JniHelper.h"
#include <jni.h>
#include <android/log.h>
const char* GP_IAB_JavaClassName = "org/PayPlugin/GooglePlayIABPlugin";
const char* GP_Activity_JavaClassName = "com/utu/star/AppActivity";

void GooglePayInAppBilling_OnReceiveItemInfo(const char *pszInfo);

extern "C"
{
	void Java_org_PayPlugin_GooglePlayIABPlugin_nativeOnReceiveItemInfo(JNIEnv* jEnv, jobject jObj, jstring params)
	{
		const char *pszParams = params ? jEnv->GetStringUTFChars(params, NULL) : NULL;
		if (pszParams) {
			GooglePayInAppBilling_OnReceiveItemInfo(pszParams);
			jEnv->ReleaseStringUTFChars(params, pszParams);
		}
	}

	void Java_org_PayPlugin_GooglePlayIABPlugin_nativeOnPurchased(JNIEnv* jEnv, jobject jObj, jstring jstrJsonPurchaseInfo, jstring jstrSignature)
	{
		const char *pszJsonPurchaseInfo = jstrJsonPurchaseInfo ? jEnv->GetStringUTFChars(jstrJsonPurchaseInfo, NULL) : NULL;
		const char *pszSignature = jstrSignature ? jEnv->GetStringUTFChars(jstrSignature, NULL) : NULL;

		auto* pJsonValue = Json_create(pszJsonPurchaseInfo);
		if (pJsonValue) {
			std::string strItemTypeId = Json_getString(pJsonValue, "productId", "");
			PaymentMgr::GetInstance()->OnPurchased(strItemTypeId.c_str(), pszJsonPurchaseInfo, pszSignature);
			Json_dispose(pJsonValue);
			
			const JSON_ITEMINFO * info = PaymentMgr::GetInstance()->GetJsonItemInfo(strItemTypeId.c_str());

			if (info) {
				cocos2d::JniMethodInfo t;
				if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_IAB_JavaClassName, "onPurchaseEvent", "(Ljava/lang/String;D)V")) {
					jstring jItemKey = t.env->NewStringUTF(strItemTypeId.c_str());
					t.env->CallStaticVoidMethod(t.classID, t.methodID, jItemKey, info->cost);
					t.env->DeleteLocalRef(jItemKey);
					t.env->DeleteLocalRef(t.classID);
				}
			}
		}

		if (pszJsonPurchaseInfo) {
			jEnv->ReleaseStringUTFChars(jstrJsonPurchaseInfo, pszJsonPurchaseInfo);
		}

		if (pszSignature) {
			jEnv->ReleaseStringUTFChars(jstrSignature, pszSignature);
		}
	}

	void Java_org_PayPlugin_GooglePlayIABPlugin_nativeOnFailed(JNIEnv* jEnv, jobject jObj, jstring jItemKey, jstring jInfo)
	{
		const char *pszItemKey = jItemKey ? jEnv->GetStringUTFChars(jItemKey, NULL) : NULL;
		const char *pszInfo = jInfo ? jEnv->GetStringUTFChars(jInfo, NULL) : NULL;

		PaymentMgr::GetInstance()->OnFailed(pszItemKey, pszInfo);

		if (pszItemKey) {
			jEnv->ReleaseStringUTFChars(jItemKey, pszItemKey);
		}

		if (pszInfo) {
			jEnv->ReleaseStringUTFChars(jInfo, pszInfo);
		}
	}

	void Java_org_PayPlugin_GooglePlayIABPlugin_nativeOnRestore(JNIEnv* jEnv, jobject jObj, jstring jstrJsonPurchaseInfo, jstring jstrSignature)
	{
		
		const char *pszJsonPurchaseInfo = jstrJsonPurchaseInfo ? jEnv->GetStringUTFChars(jstrJsonPurchaseInfo, NULL) : NULL;
		const char *pszSignature = jstrSignature ? jEnv->GetStringUTFChars(jstrSignature, NULL) : NULL;

		auto* pJsonValue = Json_create(pszJsonPurchaseInfo);
		if (pJsonValue) {
			std::string strItemTypeId = Json_getString(pJsonValue, "productId", "");
			PaymentMgr::GetInstance()->OnRestore(strItemTypeId.c_str(), pszJsonPurchaseInfo, pszSignature);
			Json_dispose(pJsonValue);
		}

		if (pszJsonPurchaseInfo) {
			jEnv->ReleaseStringUTFChars(jstrJsonPurchaseInfo, pszJsonPurchaseInfo);
		}

		if (pszSignature) {
			jEnv->ReleaseStringUTFChars(jstrSignature, pszSignature);
		}
	}
};
#endif

void GooglePayInAppBilling_OnReceiveItemInfo( const char *pszInfo )
{
	Json* pJsonValue = Json_create(pszInfo);
	if (NULL == pJsonValue) {
		return;
	}
	Json * child = pJsonValue->child;
	while(child){
		PAY_ITEMINFO info;
		info.m_strTypeId = Json_getString(child, "productId", "");
		info.m_strName = Json_getString(child, "title", "");
		info.m_strDesc = Json_getString(child, "description", "");

		auto pos = info.m_strName.find_last_of(' ');
		if (std::string::npos != pos) {
			info.m_strName = info.m_strName.substr(0, pos);
		}

		info.m_strPrice = Json_getString(child, "price", "");		
		info.m_strKey = info.m_strTypeId;
		PaymentMgr::GetInstance()->AddItemInfo(info);

		child = child->next;
	}

	Json_dispose(pJsonValue);
	//PaymentMgr::GetInstance()->NotifyObserver(PAY_EVENT_QUERY_SKU_FIN);
}

void PaymentInterface::Init(void)
{

}

std::string PaymentInterface::getUUID() {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	cocos2d::JniMethodInfo t;
	if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_Activity_JavaClassName, "getLocalMacAddress", "()Ljava/lang/String;")) {
		std::string macStr = cocos2d::JniHelper::jstring2string((jstring)t.env->CallStaticObjectMethod(t.classID, t.methodID));
		t.env->DeleteLocalRef(t.classID);
		for (std::string::iterator it = macStr.begin(); it != macStr.end(); ++it) {
			if (*it == ':') {
				it = macStr.erase(it);
			}
		}
		return macStr;
	}
	return NULL;
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	auto ud = cocos2d::UserDefault::getInstance();
	
	auto windowsUUID = ud->getStringForKey("windows_uuid");
	if (windowsUUID == "") {
		return "windows_default_uuid";
	}
	return windowsUUID;
#endif
}

void PaymentInterface::restore() {

}

void PaymentInterface::adjustTrackEvent(const std::string & event) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	cocos2d::JniMethodInfo t;
	if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_Activity_JavaClassName, "adjustTrackEvent", "(Ljava/lang/String;)V")) {
		jstring jItemKey = t.env->NewStringUTF(event.c_str());
		t.env->CallStaticVoidMethod(t.classID, t.methodID, jItemKey);
		t.env->DeleteLocalRef(jItemKey);
		t.env->DeleteLocalRef(t.classID);
	}
#endif
}
void PaymentInterface::flurryLogEvent(const std::string & event, const std::map<std::string, std::string> & params) {
	
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	
	cocos2d::JniMethodInfo t;
	if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_Activity_JavaClassName, "onFlurryEvent", "(Ljava/lang/String;[Ljava/lang/String;[Ljava/lang/String;)V")) {
		jstring jEventId = t.env->NewStringUTF(event.c_str());

		jclass stringArrCls = t.env->FindClass("java/lang/String");

		jobjectArray jKeyArr = t.env->NewObjectArray(params.size(), stringArrCls, NULL);
		jobjectArray jValueArr = t.env->NewObjectArray(params.size(), stringArrCls, NULL);

		int i = 0;
		std::map<std::string, std::string>::const_iterator   it;
		for (it = params.begin();  it != params.end(); it++)
		{
			jstring kk = t.env->NewStringUTF(it->first.c_str()); 
			t.env->SetObjectArrayElement(jKeyArr, i, kk);

			jstring vv = t.env->NewStringUTF(it->second.c_str());
			t.env->SetObjectArrayElement(jValueArr, i, vv);
			i++;

			t.env->DeleteLocalRef(kk);
			t.env->DeleteLocalRef(vv);
		}

		t.env->CallStaticVoidMethod(t.classID, t.methodID, jEventId, jKeyArr, jValueArr);
		t.env->DeleteLocalRef(jEventId);
		t.env->DeleteLocalRef(t.classID);
	}
#endif 
}

void PaymentInterface::onGAAddResourceEvent(const std::string & eventID, const int eventNum, const std::vector<std::string>& events) {

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)

	cocos2d::JniMethodInfo t;
	if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_Activity_JavaClassName, "onGAAddResourceEvent", "(Ljava/lang/String;I[Ljava/lang/String;)V")) {

		jstring jEventID = t.env->NewStringUTF(eventID.c_str());
		jint jEventNum = (int)eventNum;

		jclass stringArrCls = t.env->FindClass("java/lang/String");

		jobjectArray jEventArr = t.env->NewObjectArray(events.size(), stringArrCls, NULL);

		for (int i = 0; i < events.size(); i++)
		{
			jstring ee = t.env->NewStringUTF(events[i].c_str());
			t.env->SetObjectArrayElement(jEventArr, i, ee);
			t.env->DeleteLocalRef(ee);
		}

		t.env->CallStaticVoidMethod(t.classID, t.methodID, jEventID, jEventNum, jEventArr);
		t.env->DeleteLocalRef(jEventID);
		t.env->DeleteLocalRef(jEventArr);
		t.env->DeleteLocalRef(t.classID);
	}
#endif 
}

void PaymentInterface::onGAAddProgressionEvent(const std::string & eventID, const std::vector<std::string>& events) {

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)

	cocos2d::JniMethodInfo t;
	if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_Activity_JavaClassName, "onGAAddProgressionEvent", "(Ljava/lang/String;[Ljava/lang/String;)V")) {

		jstring jEventID = t.env->NewStringUTF(eventID.c_str());

		jclass stringArrCls = t.env->FindClass("java/lang/String");

		jobjectArray jEventArr = t.env->NewObjectArray(events.size(), stringArrCls, NULL);

		for (int i = 0; i < events.size(); i++)
		{
			jstring ee = t.env->NewStringUTF(events[i].c_str());
				t.env->SetObjectArrayElement(jEventArr, i, ee);
				t.env->DeleteLocalRef(ee);
		}

		t.env->CallStaticVoidMethod(t.classID, t.methodID, jEventID, jEventArr);
		t.env->DeleteLocalRef(jEventID);
		t.env->DeleteLocalRef(jEventArr);
		t.env->DeleteLocalRef(t.classID);
	}
#endif 
}

void PaymentInterface::onLoginEvent(const std::string & verson, const std::string & userID) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)

	cocos2d::JniMethodInfo t;
	if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_Activity_JavaClassName, "onLoginEvent", "(Ljava/lang/String;Ljava/lang/String;)V")) {
		jstring jVerson = t.env->NewStringUTF(verson.c_str());
		jstring jUserID = t.env->NewStringUTF(userID.c_str());

		t.env->CallStaticVoidMethod(t.classID, t.methodID, jVerson, jUserID);
		t.env->DeleteLocalRef(jVerson);
		t.env->DeleteLocalRef(jUserID);
		t.env->DeleteLocalRef(t.classID);
	}
#endif 
}

void PaymentInterface::RestartAPP() {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	cocos2d::JniMethodInfo t;
	if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_Activity_JavaClassName, "RestartAPP", "()V")) {
		t.env->CallStaticVoidMethod(t.classID, t.methodID);
	}
#endif 
}

void PaymentInterface::ReqItemInfo( const std::vector<std::string>& vecItemTypeId )
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	std::string strItemTypeIdSet;
	for (auto &rStrTypeInfo : vecItemTypeId) {
		strItemTypeIdSet += rStrTypeInfo;
		strItemTypeIdSet += " ";
	}

	cocos2d::JniMethodInfo t;
	if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_IAB_JavaClassName, "ReqItemInfo", "(Ljava/lang/String;)V")) {
		jstring jItemTypeIdSet = t.env->NewStringUTF(strItemTypeIdSet.c_str());
		t.env->CallStaticVoidMethod(t.classID, t.methodID, jItemTypeIdSet);
		t.env->DeleteLocalRef(jItemTypeIdSet);
		t.env->DeleteLocalRef(t.classID);
	}
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	PaymentMgr::GetInstance()->OnRequestItemsFinish(true);
#endif
}

void PaymentInterface::PayStart( const char *pszItemTypeId, const char *pszExtraVerifyInfo )
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	cocos2d::JniMethodInfo t;
	if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_IAB_JavaClassName, "PayStart", "(Ljava/lang/String;Ljava/lang/String;)V")) {
		jstring jItemTypeId = t.env->NewStringUTF(pszItemTypeId);
		jstring jExtraVerifyInfo = t.env->NewStringUTF(pszExtraVerifyInfo);
		t.env->CallStaticVoidMethod(t.classID, t.methodID, jItemTypeId, jExtraVerifyInfo);
		t.env->DeleteLocalRef(jExtraVerifyInfo);
		t.env->DeleteLocalRef(jItemTypeId);
		t.env->DeleteLocalRef(t.classID);
	}
#endif
}

void PaymentInterface::PayEnd(bool result, const char *pszItemKey )
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)

	const JSON_ITEMINFO * info = PaymentMgr::GetInstance()->GetJsonItemInfo(pszItemKey);
	if(info){
		cocos2d::JniMethodInfo t;
		if (cocos2d::JniHelper::getStaticMethodInfo(t, GP_IAB_JavaClassName, "PayEnd", "(Ljava/lang/String;DI)V")) {
			jstring jItemKey = t.env->NewStringUTF(pszItemKey);
			t.env->CallStaticVoidMethod(t.classID, t.methodID, jItemKey, info->cost, result?1:0);
			t.env->DeleteLocalRef(jItemKey);
			t.env->DeleteLocalRef(t.classID);
		}
	}

	
#endif
}
