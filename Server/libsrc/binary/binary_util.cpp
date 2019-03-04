#include "binary_util.h"
#include <string.h>
#include <arpa/inet.h>
#include <stdio.h>
//#include <iostream>
std::string CBinaryUtil::bin_hex(const void *pBin, int iSize, std::string delim)
{
	const int CHAR_NUM_PER_BYTE = 2+delim.length(); //"%02X "
	int bufflen = iSize*CHAR_NUM_PER_BYTE;
	char* buff = new char[bufflen];
	int offset = 0;
	const char* delimp = delim.c_str();
	
	for (int i=0; i<iSize; i++)
	{
	 	offset += snprintf(buff+offset, bufflen-offset, "%02X%s", ((unsigned char*)pBin)[i], delimp);
	}

	std::string ret(buff, bufflen);
	delete[] buff;
	return ret;
}

int CBinaryUtil::hex_bin(std::string& strHex, void* pBin, int& iSize, unsigned int iByteLength)
{
	int idx = 0;
	int byte1 =0;
	int byte2 = 0;
	unsigned int length = strHex.length();
	unsigned int i = 0;
	unsigned char* pBinChar = (unsigned char* )pBin;
	
	for(; i<length/iByteLength; ++i){
		byte1 = char_val(strHex[i*iByteLength]);
		byte2 = char_val(strHex[i*iByteLength+1]);
		if(byte1 == -1 || byte2 == -1)
			return -1;

		if(idx <= iSize)
		{
			pBinChar[idx++] = (byte1 << 4) + byte2;
		}
		else
			return -2;
	}

	//最后可能没有分隔符结束，兼容下
	int left = length%iByteLength;
	if(left >=2)
	{
		byte1 = char_val(strHex[i*iByteLength]);
		byte2 = char_val(strHex[i*iByteLength+1]);

		if(byte1 == -1 || byte2 == -1)
			return -1;

		if(idx <= iSize)
			pBinChar[idx++] = (byte1 << 4) + byte2;
		else
			return -2;
	}

	iSize = idx;

	return 0;
}


int CBinaryUtil::char_val(char c)
{
	if(c >= '0' && c <= '9')
	{
		return c-'0';
	}
	else if(c >= 'a' && c <= 'f')
	{
		return c-'a'+10;
	}
	else if(c >= 'A' && c <= 'F')
	{
		return c-'A'+10;
	}
	else
	{
		return -1;
	}
}

unsigned short CBinaryUtil::checksum(const void *pvBuff, int iSize)
{
	unsigned short ushSum = 0;
	const unsigned char *pszBuff = (unsigned char *)pvBuff;

	for (int i = 0; i < iSize/2; ++i)
	{
	    ushSum ^= *(short *)((char *)pszBuff + i * 2);
	}

	return ushSum;
}

long long CDRTool::htonll(long long llHost)
{
    long long llNet = (long long)ntohl((int)llHost) << 32;
    llNet += ntohl((int)(llHost >> 32));

    return llNet;
}

long long CDRTool::ntohll(long long llNet)
{
    long long llHost = (long long)ntohl((int)llNet) << 32;
    llHost += ntohl((int)(llNet >> 32));

    return llHost;
}

int CDRTool::ReadByte(const void* pvBuffer, unsigned char &ucVal)
{
    memcpy(&ucVal, pvBuffer, sizeof(unsigned char));
    return sizeof(unsigned char);
}

int CDRTool::ReadByte(const void* pvBuffer, char &cVal)
{
    memcpy(&cVal, pvBuffer, sizeof(char));
    return sizeof(char);
}

int CDRTool::WriteByte(void* pvBuffer, unsigned char ucVal)
{
    memcpy(pvBuffer, &ucVal, sizeof(unsigned char));
    return sizeof(unsigned char);
}

int CDRTool::WriteByte(void* pvBuffer, char cVal)
{
    memcpy(pvBuffer, &cVal, sizeof(char));
    return sizeof(char);
}


int CDRTool::ReadShort(const void* pvBuffer, unsigned short &ushVal, int iToHostOrder/* = 1*/)
{
    memcpy(&ushVal, pvBuffer, sizeof(unsigned short));
    if (iToHostOrder == 1)
    {
        ushVal = ntohs(ushVal);
    }
    return sizeof(unsigned short);
}

int CDRTool::ReadShort(const void* pvBuffer, short &shVal, int iToHostOrder/* = 1*/)
{
    memcpy(&shVal, pvBuffer, sizeof(short));
    if (iToHostOrder == 1)
    {
        shVal = ntohs(shVal);
    }
    return sizeof(short);
}

int CDRTool::WriteShort(void* pvBuffer, unsigned short ushVal, int iToNetOrder/* = 1*/)
{
    if (iToNetOrder == 1)
    {
        ushVal = htons(ushVal);
    }
    memcpy(pvBuffer, &ushVal, sizeof(unsigned short));
    return sizeof(unsigned short);
}

int CDRTool::WriteShort(void* pvBuffer, short shVal, int iToNetOrder/* = 1*/)
{
    if (iToNetOrder == 1)
    {
        shVal = htons(shVal);
    }
    memcpy(pvBuffer, &shVal, sizeof(short));
    return sizeof(short);
}


int CDRTool::ReadInt(const void* pvBuffer, unsigned int &uiVal, int iToHostOrder/* = 1*/)
{
    memcpy(&uiVal, pvBuffer, sizeof(unsigned int));
    if (iToHostOrder == 1)
    {
        uiVal = ntohl(uiVal);
    }
    return sizeof(unsigned int);
}

int CDRTool::ReadInt(const void* pvBuffer, int &iVal, int iToHostOrder/* = 1*/)
{
    memcpy(&iVal, pvBuffer, sizeof(int));
    if (iToHostOrder == 1)
    {
        iVal = ntohl(iVal);
    }
    return sizeof(int);
}

int CDRTool::WriteInt(void* pvBuffer, unsigned int uiVal, int iToNetOrder/* = 1*/)
{
    if (iToNetOrder == 1)
    {
        uiVal = htonl(uiVal);
    }
    memcpy(pvBuffer, &uiVal, sizeof(unsigned int));
    return sizeof(unsigned int);
}

int CDRTool::WriteInt(void* pvBuffer, int iVal, int iToNetOrder/* = 1*/)
{
    if (iToNetOrder == 1)
    {
        iVal = htonl(iVal);
    }
    memcpy(pvBuffer, &iVal, sizeof(int));
    return sizeof(int);
}


int CDRTool::ReadLong(const void* pvBuffer, unsigned long &ulVal, int iToHostOrder/* = 1*/)
{
    memcpy(&ulVal, pvBuffer, sizeof(unsigned long));
    if (iToHostOrder == 1)
    {
        ulVal = ntohl(ulVal);
    }
    return sizeof(unsigned long);
}

int CDRTool::ReadLong(const void* pvBuffer, long &lVal, int iToHostOrder/* = 1*/)
{
    memcpy(&lVal, pvBuffer, sizeof(long));
    if (iToHostOrder == 1)
    {
        lVal = ntohl(lVal);
    }
    return sizeof(long);
}

int CDRTool::WriteLong(void* pvBuffer, unsigned long ulVal, int iToNetOrder/* = 1 */)
{
    if (iToNetOrder == 1)
    {
        ulVal = htonl(ulVal);
    }
    memcpy(pvBuffer, &ulVal, sizeof(unsigned long));
    return sizeof(unsigned long);
}

int CDRTool::WriteLong(void* pvBuffer, long lVal, int iToNetOrder/* = 1 */)
{
    if (iToNetOrder == 1)
    {
        lVal = htonl(lVal);
    }
    memcpy(pvBuffer, &lVal, sizeof(long));
    return sizeof(long);
}


int CDRTool::ReadLongLong(const void* pvBuffer, unsigned long long &ullVal, int iToHostOrder/* = 0*/)
{
    memcpy(&ullVal, pvBuffer, sizeof(unsigned long long));
    if (iToHostOrder == 1)
    {
        ullVal = ntohll(ullVal);
    }
    return sizeof(unsigned long long);
}

int CDRTool::ReadLongLong(const void* pvBuffer, long long &llVal, int iToHostOrder/* = 0*/)
{
    memcpy(&llVal, pvBuffer, sizeof(long long));
    if (iToHostOrder == 1)
    {
        llVal = ntohll(llVal);
    }
    return sizeof(long long);
}

int CDRTool::WriteLongLong(void* pvBuffer, unsigned long long ullVal, int iToNetOrder/* = 0*/)
{
    if (iToNetOrder == 1)
    {
        ullVal = htonll(ullVal);
    }
    memcpy(pvBuffer, &ullVal, sizeof(unsigned long long));
    return sizeof(unsigned long long);
}

int CDRTool::WriteLongLong(void* pvBuffer, long long llVal, int iToNetOrder/* = 0*/)
{
    if (iToNetOrder == 1)
    {
        llVal = htonll(llVal);
    }
    memcpy(pvBuffer, &llVal, sizeof(long long));
    return sizeof(long long);
}


int CDRTool::ReadString(const void* pvBuffer, char *pszVal, int iStrLen)
{
    memcpy(pszVal, pvBuffer, iStrLen);
    return iStrLen;
}

int CDRTool::WriteString(void* pvBuffer, const char *pszVal, int iStrLen)
{
    memcpy(pvBuffer, pszVal, iStrLen);
    return iStrLen;
}

int CDRTool::ReadBuf(const void* pSrc, void *pDest, int iLen)
{
    memcpy(pDest, pSrc, iLen);
    return iLen;
}

int CDRTool::WriteBuf(void* pDest, const void *pSrc, int iLen)
{
    memcpy(pDest, pSrc, iLen);
    return iLen;
}


