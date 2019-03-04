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
		//call����ʱ����for_each_node�������жϣ������ظ�ֵ
		//val���Ա��޸�
		//callTimesָ���ڼ��α�����
		virtual ~CHashMapVisitor(){}
		virtual int call(const TYPE_KEY& key, TYPE_VAL& val ,int callTimes) = 0;
	public:
		bool shouldDelete;
};

#define HASHMAP_MAGICTAG "HashMap_mars_20110507"

#pragma pack(push)
#pragma pack(1)
//keyΪTKEY��ֵ��TVAL
template<typename TKEY, typename TVAL, typename THASH=HashType<TKEY> > //TKEY�����ж���hash(unsigned int hashNum)
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
		unsigned int next; //��λ�ǽڵ�������±� =0��ʾ�գ���1���ڵ���ֻվλ����ͻ
		void debug(ostream& os)
		{
			os << "HASH_MAP_NODE{" << endl;
			//���ᣬdebug״̬�¸�,val,key��֧�ֵĻ��Լ�����
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
		unsigned int maxNodeNum; //�������ɽڵ���
		unsigned int hashNum; //hash������
		unsigned int valSize;	//ֵ�Ĵ�С
		unsigned int keySize;	//key�Ĵ�С
		unsigned int curNodeNum; //�Ѿ�����Ľڵ���
		unsigned int freeHead; //���ͷŵĽڵ�����ֵ��m_pnodes�����idx 0=�գ�m_pnodes�ĵ�һ���ڵ㲻�������
		unsigned int unusedBorder; //��λ�ü�����Ľڵ�δ��ʼ������λ�ǽڵ�������±�
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
		//maxNodeNum+1 ���1��ָ��1�ڵ���Ϊ��־ʹ�ã����������
		return sizeof(HASH_MAP_HEAD)+sizeof(unsigned int)*hashNum+sizeof(HASH_MAP_NODE)*(maxNodeNum+1);
	}

	
	//ʹ��ǰmemʧЧ������mem�Ͻ���hashmap�ض��߸�ʽ������
	static void clear(void* mem)
	{
		memset(mem, 0x0, sizeof(HASH_MAP_HEAD));
	}
	
	//�Զ������Ƿ��ʽ��������valid()�鿴�Ƿ��ʼ���ɹ�������format()�鿴�Ƿ��ʽ����
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

		if(strncmp(m_phead->magicTag, HASHMAP_MAGICTAG, sizeof(m_phead->magicTag))!= 0) //��Ҫ��ʽ��
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
			m_phead->unusedBorder = 1; //��1���ڵ��Ѿ���Ϊ��־ʹ��
			//��ʼ��hash��
			memset(m_phashArray, 0x0, hashNum*sizeof(*m_phashArray));
			m_pnodes[0].next = 0; //��һ���ڵ�next����Ϊ0����ֹ�����쳣
		}
		else
		{
			//У��
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

			if(m_phead->unusedBorder == 0 || m_phead->unusedBorder > m_phead->maxNodeNum+1) //����ʱ��m_phead->unusedBorder = m_phead->maxNodeNum+1
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
			//ͳ����used�Բ�
			unsigned int used = 0;
			for(unsigned int i=0; i<m_phead->hashNum; ++i)
			{
				unsigned int next = m_phashArray[i];
				for(unsigned int j=0; j<m_phead->unusedBorder && next != 0;++j) //����unusedBorder��Ԫ��
				{
					if(next >= m_phead->unusedBorder) //�����ˡ�����
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

			//�鿴free����
			unsigned int free = 0;
			unsigned int next = m_phead->freeHead;
			for(unsigned int k=0; k<m_phead->unusedBorder && next != 0;++k) //����unusedBorder��Ԫ��
			{
				if(next >= m_phead->unusedBorder) //�����ˡ�����
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
				//�нڵ�й©
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

		//�����������copy��������Ϊ��ģ��ʵ��������Ѿ�������
		memcpy(m_pnodes, target->m_pnodes, sizeof(HASH_MAP_NODE)*phead->maxNodeNum);

		//modify head
		m_phead->unusedBorder = phead->unusedBorder;
		m_phead->freeHead = phead->freeHead;
		m_phead->curNodeNum = phead->curNodeNum;
		
		return 0;
	}

	//return =1, pold��ΪNULL��copy��ֵ��*pold
	//return 0=�½��Ľڵ㣬1=�����Ͻڵ㣬<0����
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
			//�µ�
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

			//��ֵ
			m_pnodes[idx].key = key;
			m_pnodes[idx].val = val;

			//����
			if(*tag!=0)
				m_pnodes[idx].next = m_pnodes[*tag].next; 
			else
				m_pnodes[idx].next = 0;
//LOG(LOG_INFO, "*tag=%u next=%u", *tag, m_pnodes[*tag].next);
			*tag = idx;

			//����ʹ�ýڵ�
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
			//����
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
			//�µ�
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

			//��ֵ
			m_pnodes[idx].key = key;
			theIdx = idx;

			//����
			if(*tag!=0)
				m_pnodes[idx].next = m_pnodes[*tag].next; 
			else
				m_pnodes[idx].next = 0;
			*tag = idx;

			//����ʹ�ýڵ�
			++m_phead->curNodeNum;
			return 0;
		}
		else
		{
			//����
			theIdx = idx;
			return 1;
		}
	}

	//return 0��û�нڵ㣬 1�нڵ㣬<0����
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

	//ֱ�ӷ��ؽڵ��idx������
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

	//��idx��ȡval��ָ��
	TVAL* get_val_pointer(unsigned int idx)
	{
		//���idx������get_node_idx���صĶ���������Ҳ����У����
		return &(m_pnodes[idx].val);
	}

	//��idx��ȡkey��ָ��
	const TKEY* get_key_pointer(unsigned int idx)
	{
		//���idx������get_node_idx���صĶ���������Ҳ����У����
		return &(m_pnodes[idx].key);
	}

	//return=1, pold��ΪNULL��copy��ֵ��*pold
	//return 0=�ڵ㲻���ڣ�1=�����Ͻڵ㣬<0����
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
			//����
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

	//��ӡ�ڲ�״̬
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
			for(unsigned int j=0; j<m_phead->unusedBorder && next != 0;++j) //����unusedBorder��Ԫ��
			{
				m_pnodes[next].debug(os);
				next = m_pnodes[next].next;
			}
		}

		next = m_phead->freeHead;
		os << "free=" << next << ":" << endl;
		for(unsigned int k=0; k<m_phead->unusedBorder && next != 0;++k) //����unusedBorder��Ԫ��
		{
			m_pnodes[next].debug(os);
			next = m_pnodes[next].next;
		}
	}

	//�û��Զ���������̳�VISTOR ʵ��call����
	//�����õ����������뱣֤ͬʱû��д����
	int for_each_node(CHashMapVisitor<TKEY, TVAL>* pvisitor)
	{	
		int callTimes = 0;
		int ret = 0;
		unsigned int next;
		for(unsigned int i=0; i<m_phead->hashNum; ++i)
		{
			next = m_phashArray[i];
			unsigned int* prepos = &m_phashArray[i];
			for(unsigned int j=0; j<m_phead->unusedBorder && next != 0;++j) //����unusedBorder��Ԫ��
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

	//���ڲ���Ҫɾ����Ӧ����˵�����԰�ȫ��������
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
	//idx����������Ľڵ�
	//����0��ʾû���ڴ�ɷ�����
	unsigned int new_node()
	{
		unsigned int ret = 0;
		if(m_phead->freeHead != 0)
		{
			//��free������ȡ��һ��
			ret = m_phead->freeHead;
			m_phead->freeHead = m_pnodes[m_phead->freeHead].next;
		}
		else
		{
			//ֱ�Ӵ�δ�����ַ�и���
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

	//pointAddr����ָ�ϸ��ڵ��next�ĵ�ַ�������޸ġ�
	//unsigned int��������ڵ��idx, 0û���ҵ�
	//�����ʱ��return=0 && pointAddr = NULL
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
		*prepos = m_pnodes[idx].next; //��������ȡ��
		m_pnodes[idx].next = m_phead->freeHead; //�ӵ�free���ײ�
		m_phead->freeHead = idx;
		
		//����ʹ�ýڵ���Ŀ
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

