#ifndef _WEB_COMMON_H_
#define _WEB_COMMON_H_

// c header
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/timeb.h>
#include <sys/wait.h>
#include <netdb.h>

//	stl header
#include <string>
#include <vector>
#include <map>
#include <iostream>
#include <algorithm>
#include <sstream>

using namespace std;

#ifndef SIZE_K
#define SIZE_K(size) ((size) * 1024)
#endif
#define ALIGN(size, boundary) (((size)+((boundary)-1))&~((boundary)-1))

//	8¶ÔÆë
#define ALIGN_8(size) ALIGN(size, 8)

#define CSL_MAX(a,b) ((a)>(b)?(a):(b))
#define CSL_MIN(a,b) ((a)<(b)?(a):(b))


#ifdef WEBLIB_WITH_FASTCGI
#include "fcgi_config.h"
#include "fcgiapp.h"
#include "fcgio.h"
const int DEFAULT_MAX_SERIAL_NO = 10000;
const int NO_LIMIT_SERIAL_NO = 0;
extern   FCGX_Stream *fcgi_in, *fcgi_out, *fcgi_err;
extern   FCGX_ParamArray fcgi_env;
#endif


class CHttpRespHead
{
public:
	CHttpRespHead()
	{
		m_bEnableCache = false;
		m_strContentType = "text/html";
		m_strCharSet = "";
	}

	void EnableCache(bool bEnableCache)
	{
		m_bEnableCache = bEnableCache;
	}

	void SetContentType(string strContentType)
	{
		m_strContentType = strContentType;
	}	

	void SetCharSet(string strCharSet)
	{
		m_strCharSet = strCharSet;
	}
	
	string output()
	{
		ostringstream oss;
		if(m_strCharSet == "")
		{
			oss << "Content-type: " << m_strContentType <<"\r\n";
		}
		else
		{
			oss << "Content-type: " << m_strContentType << ";charset=" << m_strCharSet << "\r\n";
		}

		
		if(!m_bEnableCache)
		{
			oss << "Cache-Control: no-cache\r\n";
			oss << "Pragma: no-cache\r\n";
		}

		oss << "\r\n";
		return oss.str();
	}

	static string  HtmlHead()
	{
		return "Content-Type:text/html\r\nCache-Control: no-cache\r\nPragma: no-cache\r\n\r\n";
	}
	
	static string  HtmlHeadGB()
	{
		return "Content-Type:text/html;charset=gb2312\r\nCache-Control: no-cache\r\nPragma: no-cache\r\n\r\n";
	}
	
	static string  XmlHead()
	{
		return "Content-Type:text/xml\r\nCache-Control: no-cache\r\nPragma: no-cache\r\n\r\n";
	}
	
	static string  XmlHeadGB()
	{
		return "Content-Type:text/xml;charset=gb2312\r\nCache-Control: no-cache\r\nPragma: no-cache\r\n\r\n";
	}
	
protected:
	bool m_bEnableCache;
	string m_strContentType;
	string m_strCharSet;
};



#endif
