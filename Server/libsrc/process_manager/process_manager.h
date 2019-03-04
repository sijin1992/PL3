/*
 * @file    process_manager.h
 * @brief    多进程管理类
 * @date     2010-11-24
 *
 * @note    
 *
 */
#ifndef _PROCESS_MANAGER_H_
#define _PROCESS_MANAGER_H_

#include <time.h>
#include <unistd.h>

class CProcessManager
{
	/* -----------------------------------------------------------
	*  在process_Manager的世界里
	*  					0   	表示成功
	*					<0 		表示系统异常
	*					>0		程序正常返回值
	*  ---------------------------------------------------------*/
public:
	const static int SUCCESS = 0;
	const static int ERROR = -1;

public:
	CProcessManager();
	virtual ~CProcessManager();

	inline void set_child_num(unsigned int iChildNum)
	{
		m_iChildNum	= iChildNum;
		if(m_childs)
		{
			delete[] m_childs;
		}
		m_childs = new pid_t[m_iChildNum];

		if(m_childs)
		{
			for(unsigned int i=0; i<m_iChildNum; ++i)
			{
				m_childs[i] = -1;
			}
		}
	}

	//开始Process Manager运行
	int run( int argc, char *argv[] );


	//绑定一个关闭信号，*f!=0时就不再监控了
	inline void attach_stop_flag(int* f)
	{
		m_piStopFlag = f;
	}

	//监控到有进程结束时重启的限制
	//在limitPeriod秒内可以重启几次.
	//达到限制之后，sleepBase秒，如果连续达到限制每次多sleep sleepInc秒
	inline void set_safe_limit(int limitPeriod, int limitTimes, int sleepBase, int sleepInc)
	{
		m_limitPeriod = limitPeriod;
		m_limitTimes = limitTimes;
		m_sleepBase = sleepBase;
		m_sleepInc = sleepInc;
	}

	inline void close_std_output()
	{
		m_stdoutput = false;
	}

protected:
	void close_childs();
	void on_child_start(pid_t id);
	void on_child_end(pid_t id);

	void for_safe();
	//程序实体，实体异常推出或者需要新的处理实体时此函数会被调用
	//return 0 是ok
	virtual int entity( int argc, char *argv[] ) = 0;

	//补充运行实体，每次补充1个
	int add_entity( int argc, char *argv[] );
	
protected:
	unsigned int 	m_iChildNum;
	pid_t*  m_childs;
	int*	m_piStopFlag;
	int	m_limitPeriod;
	int	m_limitTimes;
	int	m_sleepBase;
	int	m_sleepInc;
	int 	m_stdoutput;
	int	m_limitCount;
	int	m_incCount;
	time_t m_lastTime;
};

#endif		//_PROCESS_MANAGER_H__

