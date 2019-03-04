#ifndef __FIFO_QUEUE_H__
#define __FIFO_QUEUE_H__

#include "common_def.h"
#include <iostream>
#include <string.h>

using namespace std;


#define FIFOQueue_MAGICTAG "FIFOQueue_mars_20110424"

#pragma pack(push)
#pragma pack(1)

template<typename DATA_POINTER>
struct STFIFONode
{
public:
	int idxNext; //ǰ��idx��ʾ�ڵ���m_pnodes�����е��±�
	int idxPre; //��idx��ʾ�ڵ���m_pnodes�����е��±�
	int flag; //�Ƿ���ʹ����
	DATA_POINTER datap; //ģ�棬һ���Ǹ����ε�ƫ����������һ���û�����
	void debug(ostream& os)
	{
		os << "NODE_TYPE{" << endl;
		os << "idxNext|" << idxNext << endl;
		os << "idxPre|" << idxPre << endl;
		os << "flag|" << flag << endl;
	//���ᣬdebug״̬�¸�datap���鲻��ȥ����ע�͵���
#ifdef DEBUG
		os << "datap|" << datap << endl;
#endif
		os << "} end NODE_TYPE" << endl;
	}
};

template<typename DATA_POINTER> void debugFIFONode(const STFIFONode<DATA_POINTER>* pnode, ostream& os)
{
	os << "NODE_TYPE{" << endl;
	os << "idxNext|" << pnode->idxNext << endl;
	os << "idxPre|" << pnode->idxPre << endl;
	os << "flag|" << pnode->flag << endl;
//���ᣬdebug״̬�¸�datap���鲻��ȥ����ע�͵���
#ifdef DEBUG
	os << "datap|" << pnode->datap << endl;
#endif
	os << "} end NODE_TYPE" << endl;
}


template<typename DATA_POINTER>
class CFIFOQueueVisitor
{
	protected:
		typedef STFIFONode<DATA_POINTER> NODE_TYPE;
	public:
		CFIFOQueueVisitor()
		{
			//Ĭ�Ϸ�����used node
			m_state = 1;
		}
		//call����ʱ����for_each_node�������жϣ������ظ�ֵ
		//callTimesָ���ڼ��α�����
		virtual int call(const NODE_TYPE* pnode, int callTimes) = 0;
		//������Ҫ���ʵĽڵ�����, -1=all, 0=free, 1=used
		inline void set_state(int state)
		{
			m_state = state;
		}
		inline int get_state()
		{
			return m_state;
		}
	protected:
		int m_state;
};


template<typename DATA_POINTER>
class CFIFOQueue
{
	typedef STFIFONode<DATA_POINTER> NODE_TYPE;
	public:
		static const unsigned int VERSION = 0x1001; 
		static const int ERR_VERSION = -1;
		static const int ERR_MEM_NOT_ENOUGH = -3;
		static const int ERR_HEAD_NODENUM = -4;
		static const int ERR_HEAD_NODESIZE = -5;
		static const int ERR_HEAD_CURNUM = -6;
		static const int ERR_REINIT_NODES = -7;
		static const int ERR_NOT_VALID = -8;
		static const int ERR_DELETE_IDX_INVALID = -9;
		static const int ERR_INNER = -99;

		static const int RET_OK = 0;
		static const int RET_FULL = 1;
		static const int RET_EMPTY = 2;
		
	public:
		struct QUEUE_HEAD
		{
			char magicTag[32]; //MAGICTAG���������ڴ��Ƿ񱻳�ʼ����
			unsigned int version; //��������İ汾
			int idxUsed; //ʹ���нڵ�����, idx��ʾ�ڵ���m_pnodes�����е��±�
			int idxFree; //��������idx��ʾ�ڵ���m_pnodes�����е��±�
			unsigned int curNodeNum; //��ʹ���еĽڵ���Ŀ
			unsigned int nodeSize; //�ڵ��С��ģ���࣬�ڵ��СҪ����
			unsigned int nodeNum;  //�����ýڵ���
			char reserve[200]; //�����ֶ�
			void debug(ostream& os)
			{
				os << "QUEUE_HEAD{" << endl;
				os << "magicTag|" << magicTag << endl;
				os << "version|" << version << endl;
				os << "idxUsed|" << idxUsed << endl;
				os << "idxFree|" << idxFree << endl;
				os << "curNodeNum|" << curNodeNum << endl;
				os << "nodeSize|" << nodeSize << endl;
				os << "nodeNum|" << nodeNum << endl;
				os << "} end QUEUE_HEAD" << endl;
			}
		};

		
	public:
		static unsigned int mem_size(unsigned int nodeNum)
		{
			return sizeof(QUEUE_HEAD)+sizeof(NODE_TYPE)*nodeNum;
		}

		static unsigned int node_num(unsigned int memSize)
		{
			if(memSize <= sizeof(QUEUE_HEAD))
			{
				return 0;
			}

			return (memSize - sizeof(QUEUE_HEAD))/sizeof(NODE_TYPE);
		}

		//�ǵ�ǰmemʧЧ����ʼ��ʱһ����ʽ��
		static void clear(void* mem)
		{
			memset(mem, 0x0, sizeof(QUEUE_HEAD));
		}

		//�Զ������Ƿ��ʽ��������valid()�鿴�Ƿ��ʼ���ɹ�������format()�鿴�Ƿ��ʽ����
		//ָ��mem��С���Զ�����������ɵĽڵ�
		CFIFOQueue(void* memStart,unsigned int memSize)
		{
			m_nodeNum = node_num(memSize);
			m_memSize = mem_size(m_nodeNum); //ʵ��ռ�õ�
			if(m_nodeNum == 0)
			{
				m_valid = false;
				m_err.errcode = ERR_MEM_NOT_ENOUGH;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue memSize=%u too small", memSize);
				return;
			}

			init(memStart);
		}

		//ָ���ڵ㣬�Զ�������Ҫ���ڴ档maxMemSize����ͨ��mem_size�������㡣
		CFIFOQueue(void* memStart,unsigned int maxMemSize, unsigned int nodeNum)
		{
			m_nodeNum = nodeNum;
			m_memSize = mem_size(m_nodeNum);
			if(m_memSize > maxMemSize)
			{
				m_valid = false;
				m_err.errcode = ERR_MEM_NOT_ENOUGH;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue nodeNum=%u needs memSize=%u but maxMemSize=%u", m_nodeNum,m_memSize,maxMemSize);
				return;
			}

			init(memStart);
		}

		inline unsigned int get_node_num()
		{
			return m_nodeNum;
		}

		inline unsigned int get_mem_size()
		{
			return m_memSize;
		}

		//������У����ף�idx���ؽڵ������
		int inqueue(int& nodeIdx,DATA_POINTER datap)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue init not valid");
				return m_err.errcode;
			}

			int idx = m_phead->idxFree;
			if(idx < 0) //����
			{
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue full");
				return RET_FULL;
			}


#ifdef DEBUG
			if(m_pnodes[idx].flag != 0)
			{
				m_err.errcode = ERR_INNER;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue in freelist idx=%u flag != 0", idx);
				return m_err.errcode;
			}
#endif

			//copy ����			
			m_pnodes[idx].datap = datap;

			//ʹ����
			m_pnodes[idx].flag = 1;
		
			//ȡ�µ�һ��node
			if(m_pnodes[idx].idxNext == idx) //�Ƿ�ֻʣ��һ����
			{
				m_phead->idxFree = -1;
			}
			else
			{
				m_pnodes[m_pnodes[idx].idxNext].idxPre = m_pnodes[idx].idxPre;
				m_pnodes[m_pnodes[idx].idxPre].idxNext = m_pnodes[idx].idxNext;
				m_phead->idxFree = m_pnodes[idx].idxNext;

			}
			//�ӵ�ʹ���е�����ͷ��
			if(m_phead->idxUsed != -1)
			{
				m_pnodes[idx].idxNext = m_phead->idxUsed;
				m_pnodes[idx].idxPre = m_pnodes[m_phead->idxUsed].idxPre;
		
				m_pnodes[m_pnodes[idx].idxNext].idxPre = idx;
				m_pnodes[m_pnodes[idx].idxPre].idxNext = idx;
			}
			else
			{
				m_pnodes[idx].idxPre = idx;
				m_pnodes[idx].idxNext = idx;
			}

			m_phead->idxUsed = idx;

			nodeIdx = idx;

			++(m_phead->curNodeNum);

			return RET_OK;
		}

		//ɾ������ָ����idx
		int del(int nodeIdx,DATA_POINTER& datap)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue init not valid");
				return m_err.errcode;
			}

			if(nodeIdx < 0 || nodeIdx >= (int)m_phead->nodeNum)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue idx=%d not valid", nodeIdx);
				return m_err.errcode;
			}

			if(m_pnodes[nodeIdx].flag == 0)
			{
				m_err.errcode = ERR_INNER;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue idx=%u flag == 0, may be deleted twice", nodeIdx);
				return m_err.errcode;
			}

			datap = m_pnodes[nodeIdx].datap;

			//�ͷŽڵ�
			inner_free(nodeIdx);
	
			return RET_OK;			
		}

		//������, theIdx���ؽ����ο����Ѿ����ǺϷ���idx��
		int outqueue(DATA_POINTER& datap, int* ptheIdx=NULL, bool autodel=true)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue init not valid");
				return m_err.errcode;
			}

			if(m_phead->idxUsed == -1) //����
			{
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue empty");
				return RET_EMPTY;
			}

			int idx = m_pnodes[m_phead->idxUsed].idxPre; //pre�������һ���ڵ�

			datap = m_pnodes[idx].datap;

			if(ptheIdx)
			{
				*ptheIdx = idx;
			}

			if(autodel)
			{
				//�ͷŽڵ�
				inner_free(idx);
			}

			return RET_OK;
		}

		inline bool valid()
		{
			return m_valid;
		}

		inline bool formated()
		{
			return m_formated;
		}

		inline QUEUE_HEAD* get_head()
		{
			return m_phead;
		}


		//��ӡ�ڲ�״̬
		void debug(ostream& os)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue init not valid");
				return;
			}

			m_phead->debug(os);

			os << "used list:" << endl;
			unsigned int i = 0;
			int idx = m_phead->idxUsed;
			for(; idx >= 0 && i<m_nodeNum; ++i) //���ѭ��m_nodeNum��
			{
				m_pnodes[idx].debug(os);
				idx = m_pnodes[idx].idxNext;
				if(idx == m_phead->idxUsed)
				{
					break;
				}
			}
			
			os << endl << "free list:" << endl;
			i = 0;
			idx = m_phead->idxFree;
			for(; idx >= 0 && i<m_nodeNum; ++i) //���ѭ��m_nodeNum��
			{
				m_pnodes[idx].debug(os);
				idx = m_pnodes[idx].idxNext;
				if(idx == m_phead->idxFree)
				{
					break;
				}
			}
			
		}

		//�û��Զ���������̳�VISTOR ʵ��call����
		int for_each_node(CFIFOQueueVisitor<DATA_POINTER>* pvisitor)
		{	
			int callTimes = 0;
			int state = pvisitor->get_state();
			int ret = 0;
			for(unsigned int i=0; i<m_nodeNum; ++i)
			{
				if(state == -1 || (state==0 && m_pnodes[i].flag==0) || (state==1 && m_pnodes[i].flag!=0))
				{
					ret = pvisitor->call(&(m_pnodes[i]), ++callTimes);
					if(ret != 0)
						return ret;
				}
			}

			return 0;
		}
		
	protected:
		//�ڲ�����ǰ���Ѿ�ȷ���ͷźϷ�
		void inner_free(int idx)
		{
			m_pnodes[idx].flag = 0;
			
			//ȡ��
			if(m_pnodes[idx].idxNext == idx) //�Ƿ�ֻʣ��һ����
			{
				m_phead->idxUsed = -1;
			}
			else
			{
				m_pnodes[m_pnodes[idx].idxNext].idxPre = m_pnodes[idx].idxPre;
				m_pnodes[m_pnodes[idx].idxPre].idxNext = m_pnodes[idx].idxNext;
				if(m_phead->idxUsed == idx) //�����ǵ�һ��
				{
					m_phead->idxUsed = m_pnodes[idx].idxNext;
				}
			}

			//�ŵ�����������
			if(m_phead->idxFree != -1)
			{
				m_pnodes[idx].idxNext = m_phead->idxFree;
				m_pnodes[idx].idxPre = m_pnodes[m_phead->idxFree].idxPre;
		
				m_pnodes[m_pnodes[idx].idxNext].idxPre = idx;
				m_pnodes[m_pnodes[idx].idxPre].idxNext = idx;
			}
			else
			{
				m_pnodes[idx].idxPre = idx;
				m_pnodes[idx].idxNext = idx;
			}

			m_phead->idxFree = idx;

			if(m_phead->curNodeNum > 0)
				--(m_phead->curNodeNum);
		}

		bool check_link_list(int startIdx, bool flag_should_be_zero, unsigned int totalNum, const char* linkListName)
		{
			
			//���usednodes

			unsigned int realNum = 0; //ʵ�ʱ������Ľڵ����

			if(startIdx >= 0) //�ǿ�����
			{
				//startIdx �Բ�?
				if(startIdx >= (int)(m_phead->nodeNum))
				{
					m_err.errcode = ERR_REINIT_NODES;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s startIdx=%d not valid", linkListName, startIdx);
					return false;
				}
				
				int idx = startIdx; //������
				int idxrealpre = -1; //������ ��ʼʱ��֪�� ��ʵ���ϸ��ڵ�

				unsigned int i = 0;
				for(; i<m_nodeNum; ++i) //���ѭ��m_nodeNum��
				{
					//idx��Ч��
					if(idx < 0 || idx >= (int)(m_phead->nodeNum))
					{
						m_err.errcode = ERR_REINIT_NODES;
						snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s loop(%u) (idx=%d) not valid", linkListName, i, idx);
						return false;
					}

					//flag��Ч��
					if(flag_should_be_zero)//Ӧ��Ϊ0��
					{
						if(m_pnodes[idx].flag != 0) 
						{
							m_err.errcode = ERR_REINIT_NODES;
							snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s loop(%u) (idx=%d) flag!=0 not valid", linkListName, i, idx);
							return false;
						}
					}
					else//Ӧ�ò�Ϊ0��
					{
						if(m_pnodes[idx].flag == 0) 
						{
							m_err.errcode = ERR_REINIT_NODES;
							snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s loop(%u) (idx=%d) flag==0 not valid", linkListName, i, idx);
							return false;
						}
					}


					//pre�ļ��
					if(i != 0) //�׽ڵ�ѭ�����ټ��
					{
						if(m_pnodes[idx].idxPre != idxrealpre)
						{
							m_err.errcode = ERR_REINIT_NODES;
							snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s loop(%u) (idx=%d)->idxPre(%d) != idxrealpre(%d) not valid", 
								linkListName, i, idx, m_pnodes[idx].idxPre, idxrealpre);
							return false;
						}
					}
					idxrealpre = idx; //������
					
					//��ǰ�ڵ������
					
					//��������
					if(m_pnodes[idx].idxNext == startIdx)
					{
						break;
					}
					else
					{
						//�¸��ڵ�
						idx = m_pnodes[idx].idxNext;
					}
				}

				//�Ƿ���ѭ������?û������break
				if(i==m_nodeNum)
				{
					m_err.errcode = ERR_REINIT_NODES;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s loop(%u) == m_nodeNum(%u) not valid", 
						linkListName, i, m_nodeNum);
					return false;
				}

				//��һ��node��pre���������֮��У���Ƿ������һ��node
				if(idxrealpre != m_pnodes[startIdx].idxPre)
				{
					m_err.errcode = ERR_REINIT_NODES;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s (start_idx=%d)->idxPre(%d) != idxrealpre(%d) not valid", 
						linkListName,idx, m_pnodes[idx].idxPre, idxrealpre);
					return false;
				}

				//��ʵ�Ľڵ���
				realNum = i+1;
			}

			//��֤�ڵ���Ŀ�Բ�
			if(realNum != totalNum) 
			{
				m_err.errcode = ERR_REINIT_NODES;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s real num(%u) != totalNum(%u) not valid", linkListName,realNum,totalNum);
				return false;
			}

			return true;
		}

		void init(void* memStart)
		{
			m_phead = (QUEUE_HEAD*)memStart;
			m_pnodes = (NODE_TYPE*)((char*)memStart + sizeof(QUEUE_HEAD) );
			m_formated = false;
			m_valid = false;

			if(strncmp(m_phead->magicTag, FIFOQueue_MAGICTAG, sizeof(m_phead->magicTag))!= 0) //��Ҫ��ʽ��
			{
				m_formated = true;
				snprintf(m_phead->magicTag,sizeof(m_phead->magicTag), "%s", FIFOQueue_MAGICTAG);
				m_phead->version = VERSION;
				m_phead->idxUsed = -1; //û���Ѿ�ʹ�õĽڵ�
				m_phead->idxFree = 0; //���еĽڵ㶼��δʹ�õ�
				m_phead->curNodeNum = 0; //�Ѿ�ʹ�õĽڵ�����Ϊ0
				m_phead->nodeNum = m_nodeNum;
				m_phead->nodeSize = sizeof(NODE_TYPE);

				for(unsigned int i=0; i<m_phead->nodeNum; ++i)
				{
					if(i == m_phead->nodeNum-1)
					{
						m_pnodes[i].idxNext = 0; //ѭ����
					}
					else
					{
						m_pnodes[i].idxNext = i+1;
					}

					if(i==0)
					{
						m_pnodes[i].idxPre = m_phead->nodeNum-1; //ѭ����
					}
					else
					{
						m_pnodes[i].idxPre = i-1;
					}

					m_pnodes[i].flag = 0; //0=δʹ��
				}
			}
			
			else//�������룬����ڴ�
			{
				if(m_phead->version != VERSION )
				{
					m_err.errcode = ERR_VERSION;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue head.version(%u) != version(%u)", m_phead->version, VERSION);
					return;
				}
				
				if(m_phead->nodeNum != m_nodeNum)
				{
					m_err.errcode = ERR_HEAD_NODENUM;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue head.nodeNum(%u) != nodeNum(%u)", m_phead->nodeNum, m_nodeNum);
					return;
				}

				if(m_phead->nodeSize != sizeof(NODE_TYPE))
				{
					m_err.errcode = ERR_HEAD_NODESIZE;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue head.nodeSize(%u) != nodeSize("PRINTF_FORMAT_FOR_SIZE_T")", m_phead->nodeSize, sizeof(NODE_TYPE));
					return;
				}

#ifdef DEBUG
				//��� usedlist
				if( ! check_link_list(m_phead->idxUsed, false, m_phead->curNodeNum, "usedlist") )
				{
					return;
				}

				//���freelist (���usednodes�Ľ�����Ա�֤m_phead->curNodeNum <= m_phead->nodeNum)
				if( ! check_link_list(m_phead->idxFree, true, m_phead->nodeNum - m_phead->curNodeNum, "usedfree") )
				{
					return;
				}
#endif
			}
			
			m_valid = true; //ok��
		}

	protected:
		unsigned int m_nodeNum;
		unsigned int m_memSize;
		QUEUE_HEAD* m_phead;
		NODE_TYPE* m_pnodes;
		bool m_valid;
		bool m_formated;
	public:
		ERROR_INFO m_err;
};

#pragma pack(pop)

#endif

