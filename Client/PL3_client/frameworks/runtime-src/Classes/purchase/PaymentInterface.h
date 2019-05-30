//
//  PaymentInterface.h
//
//  Created by Ruoqian, Chen on 2014/12/20
//


#ifndef  __PAYMENT_INTERFACE_H__
#define  __PAYMENT_INTERFACE_H__

#include <string>
#include <vector>
#include <map>

class PaymentInterface
{
public:
	static void Init(void);
	static void ReqItemInfo(const std::vector<std::string>& vecItemTypeId);

	static void PayStart(const char *pszItemTypeId, const char *pszExtraVerifyInfo);
	static void PayEnd(bool result, const char *pszItemKey);
	static void restore();
	
	static void adjustTrackEvent(const std::string & event);
	static void flurryLogEvent(const std::string & event, const std::map<std::string, std::string> & params);
	static void onGAAddResourceEvent(const std::string & eventID, const int eventNum, const std::vector<std::string>& events);
	static void onGAAddProgressionEvent(const std::string & eventID, const std::vector<std::string>& events);
	static void onLoginEvent(const std::string & verson, const std::string & userID);
	static void RestartAPP();
	static std::string getUUID();

};
#endif  //__INTERFACE_FACEBOOK_H__
