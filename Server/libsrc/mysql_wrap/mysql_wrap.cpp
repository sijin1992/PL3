#include "mysql_wrap.h"
#include "stdio.h"
#include "string.h"
#include "mysqld_error.h"

	MysqlResult::MysqlResult()
	{
		m_pResult = NULL;
		m_errMsg[0] = '\0';
		m_affectRows = 0;
	}

	MysqlResult::~MysqlResult()
	{
		Free();
	}
	
	int MysqlResult::FieldNum()
	{
		if(m_pResult == NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "no result");
			return -1;
		}
		
		return mysql_num_fields(m_pResult);
	}

	int MysqlResult::FieldInfo(int idx, char* field_name, int name_len, enum_field_types* field_type)
	{
		if(m_pResult == NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "no result");
			return -1;
		}

		int iMax = mysql_num_fields(m_pResult);
		if(idx<0 || idx >= iMax)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "idx=%d not in [0,%d)", idx, iMax);
			return -1;
		}

		MYSQL_FIELD* p = mysql_fetch_field_direct(m_pResult, idx);

		snprintf(field_name, name_len, "%s", p->name);

		if( field_type != NULL )
			*field_type = p->type;
		
		return 0;
	}

	int MysqlResult::FieldIdx(const char* field_name)
	{
		if(m_pResult == NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "no result");
			return -1;
		}
		
		MYSQL_FIELD* aFields = mysql_fetch_fields(m_pResult); 

		for(unsigned int i=0; i<mysql_num_fields(m_pResult); ++i)
		{
			if(strcmp(field_name, aFields[i].name) == 0)
			{
				return i;
			}
		}

		snprintf(m_errMsg, sizeof(m_errMsg), "field(%s) not found", field_name);

		return -1;
	}

	int MysqlResult::FieldLength(int idx, unsigned long & length)
	{
		if(m_pResult == NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "no result");
			return -1;
		}
		
		int iMax = mysql_num_fields(m_pResult);
		if(idx<0 || idx >= iMax)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "idx=%d not in [0,%d)", idx, iMax);
			return -1;
		}
		
		unsigned long * array = mysql_fetch_lengths(m_pResult) ;

		length = array[idx];
		return 0;
	}
	int MysqlResult::FieldLengthArray(unsigned long * & lengthArray, int& num)
	{
		if(m_pResult == NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "no result");
			return -1;
		}

		num = mysql_num_fields(m_pResult);
		lengthArray = mysql_fetch_lengths(m_pResult);

		return 0;
	}

	int MysqlResult::RowNum()
	{
		if(m_pResult == NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "no result");
			return -1;
		}
		
		return mysql_num_rows(m_pResult);
	}

	char** MysqlResult::FetchNext()
	{
		if(m_pResult == NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "no result");
			return NULL;
		}

		MYSQL_ROW row = mysql_fetch_row(m_pResult);
		if(row == NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "mysql_fetch_row fail ");
			return NULL;
		}

		return row;
	}

	char** MysqlResult::Fetch(unsigned long long offset)
	{
		if(m_pResult == NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "no result");
			return NULL;
		}

		mysql_data_seek(m_pResult, offset);

		MYSQL_ROW row = mysql_fetch_row(m_pResult);
		if(row == NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "mysql_fetch_row fail ");
			return NULL;
		}

		return row;
	}


	void MysqlResult::Free()
	{
		if(m_pResult != NULL)
		{
			mysql_free_result(m_pResult);
			m_pResult = NULL;
		}
	}
	
	int MysqlResult::GetAffectRowNum()
	{
		return m_affectRows;
	}

	void MysqlResult::SetAffectRowNum(int num)
	{
		m_affectRows = num;
	}

	MysqlDB::MysqlDB()
	{
		memset((void*)&m_sqlHandle, 0x0, sizeof(m_sqlHandle));
		mysql_init(&m_sqlHandle);
		m_keepalive = false;
		m_errMsg[0] = '\0';
		m_connected = false;
		m_timeout = -1;
	}

	MysqlDB::~MysqlDB()
	{
		Close();
	}

	int MysqlDB::Connect(const char* host, const char* user, const char* password, const char* dbname, int port, bool keepalive, const char* sock)
	{
		if(m_connected)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "already connected");
			return -1;
		}

		if(m_timeout > 0)
		{
			unsigned int optval = m_timeout;
			if(mysql_options(&m_sqlHandle, MYSQL_OPT_CONNECT_TIMEOUT, (char *)&optval)!=0)
			{
				snprintf(m_errMsg, sizeof(m_errMsg), "mysql_options(MYSQL_OPT_CONNECT_TIMEOUT,%u) fail %s", optval, mysql_error(&m_sqlHandle));
				return -1;
			}
			if(mysql_options(&m_sqlHandle, MYSQL_OPT_READ_TIMEOUT, (char *)&optval)!=0)
			{
				snprintf(m_errMsg, sizeof(m_errMsg), "mysql_options(MYSQL_OPT_READ_TIMEOUT,%u) fail %s", optval, mysql_error(&m_sqlHandle));
				return -1;
			}
			if(mysql_options(&m_sqlHandle, MYSQL_OPT_WRITE_TIMEOUT, (char *)&optval)!=0)
			{
				snprintf(m_errMsg, sizeof(m_errMsg), "mysql_options(MYSQL_OPT_WRITE_TIMEOUT,%u) fail %s", optval, mysql_error(&m_sqlHandle));
				return -1;
			}
		}

		if( !m_encoding.empty() )
		{
			if(mysql_options(&m_sqlHandle, MYSQL_SET_CHARSET_NAME, m_encoding.c_str())!=0)
			{
				snprintf(m_errMsg, sizeof(m_errMsg), "mysql_options(MYSQL_SET_CHARSET_NAME,%s) fail %s", m_encoding.c_str(), mysql_error(&m_sqlHandle));
				return -1;
			}
		}

		m_keepalive = keepalive;
		if(keepalive)
		{
			my_bool reconnect = 1;
			if(mysql_options(&m_sqlHandle, MYSQL_OPT_RECONNECT, (char *)&reconnect)!=0)
			{
				snprintf(m_errMsg, sizeof(m_errMsg), "mysql_options(MYSQL_OPT_RECONNECT,%d) fail %s", reconnect, mysql_error(&m_sqlHandle));
				return -1;
			}
		}
	
		if(mysql_real_connect(&m_sqlHandle, host, user, password, dbname, port, sock, 0)==NULL)
		{
			snprintf(m_errMsg, sizeof(m_errMsg), "mysql_real_connect(%s,%s) fail %s", host, dbname, mysql_error(&m_sqlHandle));
			return -1;
		}

		m_connected = true;

		return 0;
	}

	
	void MysqlDB::Escape(const char* data, unsigned long dataLen, char*& newBuff, unsigned long& escapeLen)
	{
		//必须为“to”缓冲区分配至少length*2+1字节
		newBuff = new char[dataLen*2+1];
		escapeLen = mysql_real_escape_string(&m_sqlHandle, newBuff, data, dataLen);
	}

	int MysqlDB::Query(const char* sql, unsigned long sqlLen, MysqlResult* poRst, int* affectRows)
	{
		int iRet = 0;
		int iRet2 = 0;
		iRet = mysql_real_query(&m_sqlHandle, sql, sqlLen);
		if(iRet !=0 )
		{
			int mysqlErrno = mysql_errno(&m_sqlHandle);
			snprintf(m_errMsg, sizeof(m_errMsg), "mysql_query() fail return %d [%d][%s]", iRet, mysqlErrno, mysql_error(&m_sqlHandle));
			if(ER_DUP_ENTRY == mysqlErrno)
				return -2;
			else
			{
				//尝试ping一下，看能不能通
				if(m_keepalive)
				{
					iRet2 = mysql_ping(&m_sqlHandle);
					if(iRet2 != 0)
					{
						snprintf(m_errMsg, sizeof(m_errMsg), "mysql_ping() fail return %d [%s] iRet:%d", iRet2, mysql_error(&m_sqlHandle), iRet);
						Close();
						return -1;
					}
					//自动重连之后，重新设置编码
					iRet2 = mysql_real_query(&m_sqlHandle, sql, sqlLen);
					if(iRet2 != 0)
					{
						int mysqlErrno = mysql_errno(&m_sqlHandle);
						snprintf(m_errMsg, sizeof(m_errMsg), "2 mysql_query() fail return %d [%d][%s] iRet:%d", iRet2, mysqlErrno, mysql_error(&m_sqlHandle), iRet);
						if(ER_DUP_ENTRY == mysqlErrno)
							return -2;
						return -1;
					}
				}
				else
					return -1;
			}
		}

		if(affectRows)
		{
			*affectRows = mysql_affected_rows(&m_sqlHandle);
		}

		if(poRst)
		{
			MYSQL_RES* pResult = mysql_store_result(&m_sqlHandle);
			if(pResult == NULL)
			{
				snprintf(m_errMsg, sizeof(m_errMsg),"mysql_store_result fail %s", mysql_error(&m_sqlHandle));
				return -1;
			}

			poRst->m_pResult = pResult;
		}

		return 0;
	}


	void MysqlDB::Close()
	{
		mysql_close(&m_sqlHandle);
		m_connected = false;
	}

	const char* MysqlDB::GetErr() 
	{
		return m_errMsg;
	}
	
