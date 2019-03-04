#include <string>
#include "../../binary/binary_util.h"
using namespace std;

class CUrlEasyCoding
{
public:
	static string decode(const string& strSrc)
	{
		string strDest;
		int iSrcLength = strSrc.length();
		if (iSrcLength <= 0) return "";

		char ch;
		char ch1;
		char ch2;
		for (int i = 0; i < iSrcLength; i++)
		{
			switch (strSrc[i]) 
			{
				case '%':
					ch1 = CBinaryUtil::char_val(strSrc[i+1]);
					ch2 = CBinaryUtil::char_val(strSrc[i+2]);
					if(ch1 >=0 && ch2 >= 0)
					{	
						ch = (ch1 << 4) + ch2;
						i = i + 2;					
					}
					else 
						ch = strSrc[i];

					strDest += ch;
					break;
				case '+':
					ch = ' ';
					strDest += ch;
					break;
				default: 
					strDest += strSrc[i];
					break;
			}
		}

		return strDest;
	}

	static string encode(const string& strSrc)
	{
		string strDest;
		int iSrcLength = strSrc.length();
		if (iSrcLength <= 0) return "";

		static char chs[]= {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e'};
		for (int i = 0; i < iSrcLength; i++)
		{
			char c = strSrc[i];
			if((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') )
			{
				strDest += c;
			}
			else if(c == ' ')
			{
				strDest += '+';
			}
			else
			{
				strDest += "%";
				strDest += chs[c >> 4];
				strDest += chs[c & 0x0F];
			}
		}
	}
};

