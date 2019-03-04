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
		// a-z A-Z 0-9 +_-/.* ����Ҫencode
		if(IsBasicChar(c))
		{
			oss << c;
		}
		else if(c <= 0x7F) //ascii�� encode �� %XX����ʽ
		{
			oss << '%' << XXOOHEX[c >> 4] << XXOOHEX[c & 0x0F];
		}
		else
		{
			if(use_unicode)
			{
				 //unicode ��ʽ�ı���˫�ֽ� encode �� %uXXXX����ʽ
				if(++i < input.length())
				{
					c2 = input[i];
					oss << "%u" << XXOOHEX[c >> 4] << XXOOHEX[c & 0x0F] << XXOOHEX[c2 >> 4] << XXOOHEX[c2 & 0x0F];
				}
				else
				{
					//�򵥽���������������
					break;
				}
			}
			else
			{
				//�����ֽڱ���
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
		//����a-z A-Z 0-9 +_-/.* ����Ҫdecode
		if(IsBasicChar(c))
		{
			oss << c;
		}
		else if(c == '%') //�������״̬
		{
			//�����ֽ������Ƿ���unicode��ʽ�ı���
			if(++i < input.length())
			{
				if(input[i] == 'u') //unicode %uXXXX
				{
					if(i+4 < input.length())
					{
						c1 = HexCharVal(input[++i]);//��һ��X
						c2 = HexCharVal(input[++i]);//�ڶ���X
						c3 = HexCharVal(input[++i]);//������X
						c4 = HexCharVal(input[++i]);//���ĸ�X
					}
					else
					{
						//��ʽ����
						break;
					}

					if(c1==0xFF || c2==0xFF || c3==0xFF || c4==0xFF)
					{
						//�����и�X����16�����ַ�
						break;
					}

					oss << (char)((c1<<4)+c2) << (char)((c3<<4)+c4);
					
				}
				else //ascii %XX
				{
					c1 = HexCharVal(input[i]); //��һ��X
					if(++i < input.length())
					{
						c2 = HexCharVal(input[i]);//�ڶ���X
					}
					else
					{
						//��ʽ����
						break;
					}
					
					if(c1==0xFF || c2==0xFF)
					{
						//�����и�X����16�����ַ�
						break;
					}

					oss << (char)((c1<<4)+c2);
				}
			}
			else
			{
				//��ʽ����
				break;
			}
		}//��ǰ�������
		else
		{
			//����������ǷǷ����ַ���
			break;
		}
	}
	return oss.str();
}


