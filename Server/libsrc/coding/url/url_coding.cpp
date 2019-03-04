#include "url_coding.h"
#include <sstream>
#include <iostream>

static char XXOOHEX[] = {"0123456789ABCDEF"};

#define IsBasicChar(c) ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') )

char CUrlCoding::HexCharVal(char c)
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
		return 0xFF;
	}
}

string CUrlCoding::escape(string const& input, bool use_unicode)
{
	std::ostringstream oss;
	unsigned char c,c2;
	for(unsigned int i=0; i < input.length(); ++i)
	{
		c = input[i];
		// a-z A-Z 0-9 +_-/.* 不需要encode
		if(IsBasicChar(c))
		{
			oss << c;
		}
		else if(c <= 0x7F) //ascii码 encode 成 %XX的形式
		{
			oss << '%' << XXOOHEX[c >> 4] << XXOOHEX[c & 0x0F];
		}
		else
		{
			if(use_unicode)
			{
				 //unicode 形式的编码双字节 encode 成 %uXXXX的形式
				if(++i < input.length())
				{
					c2 = input[i];
					oss << "%u" << XXOOHEX[c >> 4] << XXOOHEX[c & 0x0F] << XXOOHEX[c2 >> 4] << XXOOHEX[c2 & 0x0F];
				}
				else
				{
					//简单结束不做出错处理了
					break;
				}
			}
			else
			{
				//做单字节编码
				oss << '%' << XXOOHEX[c >> 4] << XXOOHEX[c & 0x0F];
			}
		}
	}
	return oss.str();
}

string CUrlCoding::unescape(string const& input)
{
	std::ostringstream oss;
	unsigned char c,c1,c2,c3,c4;
	for(unsigned int i=0; i < input.length(); ++i)
	{
		c = input[i];
		//明文a-z A-Z 0-9 +_-/.* 不需要decode
		if(IsBasicChar(c))
		{
			oss << c;
		}
		else if(c == '%') //进入解码状态
		{
			//读下字节区分是否是unicode形式的编码
			if(++i < input.length())
			{
				if(input[i] == 'u') //unicode %uXXXX
				{
					if(i+4 < input.length())
					{
						c1 = HexCharVal(input[++i]);//第一个X
						c2 = HexCharVal(input[++i]);//第二个X
						c3 = HexCharVal(input[++i]);//第三个X
						c4 = HexCharVal(input[++i]);//第四个X
					}
					else
					{
						//格式错了
						break;
					}

					if(c1==0xFF || c2==0xFF || c3==0xFF || c4==0xFF)
					{
						//至少有个X不是16进制字符
						break;
					}

					oss << (char)((c1<<4)+c2) << (char)((c3<<4)+c4);
					
				}
				else //ascii %XX
				{
					c1 = HexCharVal(input[i]); //第一个X
					if(++i < input.length())
					{
						c2 = HexCharVal(input[i]);//第二个X
					}
					else
					{
						//格式错了
						break;
					}
					
					if(c1==0xFF || c2==0xFF)
					{
						//至少有个X不是16进制字符
						break;
					}

					oss << (char)((c1<<4)+c2);
				}
			}
			else
			{
				//格式错了
				break;
			}
		}//当前解码结束
		else
		{
			//其他情况都是非法的字符串
			break;
		}
	}
	return oss.str();
}


