#include <curl/curl.h>
#include <stdio.h>

//线程不安全
size_t CurlEsayWriteFunction(char* bufptr, size_t size, size_t nitems, void* userp);

class CCurlEasyWrap
{
	public:
		int GLibInited;
		CURLcode m_saveRetCode;
		CURL * m_handle;
		char m_errbuff[CURL_ERROR_SIZE];
		
	public:
		CCurlEasyWrap():m_saveRetCode(CURLE_OK),m_handle(NULL)
		{
			m_errbuff[0] = '\0';
			if(!GLibInited)
			{
				if((m_saveRetCode = curl_global_init(CURL_GLOBAL_DEFAULT))==CURLE_OK)
				{
					GLibInited = 1;
				}
			}
		}

		virtual ~CCurlEasyWrap()
		{
			if(GLibInited)
			{
				curl_global_cleanup();
				GLibInited = 0;
			}

			if(m_handle)
			{
				curl_easy_cleanup(m_handle);
				m_handle = NULL;
			}
		}

		int init()
		{
			if(m_saveRetCode != CURLE_OK)
			{
				return -1;
			}
		
			m_handle = curl_easy_init();
			if(m_handle == NULL)
			{
				return -1;
			}

			curl_easy_setopt(m_handle, CURLOPT_ERRORBUFFER, m_errbuff);

			return 0;
		}

		void debug()
		{
			curl_easy_setopt(m_handle, CURLOPT_VERBOSE, 1);
			curl_easy_setopt(m_handle, CURLOPT_HEADER, 1);
		}

		inline const char* errmsg()
		{
			return m_errbuff;
		}

		int setURL(const char* url)
		{
			if(curl_easy_setopt(m_handle, CURLOPT_URL, url)!=CURLE_OK)
			{
				return -1;
			}

			return 0;
		}

		int useWriteFunction()
		{
			if(curl_easy_setopt(m_handle, CURLOPT_WRITEFUNCTION, CurlEsayWriteFunction)!=CURLE_OK)
			{
				return -1;
			}

			if(curl_easy_setopt(m_handle, CURLOPT_WRITEDATA, this)!=CURLE_OK)
			{
				return -1;
			}

			return 0;
		}

		virtual int writeFunction(char* bufptr, size_t size, size_t nitems)
		{
			FILE* pf = fopen("tmp.txt", "ab+");
			if(!pf)
			{
				printf("fopen fail \n");
				return 0;
			}

			size_t retsize = fwrite(bufptr, size, nitems, pf);

			fclose(pf);
			
			return retsize;
		}

		void forbidReuse()
		{
			curl_easy_setopt(m_handle, CURLOPT_FORBID_REUSE, 1);
		}

		void maxConnects(long i)
		{
			curl_easy_setopt(m_handle, CURLOPT_MAXCONNECTS, i);
		}

		int perform()
		{
			if(curl_easy_perform(m_handle)!=CURLE_OK)
			{
				return -1;
			}

			return 0;
		}

};

size_t CurlEsayWriteFunction(char* bufptr, size_t size, size_t nitems, void* userp)
{
	CCurlEasyWrap* pobj = (CCurlEasyWrap*)userp;
	return pobj->writeFunction(bufptr, size, nitems);
}

