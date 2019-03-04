#ifndef _WEB_PAGE_H_
#define _WEB_PAGE_H_

#include <string>
#include <stdio.h>
#include "webdef.h"
using namespace std;

typedef struct _tpl_block_t
{
  	struct _tpl_block_t 		*suiv;	//	下一个块
  	struct _tpl_block_t 		*prec;	//	上一个块
  	char 						*data;	//	html数据块
  	char 						*name;	//	块名字
  	int 						ndata;	//	块长度
  	int 						type;	//	块类型
  	int 						alloc;	//	新节点
}tpl_block_t;

//	快速查询表
typedef struct _tpl_ptr_t
{
  	char 						*name;
  	tpl_block_t					*block;
}tpl_ptr_t;

typedef struct _quick_table_t
{
	tpl_ptr_t 				*pst;
	int 					nlength;
}quick_table_t;

typedef struct _buffer_t
{
	char		*pch;
	int 		length;
}buffer_t;

class webpage
{
public:
	webpage();

	~webpage();

	int load(string filename);
	int load(const char * pBuf, int length);
	
	void set(string token, string val);
	void set(string token, int val);
	void set(string token, unsigned int val);
	void set(string token, unsigned long long val);
	

	void set(string block);
	void set_bloc(string block);

	void output();
	void output(FILE *stream);
	int output(string filename);

	void release();

private:
	tpl_ptr_t * find(const char * elem, 
						const quick_table_t *base,
						int(* cmpfunc)(const void *, const void *), 
						int * nb);

	void gen_block(tpl_block_t *curr, tpl_block_t *suiv);
	void del_block(tpl_block_t *&pst);

	void parse();

private:
	
	buffer_t 			m_buf;			//	html buffer
	quick_table_t		m_vartable;		//	变量快速查询表
	quick_table_t		m_blocktable;	//	html块快速查询表
	tpl_block_t			*m_head;		//	指向数据块的双向链表指针
	FILE *			m_stream;
};

#endif
