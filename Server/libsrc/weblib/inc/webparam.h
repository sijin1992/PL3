
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
	 *	purpose:	��ʼ��������url������cookie
	 */
	webparam();	


	/*
	 *	purpose:	��ȡ����url���������map�ϣ�Ϊ��ֵ��
	 */
	inline map<string, string> getparam()
	{
		return m_Params;
	}

	/*
	 *	purpose:	��ȡcookie�������map�ϣ�Ϊ��ֵ��
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
	 *	purpose:	��ȡurl��������
	 */
	string get_cont(){return m_strContent;}

	/*
	 *	purpose:	��ȡcookie��������
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

