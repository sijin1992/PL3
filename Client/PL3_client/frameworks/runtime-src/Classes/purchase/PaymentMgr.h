//
//  PaymentMgr.h
//
//  Created by Ruoqian, Chen on 2014/12/20
//

#ifndef  __PAYMENT_MGR_H__
#define  __PAYMENT_MGR_H__

#include <vector>
#include "cocos2d.h"
#include "extensions/cocos-ext.h"
#include "network/HttpClient.h"
enum
{
	PAY_EVENT_QUERY_SKU_FIN,
};

enum
{
	PAY_VERIFY_NONE = 0,
	PAY_VERIFY_CLIENT = 1,
	PAY_VERIFY_SERVER = 1 << 1,
	PAY_VERIFY_BOTH = PAY_VERIFY_CLIENT | PAY_VERIFY_SERVER,
};

struct PAY_ITEMINFO
{
	std::string m_strKey;
	std::string m_strTypeId;
	std::string m_strName;
	std::string m_strDesc;
	std::string m_strPrice;
};

struct JSON_ITEMINFO{
	double cost;
	std::string product_id;
};

typedef std::function<void(bool succeed)> reqItemCallback; // 获取商品回调
typedef std::function<void(bool succeed, const char *productID)> payCallback; // 支付结果回调

class PaymentMgr
{
public:
	static PaymentMgr *GetInstance(void);
	static void Release(void);

	void ReqItemInfo(std::vector<JSON_ITEMINFO> & items, reqItemCallback callback);
	const std::map<std::string, PAY_ITEMINFO>& GetItemInfo(void) const;
	const PAY_ITEMINFO* GetItemInfo(const char *pszItemTypeId) const;
	void ClearItemInfo(void);
	void AddItemInfo(const PAY_ITEMINFO& info);

	bool TestVerifyMode(int nMode);
	void PayStart(const char *pszItemTypeId, payCallback callback);
	
	void OnRequestItemsFinish(bool success);

	void OnPurchased(const char *pszItemKey, const char *pszItemInfo, const char *pszVerifyInfo);
	void OnFailed(const char* pszItemKey, const char *pszInfo);
	void OnRestore(const char* pszItemKey, const char *pszItemInfo, const char *pszVerifyInfo);
	void OnServerVerifyResult(const char *pszItemKey, bool bVerifyFin);
	
	void adjustTrackEvent(const std::string & event);
	
	void flurryLogEvent(const std::string & event, const std::map<std::string, std::string> & params);
	
	void onGAAddResourceEvent(const std::string & eventID, const int eventNum, const std::vector<std::string>& events);
	void onGAAddProgressionEvent(const std::string & eventID, const std::vector<std::string>& events);

	void onLoginEvent(const std::string & verson, const std::string & userID);

	void RestartAPP();

	const JSON_ITEMINFO* GetJsonItemInfo(const char *productID) const;
	
	std::string getUUID();
private:
	PaymentMgr();
	void PayServerVerify(const char* pszItemKey, const char *pszItemInfo, const char *pszVerifyInfo);
	void PayEnd(bool result,const char *pszItemKey);
	
	void onHttpRequestCompleted(cocos2d::network::HttpClient *sender, cocos2d::network::HttpResponse *response);

	int m_nVerifyMode;
	std::map<std::string, PAY_ITEMINFO> m_mapItem;
	
	std::map<std::string, JSON_ITEMINFO> m_jsonItem;
	
	reqItemCallback _reqItemCallback; // 外部回调（商品信息）
	payCallback _payCallback; // 外部回调（购买结果）
};
#endif  //__INTERFACE_FACEBOOK_H__
