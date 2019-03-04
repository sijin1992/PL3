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
	//�����
	#define WEBOUT (*pout)
	
public:
	webapp();
	virtual ~webapp(){};

	/*
	* Ϊ���ô�Ҳ��������ͷ�����ͷ
	*/
	virtual void head() = 0;


	/*
	 *	purpose:	������, return 0��ʾok
	 */
	virtual int process() = 0;

	/*
	 *	purpose:	��ڣ���fcgi��˵����ѭ��
	 */
	virtual void run();

	/*
	* �������������ֹ��ѭ��
	*/
	inline void stop()
	{
		m_bstop = true;
	}

	/*
	*��ѭ��������
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
	*����cgi��������ƣ�main��argv[0]
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
