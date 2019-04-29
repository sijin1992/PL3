//
//  PaymentMgr.cpp
//
//  Created by Ruoqian, Chen on 2014/12/20
//

#include "PaymentInterface.h"
#include "PaymentMgr.h"
#include "json/document.h"
#include "json/stringbuffer.h"
#include "json/writer.h"
namespace
{
static PaymentMgr* s_pInstance = NULL;
}

std::string g_pszItemKey;

PaymentMgr * PaymentMgr::GetInstance( void )
{
	if (NULL == s_pInstance) {
		s_pInstance = new PaymentMgr;
		PaymentInterface::Init();
	}

	return s_pInstance;
}

void PaymentMgr::Release( void )
{
	CC_SAFE_DELETE(s_pInstance);
}

PaymentMgr::PaymentMgr()
{
	m_nVerifyMode = PAY_VERIFY_SERVER;
}

void PaymentMgr::ReqItemInfo(std::vector<JSON_ITEMINFO> & items, reqItemCallback callback)
{
	if (m_mapItem.empty()) {
		const char *pszConfig = NULL;
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
		pszConfig = "GooglePlayIAB";
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
		pszConfig = "AppleIAP";
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
		pszConfig = "WinSim";
#endif
		
		if (NULL == pszConfig) {
			return;
		}
		_reqItemCallback = callback;
		
		std::vector<std::string> vecItemTypeId;
		
		for (int i = 0; i < items.size(); ++i)
		{
			vecItemTypeId.push_back(items[i].product_id);
			m_jsonItem[items[i].product_id] = items[i];
		}
		PaymentInterface::ReqItemInfo(vecItemTypeId);
	}

	PaymentInterface::restore();
}

const JSON_ITEMINFO* PaymentMgr::GetJsonItemInfo(const char *productID) const{
	if (NULL == productID) {
		return NULL;
	}
	
	auto it = m_jsonItem.find(productID);
	if (it == m_jsonItem.end()) {
		return NULL;
	}
	
	return &it->second;
}

void PaymentMgr::ClearItemInfo( void )
{
	m_mapItem.clear();
}

void PaymentMgr::AddItemInfo( const PAY_ITEMINFO& info )
{
	m_mapItem[info.m_strTypeId] = info;
}

const PAY_ITEMINFO* PaymentMgr::GetItemInfo( const char *pszItemTypeId ) const
{
	if (NULL == pszItemTypeId) {
		return NULL;
	}

	auto it = m_mapItem.find(pszItemTypeId);
	if (it == m_mapItem.end()) {
		return NULL;
	}

	return &it->second;
}

const std::map<std::string, PAY_ITEMINFO>& PaymentMgr::GetItemInfo( void ) const
{
	return m_mapItem;
}

bool PaymentMgr::TestVerifyMode( int nMode )
{
	return (nMode & m_nVerifyMode) ? true : false;
}

void PaymentMgr::OnRestore( const char *pszItemKey, const char *pszItemInfo, const char *pszVerifyInfo )
{
	CCLOG("PaymentMgr::OnRestore [%s] [%s] [%s]", pszItemKey, pszItemInfo, pszVerifyInfo);

	if (this->TestVerifyMode(PAY_VERIFY_SERVER)) {
		this->PayServerVerify(pszItemKey, pszItemInfo, pszVerifyInfo);
	} else {
		this->PayEnd(true,pszItemKey);
	}
}

void PaymentMgr::PayStart( const char *pszItemTypeId, payCallback callback)
{
	CCLOG("PaymentMgr::PayStart [%s]", pszItemTypeId);

	_payCallback = callback;
	// some info for game server or client to verify
	const char* pszVerifyInfo = "749407975@qq.com";
	PaymentInterface::PayStart(pszItemTypeId, pszVerifyInfo);
	
}

void PaymentMgr::OnPurchased( const char *pszItemKey, const char *pszItemInfo, const char *pszVerifyInfo )
{
	CCLOG("PaymentMgr::OnPurchased [%s] [%s]", pszItemKey, pszVerifyInfo);

	if (this->TestVerifyMode(PAY_VERIFY_SERVER)) {
		this->PayServerVerify(pszItemKey, pszItemInfo, pszVerifyInfo);
	} else {
		this->PayEnd(true,pszItemKey);
	}
}

void PaymentMgr::OnFailed( const char* pszItemKey, const char *pszInfo )
{
	CCLOG("PaymentMgr::OnFailed [%s] [%s]", pszItemKey, pszInfo);

	this->PayEnd(false,pszItemKey);
}

void PaymentMgr::OnRequestItemsFinish(bool succeed){
	// 回调出去
	if (_reqItemCallback){
		
		_reqItemCallback(succeed);
	}
}

// ［回调］支付服务器结果返回
void PaymentMgr::onHttpRequestCompleted(cocos2d::network::HttpClient *sender, cocos2d::network::HttpResponse *response){
	if (!response)
	{
		return;
	}
	
	// You can get original request type from: response->request->reqType
	if (0 != strlen(response->getHttpRequest()->getTag()))
	{
		CCLOG("%s completed", response->getHttpRequest()->getTag());
	}
	
	long statusCode = response->getResponseCode();
	char statusString[64] = {};
	sprintf(statusString, "HTTP Status Code: %ld, tag = %s", statusCode, response->getHttpRequest()->getTag());
	//_labelStatusCode->setString(statusString);
	CCLOG("response code: %ld", statusCode);
	
	if (!response->isSucceed())
	{
		CCLOG("response failed");
		CCLOG("error buffer: %s", response->getErrorBuffer());
		return;
	}
	
	std::vector<char> *buffer = response->getResponseData();
	
	std::string jsStr;
	
	for (unsigned int i = 0; i < buffer->size(); ++i){
		
		jsStr += (*buffer)[i];
	}
	CCLOG("jsStr : %s", jsStr.c_str());
	
	rapidjson::Document doc;
	doc.Parse<0>(jsStr.c_str());
	
	if (jsStr == "false" || doc.HasParseError() || !doc.HasMember("result") || !doc.HasMember("msg")){
		
		CCLOG("PaymentMgr:: parse json error!");
		//for test
		//this->OnServerVerifyResult(g_pszItemKey.c_str(), true);
		return;
	}
	
	if (doc["result"].GetInt() == 0){
		
		std::string trans_id = doc["msg"].GetString();
		this->OnServerVerifyResult(g_pszItemKey.c_str(), true);
	}else{
		this->OnServerVerifyResult("", false);
		CCLOG("PaymentMgr:: parse json error!%d",doc["result"].GetInt());
	}
}

void PaymentMgr::PayServerVerify( const char* pszItemKey, const char *pszItemInfo, const char *pszVerifyInfo )
{
	CCLOG("PaymentMgr::PayServerVerify [%s] [%s] [%s]", pszItemKey, pszItemInfo, pszVerifyInfo);
	g_pszItemKey = pszItemKey;
	//付款成功 发送至服务器
	cocos2d::network::HttpRequest* request = new (std::nothrow) cocos2d::network::HttpRequest();
	
	request->setRequestType(cocos2d::network::HttpRequest::Type::POST);
	request->setResponseCallback(CC_CALLBACK_2(PaymentMgr::onHttpRequestCompleted, this));
	
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	request->setUrl("http://game01.haomiaogame.com/rgg/gppay.php");
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
	request->setUrl("http://104.225.150.99/RoSDK/api/pay/index.php");
#endif
	

	auto ud = cocos2d::UserDefault::getInstance();
	cocos2d::__String * str = nullptr;
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	str = cocos2d::__String::createWithFormat("svrid=%s&username=%s&data=%s&signature=%s", ud->getStringForKey("server_id").c_str(), ud->getStringForKey("user_id").c_str(), pszItemInfo, pszVerifyInfo);
#else
	str = cocos2d::__String::createWithFormat("svrid=%s&username=%s&data=%s", ud->getStringForKey("server_id").c_str(), ud->getStringForKey("user_id").c_str(), pszVerifyInfo);
#endif
	request->setRequestData(str->getCString(), str->length());
	request->setTag("POST server");
	cocos2d::network::HttpClient::getInstance()->send(request);
	
	request->release();
}

void PaymentMgr::OnServerVerifyResult( const char *pszItemKey, bool bVerifyFin )
{
	CCLOG("PaymentMgr::OnServerVerifyResult [%s] [%s]", pszItemKey, bVerifyFin ? "true" : "false");

	if (bVerifyFin) {
		this->PayEnd(true,pszItemKey);
	}
}

void PaymentMgr::PayEnd(bool result, const char *pszItemKey )
{
	CCLOG("PaymentMgr::PayEnd [%s]", pszItemKey);

	// if it a non-consumable like item and ONLY save owned status in google IAB, DONOT call it
	PaymentInterface::PayEnd(result, pszItemKey);
	//callback IOS removedTransactions: productID
	
	if (_payCallback){
		_payCallback(result, pszItemKey);
	}
}

void PaymentMgr::adjustTrackEvent(const std::string & event){
	PaymentInterface::adjustTrackEvent(event);
}

void PaymentMgr::flurryLogEvent(const std::string & event, const std::map<std::string, std::string> & params){
	PaymentInterface::flurryLogEvent(event, params);
}

void PaymentMgr::onGAAddResourceEvent(const std::string & eventID, const int eventNum, const std::vector<std::string>& events) {
	PaymentInterface::onGAAddResourceEvent(eventID, eventNum, events);

}

void PaymentMgr::onGAAddProgressionEvent(const std::string & eventID, const std::vector<std::string>& events) {
	PaymentInterface::onGAAddProgressionEvent(eventID, events);

}

void PaymentMgr::onLoginEvent(const std::string & verson, const std::string & userID) {
	PaymentInterface::onLoginEvent(verson,userID);
}

std::string PaymentMgr::getUUID(){
	return PaymentInterface::getUUID();
}
