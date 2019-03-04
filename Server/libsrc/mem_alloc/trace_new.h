/*
 * @file     trace_new.h
 * @brief    webgame��ܵĶ�new delete�ĸ���
 * @author   marszhang@tencent.com
 * @date     2010-11-15
 *
 * @note    	��ǰд�����ƵĶ������Ҳ����ˣ����簡
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


//�ⲿ��Ҫͳһʹ�ú�������new/delete��DEBUG�����Ƿ��¼��Ϣ
//ȱ���Ǳ��뵥��һ�У�����Ƕ�뵽()��
//trace_new������Ҫ���±���
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

//ֱ�����ز�����
//DEBUG_OPERATOR����Ҫ���±���trace_new
#ifdef DEBUG_OPERATOR
	void * operator new(size_t size, const char *file, int line);
	void * operator new[](size_t size, const char *file, int line);
	void operator delete(void *p);
	void operator delete[](void *p);


	#define OP_TRACE_NEW new(__FILE__, __LINE__) 
	#define new OP_TRACE_NEW
#endif

	

#endif

