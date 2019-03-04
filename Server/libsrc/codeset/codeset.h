#ifndef __CODESET_H__
#define __CODESET_H__

//�Ϸ�GBK���֣����buffer�����߸㶨
#include <stdlib.h>
class CCodeSet
{
public:
	static bool CheckValidNameGBK(const char *pszInStr, char *pszOutStr);

	//iconv�İ�װ
	static int CodeConvert(const char* from_charset,const char* to_charset, const char* inbuf, size_t inlen, char* outbuf, size_t& outbyteslef);

	//ʹ��CodeConvert
	static int utf8_gbk(const char* inbuf,size_t inlen, char* outbuf, size_t& outlen);

	//ʹ��CodeConvert
	static int gbk_utf8(const char* inbuf,size_t inlen, char* outbuf, size_t& outlen);
};

#endif

