#ifndef __LOGIC_HANDLE_H__
#define __LOGIC_HANDLE_H__

#include "msg.h"
#include "toolkit.h"
#include "mem_alloc/obj_pool.h"
#include "struct/mutilsize_allocator.h"

//申明
class CLogicHandle;
class CLogicCreator;

//逻辑处理对象的基类
class CLogicProcessor
{
public:
	static const int RET_YIELD = 1; //暂停，等待下一个消息
	static const int RET_DONE = 0; //结束了，可以删除对象

public:
	CLogicProcessor():m_ptoolkit(NULL),m_id(0)
	{
	}
	
	virtual ~CLogicProcessor() {};

	//是否需要使用数据持久化
	//return 绑定的共享内存块大小 0就是不需要
	//在on_init之前绑定到m_shm
	virtual int need_shm_size()
	{
		return 0;
	}

	virtual void bind_shm(char* p)
	{
	}

	//对象创建后调用一次，参数是need_shm_size申请的共享内存
	virtual void on_init() = 0; 
	//有msg到达的时候激活对象
	virtual int on_active(CLogicMsg& msg) = 0;
	//对象销毁前调用一次
	virtual void on_finish() = 0;


	//new 具体类的工厂函数, 必须用new哦，handle要delete的
	virtual CLogicProcessor* create() = 0;

	//使用objpool的版本
	virtual CLogicProcessor* create_in_objpool(CObjPools::HANDLE& objPoolHandle)
	{
		return NULL;
	}

	friend class CLogicHandle;
	friend class CToolkit;
protected:
	CToolkit* m_ptoolkit; //保存的toolkit
	unsigned int m_id; //全局唯一的id
	//char* m_shm; //绑定的共享内存
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

//逻辑处理对象的句柄
class CLogicHandle
{
public:
	struct SHM_SAVE_CREATE_INFO
	{
		//这两个字段涉及到重建对象
		unsigned int savedHandleID;
		unsigned int savedMsgCmd;
	};
	
public:

	friend class CLogicCreator;
	
	CLogicHandle();

	inline void on_init()
	{
		//可以做点切换上下文的事情
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

	//从共享内存中恢复
	int recover_processor(void* shm, unsigned shmsize, CToolkit* ptool, CMutilsizeAllocator* pallocator);

protected:
	char* m_shmaddr;
	unsigned int m_shmsize;
	CMutilsizeAllocator* m_pallocator;
	//以下都是creator修改的
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
	//creater只使用保持绑定的CLogicProcessor, 不去create新的对象，适合不RET_YIELD的CLogicProcessor
	bool m_uniq; 
};

#endif

