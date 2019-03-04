#include <iconv.h>
#include <string.h>
#include "codeset.h"

bool CCodeSet::CheckValidNameGBK(const char *pszInStr, char *pszOutStr)
{
    //���е����֡��ǳ�ֻ���������ַ���
    // 1��ASCII����е����֣�0-9����ĸ��A-Z a-z�����»��ߣ�_��
    // 2��GBK����е��ַ���0xA1A1��/0xA1B2��/0xA1B3��/0xA3A8��/0xA3A9�����⣩

    if ((pszInStr == NULL)||(pszOutStr == NULL))
    {
        return false;
    }

    const unsigned char *pcNowChar = (const unsigned char *)pszInStr;
    const int MAX_CHECK_NAME_LEN = 1024;

    bool bRetVal = true;

    int iStrLen = 0;
    while(*pcNowChar != '\0')
    {
        if(*pcNowChar < 0x80)
        {
            if (((*pcNowChar >= '0')&&(*pcNowChar <= '9'))
                ||((*pcNowChar >= 'A')&&(*pcNowChar <= 'Z'))
                ||((*pcNowChar >= 'a')&&(*pcNowChar <= 'z'))
                ||(*pcNowChar == '_'))
            {
                //��Ч�ַ�
                pszOutStr[iStrLen] = *pcNowChar;
            }
            else
            {
                //��Ч���ֽ��ַ�
                pszOutStr[iStrLen] = '_';
                bRetVal = false;
            }
            pcNowChar++;
            iStrLen++;
        }
        else
        {
            const unsigned char *pcNextChar = pcNowChar+1;
            //printf("[%02X%02X]", *pcNowChar, *pcNextChar);
            if (((*pcNowChar >= 0xA1)&&(*pcNowChar <= 0xA9)&&(*pcNextChar >= 0xA1)&&(*pcNextChar <= 0xFE))      //GBK 1��
                ||((*pcNowChar >= 0xB0)&&(*pcNowChar <= 0xF7)&&(*pcNextChar >= 0xA1)&&(*pcNextChar <= 0xFE))    //GBK 2��
                ||((*pcNowChar >= 0x81)&&(*pcNowChar <= 0xA0)&&(*pcNextChar >= 0x40)&&(*pcNextChar <= 0xFE))    //GBK 3��
                ||((*pcNowChar >= 0xAA)&&(*pcNowChar <= 0xFE)&&(*pcNextChar >= 0x40)&&(*pcNextChar <= 0xA0))    //GBK 4��
                ||((*pcNowChar >= 0xA8)&&(*pcNowChar <= 0xA9)&&(*pcNextChar >= 0x40)&&(*pcNextChar <= 0xA0)))   //GBK 5��
            {
                //GBK�ַ�
                if (((*pcNowChar == 0xA1)&&(*pcNextChar == 0xA1))   //
                    ||((*pcNowChar == 0xA1)&&(*pcNextChar == 0xB2)) //��
                    ||((*pcNowChar == 0xA1)&&(*pcNextChar == 0xB3)) //��
                    ||((*pcNowChar == 0xA3)&&(*pcNextChar == 0xA8)) //��
                    ||((*pcNowChar == 0xA3)&&(*pcNextChar == 0xA9)) //��
                    ||((*pcNowChar == 0xA9)&&(*pcNextChar == 0x76)) //�v
                    ||((*pcNowChar == 0xA9)&&(*pcNextChar == 0x77)) //�w
                    ||((*pcNowChar == 0xA9)&&(*pcNextChar == 0x7A)) //�z
                    ||((*pcNowChar == 0xA9)&&(*pcNextChar == 0x7B)) //�{
                    //||((*pcNowChar == 0xA8)&&(*pcNextChar >= 0xA1)&&(*pcNextChar <= 0xC0))  //��������ƴ��������һ����ֿ�ֻ����һ���ֽڿ�ȣ�����ռ�������ֽڵĴ洢�ռ䣬���Իᵼ����ʾ����
                    ||((*pcNowChar >= 0x81)&&(*pcNowChar <= 0xA0)&&(*pcNextChar == 0x7F))   //GBK 3�� 7F��
                    ||((*pcNowChar >= 0xAA)&&(*pcNowChar <= 0xFE)&&(*pcNextChar == 0x7F))   //GBK 4�� 7F��
                    ||((*pcNowChar >= 0xA8)&&(*pcNowChar <= 0xA9)&&(*pcNextChar == 0x7F)))  //GBK 5�� 7F��
                    //||((*pcNowChar >= 0xA8)&&(*pcNowChar <= 0xA9)&&(*pcNextChar >= 0x40)&&(*pcNextChar <= 0xA0)))   //�û��Զ�����
                {
                    pszOutStr[iStrLen] = 0xA1;
                    pszOutStr[iStrLen+1] = 0xF5;    //�Ƿ������滻Ϊ��
                    bRetVal = false;
                }
                else
                {
                    pszOutStr[iStrLen] = *pcNowChar;
                    pszOutStr[iStrLen+1] = *pcNextChar;
                }

                pcNowChar+=2;
                iStrLen+=2;
            }
            else
            {
                //���Ϸ����ֽ�
                pszOutStr[iStrLen] = '_';
                bRetVal = false;
                pcNowChar++;
                iStrLen++;
            }
        }

        if (iStrLen >= MAX_CHECK_NAME_LEN)
        {
            bRetVal = false;
            break;
        }
    }

    pszOutStr[iStrLen] = '\0';

    return bRetVal;
}

int CCodeSet::CodeConvert(const char* from_charset,const char* to_charset, const char* inbuf, size_t inlen, char* outbuf, size_t& outbyteslef)
{
    char** pin = const_cast<char**>(&inbuf);
    char** pout = &outbuf;
    iconv_t cd = iconv_open(to_charset, from_charset);
    if (cd == 0)
        return -1;
    memset(outbuf, 0, outbyteslef);
    int ret = 0;
    while (true)
    {
        //printf("before, ret=%d, pin=%x, in=%s, inlen=%d, pout=%x, outlen=%d\n", ret, *pin, Str2Hex(*pin, inlen), inlen, *pout, outbyteslef);
        ret = iconv(cd, pin, &inlen, pout, &outbyteslef);
        //printf("after, ret=%d, pin=%x, inlen=%d, pout=%x, outlen=%d, out=%s\n", ret, *pin, inlen, *pout, outbyteslef, outbuf);
        if (ret==0 || inlen == 0 || outbyteslef == 0)
        {
            break;
        }
        else
        {
            (*pin)++;
            inlen--;
            (*pout)[0]=' ';//���ת��ʧ�ܣ�ʹ�ÿո����
            (*pout)++;
            outbyteslef--;
        }
    }
    iconv_close(cd);
    return 0;

}


int CCodeSet::utf8_gbk(const char* inbuf,size_t inlen, char* outbuf, size_t& outlen)
{
    return CodeConvert("utf-8","gbk",inbuf,inlen,outbuf,outlen);
}
int CCodeSet::gbk_utf8(const char* inbuf,size_t inlen, char* outbuf, size_t& outlen)
{
    return CodeConvert("gbk","utf-8",inbuf,inlen,outbuf,outlen);
}


