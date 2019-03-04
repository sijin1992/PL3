#ifndef __CODESET_H__
#define __CODESET_H__

//合法GBK名字，输出buffer调用者搞定
#include <stdlib.h>
class CCodeSet
{
public:
	static bool CheckValidNameGBK(const char *pszInStr, char *pszOutStr);

	//iconv的包装
	static int CodeConvert(const char* from_charset,const char* to_charset, const char* inbuf, size_t inlen, char* outbuf, size_t& outbyteslef);

	//使用CodeConvert
	static int utf8_gbk(const char* inbuf,size_t inlen, char* outbuf, size_t& outlen);

	//使用CodeConvert
	static int gbk_utf8(const char* inbuf,size_t inlen, char* outbuf, size_t& outlen);
};

#endif

