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
* timer��ʱ��С��λ��ms���ڲ���ms��s��������ľ���
* 100�����µĳ�ʱ��ȷ��ms������ʱ��ȷ��s�����ʱʱ��100*1000s
* 
* ���˼��
* 1 ���ڿռ任ʱ��
* 2 ���ǳ��õ�ʱ��κ;���1ms~1000s���󲿷���%1�������
* 3 ��ӹ������2��table�ĸ��ϱ���ռ�ÿռ����
*
* ��չ
* ����������Ƴ�ֻ����һ��table��timer���Զ��帲�Ƿ�Χ�;���
* ʹ������Ҫͬʱӵ�м���timer���Լ�ѡ���ھ�������������ʹ���Ǹ�timer
* ������һ����ó�ʱ(1s����)�ͻ�дɨ��(100s����)��
*/
class CTimerPool
{
	public:
		static const unsigned int VERSION = 0x1001;
		static const unsigned int ARRAY_SIZE = 100000;
		static const unsigned int S_TO_MS = 1000; // ������1000
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
			unsigned int maxTimerNum; //��༸��timer
			unsigned int dataSize; //sizeof(TDATA),У����
			unsigned int freeHead; //���ͷŵĽڵ�����ֵ��m_nodeArray�����idx 0=�գ�m_nodeArray��һ���ڵ㲻�������
			unsigned int timeoutHead; //timeout����
			unsigned int timeoutTail; //timeout����β��������׷��
			unsigned int unusedBorder; //��λ�ü�����Ľڵ�δ��ʼ������λ�ǽڵ�������±�
			unsigned int usednum; //ʹ���˶��ٽڵ���
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
			unsigned int nextIdx; //������һ��idx��0=�������������ڿ��������У���������table��
			unsigned int valid;   //�Ƿ���Ч��del��֮�����Ч��
			TDATA data; 		
			void debug(ostream& os)
			{
				os << "TIMER_NODE{" << endl;
				os << "nextIdx|" << nextIdx << endl;
				os << "valid|" << valid << endl;
				//���ᣬdebug״̬�¸�,val,key��֧�ֵĻ��Լ�����
#ifdef DEBUG
				os << "data|" << data << endl;
#endif
				os << "} end TIMER_NODE" << endl;
			}
			
		}TIMER_NODE;

		/**
		* ��s��ms����table
		* ǰ��1s-100000s�ı�ʾ��Χ��ÿ��ƫ����1s
		* ����1ms-100s�ı�ʾ��Χ��ÿ��ƫ����1ms
		* ��set����ĳ�ʱʱ�����ֱ�100s���µķֵ�ms����
		*/
		typedef struct tagTimerTable
		{
			timeval lastCheckTime;
			unsigned int curIdx;
			unsigned int heads[ARRAY_SIZE]; //����ͷ����
			unsigned int tails[ARRAY_SIZE]; //����β����
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

		//������Ҫ���ڴ��С
		static unsigned int mem_size(unsigned int maxTimerNum)
		{
			return sizeof(TIMER_HEAD)+sizeof(TIMER_TABLE)*2+sizeof(TIMER_NODE)*(maxTimerNum+1);
		}

		////ʹ��ǰmemʧЧ������mem�Ͻ���CTimerPool�ض��߸�ʽ������
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

			if(strncmp(m_phead->magicTag, TIMER_POOL_MAGICTAG, sizeof(m_phead->magicTag))!= 0) //��Ҫ��ʽ��
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
				//���ȱ�׼��
				m_ptableS->lastCheckTime.tv_usec = 0;
				m_ptableMS->lastCheckTime.tv_usec = (m_ptableMS->lastCheckTime.tv_usec/1000)*1000; 
			}
			else
			{
				//У��
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
				
				if(m_phead->unusedBorder == 0 || m_phead->unusedBorder > m_phead->maxTimerNum+1) //����ʱ��m_phead->unusedBorder = m_phead->maxTimerNum+1
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
				//ͳ����used
				unsigned int used = 0;

				if(check_table(m_ptableS, "tableS", used) != 0)
				{
					return;
				}
				
				if(check_table(m_ptableMS, "tableMS", used) != 0)
				{
					return;
				}


				//�鿴free����
				unsigned int free = 0;
				unsigned int next = m_phead->freeHead;
				unsigned int k;
				for( k=0; k<m_phead->unusedBorder && next != 0;++k) //����unusedBorder��Ԫ��
				{
					if(next >= m_phead->unusedBorder) //�����ˡ�����
					{
						m_err.errcode = ERR_BAD_LIST;
						snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool free[%u] idx=%u > border(%u)", 
							k, next, m_phead->unusedBorder);
						return;
					}
					++free;
					next = m_pnodes[next].nextIdx;
				}

				//�鿴timeout����
				unsigned int timeout = 0;
				next = m_phead->timeoutHead;
				unsigned int tail = 0;
				for( k=0; k<m_phead->unusedBorder && next != 0;++k) //����unusedBorder��Ԫ��
				{
					if(next >= m_phead->unusedBorder) //�����ˡ�����
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

				if(tail != m_phead->timeoutTail) //�����tail�ǲ������tail
				{
					m_err.errcode = ERR_BAD_LIST;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool timeoutTail[%u] != real %u", 
						m_phead->timeoutTail, tail);
					return;
				}

				if(free + used + timeout!= m_phead->unusedBorder-1)
				{
					//�нڵ�й©
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

		//����һ��timer, return 0 ok <0 fail
		//return=0 timeID������Ч,timeoutS����Ϊ��λ��timeoutMS�Ժ���Ϊ��λ�ĳ�ʱʱ��
		//curtime=NULL,���ڲ�ȡϵͳʱ�䣬ʹ�ô����ʱ������ǰʱ��
		int set_timer(unsigned int& timeID, TDATA& data,unsigned int timeoutS, unsigned int timeoutMS,timeval* curtime = NULL)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool init not valid");
				return m_err.errcode;
			}

			//���Ѿ�timeout�Ľڵ����timeout�����У�����lastchecktime
			int ret = check_time_out(curtime);
			if(ret != 0)
				return ret;

			unsigned int diffS, diffMS;
			unsigned int tableIdx = 0;
			diffS = (timeoutS + timeoutMS/1000);
			diffMS = timeoutMS%1000;

			if(diffS >= ARRAY_SIZE)
			{
				//̫����
				m_err.errcode = ERR_TIME;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool timeout(S) %u > %u too long", diffS, ARRAY_SIZE);
				return m_err.errcode;
			}

			//����һ����ʱ���ڵ�
			unsigned int newNodeIdx = new_node();
			if(newNodeIdx == 0)
			{
				//û�пսڵ�
				m_err.errcode = ERR_MEM_NOT_ENOUGH;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool new_node() no more node");
				return m_err.errcode;
			}

			TIMER_TABLE* p = 0;

			if(diffS >= ARRAY_SIZE/S_TO_MS)
			{
				//ʹ��s��,����ms
				tableIdx = (m_ptableS->curIdx + diffS)%ARRAY_SIZE;
				p = m_ptableS;
//LOG(LOG_INFO, "diffs=%u tableIdx=%u m_ptableS", diffS, tableIdx);
			}
			else
			{
				//ʹ��ms��
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

		//ɾ��һ��timer, return 0 ok <0 fail 
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
				//timeID������Χ
				m_err.errcode = ERR_ID_NOTVALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool del(%u) id should in [1,%u]",timeID,m_phead->unusedBorder-1);
				return m_err.errcode;
			}

			//��Ϊ��Ч
			m_pnodes[timeID].valid = 0;
			
			return 0;
		}

		//ȡ����ǰ���ڵ�timer, return 0 ok <0 fail
		//curtime=NULL,���ڲ�ȡϵͳʱ�䣬ʹ�ô����ʱ������ǰʱ�� 
		int check_timer(vector<unsigned int>& vtimerID,vector<TDATA>& vtimerData, timeval* curtime = NULL)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CTimerPool init not valid");
				return m_err.errcode;
			}

			//���Ѿ�timeout�Ľڵ����timeout�����У�����lastchecktime
			int ret = check_time_out(curtime);
			if(ret != 0)
				return ret;

			//����timeout��������valid=1�ڵ������
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

			//���del=true��timeout�ǿգ��黹�ڵ�
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

			//tableS��tableMS
			os << "*******************TABLE_S:" << endl;
			m_ptableS->debug(os,m_pnodes, m_phead);
			os << "*******************TABLE_MS:" << endl;
			m_ptableMS->debug(os,m_pnodes, m_phead);

			//timeout����
			unsigned int next = m_phead->timeoutHead;
			os << "*******************TIME_OUT=" << next << ":" << endl;
			for(unsigned int i=0; i<m_phead->unusedBorder && next != 0;++i)
			{
				m_pnodes[next].debug(os);
				next = m_pnodes[next].nextIdx;
			}
			

			//free����
			next = m_phead->freeHead;
			os << "*******************FREE=" << next << ":" << endl;
			for(unsigned int k=0; k<m_phead->unusedBorder && next != 0;++k) //����unusedBorder��Ԫ��
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
			for(j=0; j<m_phead->unusedBorder && next != 0;++j) //����unusedBorder��Ԫ��
			{
				if(next >= m_phead->unusedBorder) //�����ˡ�����
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
	//�ڲ����timeout�Ľڵ㣬���뵽timeout������
	int check_time_out(timeval* curtime)
	{
		unsigned int tableIdxesNumS = 0;
		unsigned int tableIdxesNumMS = 0;
		unsigned int diffS;
		unsigned int diffMS;

		//��ǰʱ��
		timeval nowtv;
		if(curtime == NULL)
		{
			gettimeofday(&(nowtv),NULL);
		}
		else
		{
			memcpy(&nowtv, curtime, sizeof(timeval));
		}

		//tableSʱ����
		//��������
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
			//����ʱ��
			m_ptableS->lastCheckTime.tv_sec = nowtv.tv_sec;
			tabel_timeout(m_ptableS, tableIdxesNumS);
		}

		//tableMSʱ����
		//���ȵ�ms����
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
			//����ʱ��
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
				//����timeout����β��
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
		//�ƶ�curIdx
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

	//return 0 = û���ڴ���, ���򷵻�node�����е�idx
	unsigned int new_node()
	{
		unsigned int ret = 0;
		if(m_phead->freeHead != 0)
		{
			//��free������ȡ��һ��
			ret = m_phead->freeHead;
			m_phead->freeHead = m_pnodes[m_phead->freeHead].nextIdx;
		}
		else
		{
			//ֱ�Ӵ�δ�����ַ�и���
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

