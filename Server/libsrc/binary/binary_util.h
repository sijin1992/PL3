#ifndef __BINARY_UTIL_H__
#define __BINARY_UTIL_H__

#include <string>

class CBinaryUtil
{
	public:
		//�������Ƶ�buffer����ɿɶϵ�16�������֣�delimĬ���Կո����
		//eg: FF E5 10 ...
		static std::string bin_hex(const void *pBin, int iSize, std::string delim=" ");

		//bin_hex����ת�������ߴ���buffer��С��isize����buff��С������ʵ�ʴ�С
		//���ǵ��зָ����������iByteLength ֻ��strHex�ж����ֽڱ�ʾһ���������ֽڣ�
		//16������������ǰ�����ֽڣ�����"FE EE"��ô����3��û�зָ�"FEEE"����2
		//return value 0=ok -1=���벻�Ϸ�-2=buff̫С
		static int hex_bin(std::string& strHex, void* pBin, int& iSize, unsigned int iByteLength=3);

		//����16�����ַ���ֵ��-1=��16���Ƶ��ַ�
		static int char_val(char hex);

		//У��
		static unsigned short checksum(const void *pvBuff, int iSize);
};

class CDRTool
{
public:
	static inline long long htonll(long long llHost);
	static inline long long ntohll(long long llNet);
	//���صĶ��Ƕ�/д�ĳ���
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

