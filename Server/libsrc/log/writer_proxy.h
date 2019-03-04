#ifndef __WRITER_PROXY_H__
#define __WRITER_PROXY_H__

class CWriterProxy
{
public:
	virtual ~CWriterProxy(){}
	//写数据，成功返回写入的字节数，出错返回<0
	virtual int writeData(const char *data, unsigned int size, int level) = 0;
};

#endif
