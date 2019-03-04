#ifndef __MYSQL_WRAP_H__
#define __MYSQL_WRAP_H__

#include "stdlib.h"
#include "mysql.h"
#include <string>

class MysqlResult
{
	friend class MysqlDB;
	
public:

	MysqlResult();

	~MysqlResult();

	//��ѯ����
	int FieldNum();

	//ͨ��id��ѯ����Ϣ
	int FieldInfo(int idx, char* field_name, int name_len, enum_field_types* field_type);

	//ͨ��������idx
	int FieldIdx(const char* field_name);

	//��idx�еĳ���
	int FieldLength(int idx, unsigned long & length);

	//�����г��ȵ�����
	int FieldLengthArray(unsigned long * & lengthArray, int& num);

	//effect raw
	int RowNum();

	char** FetchNext();

	char** Fetch(unsigned long long offset);

	void Free();

	//insert && update
	int GetAffectRowNum();

	void SetAffectRowNum(int num);
protected:
	MYSQL_RES* m_pResult;
	char m_errMsg[256];
	int m_affectRows;
};
class MysqlDB
{
public:
	
	MysqlDB();

	~MysqlDB();

	//0=ok <0=error
	int Connect(const char* host, const char* user, const char* password, const char* dbname, int port=3306, bool keepalive = false, const char* sock=NULL);

	//0=ok <0=error (-2=key��ͻ)
	int Query(const char* sql, unsigned long sqlLen, MysqlResult* poRst=NULL,  int* affectRows=NULL);

	//0=ok <0=error
	void Escape(const char* data, unsigned long dataLen, char*& newBuff,  unsigned long& escapeLen);

	//0=ok <0=error
	void Close();

	inline bool IsConnected()
	{
		return m_connected;
	}

	const char* GetErr() ;

	//timeout ��λs, Ĭ����<0��ʾ������
	//������connect֮ǰ����
	inline void SetTimeOut(int timeout)
	{
		m_timeout = timeout;
	}

	inline void SetEncoding(const char *utf8)
	{
		m_encoding = utf8;
	}
	
protected:
	MYSQL m_sqlHandle;
	char m_errMsg[256];
	bool m_keepalive;
	bool m_connected;
	std::string m_encoding;
	int m_timeout;
};

#endif

