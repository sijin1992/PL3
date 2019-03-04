#include "html_coding.h"

string CHtmlCoding::simpleHtmlEncode(string src)
{
	ostringstream oss;

	char c;
	unsigned int len = src.length();
	for(unsigned int i=0; i < len; ++i)
	{
		c = src[i];
		if (c == '<')
		{
			oss << "&lt;";
		}
		else if (c == '>')
		{
		      oss << "&gt;";
		}
		else if (c == '&')
		{
			oss << "&amp;";
		}
		else if (c == '\"')
		{
			oss << "&quot;";
		}
		else if(c == '\'')
		{
			oss << "&#39;";
		}
		else if (c == ' ')
		{
			oss << "&nbsp;";
		}
		else
		{
			oss << c;
		}

	}

	return oss.str();
}

