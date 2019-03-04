////////////////////////////////////////////////////////////////////////////////
// @(#) strutil.h
// Utilities for std::string
// defined in namespace strutil
// by James Fancy
//
// ���޲��������ã�marszhang
////////////////////////////////////////////////////////////////////////////////

#ifndef __STRUTIL_H__
#define __STRUTIL_H__

#include <string>
#include <vector>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <cctype>
#include <stdarg.h>
#include <map>
#include <string.h>
#include "../coding/url/url_easy.h"
using namespace std;

// declaration
class strutil
{

public:
	class Tokenizer
	{
	protected:
		size_t m_Offset;
		const std::string m_String;
		std::string m_Token;
		std::string m_Delimiters;
	public:
		Tokenizer(const std::string& str)
			: m_Offset(0), m_String(str), m_Delimiters(" \r\n\t")
		{}

		Tokenizer(const std::string& str, const std::string& delimiters)
			: m_Offset(0), m_String(str), m_Delimiters(delimiters)
		{}

		bool nextToken()
		{
			return nextToken(m_Delimiters);
		}

		bool nextToken(const std::string& delimiters)
		{
			// find the start charater of the next token.
			size_t i = m_String.find_first_not_of(delimiters, m_Offset);
			if (i == string::npos)
			{
				m_Offset = m_String.length();
				return false;
			}

			// find the end of the token.
			size_t j = m_String.find_first_of(delimiters, i);
			if (j == string::npos)
			{
				m_Token = m_String.substr(i);
				m_Offset = m_String.length();
				return true;
			}

			// to intercept the token and save current position
			m_Token = m_String.substr(i, j - i);
			m_Offset = j;
			return true;
		}

		const std::string getToken() const
		{
			return m_Token;
		}

		/**
		* to reset the tokenizer. After reset it, the tokenizer can get
		* the tokens from the first token.
		*/
		void reset()
		{
			m_Offset = 0;
		}
	};

	static int parseQueryStr(string& querystr, map<string, string>& nvmap)
	{
		strutil::Tokenizer tokentop(querystr, "&");
		while(tokentop.nextToken())
		{
			string nvpair = tokentop.getToken();
			strutil::Tokenizer nvtoken(nvpair, "=");
			
			string name;
			string value;
			if(nvtoken.nextToken())
			{
				name = strutil::trim(CUrlEasyCoding::decode(nvtoken.getToken()));
			}
			else
			{
				return -1;
			}

			if(nvtoken.nextToken())
			{
				value = strutil::trim(CUrlEasyCoding::decode(nvtoken.getToken()));
			}
			else
			{
				return -1;
			}

			nvmap[name] = value;
		}

		return 0;
	}

	static std::string trimLeft(const std::string& str)
	{
		string t = str;
		string::iterator i;
		for (i = t.begin(); i != t.end(); i++)
		{
			if (!isspace(*i))
			{
				break;
			}
		}
		if (i == t.end())
		{
			t.clear();
		}
		else
		{
			t.erase(t.begin(), i);
		}
		return t;
	}

	static std::string trimRight(const std::string& str)
	{
		if (str.begin() == str.end())
		{
			return str;
		}

		string t = str;
		string::iterator i;
		for (i = t.end() - 1;;i--)
		{
			if (!isspace(*i))
			{
				t.erase(i + 1, t.end());
				break;
			}
			if (i == t.begin())
			{
				t.clear();
				break;
			}
		}
		return t;
	}

	static std::string trim(const std::string& str)
	{
		string t = str;

		string::iterator i;
		for (i = t.begin(); i != t.end(); i++)
		{
			if(!isspace(*i))
			{
				break;
			}
		}
		if (i == t.end())
		{
			t.clear();
			return t;
		}
		else
		{
			t.erase(t.begin(), i);
		}

		for (i = t.end() - 1;;i--)
		{
			if (!isspace(*i))
			{
				t.erase(i + 1, t.end());
				break;
			}
			if (i == t.begin())
			{
				t.clear();
				break;
			}
		}

		return t;
	}

	static std::string  toLower(const std::string& str)
	{
		string str__ = str;
		for(size_t i = 0; i < str__.length(); ++i)
		{
			str__[i] = tolower(str__[i]);
		}

		return str__;
	}

	static std::string toUpper(const std::string& str)
	{
		string str__ = str;
		for(size_t i = 0; i < str__.length(); ++i)
		{
			str__[i] = toupper(str__[i]);
		}

		return str__;
	}

	static std::string repeat(char c, int n)
	{
		ostringstream s;
		s << setw(n) << setfill(c) << "";
		return s.str();
	}

	static std::string repeat(const std::string& str, int n)
	{
		string s;
		for (int i = 0; i < n; i++)
		{
			s += str;
		}
		return s;
	}

	static bool startsWith(const std::string& str, const std::string& substr)
	{
		return str.find(substr) == 0;
	}

	static bool endsWith(const std::string& str, const std::string& substr)
	{
		size_t i = str.rfind(substr);return (i != string::npos) && (i == (str.length() - substr.length()));
	}

	static bool equalsIgnoreCase(const std::string& str1, const std::string& str2)
	{
		return toUpper(str1) == toUpper(str2);
	}



	static std::vector<std::string> split(const std::string& str, const std::string& delimiters = " \r\n\t")
	{
		vector<string> ss;

		Tokenizer tokenizer(str, delimiters);
		while (tokenizer.nextToken())
		{
			ss.push_back(tokenizer.getToken());
		}

		return ss;
	}

	//�����Ǽӵ�
	static std::string jion(const std::vector<std::string>& vec, const std::string& jioner = "|")
	{
		bool bfirst = true;
		std::ostringstream oss;
		for(unsigned int i=0; i<vec.size(); ++i)
		{
			if(bfirst)
			{
				bfirst=false;
			}
			else
			{
				oss << jioner;
			}
			oss << vec[i];
		}

		return oss.str();
	}

	//����Ǵ�c++��վ�ϳ���
	static std::string& replaceAll(std::string& context, const std::string& from, const std::string& to)
	{
		size_t lookHere = 0;
		size_t foundHere;
		while((foundHere = context.find(from, lookHere)) != std::string::npos)
		{
		      context.replace(foundHere, from.size(), to);
		      lookHere = foundHere + to.size();
		}
		return context;
	}

	//����snprint��������4k��С������ͼ����
	static std::string format(const char* pszFmt, ...)
	{
		va_list stApList;
		va_start(stApList, pszFmt);
		char sbuffer[4096];
		vsnprintf(sbuffer, sizeof(sbuffer), pszFmt, stApList);
		va_end(stApList);
		return string(sbuffer);
	}

	//��ֵ�Խ���a=b&c=d����ʽ�������к���=��&������ת��
	//return 0 ok,-1strkv����ȷ
	static int strToMap(std::map<std::string, std::string>& mapkv, const char* strkv)
	{
		const char* p = strkv;
		string key;
		string val;
		bool expact_key = true;
		const char* last = p;
		while(true)
		{
			if(*p == '=')
			{
				if(expact_key)
				{
					expact_key = false;
					key = string(last, p-last);
					last = p+1;
				}
				else
				{
					return -1;//�﷨����
				}
			}
			else if(*p == '&' || *p == 0)
			{
				if(!expact_key)
				{
					expact_key = true;
					val = string(last, p-last);
					if(*p)
						last = p+1;
					mapkv[key] = val;
					//cout << "map[" << key  << "]=" << val << endl;
				}
				else
				{
					return -1;//�﷨����
				}
			}
			else
			{
				//pass
			}
			
			if(*p)
				++p;
			else
				break;

		}

		return 0;
	}

	//������������������
	static std::string mapToStr(std::map<std::string, std::string>& mapkv)
	{
		ostringstream oss;
		bool bfirst = true;
		std::map<std::string, std::string>::iterator it;
		for(it = mapkv.begin(); it!=mapkv.end(); ++it)
		{
			if(bfirst)
				bfirst = false;
			else
				oss << "&";
			oss << it->first << "=" << it->second;
		}

		return oss.str();
	}

	//�����滻��ɨ��Դ������֤���б��������滻���������ڵı����滻Ϊ��
	static std::string replaceVariables(std::string& tmp, std::map<std::string, std::string>& mapVar, const char* varstart, const char* varend)
	{
		//һ������״̬start��end
		bool expect_start = true;
		ostringstream oss;
		std::string::size_type index = 0;
		std::string::size_type last = 0;
		unsigned int start_len = strlen(varstart);
		unsigned int end_len = strlen(varend);
		std::map<std::string, std::string>::iterator it;

		while(true)
		{
			if(expect_start)
			{
				index = tmp.find(varstart, last);
				if(index == string::npos)
				{
					//�Ҳ����˽���
					oss << tmp.substr(last);
					break;
				}
				else
				{
					//�ҵ���
					//���֮ǰ�Ĳ���
					oss << tmp.substr(last, index-last);
					//��end�Ľ׶�
					expect_start = false;
					//Ų�����
					last = index+start_len;
				}
			}
			else
			{
				index = tmp.find(varend, last);
				if(index == string::npos)
				{
					//�Ҳ����ˣ���ʽ���󣬷���֮�������
					break;
				}
				else
				{
					//���ұ���
					it =mapVar.find( tmp.substr(last, index-last));
					if(it != mapVar.end())
					{
						//�������
						oss << it->second;
					}
					//��start�Ľ׶�
					expect_start = true;
					//Ų�����
					last = index+end_len;
				}
			}
		}

		return oss.str();
	}

	static std::string toString(const bool& value)
	{
		ostringstream oss;
		oss << boolalpha << value;
		return oss.str();
	}

} ;

template<class T> T parseString(const std::string& str)
{
	T value;
	std::istringstream iss(str);
	iss >> value;
	return value;
}

template<class T> T parseHexString(const std::string& str)
{
	T value;
	std::istringstream iss(str);
	iss >> hex >> value;
	return value;
}

template<bool> bool parseString(const std::string& str)
{
	bool value;
	std::istringstream iss(str);
	iss >> boolalpha >> value;
	return value;
}

template<class T> std::string toString(const T& value)
{
	std::ostringstream oss;
	oss << value;
	return oss.str();
}


template<class T> std::string toHexString(const T& value, int width)
{
	std::ostringstream oss;
	oss << hex;
	if (width> 0)
	{
		oss << setw(width) << setfill('0');
	}
	oss << value;
	return oss.str();
}


#endif //__STRUTIL_H__

