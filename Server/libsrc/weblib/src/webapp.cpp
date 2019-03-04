/*
 *	SOURCE：	webapp.cpp
 *	COPYRIGHT：	Tencent
 *	DATE：		2006-10-24
 *	AUTHOR：	chrislin
 *
 *	PURPOSE:	class for pet community
 */

#include "webapp.h"
#include <sys/stat.h>
#include <unistd.h>

#ifdef WEBLIB_WITH_FASTCGI
    FCGX_Stream *fcgi_in, *fcgi_out, *fcgi_err;
    FCGX_ParamArray fcgi_env;
#endif

webapp::webapp():m_sArgv0(NULL)
{
	m_bstop = false;
	m_iSerialNo = 0;
	m_errcount = 0;
#ifdef WEBLIB_WITH_FASTCGI
	m_iMaxNo = DEFAULT_MAX_SERIAL_NO;
#else
	m_iMaxNo = 0;
#endif
}

/*
 *	PURPOSE: CGI执行的主函数
 */
void webapp::run()
{
	#ifdef WEBLIB_WITH_FASTCGI
	time_t tStart = 0;
	struct stat stStatTmp;  
    	if(m_sArgv0 != NULL)
    	{
    		if(stat(m_sArgv0,  &stStatTmp) == 0)
    		{
    			tStart = stStatTmp.st_mtime;
    		}
    	}
    	
    	while (FCGX_Accept(&fcgi_in, &fcgi_out, &fcgi_err, &fcgi_env) >= 0) 
    	{
    		
    		fcgi_ostream oStream(fcgi_out);
    		pout = &oStream;
    	#else
		pout = &cout;
	#endif

		webparam param;
		m_param = param.getparam();	
		m_cookie = param.getcookie();
		m_env = param.getenv();

		++m_iSerialNo;
		head();
		int ret = process();
		if(ret != 0)
		{
			++m_errcount;
		}

#ifdef WEBLIB_WITH_FASTCGI
		//主动退出
            if(m_bstop)
            {
                FCGX_Finish();
                return;
            }
		
		//最大循环次数结束
		if(m_iMaxNo != NO_LIMIT_SERIAL_NO && m_iSerialNo >= m_iMaxNo)
		{
			FCGX_Finish();
			return;
		}

		//程序是有更新结束
    		if(tStart != 0 && stat(m_sArgv0,  &stStatTmp) == 0 && tStart != stStatTmp.st_mtime)
    		{
 			FCGX_Finish();
   			return;
    		}
	}
#endif

}


