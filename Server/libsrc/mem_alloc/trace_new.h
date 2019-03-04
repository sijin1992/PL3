/*
 * @file     trace_new.h
 * @brief    webgame框架的对new delete的跟踪
 * @author   marszhang@tencent.com
 * @date     2010-11-15
 *
 * @note    	以前写过类似的东西，找不到了，悲剧啊
* 
 *
 */
#ifndef _TRACE_NEW_H_
#define _TRACE_NEW_H_

#include <map>
#include <ostream>
#include <iostream>

using namespace std;

class CTraceNew
{
	public:
		class CInfo
		{
			public:
				void* paddr;
				int unit_size;
				int line;
				string file;
		};

		void insert(void* paddr, int unit_size, int line, const char* file);

		void remove(void* paddr);

		void show(ostream& output);
		
		static CTraceNew* Instance();

	protected:
		CTraceNew();
		
	public:
		map<void*, CInfo> infoMap;
		static CTraceNew *pinstance;
		static void* ptr;
};

ostream& operator<<(ostream& output, CTraceNew::CInfo& info);


//外部需要统一使用宏来代替new/delete，DEBUG开关是否记录信息
//缺陷是必须单独一行，不能嵌入到()中
//trace_new本身不需要重新编译
#ifdef DEBUG
#define TRACE_NEW(TYPENAME) \
	(TYPENAME*)(CTraceNew::ptr=new TYPENAME);CTraceNew::Instance()->insert(CTraceNew::ptr, sizeof(TYPENAME),  __LINE__, __FILE__)
#define TRACE_NEW_ARGS(TYPENAME, ARGS...) \
	(TYPENAME*)(CTraceNew::ptr=new TYPENAME(ARGS));CTraceNew::Instance()->insert(CTraceNew::ptr, sizeof(TYPENAME),  __LINE__, __FILE__)
#define TRACE_NEW_ARRAY(TYPENAME, ELEMENT_NUM) \
	(TYPENAME*)(CTraceNew::ptr=new TYPENAME[ELEMENT_NUM]);CTraceNew::Instance()->insert(CTraceNew::ptr, sizeof(TYPENAME)*ELEMENT_NUM,  __LINE__, __FILE__)

#define TRACE_DEL(POINTER) \
	CTraceNew::Instance()->remove(POINTER);delete POINTER
#define TRACE_DEL_ARRAY(POINTER) \
	CTraceNew::Instance()->remove(POINTER);delete[] POINTER
#else
	#ifdef TRACE_NEW_STDOUT
#define TRACE_NEW(TYPENAME) new TYPENAME; cout << "new "#TYPENAME" size=" << sizeof(TYPENAME) << endl;
#define TRACE_NEW_ARGS(TYPENAME, ARGS...) new TYPENAME(ARGS); cout << "new "#TYPENAME" size=" << sizeof(TYPENAME) << endl;
#define TRACE_NEW_ARRAY(TYPENAME, ELEMENT_NUM) new TYPENAME[ELEMENT_NUM]; cout << "new "#TYPENAME"[" << ELEMENT_NUM << "] size=" << sizeof(TYPENAME) << endl;
#define TRACE_DEL(POINTER) delete POINTER; cout << "delete " << endl;
#define TRACE_DEL_ARRAY(POINTER) delete[] POINTER; cout << "delete array " << endl;
	#else
#define TRACE_NEW(TYPENAME) new TYPENAME
#define TRACE_NEW_ARGS(TYPENAME, ARGS...) new TYPENAME(ARGS)
#define TRACE_NEW_ARRAY(TYPENAME, ELEMENT_NUM) new TYPENAME[ELEMENT_NUM]
#define TRACE_DEL(POINTER) delete POINTER
#define TRACE_DEL_ARRAY(POINTER) delete[] POINTER
	#endif
#endif

//直接重载操作符
//DEBUG_OPERATOR，需要重新编译trace_new
#ifdef DEBUG_OPERATOR
	void * operator new(size_t size, const char *file, int line);
	void * operator new[](size_t size, const char *file, int line);
	void operator delete(void *p);
	void operator delete[](void *p);


	#define OP_TRACE_NEW new(__FILE__, __LINE__) 
	#define new OP_TRACE_NEW
#endif

	

#endif

