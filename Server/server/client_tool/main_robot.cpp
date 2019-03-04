#include <iostream>
#include "net/tcpwrap.h"
#include <map>
#include <vector>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <errno.h>
#include "common/server_tool.h"
#include "all_client.h"
#include "struct/timer.h"
#include <google/protobuf/message.h>
#include <stdlib.h>

//#define DEBUG
//#define TRACE_NEW_STDOUT
#include "mem_alloc/trace_new.h"

using namespace std;
using namespace google::protobuf;
int gstop = 0;

CLIENT_MAP grespMap;
CLIENT_MAP greqMap;

int gdebugCout = 0;

int SLEEP_MS_BASE=5000;
int SLEEP_MS_RAND=5000;
int SLEEP_MS_LOGIN=10;

char g_buffer[100*1024];
char time_buff[64];

void update_time()
{
	timeval tmval;
	gettimeofday(&tmval, NULL);
	snprintf(time_buff,sizeof(time_buff), "%ld.%ld", tmval.tv_sec, tmval.tv_usec);
}

#define TEST_CASE_OUTPUT(stri) cout << time_buff << "|" << name() << "|" << m_timerID << "|" << m_currentusr.str() << stri << endl

class CTestCase
{
	public:
		CTestCase():m_bend(false),m_step(0)
		{
		}

		inline void set_user(USER_NAME& user)
		{
			m_currentusr = user;
		}

		inline void set_timer(int timerid)
		{
			m_timerID = timerid;
		}

		virtual ~CTestCase() {}
		
		virtual int get_req(unsigned int& cmd, Message*& pmessage) = 0;
		virtual int parse_resp(unsigned int cmd, CBinProtocol& binpro) = 0;
		virtual CTestCase* clone() = 0;
		virtual string name() = 0;

		//TestCase 是否结束
		inline bool end()
		{
			return m_bend;
		}
		
	protected:
		bool m_bend;
		int m_step;
		USER_NAME m_currentusr;
		int m_timerID;
};

//登录例子
class CTestCaseLogin:public CTestCase
{
	public:
	
		virtual int get_req(unsigned int& cmd, Message*& pmessage)
		{
			if(m_step == 0)
			{
				cmd = m_login.req_cmd();
				m_login.set_param(NULL, NULL, NULL, "xxxx");
				if(m_login.req_msg(0, NULL, pmessage))
				{
					TEST_CASE_OUTPUT("|INFO|login req");
					return 0;
				}
			}
			else
			{
				cmd = m_regist.req_cmd();
				const int ARGC = 3;
				char argv0[16] = {"robot"};
				char argv1[16] = {"1"};
				char argv2[16] = {"1"};
				char* argv[ARGC] = {argv0, argv1, argv2};
				if(m_regist.req_msg(ARGC, argv, pmessage))
				{
					TEST_CASE_OUTPUT("|INFO|regist req");
					return 0;
				}
			}

			return -1;
		}
		
		virtual int parse_resp(unsigned int cmd, CBinProtocol& binpro)
		{
			if(cmd == m_login.resp_cmd() && m_step == 0)
			{
				LoginResp* ploginresp = (LoginResp*)m_login.resp_msg();
				ploginresp->Clear();
				if( !ploginresp->ParseFromArray(binpro.packet(), binpro.packet_len()))
				{
					TEST_CASE_OUTPUT("|ERROR|parse login resp fail");
					return -1;
				}
				
				if(ploginresp->result() == ploginresp->NODATA)
				{
					TEST_CASE_OUTPUT("|INFO|login resp nodata");
					m_step = 1;
				}
				else
				{
					m_bend = true;
					if(ploginresp->result() == ploginresp->OK)
						TEST_CASE_OUTPUT("|INFO|login resp ok");
					else
					{
						TEST_CASE_OUTPUT("|INFO|login resp fail");
						return -1;
					}
				}
			}
			else if(cmd == m_regist.resp_cmd() && m_step == 1)
			{
				m_bend = true;
				LoginResp* pregistresp = (LoginResp*)m_login.resp_msg();
				pregistresp->Clear();
				if( !pregistresp->ParseFromArray(binpro.packet(), binpro.packet_len()))
				{
					TEST_CASE_OUTPUT("|ERROR|regist resp fail");
					return -1;
				}
				if(pregistresp->result() == pregistresp->OK)
				{
					TEST_CASE_OUTPUT("|INFO|regist resp ok");
				}
				else
				{
					TEST_CASE_OUTPUT("|INFO|regist resp fail");
					return -1;
				}
			}
			else
			{
				TEST_CASE_OUTPUT("|INFO|UNKOWN CMD");
				return 1;
			}

			return 0;
		}

		virtual CTestCase* clone()
		{
			CTestCase* p =  TRACE_NEW(CTestCaseLogin);
			return p;
		}

		virtual string name()
		{
			return "CTestCaseLogin";
		}
		
	protected:
		CClientLogin m_login;
		CClientRegist m_regist;
};

//登出例子
class CTestCaseLogout:public CTestCase
{
	public:
		virtual int get_req(unsigned int& cmd, Message*& pmessage) 
		{
			if(m_step == 0)
			{
				cmd = m_logout.req_cmd();
				if(m_logout.req_msg(0, NULL, pmessage))
				{
					TEST_CASE_OUTPUT("|INFO|logout req");
					return 0;
				}
			}

			return -1;
		}
		
		virtual int parse_resp(unsigned int cmd, CBinProtocol& binpro)
		{
			if(cmd == m_logout.resp_cmd())
			{
				m_bend = true;
				LogoutResp* plogoutresp = (LogoutResp*)m_logout.resp_msg();
				plogoutresp->Clear();
				if( !plogoutresp->ParseFromArray(binpro.packet(), binpro.packet_len()))
				{
					TEST_CASE_OUTPUT("|ERROR|parse logout resp fail");
					return -1;
				}
				if(plogoutresp->result() == plogoutresp->OK)
				{
					TEST_CASE_OUTPUT("|INFO|logout resp ok");
				}
				else
				{
					TEST_CASE_OUTPUT("|INFO|logout resp fail");
				}
			}
			else
			{
				TEST_CASE_OUTPUT("|INFO|UNKOWN CMD");
				return 1;
			}
			return 0;
		}
		
		virtual CTestCase* clone()
		{
			CTestCase* p =  TRACE_NEW(CTestCaseLogout);
			return p;
		}

		virtual string name()
		{
			return "CTestCaseLogout";
		}

	protected:
		CClientLogout m_logout;
};

////种植
//class CTestCasePlant:public CTestCase
//{
//	public:
//		virtual int get_req(unsigned int& cmd, Message*& pmessage) 
//		{
//			if(m_step == 0)
//			{
//				cmd = m_seed.req_cmd();
//				const int ARGC = 2;
//				char argv0[16] = {"1"};
//				char argv1[16] = {"1"};
//				char* argv[ARGC] = {argv0, argv1};
//				if(m_seed.req_msg(ARGC, argv, pmessage))
//				{
//					TEST_CASE_OUTPUT("|INFO|seed req");
//					return 0;
//				}
//			}
//			else if(m_step == 1)
//			{
//				//清除
//				cmd = m_weed.req_cmd();
//				const int ARGC = 1;
//				char argv0[16] = {"1"};
//				char* argv[ARGC] = {argv0};
//				if(m_weed.req_msg(ARGC, argv, pmessage))
//				{
//					TEST_CASE_OUTPUT("|INFO|weed req");
//					return 0;
//				}
//			}
//
//			return -1;
//		}
//		
//		virtual int parse_resp(unsigned int cmd, CBinProtocol& binpro)
//		{
//			if(cmd == m_seed.resp_cmd() && m_step == 0)
//			{
//				FieldResp* pseedresp = (FieldResp*)m_seed.resp_msg();
//				pseedresp->Clear();
//				if( !pseedresp->ParseFromArray(binpro.packet(), binpro.packet_len()))
//				{
//					TEST_CASE_OUTPUT("|ERROR|parse seed resp fail");
//					return -1;
//				}
//				if(pseedresp->result() == pseedresp->OK)
//				{
//					TEST_CASE_OUTPUT("|INFO|seed resp ok");
//					m_step = 1;
//				}
//				else
//				{
//					TEST_CASE_OUTPUT("|INFO|seed resp fail");
//					m_bend = true;
//				}
//			}
//			else if(cmd == m_weed.resp_cmd() && m_step == 1)
//			{
//				m_bend = true;
//				FieldResp* pweedresp = (FieldResp*)m_weed.resp_msg();
//				pweedresp->Clear();
//				if( !pweedresp->ParseFromArray(binpro.packet(), binpro.packet_len()))
//				{
//					TEST_CASE_OUTPUT("|ERROR|parse weed resp fail");
//					return -1;
//				}
//				if(pweedresp->result() == pweedresp->OK)
//				{
//					TEST_CASE_OUTPUT("|INFO|weed resp ok");
//				}
//				else
//				{
//					TEST_CASE_OUTPUT("|INFO|weed resp fail");
//				}
//
//			}
//			else
//			{
//				TEST_CASE_OUTPUT("|INFO|UNKOWN CMD");
//				return 1;
//			}
//			return 0;
//		}
//		
//		virtual CTestCase* clone()
//		{
//			CTestCase* p =  TRACE_NEW(CTestCasePlant);
//			return p;
//		}
//
//		virtual string name()
//		{
//			return "CTestCasePlant";
//		}
//
//	protected:
//		CClientFieldSeed m_seed;
//		CClientFieldWeed m_weed;
//};
//
////建造
//class CTestCaseBuild:public CTestCase
//{
//	public:
//		virtual int get_req(unsigned int& cmd, Message*& pmessage) 
//		{
//			if(m_step == 0)
//			{
//				cmd = m_newbuild.req_cmd();
//				const int ARGC = 4;
//				char argv0[16] = {"10101"}; //造一个房子
//				char argv1[16] = {"30"};
//				char argv2[16] = {"40"};
//				char argv3[16] = {"0"};
//				char* argv[ARGC] = {argv0, argv1, argv2, argv3};
//				if(m_newbuild.req_msg(ARGC, argv, pmessage))
//				{
//					TEST_CASE_OUTPUT("|INFO|newbuild req");
//					return 0;
//				}
//			}
//			else if(m_step == 1)
//			{
//				//清除
//				cmd = m_cancel.req_cmd();
//				const int ARGC = 1;
//				char argv0[16];
//				snprintf(argv0,sizeof(argv0), "%d", m_uniqid);
//				char* argv[ARGC] = {argv0};
//				if(m_cancel.req_msg(ARGC, argv, pmessage))
//				{
//					TEST_CASE_OUTPUT("|INFO|cancelbuild req");
//					return 0;
//				}
//			}
//
//			return -1;
//		}
//		virtual int parse_resp(unsigned int cmd, CBinProtocol& binpro)
//		{
//			if(cmd == m_newbuild.resp_cmd()  && m_step == 0)
//			{
//				BuildResp* pbuildresp = (BuildResp*)m_newbuild.resp_msg();
//				pbuildresp->Clear();
//				if( !pbuildresp->ParseFromArray(binpro.packet(), binpro.packet_len()))
//				{
//					TEST_CASE_OUTPUT("|ERROR|parse newbuild resp fail");
//					return -1;
//				}
//				if(pbuildresp->result() == pbuildresp->OK)
//				{
//					TEST_CASE_OUTPUT("|INFO|newbuild resp ok");
//					m_step = 1;
//					const Building& thebuild = pbuildresp->building();
//					m_uniqid = thebuild.uniqid();
//				}
//				else
//				{
//					TEST_CASE_OUTPUT("|INFO|newbuild resp fail");
//					m_bend = true;
//				}
//			}
//			else if(cmd == m_cancel.resp_cmd()  && m_step == 1)
//			{
//				m_bend = true;
//				BuildResp* pcancelresp = (BuildResp*)m_cancel.resp_msg();
//				pcancelresp->Clear();
//				if( !pcancelresp->ParseFromArray(binpro.packet(), binpro.packet_len()))
//				{
//					TEST_CASE_OUTPUT("|ERROR|parse cancelbuild resp fail");
//					return -1;
//				}
//				if(pcancelresp->result() == pcancelresp->OK)
//				{
//					TEST_CASE_OUTPUT("|INFO|cancelbuild resp ok");
//				}
//				else
//				{
//					TEST_CASE_OUTPUT("|INFO|cancelbuild resp fail");
//				}
//
//			}
//			else
//			{
//				TEST_CASE_OUTPUT("|INFO|UNKOWN CMD");
//				return 1;
//			}
//			return 0;
//		}
//		
//		virtual CTestCase* clone()
//		{
//			CTestCase* p =  TRACE_NEW(CTestCaseBuild);
//			return p;
//		}
//
//		virtual string name()
//		{
//			return "CTestCaseBuild";
//		}
//
//	protected:
//		CClientBuildingNew m_newbuild;
//		CClientBuildingCancel m_cancel;
//		int m_uniqid;
//};
//
////战斗
//class CTestCaseFight:public CTestCase
//{
//	public:
//		virtual int get_req(unsigned int& cmd, Message*& pmessage) 
//		{
//			if(m_step == 0)
//			{
//				cmd = m_fight.req_cmd();
//				const int ARGC = 3;
//				char argv0[16] = {"3"};
//				char argv1[16] = {"xx"};
//				char argv2[16] = {"0"};
//				char* argv[ARGC] = {argv0, argv1, argv2};
//				if(m_fight.req_msg(ARGC, argv, pmessage))
//				{
//					TEST_CASE_OUTPUT("|INFO|fight stranger req");
//					return 0;
//				}
//			}
//
//			return -1;
//		}
//		
//		virtual int parse_resp(unsigned int cmd, CBinProtocol& binpro)
//		{
//			if(cmd == m_fight.resp_cmd())
//			{
//				m_bend = true;
//				FightResp_old* pfightresp = (FightResp_old*)m_fight.resp_msg();
//				pfightresp->Clear();
//				if( !pfightresp->ParseFromArray(binpro.packet(), binpro.packet_len()))
//				{
//					TEST_CASE_OUTPUT("|ERROR|parse fight resp fail");
//					return -1;
//				}
//				if(pfightresp->result() == pfightresp->OK)
//				{
//					TEST_CASE_OUTPUT("|INFO|fight resp ok");
//				}
//				else
//				{
//					TEST_CASE_OUTPUT("|INFO|fight resp fail");
//				}
//			}
//			else
//			{
//				TEST_CASE_OUTPUT("|INFO|UNKOWN CMD");
//				return 1;
//			}
//			return 0;
//		}
//		
//		virtual CTestCase* clone()
//		{
//			CTestCase* p =  TRACE_NEW(CTestCaseFight);
//			return p;
//		}
//
//		virtual string name()
//		{
//			return "CTestCaseFight";
//		}
//
//	protected:
//		CClientFight m_fight;
//};
//
////名将之路
//class CTestCaseGladiator:public CTestCase
//{
//	public:
//		virtual int get_req(unsigned int& cmd, Message*& pmessage) 
//		{
//			if(m_step == 0)
//			{
//				cmd = m_gladiator.req_cmd();
//				if(m_gladiator.req_msg(0, NULL, pmessage))
//				{
//					TEST_CASE_OUTPUT("|INFO|gladiator req");
//					return 0;
//				}
//			}
//
//			return -1;
//		}
//		
//		virtual int parse_resp(unsigned int cmd, CBinProtocol& binpro)
//		{
//			if(cmd == m_gladiator.resp_cmd())
//			{
//				m_bend = true;
//				GladiatorResp* presp = (GladiatorResp*)m_gladiator.resp_msg();
//				presp->Clear();
//				if( !presp->ParseFromArray(binpro.packet(), binpro.packet_len()))
//				{
//					TEST_CASE_OUTPUT("|ERROR|parse gladiator resp fail");
//					return -1;
//				}
//				if(presp->result() == presp->OK)
//				{
//					TEST_CASE_OUTPUT("|INFO|gladiator resp ok");
//				}
//				else
//				{
//					TEST_CASE_OUTPUT("|INFO|gladiator resp fail");
//				}
//			}
//			else
//			{
//				TEST_CASE_OUTPUT("|INFO|UNKOWN CMD");
//				return 1;
//			}
//			
//			return 0;
//		}
//		
//		virtual CTestCase* clone()
//		{
//			CTestCase* p =  TRACE_NEW(CTestCaseGladiator);
//			return p;
//		}
//
//		virtual string name()
//		{
//			return "CTestCaseGladiator";
//		}
//
//	protected:
//		CClientGladiator m_gladiator;
//};
//
//
//class CTestCaseVisitFriend:public CTestCase
//{
//	public:
//		virtual int get_req(unsigned int& cmd, Message*& pmessage) 
//		{
//			if(m_step == 0)
//			{
//				cmd = m_visit.req_cmd();
//				const int ARGC = 1;
//				char argv0[33] = {0};
//				int len = snprintf(argv0, sizeof(argv0),"%s",m_currentusr.str());
//				int lastnum = atoi(argv0+len-1);
//				argv0[len-1] = '0'+(lastnum+1)%10;
//				
//				char* argv[ARGC] = {argv0};
//				if(m_visit.req_msg(ARGC, argv, pmessage))
//				{
//					TEST_CASE_OUTPUT("|INFO|visit req");
//					return 0;
//				}
//			}
//
//			return -1;
//		}
//		
//		virtual int parse_resp(unsigned int cmd, CBinProtocol& binpro)
//		{
//			if(cmd == m_visit.resp_cmd())
//			{
//				m_bend = true;
//				FriendVisitResp* pvisitresp = (FriendVisitResp*)m_visit.resp_msg();
//				pvisitresp->Clear();
//				if( !pvisitresp->ParseFromArray(binpro.packet(), binpro.packet_len()))
//				{
//					TEST_CASE_OUTPUT("|ERROR|parse visit resp fail");
//					return -1;
//				}
//				if(pvisitresp->result() == pvisitresp->OK)
//				{
//					TEST_CASE_OUTPUT("|INFO|visit resp ok");
//				}
//				else
//				{
//					TEST_CASE_OUTPUT("|INFO|visit resp fail");
//				}
//			}
//			else
//			{
//				TEST_CASE_OUTPUT("|INFO|UNKOWN CMD");
//				return 1;
//			}
//			return 0;
//		}
//		
//		virtual CTestCase* clone()
//		{
//			CTestCase* p =  TRACE_NEW(CTestCaseVisitFriend);
//			return p;
//		}
//
//		virtual string name()
//		{
//			return "CTestCaseVisitFriend";
//		}
//
//	protected:
//		CClientFriendVisit m_visit;
//};
//
//class CTestCaseToolAddExpr:public CTestCase
//{
//	public:
//		virtual int get_req(unsigned int& cmd, Message*& pmessage) 
//		{
//			if(m_step == 0)
//			{
//				cmd = m_role.req_cmd();
//				const int ARGC = 3;
//				char argv0[33] = {0};
//				char argv1[33] = {0};
//				char argv2[33] = {0};
//				snprintf(argv0, sizeof(argv0),"%s","expr");
//				snprintf(argv1, sizeof(argv1),"%d", rand()%1000000);
//				snprintf(argv2, sizeof(argv2),"%s", "wBOZsRI.D8ghMfOCM4De70");
//				
//				char* argv[ARGC] = {argv0,argv1,argv2};
//				if(m_role.req_msg(ARGC, argv, pmessage))
//				{
//					TEST_CASE_OUTPUT("|INFO|addexpr req");
//					return 0;
//				}
//			}
//
//			return -1;
//		}
//		
//		virtual int parse_resp(unsigned int cmd, CBinProtocol& binpro)
//		{
//			if(cmd == m_role.resp_cmd())
//			{
//				m_bend = true;
//				ModifyDataResp* pvisitresp = (ModifyDataResp*)m_role.resp_msg();
//				pvisitresp->Clear();
//				if( !pvisitresp->ParseFromArray(binpro.packet(), binpro.packet_len()))
//				{
//					TEST_CASE_OUTPUT("|ERROR|parse addexpr resp fail");
//					return -1;
//				}
//				if(pvisitresp->result() == pvisitresp->OK)
//				{
//					TEST_CASE_OUTPUT("|INFO|addexpr resp ok");
//				}
//				else
//				{
//					TEST_CASE_OUTPUT("|INFO|addexpr resp fail");
//				}
//			}
//			else
//			{
//				TEST_CASE_OUTPUT("|INFO|UNKOWN CMD");
//				return 1;
//			}
//			return 0;
//		}
//		
//		virtual CTestCase* clone()
//		{
//			CTestCase* p =  TRACE_NEW(CTestCaseToolAddExpr);
//			return p;
//		}
//
//		virtual string name()
//		{
//			return "CTestCaseToolAddExpr";
//		}
//
//	protected:
//		CClientToolRole m_role;
//};


class CTestCasePool
{
	public:
		CTestCasePool()
		{
			/*CTestCase* newcase;
			
			newcase = TRACE_NEW(CTestCasePlant);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCasePlant);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseBuild);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseBuild);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseFight);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseFight);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseFight);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseVisitFriend);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseVisitFriend);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseVisitFriend);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseGladiator);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseGladiator);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseGladiator);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseGladiator);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseGladiator);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseGladiator);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseGladiator);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseGladiator);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseGladiator);
			m_pool.push_back(newcase);
			newcase = TRACE_NEW(CTestCaseGladiator);
			m_pool.push_back(newcase);
			*/
			//newcase = TRACE_NEW(CTestCaseToolAddExpr);
			//m_pool.push_back(newcase);
		}
		
		~CTestCasePool()
		{
			clear();
		}

		void clear()
		{
			for(unsigned int i=0; i<m_pool.size(); ++i)
			{
				if(m_pool[i] != NULL)
				{
					TRACE_DEL(m_pool[i]);
					m_pool[i] = NULL;
				}
			}
		}

		CTestCase* select_rand_case()
		{
			//初始化保证m_pool非空
			return m_pool[rand()%m_pool.size()]->clone();
		}

		CTestCase* select_case_by_idx(int idx)
		{
			if(idx < 0 || idx >= (int)m_pool.size())
			{
				return NULL;
			}

			return m_pool[idx]->clone();
		}
		
	protected:
		
		vector<CTestCase*> m_pool;
};

CTestCasePool gtcpool;

class CRobot
{
	public:
		CRobot(CTimerPool<int>& timer, const char* name):m_curtc(NULL),m_timer(timer)
		{
			snprintf(m_robotname, sizeof(m_robotname), "%s", name);
		}
		
		~CRobot()
		{
			if(m_curtc)
			{
				TRACE_DEL(m_curtc);
				m_curtc = NULL;
			}
		}
		
		int create(string addr, unsigned short port, int idx, int loopnum, int userPerRobot)
		{
			int ret = m_socket.init();
			if(ret != 0)
			{
				cout << idx << "|INIT|m_socket.init() fail: " << m_socket.errmsg() << endl;
				return -1;
			}
			
			m_idx = idx;
			m_loopnum = loopnum;
			m_addr = addr;
			m_port = port;
			m_userPerRobot = userPerRobot;
			return 0;
		}

		int start()
		{
			shift_user();
			m_caseidx = 0;
			m_endflag = false;

			int ret = m_socket.connect(m_addr, m_port);
			if(ret != 0)
			{
				cout << m_name.str() << "|ERROR|m_socket.connect fail: " << m_socket.errmsg() << endl;
				return -1;
			}
			
			//必须先登录
			cout << time_buff << "|" << m_name.str() << "|INFO|start" << endl;
			CTestCase* newcase = TRACE_NEW(CTestCaseLogin);
			assgin_case(newcase);

			if(m_idx < m_loopnum)
			{
				return timer_delay_send(m_idx*SLEEP_MS_LOGIN, 0);
			}
			else
			{
				return timer_delay_send(SLEEP_MS_BASE, SLEEP_MS_RAND);
			}
		}

		inline int reinit()
		{
			m_idx += m_loopnum;
			if(m_idx >= m_loopnum*m_userPerRobot)
			{
				m_idx = m_idx%m_loopnum;
			}
			
			int ret = m_socket.init();
			if(ret != 0)
			{
				cout << m_idx << "|INIT|m_socket.init() fail: " << m_socket.errmsg() << endl;
				return -1;
			}
			return 0;
		}

		inline string get_name()
		{
			return m_name.str();
		}

		int on_poll()
		{
			//recv
			unsigned int cmd;
			int recvresult = recv(cmd);
			if(recvresult < 0)
				return -1;
			else if(recvresult == 1) //重新连接了
				return 1;

			//解析
			int ret = m_curtc->parse_resp(cmd, m_binpro);
			if(ret < 0)
				return -1;
			else if(ret == 1)
			{
				//其他通知包,不理会
				return 0;
			}

			if(gstop || m_endflag)
				return 0; //不发了
				
			//本case是否结束
			if(m_curtc->end())
			{
				//取下个case
				CTestCase*  newcase = gtcpool.select_case_by_idx(m_caseidx++);
				if(newcase == NULL)
				{
					//所有case执行完毕, logout
					m_endflag = true;
					CTestCase* newcase1 = TRACE_NEW(CTestCaseLogout);
					assgin_case( newcase1);
				}
				else
				{
					assgin_case( newcase);
				}
				
				//初始化
				cout << time_buff << "|" << m_name.str() << "|INFO|select testcase " << m_curtc->name() << endl;
			}

			timer_delay_send(SLEEP_MS_BASE, SLEEP_MS_RAND);
			
			return 0;
		}


		//发送下一个命令
		int send_on_timeout(int timerID)
		{
			unsigned int cmd=0;
			Message* pmessage = NULL;
			m_curtc->set_timer(timerID);
			if(m_curtc->get_req(cmd, pmessage) != 0)
			{
				return -1;
			}
			
			return send(cmd, pmessage);
		}

		inline int get_socket()
		{
			return m_socket.get_socket();
		}

		inline int get_idx()
		{
			return m_idx%m_loopnum;
		}

		
	protected:
		void assgin_case(CTestCase* newcase)
		{
			if(m_curtc != NULL)
			{
				TRACE_DEL(m_curtc);
			}

			m_curtc = newcase;
			m_curtc->set_user(m_name);
		}
	
		int timer_delay_send(int base, int expend)
		{
			//set timer
			unsigned int timeID;
			unsigned int timeoutMS = base; //延迟
			if(expend>0)
				timeoutMS += rand()%expend;

			int idx = get_idx();
			if(m_timer.set_timer_ms(timeID, idx, timeoutMS) != 0)
			{
				cout << m_name.str() << "|ERROR|set timer for " << idx << " in " << timeoutMS << "ms fail: " 
					<< m_timer.m_err.errcode << "," << m_timer.m_err.errstrmsg << endl;
				return -1;
			}

			cout << time_buff << "|" << m_name.str() << "|INFO|timer_delay_send|" << timeID << endl;

			return 0;
		}

		void shift_user()
		{
			char tmpname[16] = {0};
			snprintf(tmpname, sizeof(tmpname), "%s%d", m_robotname, m_idx);
			string tmpnamestr = tmpname;
			m_name.from_str(tmpnamestr);
		}

		int send(unsigned int cmd, Message* themsg)
		{
			if(gdebugCout)
			{
				cout << "send[" << hex << cmd << dec << "]: ";
				if(themsg)
					cout << themsg->DebugString() << endl;
				else
					cout << "NULL msg" << endl;
			}

			m_binpro.bind(g_buffer, sizeof(g_buffer));
			if(themsg && !themsg->SerializeToArray(m_binpro.packet(), m_binpro.packet_len()))
			{
				cout << m_name.str() << "|ERROR|SerializeToArray fail" << endl;
				return -1;
			}
		
			int sendLen  = themsg?m_binpro.total_len(themsg->GetCachedSize()):m_binpro.total_len(0);
			m_binpro.head()->format(m_name, cmd, sendLen);
			if(m_socket.write(m_binpro.buff(), sendLen) < 0)
			{
				cout << m_name.str() << "|ERROR|send fail: " << m_socket.errmsg() << endl;
				return -1;
			}
			
			return 0;
		}
	
		int recv(unsigned int& cmd)
		{
			int readresult = m_socket.read(m_binpro.buff(), m_binpro.total_len(0));
			if(readresult < 0)
			{
				cout << m_name.str() << "|ERROR|recv head fail: " << m_socket.errmsg() << endl;
				return -1;
			}
			else if(readresult == 0)
			{
				//closed, should restart
				return 1;
			}

			if(m_binpro.head()->parse_result() != COMMON_RESULT_OK)
			{
				cout << m_name.str() << "|ERROR|result from head=" << m_binpro.head()->parse_result() << endl;
				return -1;
			}

			int len = m_binpro.head()->parse_len();
			cmd = m_binpro.head()->parse_cmd();

			//cout << "recved cmd=" << cmd << " msg_len" << len << " proto_len=" << len - m_binpro.total_len(0) << endl;
			
			if(m_socket.read(m_binpro.packet(), len - m_binpro.total_len(0)) < 0)
			{
				cout << m_name.str() << "|ERROR|recv packet fail: " << m_socket.errmsg() << endl;
				return -1;
			}

			m_binpro.bind(g_buffer, len);

			if(gdebugCout)
				cout << "recv[" << hex << cmd << dec << "]" << endl;
			
			return 0;
		}

	protected:
		CTcpClientSocket m_socket;
		CBinProtocol m_binpro;
		int m_idx;
		int m_loopnum;
		int m_caseidx;
		CTestCase* m_curtc;
		CTimerPool<int>& m_timer;
		USER_NAME m_name;
		bool m_endflag;
		string m_addr;
		unsigned short  m_port;
		int m_userPerRobot;
		char m_robotname[64];
};

typedef map<int, CRobot*> ROBERT_MAP;

class CRobotEventManager
{
public:
	CRobotEventManager(CTimerPool<int>& thetimer):m_epollfd(0),m_events(NULL),m_epolltimeout(100),m_thetimer(thetimer) {}
	~CRobotEventManager()
	{
		if(m_epollfd > 0)
			close(m_epollfd);
		if(m_events != NULL)
			TRACE_DEL_ARRAY(m_events);
		ROBERT_MAP::iterator it;
		for(it = m_themap.begin(); it!= m_themap.end(); ++it)
		{
			TRACE_DEL( it->second);
		}
	}
	
	int create(int maxnum)
	{
		m_eventmaxnum = maxnum;
		m_epollfd = epoll_create(m_eventmaxnum);
		if(m_epollfd < 0)
		{
			cout << "epoll_create(" << maxnum << ") err=" << errno << "," << strerror(errno) << endl;
			return -1;
		}

		m_events = TRACE_NEW_ARRAY(epoll_event,maxnum);

		if(m_events == NULL)
		{
			cout << "new epoll_event fail" << endl;
			return -1;
		}

		return 0;
	}

	int add_robot(string addr, unsigned short port, int idx, int loopnum, int userPerRobot, const char* robotname)
	{
		CRobot* thenewrobot = TRACE_NEW_ARGS(CRobot,m_thetimer,robotname);
		if(thenewrobot == NULL)
		{
			cout << "new robot[" << idx << "] fail" << endl;
			return -1;
		}

		if(thenewrobot->create(addr, port, idx, loopnum, userPerRobot) != 0)
		{
			TRACE_DEL(thenewrobot);
			return -1;
		}

		if(add_pollin_event(thenewrobot) != 0)
		{
			TRACE_DEL(thenewrobot);
			return -1;
		}

		if(thenewrobot->start() != 0)
		{
			TRACE_DEL(thenewrobot);
			return -1;
		}

		m_themap[idx] = thenewrobot;
		
		return 0;
	}

	int poll_event()
	{
		update_time();
		int ret;
		int intrmax=3;
		while(intrmax-- > 0)
		{
			ret = epoll_wait(m_epollfd, m_events, m_eventmaxnum, m_epolltimeout);
			if(ret < 0)
			{
				if(errno == EINTR)
				{
					//中断重试
					continue;
				}
				else
				{
					cout << "epoll_wait err=" << errno << "," << strerror(errno) << endl;
					return -1; 
				}
			}

			for(int i=0; i<ret; ++i)
			{
				int idx = m_events[i].data.u32;
				ROBERT_MAP::iterator it = m_themap.find(idx);
				if(it == m_themap.end())
				{
					cout << "idx[" << idx << "] not in map" << endl;
					continue;
				}
				
				CRobot* probot = it->second;
				bool shouldrestart = false;

				if(m_events[i].events & EPOLLIN)
				{
					if(probot->on_poll() != 0)
					{
						shouldrestart = true;
					}
				}

				if(m_events[i].events & EPOLLOUT)
				{
					cout << probot->get_name() << "|INFO|EPOLLOUT comes..." << endl;
				}

				if(m_events[i].events &  EPOLLERR || m_events[i].events & EPOLLHUP)
				{
					cout << probot->get_name() << "|ERROR|EPOLLERR or EPOLLHUP comes..." << endl;
					shouldrestart = true;
				}

				if(shouldrestart)
				{
					del_event(probot);
					if(probot->reinit() == 0)
					{
						if(add_pollin_event(probot) == 0)
						{
							if(probot->start() ==0)
							{
							}
							else
							{
								del_event(probot);
							}
						}
					}
				}
			}

			break;
		}

		if(intrmax < 0)
		{
			return -1;
		}

		vector < unsigned int > vtimerID;
		vector < int >vtimerData;
		if(m_thetimer.check_timer( vtimerID,vtimerData) == 0)
		{
			for(unsigned int j=0;  j< vtimerID.size(); ++j)
			{
				int idx = vtimerData[j];
				ROBERT_MAP::iterator it = m_themap.find(idx);
				if(it == m_themap.end())
				{
					cout << "idx[" << idx<< "] not in map" << endl;
					continue;
				}

				CRobot* probot = it->second;
				if(probot->send_on_timeout(vtimerID[j]) == 0)
				{
				/* 重复加了	add_pollin_event(probot);*/
				}
			}
		}

		return 0;
	}

protected:
	int add_pollin_event(CRobot* probot)
	{
		int sock = probot->get_socket();
		struct epoll_event ev;
		ev.events = EPOLLIN;
		ev.data.u32 = probot->get_idx();
		int ret = epoll_ctl(m_epollfd, EPOLL_CTL_ADD, sock, &ev);
		if(ret < 0)
		{
			cout << "epoll_ctl(EPOLL_CTL_ADD) err=" << errno << "," << strerror(errno) << endl;
			return -1;
		}

		return 0;
	}

	int del_event(CRobot* probot)
	{
		int sock = probot->get_socket();
		epoll_event ignored;
		if(epoll_ctl(m_epollfd, EPOLL_CTL_DEL, sock, &ignored) < 0)
		{
			cout << "epoll_ctl(EPOLL_CTL_DEL)  err=" << errno << "," << strerror(errno) << endl;
			return -1;
		}

		return 0;
	}

protected:
	int m_epollfd; //epoll的fd
	ROBERT_MAP m_themap;
	epoll_event * m_events;//epoll用的events
	int m_eventmaxnum;
	int m_epolltimeout;
	CTimerPool<int>& m_thetimer;
};


int main_robot(int argc, char** argv, int* thestop)
{
	if(argc < 6)
	{	
		cout << argv[0] << ": robotnum userPerRobot robotname svrip1 svrport1 svrip2 svrpot2 ..." << endl;
		return -1;
	}

	int curpos = 1;
	int robotnum = atoi(argv[curpos++]);
	int userPerRobot = atoi(argv[curpos++]);
	int nameidx = curpos++;
	vector<string> ips;
	vector<unsigned short> ports;
	int randval = 0;
	int svrnum = 0;

	if(CServerTool::ensure_max_fds(robotnum+10) != 0)
	{
		cout << "setrlimit fail: error=" << errno << "," << strerror(errno) << endl;
		return -1;
	}
		
	unsigned int  memsize = CTimerPool<int>::mem_size(robotnum);
	char* mem = TRACE_NEW_ARRAY(char, memsize);
	CTimerPool<int> thetimer(mem, memsize, robotnum);
	if(!thetimer.valid())
	{
		cout << "timer not valid" << endl;
		TRACE_DEL_ARRAY(mem);
		return -1;
	}

	update_time();

	CRobotEventManager theeventmgr(thetimer);
	
	while(curpos < argc)
	{
		ips.push_back(argv[curpos++]);
		if(curpos == argc)
		{
			cout << "args not enough" << endl;
			TRACE_DEL_ARRAY(mem);
			return -1;
		}

		ports.push_back(atoi(argv[curpos++]));
	}

	if((svrnum=ips.size()) == 0)
	{
		cout << "args not enough" << endl;
		TRACE_DEL_ARRAY(mem);
		return -1;
	}

	if(theeventmgr.create(robotnum) != 0)
	{
		cout << "event manager create fail" << endl;
		TRACE_DEL_ARRAY(mem);
		return -1;
	}

	cout << "robortnum=" << robotnum << endl;
	for(int i=0; i<robotnum; ++i)
	{
		randval = rand()%svrnum;
		if(theeventmgr.add_robot(ips[randval],ports[randval], i, robotnum, userPerRobot, argv[nameidx]) !=0)
		{
			TRACE_DEL_ARRAY(mem);
			return -1;
		}
	}

	while( (*thestop) == 0)
	{
		theeventmgr.poll_event();
	}

	//等待未处理的信息
	for(int i=0; i<10; ++i)
	{
		usleep(100000);
		theeventmgr.poll_event();
	}

	TRACE_DEL_ARRAY(mem);

	return 0;
}


static void stophandle(int iSigNo)
{
	gstop = 1;
	cout << "recv signal(" << iSigNo << ") stop=" << gstop << endl;
}

int main(int argc, char** argv)
{
	//env
	char* envval = getenv("SLEEP_MS_BASE");
	if(envval)
	{
		SLEEP_MS_BASE = atoi(envval);
	}

	envval = getenv("SLEEP_MS_RAND");
	if(envval)
	{
		SLEEP_MS_RAND = atoi(envval);
	}
	
	envval = getenv("SLEEP_MS_LOGIN");
	if(envval)
	{
		SLEEP_MS_LOGIN = atoi(envval);
	}

	cout << "SLEEP_MS_BASE=" << SLEEP_MS_BASE << endl;
	cout << "SLEEP_MS_RAND=" << SLEEP_MS_RAND << endl;
	cout << "SLEEP_MS_LOGIN=" << SLEEP_MS_LOGIN << endl;
	
	//单进程
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::ignore(SIGPIPE);
	main_robot(argc, argv, &gstop);
	gtcpool.clear();
	CTraceNew::Instance()->show(cout);

	return 0;
}

