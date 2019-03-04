#ifndef __BINARY_UTIL_H__
#define __BINARY_UTIL_H__

#include <string>

class CBinaryUtil
{
	public:
		//将二进制的buffer输出成可断的16进制数字，delim默认以空格隔开
		//eg: FF E5 10 ...
		static std::string bin_hex(const void *pBin, int iSize, std::string delim=" ");

		//bin_hex的逆转，调用者处理buffer大小，isize输入buff大小，返回实际大小
		//考虑到有分隔符的情况，iByteLength 只在strHex中多少字节表示一个二进制字节，
		//16进制数必须是前两个字节，比如"FE EE"那么就是3，没有分隔"FEEE"就是2
		//return value 0=ok -1=输入不合法-2=buff太小
		static int hex_bin(std::string& strHex, void* pBin, int& iSize, unsigned int iByteLength=3);

		//单个16进制字符的值，-1=非16进制的字符
		static int char_val(char hex);

		//校验
		static unsigned short checksum(const void *pvBuff, int iSize);
};

class CDRTool
{
public:
	static inline long long htonll(long long llHost);
	static inline long long ntohll(long long llNet);
	//返回的都是读/写的长度
	static int ReadByte(const void *pvBuffer, unsigned char &ucVal);
	static int ReadByte(const void *pvBuffer, char &cVal);
	static int WriteByte(void *pvBuffer, unsigned char ucVal);
	static int WriteByte(void *pvBuffer, char cVal);

	static int ReadShort(const void *pvBuffer, unsigned short &ushVal, int iToHostOrder = 1);
	static int ReadShort(const void *pvBuffer, short &shVal, int iToHostOrder = 1);
	static int WriteShort(void *pvBuffer, unsigned short ushVal, int iToNetOrder = 1);
	static int WriteShort(void *pvBuffer, short shVal, int iToNetOrder = 1);

	static int ReadInt(const void *pvBuffer, unsigned int &uiVal, int iToHostOrder = 1);
	static int ReadInt(const void *pvBuffer, int &iVal, int iToHostOrder = 1);
	static int WriteInt(void *pvBuffer, unsigned int uiVal, int iToNetOrder = 1);
	static int WriteInt(void *pvBuffer, int iVal, int iToNetOrder = 1);

	static int ReadLong(const void *pvBuffer, unsigned long &ulVal, int iToHostOrder = 1);
	static int ReadLong(const void *pvBuffer, long &lVal, int iToHostOrder = 1);
	static int WriteLong(void *pvBuffer, unsigned long ulVal, int iToNetOrder = 1);
	static int WriteLong(void *pvBuffer, long lVal, int iToNetOrder = 1);

	static int ReadLongLong(const void *pvBuffer, unsigned long long &ullVal, int iToHostOrder = 0);
	static int ReadLongLong(const void *pvBuffer, long long &llVal, int iToHostOrder = 0);
	static int WriteLongLong(void *pvBuffer, unsigned long long ullVal, int iToNetOrder = 0);
	static int WriteLongLong(void *pvBuffer, long long llVal, int iToNetOrder = 0);

	static int ReadString(const void *pvBuffer, char *pszVal, int iStrLen);
	static int WriteString(void *pvBuffer, const char *pszVal, int iStrLen);

	static int ReadBuf(const void *pvBuffer, void *pszVal, int iStrLen);
	static int WriteBuf(void *pvBuffer, const void *pszVal, int iStrLen);
};

#endif

