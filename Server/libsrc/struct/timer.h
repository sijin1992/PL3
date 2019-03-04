#ifndef __TIMER_H__
#define __TIMER_H__

#include "common_def.h"
#include <sys/time.h>
#include <iostream>
#include <vector>
#include <string.h>
#include <stdio.h>
//#include "../log/log.h"

using namespace std;


#define  TIMER_POOL_MAGICTAG "Timer_mars_20110522"

#pragma pack(push)
#pragma pack(1)

template<typename TDATA>
/*
* timer定时最小单位是ms，内部有ms和s两个级别的精度
* 100秒以下的超时精确到ms，否则超时精确到s，最大超时时间100*1000s
* 
* 设计思想
* 1 基于空间换时间
* 2 涵盖常用的时间段和精度1ms~1000s，大部分在%1的误差内
* 3 中庸。采用2个table的复合避免占用空间过大。
*
* 扩展
* 可以重新设计成只含有一个table的timer，自定义覆盖范围和精度
* 使用者需要同时拥有几个timer，自己选择在具体需求的情况上使用那个timer
* 比如在一般调用超时(1s级别)和回写扫描(100s级别)。
*/
class CTimerPool
{
	public:
		static const unsigned int VERSION = 0x1001;
		static const unsigned int ARRAY_SIZE = 100000;
		static const unsigned int S_TO_MS = 1000; // 进制是1000
		static const int ERR_VERSION = -1;
		static const int ERR_MEM_NOT_ENOUGH = -2;
		static const int ERR_BAD_HEADER = -3;
		static const int ERR_BAD_LIST = -4;
		static const int ERR_NOT_VALID = -5;
		static const int ERR_TIME = -6;
		static const int ERR_ID_NOTVALID = -7;


		typedef struct tagTimerHead
		{
			char magicTag[32];
			unsigned int version;
			unsigned int maxTimerNum; //最多几个timer
			unsigned int dataSize; //sizeof(TDATA),校验用
			unsigned int freeHead; //已释放的节点链表，值是m_nodeArray数组的idx 0=空，m_nodeArray第一个节点不参与分配
			unsigned int timeoutHead; //timeout链表
			unsigned int timeoutTail; //timeout链表尾部，便于追加
			unsigned int unusedBorder; //此位置及后面的节点未初始化，单位是节点数组的下标
			unsigned int usednum; //使用了多少节点了
			char reserve[196];
			void debug(ostream& os)
			{
				os << "TIMER_HEAD{" << endl;
				os << "magicTag|" << magicTag << endl;
				os << "version|" << version << endl;
				os << "maxTimerNum|" << maxTimerNum << endl;
				os << "dataSize|" << dataSize << endl;
				os << "freeHead|" << freeHead << endl;
				os << "timeoutHead|" << timeoutHead << endl;
				os << "unusedBorder|" << unusedBorder << endl;
				os << "usednum|" << usednum << endl;
				os << "} end TIMER_HEAD" << endl;
			}
		}TIMER_HEAD;

		typedef struct tagTimerNode
		{
			unsigned int nextIdx; //链表下一个idx，0=结束。可能是在空闲链表中，可能是在table中
			unsigned int valid;   //是否有效，del掉之后就无效了
			TDATA data; 		
			void debug(ostream& os)
			{
				os << "TIMER_NODE{" << endl;
				os << "nextIdx|" << nextIdx << endl;
				os << "valid|" << valid << endl;
				//纠结，debug状态下搞,val,key不支持的话自己重载
#ifdef DEBUG
				os << "data|" << data << endl;
#endif
				os << "} end TIMER_NODE" << endl;
			}
			
		}TIMER_NODE;

		/**
		* 有s和ms两个table
		* 前者1s-100000s的表示范围，每个偏移是1s
		* 后者1ms-100s的表示范围，每个偏移是1ms
		* 以set传入的超时时间来分表，100s以下的分到ms表中
		*/
		typedef struct tagTimerTable
		{
			timeval lastCheckTime;
			unsigned int curIdx;
			unsigned int heads[ARRAY_SIZE]; //链表头数组
			unsigned int tails[ARRAY_SIZE]; //链表尾数组
			void debug(ostream& os, TIMER_NODE* pnodes, TIMER_HEAD* phead)
			{
				os << "TIMER_TABLE{" << endl;
				os << "lastCheckTime|" << lastCheckTime.tv_sec << "s, " << lastCheckTime.tv_usec << "us" << endl;
				os << "curIdx|" << curIdx << endl;
				unsigned int it = curIdx;
				for(unsigned int i=0; i<ARRAY_SIZE; ++i)
				{
					unsigned int nodeIdx = heads[it];
					if(nodeIdx != 0)
					{
						os << "[" << it << "] head=" << heads[it] << " tail=" << tails[it]<< endl;
						os << "----------node list----------" << endl;
						for(unsigned int j=0; j<phead->unusedBorder && nodeIdx != 0;++j)
						{
							pnodes[nodeIdx].debug(os);
							nodeIdx = pnodes[nodeIdx].nextIdx;
						}
						os << "----------end----------" << endl;
					}
					it = (it+1)%ARRAY_SIZE;
				}
				
				os << "} end TIMER_TABLE" << endl;
			}
		}TIMER_TABLE;


	public:

		//计算需要的内存大小
		static unsigned int mem_size(unsigned int maxTimerNum)
		{
			return sizeof(TIMER_HEAD)+sizeof(TIMER_TABLE)*2+sizeof(TIMER_NODE)*(maxTimerNum+1);
		}

		////使当前mem失效，若在mem上建立CTimerPool必定走格式化流程
		static void clear(void* mem)
		{
			memset(mem, 0x0, sizeof(TIMER_HEAD));
		}



		CTimerPool(void* memStart, unsigned int maxMemSize, unsigned int maxTimerNum, timeval* curtime = NULL)
		{
			m_valid = false;
			m_memSize = mem_size(maxTimerNum);
			if(maxMemSize < m_memSize)
			{
				m_err.errcode = ERR_MEM_NOT_ENOUGH;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool maxTimerNum=%u needs memSize=%u but maxMemSize=%u", 
					maxTimerNum, m_memSize,maxMemSize);
				return;
			}

			m_phead = (TIMER_HEAD*)memStart;
			m_ptableS = (TIMER_TABLE*)((char*)m_phead+sizeof(*m_phead));
			m_ptableMS = (TIMER_TABLE*)((char*)m_ptableS+sizeof(*m_ptableS));
			m_pnodes = (TIMER_NODE*)((char*)m_ptableMS+sizeof(*m_ptableMS));
			m_formated = false;

			if(strncmp(m_phead->magicTag, TIMER_POOL_MAGICTAG, sizeof(m_phead->magicTag))!= 0) //需要格式化
			{
				m_formated = true;
				snprintf(m_phead->magicTag,sizeof(m_phead->magicTag), "%s", TIMER_POOL_MAGICTAG);
				m_phead->version = VERSION;
				m_phead->dataSize = sizeof(TDATA);
				m_phead->timeoutHead = 0;
				m_phead->timeoutTail = 0;
				m_phead->freeHead = 0;
				m_phead->unusedBorder = 1;
				m_phead->maxTimerNum = maxTimerNum;
				m_phead->usednum = 0;
				memset(m_ptableS, 0x0, sizeof(*m_ptableS));
				memset(m_ptableMS, 0x0, sizeof(*m_ptableMS));
				if(curtime == NULL)
				{
					gettimeofday(&(m_ptableS->lastCheckTime),NULL);
				}
				else
				{
					memcpy(&(m_ptableS->lastCheckTime),curtime, sizeof(timeval));
				}
				memcpy(&(m_ptableMS->lastCheckTime),&(m_ptableS->lastCheckTime), sizeof(timeval));
				//精度标准化
				m_ptableS->lastCheckTime.tv_usec = 0;
				m_ptableMS->lastCheckTime.tv_usec = (m_ptableMS->lastCheckTime.tv_usec/1000)*1000; 
			}
			else
			{
				//校验
				if(m_phead->version != VERSION )
				{
					m_err.errcode = ERR_VERSION;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool head.version(%u) != version(%u)", m_phead->version, VERSION);
					return;
				}
				
				if(m_phead->maxTimerNum != maxTimerNum)
				{
					m_err.errcode = ERR_BAD_HEADER;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool head.maxTimerNum(%u) != maxTimerNum(%u)", m_phead->maxTimerNum, maxTimerNum);
					return;
				}
				
				if(m_phead->dataSize != sizeof(TDATA))
				{
					m_err.errcode = ERR_BAD_HEADER;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool head.dataSize(%u) != dataSize"PRINTF_FORMAT_FOR_SIZE_T, m_phead->dataSize, sizeof(TDATA));
					return;
				}
				
				if(m_phead->unusedBorder == 0 || m_phead->unusedBorder > m_phead->maxTimerNum+1) //满的时候m_phead->unusedBorder = m_phead->maxTimerNum+1
				{
					m_err.errcode = ERR_BAD_HEADER;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool head.unusedBorder(%u) not valid maxidx=%u", 
						m_phead->unusedBorder, m_phead->maxTimerNum);
					return;
				}
				
				if(m_phead->freeHead >= m_phead->unusedBorder)
				{
					m_err.errcode = ERR_BAD_HEADER;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool head.freeHead(%u) >= unusedBorder(%u)", 
						m_phead->freeHead, m_phead->unusedBorder);
					return;
				}
				
#ifdef DEBUG
				//统计下used
				unsigned int used = 0;

				if(check_table(m_ptableS, "tableS", used) != 0)
				{
					return;
				}
				
				if(check_table(m_ptableMS, "tableMS", used) != 0)
				{
					return;
				}


				//查看free链表
				unsigned int free = 0;
				unsigned int next = m_phead->freeHead;
				unsigned int k;
				for( k=0; k<m_phead->unusedBorder && next != 0;++k) //最多才unusedBorder个元素
				{
					if(next >= m_phead->unusedBorder) //超过了。。。
					{
						m_err.errcode = ERR_BAD_LIST;
						snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool free[%u] idx=%u > border(%u)", 
							k, next, m_phead->unusedBorder);
						return;
					}
					++free;
					next = m_pnodes[next].nextIdx;
				}

				//查看timeout链表
				unsigned int timeout = 0;
				next = m_phead->timeoutHead;
				unsigned int tail = 0;
				for( k=0; k<m_phead->unusedBorder && next != 0;++k) //最多才unusedBorder个元素
				{
					if(next >= m_phead->unusedBorder) //超过了。。。
					{
						m_err.errcode = ERR_BAD_LIST;
						snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool timeout[%u] idx=%u > border(%u)", 
							k, next, m_phead->unusedBorder);
						return;
					}
					++timeout;
					if(m_pnodes[next].nextIdx == 0)
					{
						tail = next;
					}
					next = m_pnodes[next].nextIdx;
				}				

				if(tail != m_phead->timeoutTail) //检查下tail是不是真的tail
				{
					m_err.errcode = ERR_BAD_LIST;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool timeoutTail[%u] != real %u", 
						m_phead->timeoutTail, tail);
					return;
				}

				if(free + used + timeout!= m_phead->unusedBorder-1)
				{
					//有节点泄漏
					m_err.errcode = ERR_BAD_HEADER;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool freeNodeNum(%u) + used(%u) + timeout(%u) != unused(%u) -1", 
						free, used, timeout, m_phead->unusedBorder);
					return;
				}
#endif
				
			}

			m_valid = true;
		}

		inline int set_timer_s(unsigned int& timeID, TDATA& data, unsigned int timeout,timeval* curtime = NULL)
		{
			return set_timer(timeID, data, timeout, 0, curtime);
		}

		inline int set_timer_ms(unsigned int& timeID, TDATA& data, unsigned int timeout,timeval* curtime = NULL)
		{
			return set_timer(timeID, data,  0, timeout, curtime);
		}

		//设置一个timer, return 0 ok <0 fail
		//return=0 timeID返回有效,timeoutS以秒为单位，timeoutMS以毫秒为单位的超时时间
		//curtime=NULL,则内部取系统时间，使用传入的时间做当前时间
		int set_timer(unsigned int& timeID, TDATA& data,unsigned int timeoutS, unsigned int timeoutMS,timeval* curtime = NULL)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool init not valid");
				return m_err.errcode;
			}

			//把已经timeout的节点放入timeout链表中，更新lastchecktime
			int ret = check_time_out(curtime);
			if(ret != 0)
				return ret;

			unsigned int diffS, diffMS;
			unsigned int tableIdx = 0;
			diffS = (timeoutS + timeoutMS/1000);
			diffMS = timeoutMS%1000;

			if(diffS >= ARRAY_SIZE)
			{
				//太大了
				m_err.errcode = ERR_TIME;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool timeout(S) %u > %u too long", diffS, ARRAY_SIZE);
				return m_err.errcode;
			}

			//插入一个定时器节点
			unsigned int newNodeIdx = new_node();
			if(newNodeIdx == 0)
			{
				//没有空节点
				m_err.errcode = ERR_MEM_NOT_ENOUGH;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool new_node() no more node");
				return m_err.errcode;
			}

			TIMER_TABLE* p = 0;

			if(diffS >= ARRAY_SIZE/S_TO_MS)
			{
				//使用s表,忽略ms
				tableIdx = (m_ptableS->curIdx + diffS)%ARRAY_SIZE;
				p = m_ptableS;
//LOG(LOG_INFO, "diffs=%u tableIdx=%u m_ptableS", diffS, tableIdx);
			}
			else
			{
				//使用ms表
				tableIdx = (m_ptableMS->curIdx + diffS*S_TO_MS+diffMS)%ARRAY_SIZE;
				p = m_ptableMS;
//LOG(LOG_INFO, "diffs=%u diffMS=%u tableIdx=%u m_ptableMS", diffS, diffMS, tableIdx);
			}

			//cout << "||||||||||||||| timeout(" << timeoutS << "," << timeoutMS << ") diffS=" << diffS << " diffMS=" << diffMS << "current " << p->curIdx << " and set at idx " << tableIdx << "||||||||||||||||||||||||||" << endl;

			add_node_to_list(p, tableIdx, newNodeIdx);

			m_pnodes[newNodeIdx].valid = 1;
			m_pnodes[newNodeIdx].data = data;

			timeID = newNodeIdx;

			return 0;
		}

		//删除一个timer, return 0 ok <0 fail 
		int del_timer(unsigned int timeID)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool init not valid");
				return m_err.errcode;
			}

			if(timeID >= m_phead->unusedBorder || timeID == 0)
			{
				//timeID超出范围
				m_err.errcode = ERR_ID_NOTVALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool del(%u) id should in [1,%u]",timeID,m_phead->unusedBorder-1);
				return m_err.errcode;
			}

			//置为无效
			m_pnodes[timeID].valid = 0;
			
			return 0;
		}

		//取出当前过期的timer, return 0 ok <0 fail
		//curtime=NULL,则内部取系统时间，使用传入的时间做当前时间 
		int check_timer(vector<unsigned int>& vtimerID,vector<TDATA>& vtimerData, timeval* curtime = NULL)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool init not valid");
				return m_err.errcode;
			}

			//把已经timeout的节点放入timeout链表中，更新lastchecktime
			int ret = check_time_out(curtime);
			if(ret != 0)
				return ret;

			//遍历timeout链表，读出valid=1节点的数据
			vtimerID.clear();
			vtimerData.clear();
			unsigned int next = m_phead->timeoutHead;
			unsigned int total = 0;
			for(unsigned int j=0; j<m_phead->unusedBorder && next != 0;++j)
			{
				if(m_pnodes[next].valid == 1)
				{
					vtimerID.push_back(next);
					vtimerData.push_back(m_pnodes[next].data);
					m_pnodes[next].valid = 0;
				}
				
				next = m_pnodes[next].nextIdx;
				total++;
			}

			//如果del=true，timeout非空，归还节点
			if(m_phead->timeoutTail != 0)
			{
				m_pnodes[m_phead->timeoutTail].nextIdx = m_phead->freeHead;
				m_phead->freeHead = m_phead->timeoutHead;
				m_phead->timeoutHead = 0;
				m_phead->timeoutTail = 0;

				if(m_phead->usednum > total)
				{
					m_phead->usednum -= total;
				}
				else
				{
					m_phead->usednum = 0;
				}
			}

			return 0;
		}
		
		inline bool valid()
		{
			return m_valid;
		}
		
		inline bool formated()
		{
			return m_formated;
		}

		inline TIMER_HEAD* get_head()
		{
			return m_phead;
		}

		void debug(ostream& os)
		{

			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool init not valid");
				return;
			}
			
			m_phead->debug(os);

			//tableS和tableMS
			os << "*******************TABLE_S:" << endl;
			m_ptableS->debug(os,m_pnodes, m_phead);
			os << "*******************TABLE_MS:" << endl;
			m_ptableMS->debug(os,m_pnodes, m_phead);

			//timeout链表
			unsigned int next = m_phead->timeoutHead;
			os << "*******************TIME_OUT=" << next << ":" << endl;
			for(unsigned int i=0; i<m_phead->unusedBorder && next != 0;++i)
			{
				m_pnodes[next].debug(os);
				next = m_pnodes[next].nextIdx;
			}
			

			//free链表
			next = m_phead->freeHead;
			os << "*******************FREE=" << next << ":" << endl;
			for(unsigned int k=0; k<m_phead->unusedBorder && next != 0;++k) //最多才unusedBorder个元素
			{
				m_pnodes[next].debug(os);
				next = m_pnodes[next].nextIdx;
			}
		
		}

		inline void passerr(char* errmsg, int size)
		{
			snprintf(errmsg, size, "%d %s", m_err.errcode, m_err.errstrmsg);
		}

	protected:
#ifdef DEBUG	
	int check_table(TIMER_TABLE* p, const char* name, unsigned int& used)
	{
		unsigned int i = 0;
		unsigned int j = 0;
		if(p->curIdx >= ARRAY_SIZE)
		{
			m_err.errcode = ERR_BAD_LIST;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool %s curIdx[%u] > ARRAY_SIZE(%u)", 
				name, p->curIdx, ARRAY_SIZE);
			return -1;
		}
		
		for(i=0; i<ARRAY_SIZE; ++i)
		{
			unsigned int next = p->heads[i];
			unsigned int tail = 0;
			for(j=0; j<m_phead->unusedBorder && next != 0;++j) //最多才unusedBorder个元素
			{
				if(next >= m_phead->unusedBorder) //超过了。。。
				{
					m_err.errcode = ERR_BAD_LIST;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool %s[%u][%u] idx=%u > border(%u)", 
						name, i, j, next, m_phead->unusedBorder);
					return -1;
				}
				++used;

				if(m_pnodes[next].nextIdx == 0)
				{
					tail = next;
				}
				next = m_pnodes[next].nextIdx;
			}

			if(tail != p->tails[i])
			{
				m_err.errcode = ERR_BAD_LIST;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool %s[%u] tail(%u) != real(%u)", 
					name, i, p->tails[i], tail);
				return -1;
			}
		}
		
		return 0;
	}
#endif
	//内部检查timeout的节点，加入到timeout链表中
	int check_time_out(timeval* curtime)
	{
		unsigned int tableIdxesNumS = 0;
		unsigned int tableIdxesNumMS = 0;
		unsigned int diffS;
		unsigned int diffMS;

		//当前时间
		timeval nowtv;
		if(curtime == NULL)
		{
			gettimeofday(&(nowtv),NULL);
		}
		else
		{
			memcpy(&nowtv, curtime, sizeof(timeval));
		}

		//tableS时间检测
		//精度是秒
		if(nowtv.tv_sec < m_ptableS->lastCheckTime.tv_sec)
		{
			m_err.errcode = ERR_TIME;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "m_ptableS time(%lu) < last(%lu)",
				nowtv.tv_sec, m_ptableS->lastCheckTime.tv_sec);
			return m_err.errcode;
		}
		
		diffS = nowtv.tv_sec - m_ptableS->lastCheckTime.tv_sec; 

		if(diffS >= ARRAY_SIZE)
			tableIdxesNumS = ARRAY_SIZE;
		else
			tableIdxesNumS = diffS;
		
		if(tableIdxesNumS > 0)
		{
			//更新时间
			m_ptableS->lastCheckTime.tv_sec = nowtv.tv_sec;
			tabel_timeout(m_ptableS, tableIdxesNumS);
		}

		//tableMS时间检测
		//精度到ms够了
		nowtv.tv_usec = (nowtv.tv_usec/1000)*1000;
		if(nowtv.tv_sec < m_ptableMS->lastCheckTime.tv_sec)
		{
			m_err.errcode = ERR_TIME;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "m_ptableMS time(%lu) < last(%lu)",
				nowtv.tv_sec, m_ptableMS->lastCheckTime.tv_sec);
			return m_err.errcode;
		}

		diffS = nowtv.tv_sec - m_ptableMS->lastCheckTime.tv_sec;
		if(nowtv.tv_usec < m_ptableMS->lastCheckTime.tv_usec)
		{
			if(diffS == 0)
			{
				m_err.errcode = ERR_TIME;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "m_ptableMS diffs=0 and usec(%lu) < last(%lu)",
					nowtv.tv_usec, m_ptableMS->lastCheckTime.tv_usec);
				return m_err.errcode;
			}

			diffS -= 1;
			diffMS = (nowtv.tv_usec+1000000 - m_ptableMS->lastCheckTime.tv_usec)/1000;
		}
		else
		{
			diffMS = (nowtv.tv_usec - m_ptableMS->lastCheckTime.tv_usec)/1000;
		}

		if(diffS >= ARRAY_SIZE/S_TO_MS)
		{
			tableIdxesNumMS = ARRAY_SIZE;
		}
		else
		{
			tableIdxesNumMS = diffS*S_TO_MS+diffMS;
		}	

		if(tableIdxesNumMS > 0)
		{
//LOG(LOG_INFO, "curIdx=%d tableIdxesNumMS=%d", m_ptableMS->curIdx, tableIdxesNumMS);
			//更新时间
			memcpy(&m_ptableMS->lastCheckTime, &nowtv, sizeof(timeval));
			tabel_timeout(m_ptableMS, tableIdxesNumMS);
		}
		
		return 0;
	}

	void tabel_timeout(TIMER_TABLE* p, unsigned int idexesNum)
	{
		unsigned int idx = p->curIdx;
		for(unsigned int i=0; i<idexesNum; ++i)
		{
			if(p->heads[idx] != 0)
			{
//LOG(LOG_INFO, "idexesNum=%u idx=%u head=%u", idexesNum, idx, p->heads[idx]);
				//加入timeout链表尾部
				if(m_phead->timeoutHead == 0)
				{
					m_phead->timeoutHead = p->heads[idx];
				}

				if(m_phead->timeoutTail != 0)
				{
					m_pnodes[m_phead->timeoutTail].nextIdx = p->heads[idx];
				}

				m_phead->timeoutTail = p->tails[idx];

				p->heads[idx] = 0;
				p->tails[idx] = 0;
			}

			idx = (idx+1)%ARRAY_SIZE;
		}
		//移动curIdx
		p->curIdx = idx;
	}

	inline void add_node_to_list(TIMER_TABLE* table, unsigned int tableIdx, unsigned int nodeIdx)
	{
		if(table->tails[tableIdx] == 0)
		{
			table->tails[tableIdx] = nodeIdx;
		}

		m_pnodes[nodeIdx].nextIdx = table->heads[tableIdx];
		table->heads[tableIdx] = nodeIdx;
	}

	//return 0 = 没有内存了, 否则返回node数组中的idx
	unsigned int new_node()
	{
		unsigned int ret = 0;
		if(m_phead->freeHead != 0)
		{
			//从free链表上取第一个
			ret = m_phead->freeHead;
			m_phead->freeHead = m_pnodes[m_phead->freeHead].nextIdx;
		}
		else
		{
			//直接从未分配地址中给出
			if(m_phead->unusedBorder <= m_phead->maxTimerNum)
			{
				ret = m_phead->unusedBorder++;
			}
		}

		if(ret != 0)
		{
			m_pnodes[ret].nextIdx = 0;
			m_pnodes[ret].valid = 0;
			m_phead->usednum++;
		}

		return ret;
	}


	protected:
		unsigned int m_memSize;
		TIMER_HEAD* m_phead;
		TIMER_TABLE* m_ptableS;
		TIMER_TABLE* m_ptableMS;
		TIMER_NODE* m_pnodes;
		bool m_valid;
		bool m_formated;
	public:
		ERROR_INFO m_err;
};

#pragma pack(pop)

#endif

