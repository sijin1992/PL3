
#ifndef _WEB_PARAM_H_
#define _WEB_PARAM_H_

#include <string>
#include <map>
#include <iostream>
#include "webdef.h"

using namespace std;

class webparam
{
public:
	
	/*
	 *	purpose:	初始化，解析url参数、cookie
	 */
	webparam();	


	/*
	 *	purpose:	获取所有url参数存放于map上，为名值对
	 */
	inline map<string, string> getparam()
	{
		return m_Params;
	}

	/*
	 *	purpose:	获取cookie，存放于map上，为名值对
	 */
	inline map<string, string> getcookie()
	{
		return m_cookie;
	}

	inline map<string, string> getenv()
	{
		return m_env;
	}

	/*
	 *	purpose:	获取url环境变量
	 */
	string get_cont(){return m_strContent;}

	/*
	 *	purpose:	获取cookie环境变量
	 */
	string get_cookie(){return m_strCookies;}


	
protected:
	inline string GetRequestMethod();
	
	void GetCgiValue();
	
	void ParseParams();

	void ParseCookies();

	void ParseEnv();

	string UrlDecode(const string strSrc);

	int HexToInt(char ch);

protected:
	string 					m_strContent;
	string 					m_strCookies;
	map<string, string> 	m_Params;
	map<string, string>		m_cookie;
	map<string, string>	m_env;
};


#endif

