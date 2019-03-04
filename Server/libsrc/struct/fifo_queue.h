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
	int idxNext; //前，idx表示节点在m_pnodes数组中的下标
	int idxPre; //后，idx表示节点在m_pnodes数组中的下标
	int flag; //是否在使用中
	DATA_POINTER datap; //模版，一般是个整形的偏移量，关联一块用户数据
	void debug(ostream& os)
	{
		os << "NODE_TYPE{" << endl;
		os << "idxNext|" << idxNext << endl;
		os << "idxPre|" << idxPre << endl;
		os << "flag|" << flag << endl;
	//纠结，debug状态下搞datap，遍不过去，就注释掉吧
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
//纠结，debug状态下搞datap，遍不过去，就注释掉吧
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
			//默认访问是used node
			m_state = 1;
		}
		//call非零时，从for_each_node调用中中断，并返回改值
		//callTimes指明第几次被调用
		virtual int call(const NODE_TYPE* pnode, int callTimes) = 0;
		//设置需要访问的节点类型, -1=all, 0=free, 1=used
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
			char magicTag[32]; //MAGICTAG，标记这块内存是否被初始化过
			unsigned int version; //关联的类的版本
			int idxUsed; //使用中节点链表, idx表示节点在m_pnodes数组中的下标
			int idxFree; //空闲链表，idx表示节点在m_pnodes数组中的下标
			unsigned int curNodeNum; //在使用中的节点数目
			unsigned int nodeSize; //节点大小，模版类，节点大小要配套
			unsigned int nodeNum;  //最大可用节点数
			char reserve[200]; //保留字段
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

		//是当前mem失效，初始化时一定格式化
		static void clear(void* mem)
		{
			memset(mem, 0x0, sizeof(QUEUE_HEAD));
		}

		//自动区分是否格式化，调用valid()查看是否初始化成功，调用format()查看是否格式化了
		//指定mem大小，自动计算可以容纳的节点
		CFIFOQueue(void* memStart,unsigned int memSize)
		{
			m_nodeNum = node_num(memSize);
			m_memSize = mem_size(m_nodeNum); //实际占用的
			if(m_nodeNum == 0)
			{
				m_valid = false;
				m_err.errcode = ERR_MEM_NOT_ENOUGH;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue memSize=%u too small", memSize);
				return;
			}

			init(memStart);
		}

		//指定节点，自动计算需要的内存。maxMemSize可以通过mem_size函数计算。
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

		//进入队列，队首，idx返回节点的索引
		int inqueue(int& nodeIdx,DATA_POINTER datap)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue init not valid");
				return m_err.errcode;
			}

			int idx = m_phead->idxFree;
			if(idx < 0) //满了
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

			//copy 数据			
			m_pnodes[idx].datap = datap;

			//使用中
			m_pnodes[idx].flag = 1;
		
			//取下第一个node
			if(m_pnodes[idx].idxNext == idx) //是否只剩下一个了
			{
				m_phead->idxFree = -1;
			}
			else
			{
				m_pnodes[m_pnodes[idx].idxNext].idxPre = m_pnodes[idx].idxPre;
				m_pnodes[m_pnodes[idx].idxPre].idxNext = m_pnodes[idx].idxNext;
				m_phead->idxFree = m_pnodes[idx].idxNext;

			}
			//加到使用中的链表头部
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

		//删除，按指定的idx
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

			//释放节点
			inner_free(nodeIdx);
	
			return RET_OK;			
		}

		//出队列, theIdx返回仅供参考，已经不是合法的idx了
		int outqueue(DATA_POINTER& datap, int* ptheIdx=NULL, bool autodel=true)
		{
			if(!m_valid)
			{
				m_err.errcode = ERR_NOT_VALID;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue init not valid");
				return m_err.errcode;
			}

			if(m_phead->idxUsed == -1) //空了
			{
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue empty");
				return RET_EMPTY;
			}

			int idx = m_pnodes[m_phead->idxUsed].idxPre; //pre就是最后一个节点

			datap = m_pnodes[idx].datap;

			if(ptheIdx)
			{
				*ptheIdx = idx;
			}

			if(autodel)
			{
				//释放节点
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


		//打印内部状态
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
			for(; idx >= 0 && i<m_nodeNum; ++i) //最多循环m_nodeNum次
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
			for(; idx >= 0 && i<m_nodeNum; ++i) //最多循环m_nodeNum次
			{
				m_pnodes[idx].debug(os);
				idx = m_pnodes[idx].idxNext;
				if(idx == m_phead->idxFree)
				{
					break;
				}
			}
			
		}

		//用户自定义遍历，继承VISTOR 实现call函数
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
		//内部调用前，已经确认释放合法
		void inner_free(int idx)
		{
			m_pnodes[idx].flag = 0;
			
			//取下
			if(m_pnodes[idx].idxNext == idx) //是否只剩下一个了
			{
				m_phead->idxUsed = -1;
			}
			else
			{
				m_pnodes[m_pnodes[idx].idxNext].idxPre = m_pnodes[idx].idxPre;
				m_pnodes[m_pnodes[idx].idxPre].idxNext = m_pnodes[idx].idxNext;
				if(m_phead->idxUsed == idx) //正好是第一个
				{
					m_phead->idxUsed = m_pnodes[idx].idxNext;
				}
			}

			//放到空闲链表中
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
			
			//检查usednodes

			unsigned int realNum = 0; //实际遍历到的节点个数

			if(startIdx >= 0) //非空链表
			{
				//startIdx 对不?
				if(startIdx >= (int)(m_phead->nodeNum))
				{
					m_err.errcode = ERR_REINIT_NODES;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s startIdx=%d not valid", linkListName, startIdx);
					return false;
				}
				
				int idx = startIdx; //遍历用
				int idxrealpre = -1; //遍历用 初始时不知道 真实的上个节点

				unsigned int i = 0;
				for(; i<m_nodeNum; ++i) //最多循环m_nodeNum次
				{
					//idx有效性
					if(idx < 0 || idx >= (int)(m_phead->nodeNum))
					{
						m_err.errcode = ERR_REINIT_NODES;
						snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s loop(%u) (idx=%d) not valid", linkListName, i, idx);
						return false;
					}

					//flag有效性
					if(flag_should_be_zero)//应该为0的
					{
						if(m_pnodes[idx].flag != 0) 
						{
							m_err.errcode = ERR_REINIT_NODES;
							snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s loop(%u) (idx=%d) flag!=0 not valid", linkListName, i, idx);
							return false;
						}
					}
					else//应该不为0的
					{
						if(m_pnodes[idx].flag == 0) 
						{
							m_err.errcode = ERR_REINIT_NODES;
							snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s loop(%u) (idx=%d) flag==0 not valid", linkListName, i, idx);
							return false;
						}
					}


					//pre的检查
					if(i != 0) //首节点循环后再检查
					{
						if(m_pnodes[idx].idxPre != idxrealpre)
						{
							m_err.errcode = ERR_REINIT_NODES;
							snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s loop(%u) (idx=%d)->idxPre(%d) != idxrealpre(%d) not valid", 
								linkListName, i, idx, m_pnodes[idx].idxPre, idxrealpre);
							return false;
						}
					}
					idxrealpre = idx; //记下来
					
					//当前节点检查完毕
					
					//结束条件
					if(m_pnodes[idx].idxNext == startIdx)
					{
						break;
					}
					else
					{
						//下个节点
						idx = m_pnodes[idx].idxNext;
					}
				}

				//是否有循环链表?没有正常break
				if(i==m_nodeNum)
				{
					m_err.errcode = ERR_REINIT_NODES;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s loop(%u) == m_nodeNum(%u) not valid", 
						linkListName, i, m_nodeNum);
					return false;
				}

				//第一个node的pre，遍历完毕之后校验是否是最后一个node
				if(idxrealpre != m_pnodes[startIdx].idxPre)
				{
					m_err.errcode = ERR_REINIT_NODES;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "FIFOQueue %s (start_idx=%d)->idxPre(%d) != idxrealpre(%d) not valid", 
						linkListName,idx, m_pnodes[idx].idxPre, idxrealpre);
					return false;
				}

				//真实的节点数
				realNum = i+1;
			}

			//验证节点数目对不
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

			if(strncmp(m_phead->magicTag, FIFOQueue_MAGICTAG, sizeof(m_phead->magicTag))!= 0) //需要格式化
			{
				m_formated = true;
				snprintf(m_phead->magicTag,sizeof(m_phead->magicTag), "%s", FIFOQueue_MAGICTAG);
				m_phead->version = VERSION;
				m_phead->idxUsed = -1; //没有已经使用的节点
				m_phead->idxFree = 0; //所有的节点都是未使用的
				m_phead->curNodeNum = 0; //已经使用的节点总数为0
				m_phead->nodeNum = m_nodeNum;
				m_phead->nodeSize = sizeof(NODE_TYPE);

				for(unsigned int i=0; i<m_phead->nodeNum; ++i)
				{
					if(i == m_phead->nodeNum-1)
					{
						m_pnodes[i].idxNext = 0; //循环的
					}
					else
					{
						m_pnodes[i].idxNext = i+1;
					}

					if(i==0)
					{
						m_pnodes[i].idxPre = m_phead->nodeNum-1; //循环的
					}
					else
					{
						m_pnodes[i].idxPre = i-1;
					}

					m_pnodes[i].flag = 0; //0=未使用
				}
			}
			
			else//保护代码，检查内存
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
				//检查 usedlist
				if( ! check_link_list(m_phead->idxUsed, false, m_phead->curNodeNum, "usedlist") )
				{
					return;
				}

				//检查freelist (检查usednodes的结果可以保证m_phead->curNodeNum <= m_phead->nodeNum)
				if( ! check_link_list(m_phead->idxFree, true, m_phead->nodeNum - m_phead->curNodeNum, "usedfree") )
				{
					return;
				}
#endif
			}
			
			m_valid = true; //ok的
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

