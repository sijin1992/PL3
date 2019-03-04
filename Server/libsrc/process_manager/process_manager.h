/*
 * @file    process_manager.h
 * @brief    ����̹�����
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
	*  ��process_Manager��������
	*  					0   	��ʾ�ɹ�
	*					<0 		��ʾϵͳ�쳣
	*					>0		������������ֵ
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

	//��ʼProcess Manager����
	int run( int argc, char *argv[] );


	//��һ���ر��źţ�*f!=0ʱ�Ͳ��ټ����
	inline void attach_stop_flag(int* f)
	{
		m_piStopFlag = f;
	}

	//��ص��н��̽���ʱ����������
	//��limitPeriod���ڿ�����������.
	//�ﵽ����֮��sleepBase�룬��������ﵽ����ÿ�ζ�sleep sleepInc��
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
	//����ʵ�壬ʵ���쳣�Ƴ�������Ҫ�µĴ���ʵ��ʱ�˺����ᱻ����
	//return 0 ��ok
	virtual int entity( int argc, char *argv[] ) = 0;

	//��������ʵ�壬ÿ�β���1��
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

