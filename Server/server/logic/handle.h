#ifndef __LOGIC_HANDLE_H__
#define __LOGIC_HANDLE_H__

#include "msg.h"
#include "toolkit.h"
#include "mem_alloc/obj_pool.h"
#include "struct/mutilsize_allocator.h"

//����
class CLogicHandle;
class CLogicCreator;

//�߼��������Ļ���
class CLogicProcessor
{
public:
	static const int RET_YIELD = 1; //��ͣ���ȴ���һ����Ϣ
	static const int RET_DONE = 0; //�����ˣ�����ɾ������

public:
	CLogicProcessor():m_ptoolkit(NULL),m_id(0)
	{
	}
	
	virtual ~CLogicProcessor() {};

	//�Ƿ���Ҫʹ�����ݳ־û�
	//return �󶨵Ĺ����ڴ���С 0���ǲ���Ҫ
	//��on_init֮ǰ�󶨵�m_shm
	virtual int need_shm_size()
	{
		return 0;
	}

	virtual void bind_shm(char* p)
	{
	}

	//���󴴽������һ�Σ�������need_shm_size����Ĺ����ڴ�
	virtual void on_init() = 0; 
	//��msg�����ʱ�򼤻����
	virtual int on_active(CLogicMsg& msg) = 0;
	//��������ǰ����һ��
	virtual void on_finish() = 0;


	//new ������Ĺ�������, ������newŶ��handleҪdelete��
	virtual CLogicProcessor* create() = 0;

	//ʹ��objpool�İ汾
	virtual CLogicProcessor* create_in_objpool(CObjPools::HANDLE& objPoolHandle)
	{
		return NULL;
	}

	friend class CLogicHandle;
	friend class CToolkit;
protected:
	CToolkit* m_ptoolkit; //�����toolkit
	unsigned int m_id; //ȫ��Ψһ��id
	//char* m_shm; //�󶨵Ĺ����ڴ�
};


template<typename SHM_DATA_TYPE>
class CLogicProcessorTyped: public CLogicProcessor
{
	virtual int need_shm_size()
	{
		return sizeof(SHM_DATA_TYPE);
	}

	virtual void bind_shm(char* p)
	{
		//placement new
		m_shm = new(p)  SHM_DATA_TYPE;
	}
	
public:
	SHM_DATA_TYPE* m_shm;
};

//�߼��������ľ��
class CLogicHandle
{
public:
	struct SHM_SAVE_CREATE_INFO
	{
		//�������ֶ��漰���ؽ�����
		unsigned int savedHandleID;
		unsigned int savedMsgCmd;
	};
	
public:

	friend class CLogicCreator;
	
	CLogicHandle();

	inline void on_init()
	{
		//���������л������ĵ�����
		m_processor->m_ptoolkit->set_processorID(m_processor->m_id);
		m_processor->on_init();
	}

	inline int on_active(CLogicMsg& msg)
	{
		m_processor->m_ptoolkit->set_processorID(m_processor->m_id);
		return m_processor->on_active(msg);
	}

	inline void on_finish()
	{
		m_processor->m_ptoolkit->set_processorID(m_processor->m_id);
		return m_processor->on_finish();
	}

	inline CLogicProcessor* get_processor()
	{
		return m_processor;
	}

	void free_processor();
	
	int init_processor(unsigned int id, unsigned int msgID, CToolkit* ptool, CMutilsizeAllocator* pallocator);

	//�ӹ����ڴ��лָ�
	int recover_processor(void* shm, unsigned shmsize, CToolkit* ptool, CMutilsizeAllocator* pallocator);

protected:
	char* m_shmaddr;
	unsigned int m_shmsize;
	CMutilsizeAllocator* m_pallocator;
	//���¶���creator�޸ĵ�
	CLogicProcessor* m_processor;
	CObjPools::HANDLE m_objPoolHandle;
	bool m_busepool;
	bool m_bholdprocessor;
};

class CLogicCreator
{
public:
	CLogicCreator(CLogicProcessor* protoProcessor,  bool uniq =false):m_proto(protoProcessor), m_uniq(uniq)
	{
	}

	CLogicCreator():m_proto(NULL)
	{
	}
	
	inline bool uniq()
	{
		return m_uniq;
	}

	int create(CLogicHandle& handle, bool buseobjpool);
	
protected:
	CLogicProcessor* m_proto;
	//createrֻʹ�ñ��ְ󶨵�CLogicProcessor, ��ȥcreate�µĶ����ʺϲ�RET_YIELD��CLogicProcessor
	bool m_uniq; 
};

#endif

