#include <iconv.h>
#include <string.h>
#include "codeset.h"

bool CCodeSet::CheckValidNameGBK(const char *pszInStr, char *pszOutStr)
{
    //所有的名字、昵称只允许如下字符：
    // 1）ASCII码表中的数字（0-9）字母（A-Z a-z）和下划线（_）
    // 2）GBK码表中的字符（0xA1A1　/0xA1B2〔/0xA1B3〕/0xA3A8（/0xA3A9）除外）

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
                //有效字符
                pszOutStr[iStrLen] = *pcNowChar;
            }
            else
            {
                //无效单字节字符
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
            if (((*pcNowChar >= 0xA1)&&(*pcNowChar <= 0xA9)&&(*pcNextChar >= 0xA1)&&(*pcNextChar <= 0xFE))      //GBK 1区
                ||((*pcNowChar >= 0xB0)&&(*pcNowChar <= 0xF7)&&(*pcNextChar >= 0xA1)&&(*pcNextChar <= 0xFE))    //GBK 2区
                ||((*pcNowChar >= 0x81)&&(*pcNowChar <= 0xA0)&&(*pcNextChar >= 0x40)&&(*pcNextChar <= 0xFE))    //GBK 3区
                ||((*pcNowChar >= 0xAA)&&(*pcNowChar <= 0xFE)&&(*pcNextChar >= 0x40)&&(*pcNextChar <= 0xA0))    //GBK 4区
                ||((*pcNowChar >= 0xA8)&&(*pcNowChar <= 0xA9)&&(*pcNextChar >= 0x40)&&(*pcNextChar <= 0xA0)))   //GBK 5区
            {
                //GBK字符
                if (((*pcNowChar == 0xA1)&&(*pcNextChar == 0xA1))   //
                    ||((*pcNowChar == 0xA1)&&(*pcNextChar == 0xB2)) //〔
                    ||((*pcNowChar == 0xA1)&&(*pcNextChar == 0xB3)) //〕
                    ||((*pcNowChar == 0xA3)&&(*pcNextChar == 0xA8)) //（
                    ||((*pcNowChar == 0xA3)&&(*pcNextChar == 0xA9)) //）
                    ||((*pcNowChar == 0xA9)&&(*pcNextChar == 0x76)) //﹙
                    ||((*pcNowChar == 0xA9)&&(*pcNextChar == 0x77)) //﹚
                    ||((*pcNowChar == 0xA9)&&(*pcNextChar == 0x7A)) //﹝
                    ||((*pcNowChar == 0xA9)&&(*pcNextChar == 0x7B)) //﹞
                    //||((*pcNowChar == 0xA8)&&(*pcNextChar >= 0xA1)&&(*pcNextChar <= 0xC0))  //带音调的拼音，由于一般的字库只绘制一个字节宽度，但是占用两个字节的存储空间，所以会导致显示问题
                    ||((*pcNowChar >= 0x81)&&(*pcNowChar <= 0xA0)&&(*pcNextChar == 0x7F))   //GBK 3区 7F列
                    ||((*pcNowChar >= 0xAA)&&(*pcNowChar <= 0xFE)&&(*pcNextChar == 0x7F))   //GBK 4区 7F列
                    ||((*pcNowChar >= 0xA8)&&(*pcNowChar <= 0xA9)&&(*pcNextChar == 0x7F)))  //GBK 5区 7F列
                    //||((*pcNowChar >= 0xA8)&&(*pcNowChar <= 0xA9)&&(*pcNextChar >= 0x40)&&(*pcNextChar <= 0xA0)))   //用户自定义区
                {
                    pszOutStr[iStrLen] = 0xA1;
                    pszOutStr[iStrLen+1] = 0xF5;    //非法中文替换为□
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
                //不合法单字节
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
            (*pout)[0]=' ';//如果转换失败，使用空格填充
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


