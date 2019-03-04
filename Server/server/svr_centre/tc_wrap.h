#ifndef __TC_WRAP_H__
#define __TC_WRAP_H__
#include <tcutil.h> 
#include <tchdb.h> 
#include <stdlib.h> 
#include <stdbool.h> 
#include <stdint.h>
#include <stdio.h>
#include "log/log.h"

class CTCHDBWrap
{
	public:
		CTCHDBWrap()
		{
			m_tcdbhandle = NULL;
			m_inited = false;
		}

		~CTCHDBWrap()
		{
			release();
		}

		inline bool inited()
		{
			return m_inited;
		}

		TCHDB* open(int64_t bucketNum, const char* path, bool compress = false, int cachercdnum=0, bool format = false)
		{
			if(m_tcdbhandle)
				return m_tcdbhandle;

			TCHDB* newdb = tchdbnew();

			uint8_t opts = HDBTLARGE;
			if(compress)
				opts |=  HDBTDEFLATE;
			
			if(!tchdbtune(newdb, bucketNum, -1, -1, opts))
			{
				m_lasterrcode = tchdbecode(newdb);
				tchdbdel(newdb);
				return NULL;
			}

			if(!tchdbsetcache(newdb, cachercdnum))
			{
				m_lasterrcode = tchdbecode(newdb);
				tchdbdel(newdb);
				return NULL;
			}
			int mode = HDBOCREAT | HDBOWRITER;
			if( format )
			{
				mode |= HDBOTRUNC;
			}

			if(!tchdbopen(newdb, path, mode))
			{
				m_lasterrcode = tchdbecode(newdb);
				tchdbdel(newdb);
				return NULL;
			}

			m_tcdbhandle = newdb;
			m_inited = true;
			return m_tcdbhandle;
		}

		inline void log_last_error(const char* currentuser = NULL)
		{
			if(m_tcdbhandle)
				m_lasterrcode = tchdbecode(m_tcdbhandle);

			const char* errmsg = tchdberrmsg(m_lasterrcode);
			if(!currentuser)
				LOG(LOG_ERROR, "tchdb errcode=%d %s", m_lasterrcode, errmsg);
			else
				LOG(LOG_ERROR, "%s|tchdb errcode=%d %s", currentuser, m_lasterrcode, errmsg);
		}

		inline void print_last_error(const char* currentuser = NULL)
		{
			if(m_tcdbhandle)
				m_lasterrcode = tchdbecode(m_tcdbhandle);

			const char* errmsg = tchdberrmsg(m_lasterrcode);
			if(!currentuser)
				printf("tchdb errcode=%d %s\r\n", m_lasterrcode, errmsg);
			else
				printf("%s|tchdb errcode=%d %s\r\n", currentuser, m_lasterrcode, errmsg);
		}

		inline int error_code()
		{
			return m_lasterrcode;
		}

		inline TCHDB* gettc()
		{
			return m_tcdbhandle;
		}
		
	protected:
		inline void release()
		{
			if(m_tcdbhandle)
			{
				tchdbclose(m_tcdbhandle);
				tchdbdel(m_tcdbhandle);
				m_tcdbhandle = NULL;
			}
			m_inited = false;
		}
		
	protected:
		TCHDB* m_tcdbhandle;
		int m_lasterrcode;
		bool m_inited;
};

#endif


