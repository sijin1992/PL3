#ifndef __HASH_MAP_H__
#define __HASH_MAP_H__

#include "common_def.h"
#include <iostream>
#include <string.h>
#include <string>
#include "hash_type.h"
#include "../log/log.h"
//#include <sstream>

using namespace std;

template<typename TKEY, typename TVAL>
class CHashMapVisitor
{
	protected:
		typedef TKEY TYPE_KEY;
		typedef TVAL TYPE_VAL;
	public:
		//call非零时，从for_each_node调用中中断，并返回改值
		//val可以被修改
		//callTimes指明第几次被调用
		virtual ~CHashMapVisitor(){}
		virtual int call(const TYPE_KEY& key, TYPE_VAL& val ,int callTimes) = 0;
	public:
		bool shouldDelete;
};

#define HASHMAP_MAGICTAG "HashMap_mars_20110507"

#pragma pack(push)
#pragma pack(1)
//key为TKEY，值是TVAL
template<typename TKEY, typename TVAL, typename THASH=HashType<TKEY> > //TKEY必须有定义hash(unsigned int hashNum)
class CHashMap
{
public:
	static const unsigned int VERSION = 0x1001; 
	static const int ERR_VERSION = -1;
	static const int ERR_MEM_NOT_ENOUGH = -3;
	static const int ERR_HEAD_NODENUM = -4;
	static const int ERR_HEAD_VALSIZE = -5;
	static const int ERR_HEAD_KEYSIZE = -6;
	static const int ERR_HASH = -7;
	static const int ERR_BORDER = -8;
	static const int ERR_HEAD_CURNUM = -9;
	static const int ERR_FREE = -10;
	static const int ERR_NOT_VALID = -11;

	typedef struct tagHashMapNode
	{
		TKEY key; 
		TVAL val;
		unsigned int next; //单位是节点数组的下标 =0表示空，第1个节点是只站位不冲突
		void debug(ostream& os)
		{
			os << "HASH_MAP_NODE{" << endl;
			//纠结，debug状态下搞,val,key不支持的话自己重载
//#ifdef DEBUG
//			os << "key|" << key.str() << endl;
//			os << "val|" << val.roomid << "," << val.useridx << endl;
//#endif
			os << "next|" << next << endl;
			os << "} end HASH_MAP_NODE" << endl;
		}

	}HASH_MAP_NODE;
	
	typedef struct tagHashMapHead
	{
		char magicTag[32];
		unsigned int version;
		unsigned int maxNodeNum; //最多可容纳节点数
		unsigned int hashNum; //hash的数量
		unsigned int valSize;	//值的大小
		unsigned int keySize;	//key的大小
		unsigned int curNodeNum; //已经分配的节点数
		unsigned int freeHead; //已释放的节点链表，值是m_pnodes数组的idx 0=空，m_pnodes的第一个节点不参与分配
		unsigned int unusedBorder; //此位置及后面的节点未初始化，单位是节点数组的下标
		char reserve[200];

		void debug(ostream& os)
		{
			os << "HASH_MAP_HEAD{" << endl;
			os << "magicTag|" << magicTag << endl;
			os << "version|" << version << endl;
			os << "maxNodeNum|" << maxNodeNum << endl;
			os << "hashNum|" << hashNum << endl;
			os << "curNodeNum|" << curNodeNum << endl;
			os << "valSize|" << valSize << endl;
			os << "keySize|" << keySize << endl;
			os << "freeHead|" << freeHead << endl;
			os << "unusedBorder|" << unusedBorder << endl;
			os << "} end HASH_MAP_HEAD" << endl;
		}

	}HASH_MAP_HEAD;

public:
	static size_t mem_size(unsigned int maxNodeNum, unsigned int hashNum)
	{
		//maxNodeNum+1 这个1是指第1节点作为标志使用，不参与分配
		return sizeof(HASH_MAP_HEAD)+sizeof(unsigned int)*hashNum+sizeof(HASH_MAP_NODE)*(maxNodeNum+1);
	}

	
	//使当前mem失效，若在mem上建立hashmap必定走格式化流程
	static void clear(void* mem)
	{
		memset(mem, 0x0, sizeof(HASH_MAP_HEAD));
	}
	
	//自动区分是否格式化，调用valid()查看是否初始化成功，调用format()查看是否格式化了
	CHashMap(void* memStart,size_t maxMemSize,unsigned int maxNodeNum, unsigned int hashNum)
	{
		if(maxNodeNum == 0 || hashNum == 0)
		{
			m_valid = false;
			m_err.errcode = ERR_NOT_VALID;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "maxNodeNum=%u and hashNum=%u not valid", 
				maxNodeNum, hashNum);
			return;
		}
		
		size_t needMem = mem_size(maxNodeNum, hashNum);
		if(needMem < maxMemSize)
		{
			m_valid = false;
			m_err.errcode = ERR_MEM_NOT_ENOUGH;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap node_num=%u hash_num=%u needs memSize="PRINTF_FORMAT_FOR_SIZE_T" but maxMemSize="PRINTF_FORMAT_FOR_SIZE_T"", 
				maxNodeNum, hashNum,needMem,maxMemSize);
			return;
		}

		m_phead = (HASH_MAP_HEAD*)memStart;
		m_phashArray = (unsigned int*)((char*)m_phead + sizeof(HASH_MAP_HEAD));
		m_pnodes = (HASH_MAP_NODE*)((char*)m_phashArray + sizeof(unsigned int)*hashNum);
		m_formated = false;
		m_valid = false;

		if(strncmp(m_phead->magicTag, HASHMAP_MAGICTAG, sizeof(m_phead->magicTag))!= 0) //需要格式化
		{
			m_formated = true;
			snprintf(m_phead->magicTag,sizeof(m_phead->magicTag), "%s", HASHMAP_MAGICTAG);
			m_phead->version = VERSION;
			m_phead->maxNodeNum = maxNodeNum;
			m_phead->hashNum = hashNum;
			m_phead->valSize = sizeof(TVAL);
			m_phead->keySize = sizeof(TKEY);
			m_phead->curNodeNum = 0;
			m_phead->freeHead = 0;
			m_phead->unusedBorder = 1; //第1个节点已经作为标志使用
			//初始化hash表
			memset(m_phashArray, 0x0, hashNum*sizeof(*m_phashArray));
			m_pnodes[0].next = 0; //第一个节点next设置为0，防止出现异常
		}
		else
		{
			//校验
			if(m_phead->version != VERSION )
			{
				m_err.errcode = ERR_VERSION;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap head.version(%u) != version(%u)", m_phead->version, VERSION);
				return;
			}

			if(m_phead->maxNodeNum != maxNodeNum)
			{
				m_err.errcode = ERR_HEAD_NODENUM;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap head.maxNodeNum(%u) != maxNodeNum(%u)", m_phead->maxNodeNum, maxNodeNum);
				return;
			}
			
			if(m_phead->valSize != sizeof(TVAL))
			{
				m_err.errcode = ERR_HEAD_VALSIZE;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap head.valSize(%u) != valSize("PRINTF_FORMAT_FOR_SIZE_T")", m_phead->valSize, sizeof(TVAL));
				return;
			}

			if(m_phead->keySize != sizeof(TKEY))
			{
				m_err.errcode = ERR_HEAD_KEYSIZE;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap head.keySize(%u) != keySize("PRINTF_FORMAT_FOR_SIZE_T")", m_phead->keySize, sizeof(TKEY));
				return;
			}

			if(m_phead->unusedBorder == 0 || m_phead->unusedBorder > m_phead->maxNodeNum+1) //满的时候m_phead->unusedBorder = m_phead->maxNodeNum+1
			{
				m_err.errcode = ERR_BORDER;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap head.unusedBorder(%u) not valid maxidx=%u", 
					m_phead->unusedBorder, m_phead->maxNodeNum);
				return;
			}

			if(m_phead->freeHead >= m_phead->unusedBorder)
			{
				m_err.errcode = ERR_FREE;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap head.freeHead(%u) >= unusedBorder(%u)", 
					m_phead->freeHead, m_phead->unusedBorder);
				return;
			}

			if(m_phead->curNodeNum > m_phead->maxNodeNum)
			{
				m_err.errcode = ERR_FREE;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap head.curNodeNum(%u) > maxNodeNum(%u)", 
					m_phead->curNodeNum, m_phead->maxNodeNum);
				return;
			}
			
			
#ifdef DEBUG
			//统计下used对不
			unsigned int used = 0;
			for(unsigned int i=0; i<m_phead->hashNum; ++i)
			{
				unsigned int next = m_phashArray[i];
				for(unsigned int j=0; j<m_phead->unusedBorder && next != 0;++j) //最多才unusedBorder个元素
				{
					if(next >= m_phead->unusedBorder) //超过了。。。
					{
						m_err.errcode = ERR_HASH;
						snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap hash[%u] list[%u] idx=%u > border(%u)", 
							i, j, next, m_phead->unusedBorder);
						return;
					}
					++used;
					next = m_pnodes[next].next;
				}
			}

			if(used != m_phead->curNodeNum)
			{
				m_err.errcode = ERR_HEAD_CURNUM;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap head.curNodeNum(%u) != %u", 
					m_phead->curNodeNum, used);
				return;
			}

			//查看free链表
			unsigned int free = 0;
			unsigned int next = m_phead->freeHead;
			for(unsigned int k=0; k<m_phead->unusedBorder && next != 0;++k) //最多才unusedBorder个元素
			{
				if(next >= m_phead->unusedBorder) //超过了。。。
				{
					m_err.errcode = ERR_FREE;
					snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap free[%u] idx=%u > border(%u)", 
						k, next, m_phead->unusedBorder);
					return;
				}
				++free;
				next = m_pnodes[next].next;
			}

			if(free + used != m_phead->unusedBorder-1)
			{
				//有节点泄漏
				m_err.errcode = ERR_FREE;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap freeNodeNum(%u) + used(%u) != unused(%u) -1", 
					free, used, m_phead->unusedBorder);
				return;
			}
#endif
		}

		m_valid = true;
	}

	int copyFrom(CHashMap<TKEY, TVAL, THASH>* target)
	{
		if(!m_valid)
		{
			m_err.errcode = ERR_NOT_VALID;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap init not valid");
			return m_err.errcode;
		}

		HASH_MAP_HEAD* phead = target->get_head();
		
		if(m_phead->hashNum < phead->hashNum)
		{
			m_err.errcode = ERR_NOT_VALID;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "hashNum(%u) < %u", m_phead->hashNum, phead->hashNum);
			return m_err.errcode;
		}

		if(m_phead->maxNodeNum < phead->maxNodeNum)
		{
			m_err.errcode = ERR_NOT_VALID;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "maxNodeNum(%u) < %u", m_phead->maxNodeNum, phead->maxNodeNum);
			return m_err.errcode;
		}
		

		//copy hash
		memcpy(m_phashArray, target->m_phashArray, sizeof(unsigned int)*phead->hashNum);

		//做最大数量的copy，这里是为了模拟实际情况下已经满负荷
		memcpy(m_pnodes, target->m_pnodes, sizeof(HASH_MAP_NODE)*phead->maxNodeNum);

		//modify head
		m_phead->unusedBorder = phead->unusedBorder;
		m_phead->freeHead = phead->freeHead;
		m_phead->curNodeNum = phead->curNodeNum;
		
		return 0;
	}

	//return =1, pold不为NULL，copy旧值到*pold
	//return 0=新建的节点，1=覆盖老节点，<0错误
	int set_node(const TKEY& key, const TVAL& val, TVAL* pold=NULL, unsigned int* pidx=NULL)
	{
		if(!m_valid)
		{
			m_err.errcode = ERR_NOT_VALID;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap init not valid");
			return m_err.errcode;
		}

		unsigned int* tag;
		unsigned int idx = find(key,tag);
		if(idx == 0)
		{
			//新的
			if(tag == NULL)
			{
				return m_err.errcode;
			}

			//new node
			idx = new_node();
			if(idx == 0)
			{
				m_err.errcode = ERR_MEM_NOT_ENOUGH;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap new_node no memory");
				return m_err.errcode;
			}

			//赋值
			m_pnodes[idx].key = key;
			m_pnodes[idx].val = val;

			//插入
			if(*tag!=0)
				m_pnodes[idx].next = m_pnodes[*tag].next; 
			else
				m_pnodes[idx].next = 0;
//LOG(LOG_INFO, "*tag=%u next=%u", *tag, m_pnodes[*tag].next);
			*tag = idx;

			//增加使用节点
			++m_phead->curNodeNum;

			if(pidx)
			{
				*pidx = idx;
			}
//ostringstream os;
//debug(os);
//LOG(LOG_INFO, "set0 debug: %s", os.str().c_str());
			
			
			return 0;
		}
		else
		{
			//覆盖
			if(pold)
				*pold = m_pnodes[idx].val;

			m_pnodes[idx].val = val;
			
			if(pidx)
			{
				*pidx = idx;
			}

//ostringstream os;
//debug(os);
//LOG(LOG_INFO, "set1 debug: %s", os.str().c_str());

			return 1;
		}
	}

	int set_node_idx(const TKEY& key, unsigned int& theIdx)
	{
		if(!m_valid)
		{
			m_err.errcode = ERR_NOT_VALID;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap init not valid");
			return m_err.errcode;
		}

		unsigned int* tag;
		unsigned int idx = find(key,tag);
		if(idx == 0)
		{
			//新的
			if(tag == NULL)
			{
				return m_err.errcode;
			}

			//new node
			idx = new_node();
			if(idx == 0)
			{
				m_err.errcode = ERR_MEM_NOT_ENOUGH;
				snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap new_node no memory");
				return m_err.errcode;
			}

			//赋值
			m_pnodes[idx].key = key;
			theIdx = idx;

			//插入
			if(*tag!=0)
				m_pnodes[idx].next = m_pnodes[*tag].next; 
			else
				m_pnodes[idx].next = 0;
			*tag = idx;

			//增加使用节点
			++m_phead->curNodeNum;
			return 0;
		}
		else
		{
			//覆盖
			theIdx = idx;
			return 1;
		}
	}

	//return 0，没有节点， 1有节点，<0错误。
	int get_node(const TKEY& key, TVAL& val)
	{
		if(!m_valid)
		{
			m_err.errcode = ERR_NOT_VALID;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap init not valid");
			return m_err.errcode;
		}
	
		unsigned int* tag;
		unsigned int idx = find(key, tag);
		if(idx == 0)
		{
			if(tag == NULL)
			{
				return m_err.errcode;
			}

			return 0;
		}
		else
		{
			val = m_pnodes[idx].val;
			return 1;
		}
	}

	//直接返回节点的idx，慎用
	int get_node_idx(const TKEY& key,unsigned int& theIdx)
	{
		if(!m_valid)
		{
			m_err.errcode = ERR_NOT_VALID;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap init not valid");
			return m_err.errcode;
		}
	
		unsigned int* tag;
		unsigned int idx = find(key,tag);

		if(idx == 0)
		{
			if(tag == NULL)
			{
				return m_err.errcode;
			}
		
			return 0;
		}
		else
		{
			theIdx = idx;
			return 1;
		}
	}

	//从idx获取val的指针
	TVAL* get_val_pointer(unsigned int idx)
	{
		//这个idx必须是get_node_idx返回的东西，所以也不做校验了
		return &(m_pnodes[idx].val);
	}

	//从idx获取key的指针
	const TKEY* get_key_pointer(unsigned int idx)
	{
		//这个idx必须是get_node_idx返回的东西，所以也不做校验了
		return &(m_pnodes[idx].key);
	}

	//return=1, pold不为NULL，copy旧值到*pold
	//return 0=节点不存在，1=覆盖老节点，<0错误
	int del_node(const TKEY& key, TVAL* pold=NULL)	
	{
		if(!m_valid)
		{
			m_err.errcode = ERR_NOT_VALID;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap init not valid");
			return m_err.errcode;
		}
		
		unsigned int* tag;
		unsigned int idx = find(key,tag);
		if(idx == 0)
		{
			if(tag == NULL)
			{
				return m_err.errcode;
			}

			return 0;
		}
		else
		{
			//覆盖
			if(pold)
				*pold = m_pnodes[idx].val;

			releaseNode(tag, idx);
//ostringstream os;
//debug(os);
//LOG(LOG_INFO, "del1 debug: %s", os.str().c_str());

			return 1;
		}
	}

	inline HASH_MAP_HEAD* get_head()
	{
		return m_phead;
	}

	inline int free_num()
	{
		return m_phead->maxNodeNum - m_phead->curNodeNum;
	}
	
	inline bool valid()
	{
		return m_valid;
	}
	
	inline bool formated()
	{
		return m_formated;
	}

	//打印内部状态
	void debug(ostream& os)
	{
		if(!m_valid)
		{
			m_err.errcode = ERR_NOT_VALID;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap init not valid");
			return ;
		}

		m_phead->debug(os);

		unsigned int next;
		for(unsigned int i=0; i<m_phead->hashNum; ++i)
		{
			next = m_phashArray[i];
			os << "hash[" << i << "]=" << next << ":" << endl;
			for(unsigned int j=0; j<m_phead->unusedBorder && next != 0;++j) //最多才unusedBorder个元素
			{
				m_pnodes[next].debug(os);
				next = m_pnodes[next].next;
			}
		}

		next = m_phead->freeHead;
		os << "free=" << next << ":" << endl;
		for(unsigned int k=0; k<m_phead->unusedBorder && next != 0;++k) //最多才unusedBorder个元素
		{
			m_pnodes[next].debug(os);
			next = m_pnodes[next].next;
		}
	}

	//用户自定义遍历，继承VISTOR 实现call函数
	//由于用到了链表，必须保证同时没有写操作
	int for_each_node(CHashMapVisitor<TKEY, TVAL>* pvisitor)
	{	
		int callTimes = 0;
		int ret = 0;
		unsigned int next;
		for(unsigned int i=0; i<m_phead->hashNum; ++i)
		{
			next = m_phashArray[i];
			unsigned int* prepos = &m_phashArray[i];
			for(unsigned int j=0; j<m_phead->unusedBorder && next != 0;++j) //最多才unusedBorder个元素
			{
				pvisitor->shouldDelete = false;
				ret = pvisitor->call(m_pnodes[next].key, m_pnodes[next].val,++callTimes);
				if(ret != 0)
					return ret;
				
				if(pvisitor->shouldDelete)
				{
					unsigned int tmp = next;
					next = m_pnodes[next].next;
					releaseNode(prepos, tmp);
				}
				else
				{
					prepos = &m_pnodes[next].next;
					next = m_pnodes[next].next;
				}
			}
		}
		
		return 0;
	}

	//对于不需要删除的应用来说，可以安全的做遍历
	int for_used_data(CHashMapVisitor<TKEY, TVAL>* pvisitor)
	{
		int callTimes = 0;
		int ret = 0;
		for(unsigned int j=1; j<m_phead->unusedBorder; ++j)
		{
			ret = pvisitor->call(m_pnodes[j].key, m_pnodes[j].val,++callTimes);
			if(ret != 0)
				return ret;
		}

		return 0;
	}

	int reverse_used_data(CHashMapVisitor<TKEY, TVAL>* pvisitor)
	{
		int callTimes = 0;
		int ret = 0;
		
		for(unsigned int j=m_phead->unusedBorder-1; j>0; --j)
		{
			ret = pvisitor->call(m_pnodes[j].key, m_pnodes[j].val,++callTimes);
			if(ret != 0)
				return ret;
		}
		
		return 0;
	}

	int random_used_data(CHashMapVisitor<TKEY, TVAL>* pvisitor, int randOffset)
	{
		int callTimes = 0;
		int max = m_phead->unusedBorder-1;
		int offset = randOffset%max;
		int ret = 0;
		for(unsigned int j=1; j<=max; ++j)
		{
			int nowIdx = (j+offset)%max+1;
			ret = pvisitor->call(m_pnodes[nowIdx].key, m_pnodes[nowIdx].val,++callTimes);
			if(ret != 0)
				return ret;
		}
		
		return 0;
	}

protected:
	//idx返回新申请的节点
	//返回0表示没有内存可分配了
	unsigned int new_node()
	{
		unsigned int ret = 0;
		if(m_phead->freeHead != 0)
		{
			//从free链表上取第一个
			ret = m_phead->freeHead;
			m_phead->freeHead = m_pnodes[m_phead->freeHead].next;
		}
		else
		{
			//直接从未分配地址中给出
			if(m_phead->unusedBorder <= m_phead->maxNodeNum)
			{
				ret = m_phead->unusedBorder++;
			}
		}

		if(ret != 0)
		{
			m_pnodes[ret].next = 0;
		}

//LOG(LOG_INFO, "new node %u", ret);		
		return ret;
	}

	inline unsigned int get_hash(const TKEY& key,unsigned int hashNum)
	{
		return (m_hashobj.do_hash(key))%hashNum;
	}

	//pointAddr返回指上个节点的next的地址，用来修改。
	//unsigned int返回这个节点的idx, 0没有找到
	//出错的时候，return=0 && pointAddr = NULL
	unsigned int find(const TKEY& key, unsigned int*& pposAddr)
	{
		unsigned int hashval = get_hash(key,m_phead->hashNum);

		if(hashval >= m_phead->hashNum)
		{
			m_err.errcode = ERR_HASH;
			snprintf(m_err.errstrmsg, sizeof(m_err.errstrmsg), "CHashMap find(...) bad hash %u", hashval);
			pposAddr = NULL;
			return 0;
		}

		pposAddr = &(m_phashArray[hashval]);
		unsigned int idx = m_phashArray[hashval];
		unsigned int j;
		for( j=0; j<m_phead->unusedBorder && idx != 0; ++j)
		{
			if(m_pnodes[idx].key == key)
			{
				break;
			}
			else
			{
				pposAddr = &(m_pnodes[idx].next);
				idx = m_pnodes[idx].next;
			}
		}

		if(j >= m_phead->unusedBorder)
		{
//			ostringstream os;
//			debug(os);
//			LOG(LOG_INFO, "find error debug: %s", os.str().c_str());
		}
		
		return idx;
	}

	inline void releaseNode(unsigned int* prepos, unsigned int idx)
	{
		*prepos = m_pnodes[idx].next; //从链表上取下
		m_pnodes[idx].next = m_phead->freeHead; //加到free的首部
		m_phead->freeHead = idx;
		
		//减少使用节点数目
		-- m_phead->curNodeNum;
	}

protected:
	HASH_MAP_HEAD* m_phead;
	unsigned int* m_phashArray;
	HASH_MAP_NODE* m_pnodes;
	bool m_valid;
	bool m_formated;
	THASH m_hashobj;
public:
	ERROR_INFO m_err;
};
#pragma pack(pop)

#endif

