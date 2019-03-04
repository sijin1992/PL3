#ifndef __LOGIC_DIRVER_H__
#define __LOGIC_DIRVER_H__

#include "msg.h"
#include "msg_queue.h"
#include "struct/timer.h"
#include "handle_manager.h"
#include "toolkit.h"
#include "../common/sleep_control.h"
#include "ini/ini_file.h"
#include "log/log.h"
#include "net/tcpwrap.h"
#include <map>
#include <vector>
#include <assert.h>
#include "log_pipe_writer.h"

using namespace std;

//driver��������Ӧ�ùᴩ����������
//create LogicProcessor ʹ��newʱ��driverֹͣʱ���������еĶ����ǲ���delete�ģ�Ҳû��Ҫ��
//ʹ��objpool�����ɶ�������Զ������ڴ�

//msg�������, ���queue����ܾ�����
typedef map<unsigned int, vector<unsigned int>* > CMD_QUEUEID_MAP;
class CCmdFilter
{
	public:
		inline void allow(unsigned int cmd, unsigned int queueID)
		{
			add_to_map(&m_allowMap, cmd, queueID);
		}

		inline void deny(unsigned int cmd, unsigned int queueID)
		{
			add_to_map(&m_denyMap, cmd, queueID);
		}

		bool check(unsigned int cmd, unsigned int queueID);


		~CCmdFilter();

	protected:
		inline void add_to_map(CMD_QUEUEID_MAP* pmap,unsigned int cmd, unsigned int queueID)
		{
			CMD_QUEUEID_MAP::iterator it = pmap->find(cmd);
			if(it != pmap->end())
			{
				it->second->push_back(queueID);
			}
			else
			{
				vector<unsigned int>* p = new vector<unsigned int>;
				assert(p);
				p->push_back(queueID);
				(*pmap)[cmd] = p;
			}
		}

	protected:
		CMD_QUEUEID_MAP m_allowMap;
		CMD_QUEUEID_MAP m_denyMap;
};

class CLogicDriverConfig
{
public:
	bool saveLogicInMsa;
	unsigned int msaKey;
	unsigned int msaSize;
	unsigned int msaBlocksize;
	bool useTimer;
	unsigned int timerKey;
	unsigned int timerMaxNum;
	bool useObjPool;
	unsigned int readMsgNumInLoop;
	unsigned int atWhichServer;
	bool useSuperCreator; //�Ƿ�ʹ��SuperCreator���Զ��崦���߼�
	unsigned int logReportQueueID;
	unsigned int logReportSvrID;
public:
	CLogicDriverConfig();
	int readFromIni(const char* file, const char* sector="LOGIC_DRIVER");
	int readFromIni(CIniFile& oIni, const char* sector="LOGIC_DRIVER");
	
};

class CLogicDriver
{

public:
	unsigned int stopFlag;

public:
	CLogicDriver();

	virtual ~CLogicDriver();

	//return 0=����superCreator, ������ʹ��
	virtual int set_super_creator(CLogicMsg& msg, CLogicCreator& superCreator);

	//hook
	//��ÿ��ѭ���м����Լ��Ĵ������
	//����ֵ�Ǻ�������Ĺ������������ݸ�sleep.week
	virtual int hook_loop_end();
	
	int init(CLogicDriverConfig& config);

	int add_msg_queue(unsigned int id, CMsgQueue* pqueue);

	inline void allow_cmd(unsigned int cmd, unsigned int queueID)
	{
		m_cmdFilter.allow(cmd,  queueID);
	}

	inline void deny_cmd(unsigned int cmd, unsigned int queueID)
	{
		m_cmdFilter.deny(cmd,  queueID);
	}

	void remove_msg_queue(unsigned int id)
	{
		m_queuemap.erase(id);
	}

	int regist_handle(unsigned int msgCmd, CLogicCreator creator);

	inline int do_msg(CLogicMsg& msg)
	{
		if(!m_inited)
		{
			LOG(LOG_ERROR, "do_msg() not inited");
			return -1;
		}

		return m_pmanager->process_msg(msg);
	}

	//loopNum < 0 ������ѭ������
	int main_loop(int loopNum);

	CToolkit* get_toolkit() {return &m_toolkit;}

protected:
	CLogicHandleManager* m_pmanager;
	DRIVER_TIMER* m_ptimer;
	CShmWrapper m_timershm;
	char *m_delTimerMem;
	MSG_QUEUE_MAP m_queuemap;
	CToolkit m_toolkit;
	unsigned int m_readMsgNumInLoop;
	bool m_inited;
	unsigned int m_serverID;
	HANDLE_REG_MAP m_theRegMap;
	CLogicCreator m_theSuper;
	bool m_useSuper;
	CSleepControl m_sleep;
	CCmdFilter m_cmdFilter;
	unsigned long m_msgcnt;
	unsigned long m_timermsgcnt;
	CLogPipeWriter *m_logPipeWriter;
};

#endif

