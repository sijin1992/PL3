#ifndef __WRITER_PROXY_H__
#define __WRITER_PROXY_H__

class CWriterProxy
{
public:
	virtual ~CWriterProxy(){}
	//д���ݣ��ɹ�����д����ֽ�����������<0
	virtual int writeData(const char *data, unsigned int size, int level) = 0;
};

#endif
