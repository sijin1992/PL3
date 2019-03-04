#ifndef _WEB_APP_H_
#define _WEB_APP_H_

/*
 *	our header file
 */
#include "webparam.h"
#include "webpage.h"

/*
 *	system header file
 */
#include <sys/types.h>
#include <sys/shm.h>
#include <string>
#include <vector>
#include <iostream>
#include <map>
#include <set>

using namespace std;

/*
 *	class for webapp
 */
class webapp
{
	//输出用
	#define WEBOUT (*pout)
	
public:
	webapp();
	virtual ~webapp(){};

	/*
	* 为了让大家不忘记输出头，输出头
	*/
	virtual void head() = 0;


	/*
	 *	purpose:	处理函数, return 0表示ok
	 */
	virtual int process() = 0;

	/*
	 *	purpose:	入口，对fcgi来说是主循环
	 */
	virtual void run();

	/*
	* 调用这个函数中止主循环
	*/
	inline void stop()
	{
		m_bstop = true;
	}

	/*
	*主循环最大次数
	*/
	inline void set_maxno(int iMax)
	{
		m_iMaxNo = iMax;
	}

	inline int get_errcount()
	{
		return m_errcount;
	}

	inline int get_serial()
	{
		return m_iSerialNo;
	}

	/*
	*设置cgi程序的名称，main的argv[0]
	*/
	void set_program_name(const char* argv0)
	{
		m_sArgv0 = argv0;
	}

protected:
	map<string,string>		m_param;
	map<string,string>		m_cookie;
	map<string,string>		m_env;
	webpage				m_page;
	ostream*				pout;

	int					m_iSerialNo;
	int 					m_iMaxNo;
	bool 				m_bstop;

	int					m_errcount;

	const char*				m_sArgv0;
};
#endif
