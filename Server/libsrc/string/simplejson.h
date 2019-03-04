#include <string>
#include <string.h>
#include <map>
#include <iostream>

using namespace std;

#define NO_QUOTATION 0
#define IN_DOUBLE_QUOTATION 1
#define IN_QUOTATION 2
#define EXPECT_KEY 0
#define PARSE_KEY 1
#define EXPECT_VAL 2
#define PARSE_VAL 3

//��ʵ�ֶ��������Ԫ��
typedef map<string, string> NameValMap;
class CSimpleJSON
{
	public:
		int parse(const string& strjson)
		{
			m_wordlen = 0;
			bool started = false;
			int quotaState = NO_QUOTATION;
			int parseState = EXPECT_KEY;
			char ch;
			int total = strjson.length();
			for(int i=0; i<total; ++i)
			{
				ch = strjson[i];
				if(!started)
				{
					if(ch != '{')
					{
						continue;
					}

					started = true;
				}
				
				if(quotaState != NO_QUOTATION)
				{
					//����״̬�µĲ���
					if(ch == '\\')
					{
						//escape ֱ��copy��ǰ�˲�����
						if(!push_char(ch))
							return -1;
						if(!move_idx(i, total))
							return -1;
						if(!push_char(strjson[i]))
							return -1;
					}
					else if(ch == '"')
					{
						if(quotaState == IN_DOUBLE_QUOTATION)
						{
							quotaState = NO_QUOTATION;
							if(!end_word(parseState))
								return -1;
						}
						//�������е�˫����ֱ��copy
						else
						{
							if(!push_char(ch))
								return -1;
						}
					}
					else if(ch == '\'')
					{
						if(quotaState == IN_QUOTATION)
						{
							quotaState = NO_QUOTATION;
							if(!end_word(parseState))
								return -1;
						}
						else
						{	
							//˫�����еĵ�����ֱ��copy
							if(!push_char(ch))
								return -1;
						}
					}
					else
					{
						//ֱ��copy
						if(!push_char(ch))
							return -1;
					}
				}
				else
				{
					if(ch == '"')
					{
						quotaState = IN_DOUBLE_QUOTATION;
						if(!start_word(parseState))
							return -1;
					}
					else if(ch == '\'')
					{
						quotaState = IN_QUOTATION;
						if(!start_word(parseState))
							return -1;
					}
					else if(ch == ':')
					{
						if(!start_word(parseState))
							return -1;
					}
					else if(ch == ',')
					{
						if(!end_word(parseState))
							return -1;
					}
					else if(ch == '}')
					{
						if(!end_word(parseState))
							return -1;
						break;
					}
					else if(ch == ' ' ||ch == '\r' || ch == '\n' || ch=='\t')
					{
						//���ӿո�
					}
					else if(ch=='{')
					{
						//��ʼ�Ѿ�������жϹ���
					}
					else
					{
						if(!push_char(ch))
							return -1;
					}
				}
				
			}
			
			return 0;
		}

		bool get(const char* name, string& val)
		{
			m_mapit = m_map.find(name);
			if(m_mapit == m_map.end())
					return false;
			val = m_mapit->second;
			return true;
		}

		bool get(const string& name, string& val)
		{
			m_mapit = m_map.find(name);
			if(m_mapit == m_map.end())
				return false;
			val = m_mapit->second;
			return true;
		}

		bool get(const char* name, int& val)
		{
			m_mapit = m_map.find(name);
			if(m_mapit == m_map.end())
				return false;
			val = atoi(m_mapit->second.c_str());
			return true;
		}

		bool get(const string& name, int& val)
		{
			m_mapit = m_map.find(name);
			if(m_mapit == m_map.end())
				return false;
			val = atoi(m_mapit->second.c_str());
			return true;
		}

		void test_parse(const string& strjson)
		{
			cout << strjson << endl;
			if(parse(strjson)!=0)
			{
				cout << "fail" << endl;
			}

			for(m_mapit=m_map.begin(); m_mapit!=m_map.end(); ++m_mapit)
			{
				cout << m_mapit->first << "=" << m_mapit->second << endl;
			}
		}

		void debug(ostream& os)
		{
			for(m_mapit = m_map.begin(); m_mapit != m_map.end(); ++m_mapit)
			{
				os << m_mapit->first << "=" << m_mapit->second << endl;
			}
		}

	protected:
		inline bool push_char(char ch)
		{
			if((unsigned int)m_wordlen >= sizeof(m_wordbuff))
			{
				return false;
			}
			m_wordbuff[m_wordlen++] = ch;
			return true;
		}

		inline bool move_idx(int& idx, int max, int step=1)
		{
			idx += step;
			if(idx >= max || idx < 0)
			{
				return false;
			}
			return true;
		}

		bool start_word(int& parseState)
		{
			if(parseState == EXPECT_KEY)
			{
				parseState = PARSE_KEY;
			}
			else if(parseState == EXPECT_VAL || parseState == PARSE_VAL)
			{
				//valʹ��:������״̬
				//�ַ�val����" or '��ͷ�����ظ�����start
				//�����������
				parseState = PARSE_VAL;
			}
			else
			{
				return false;
			}
			
			m_wordlen = 0;
			return true;
		}

		bool end_word(int& parseState)
		{
			if(parseState == PARSE_KEY)
			{
				m_key.assign(m_wordbuff, m_wordlen);
				parseState = EXPECT_VAL;
			}
			else if(parseState == PARSE_VAL)
			{
				m_val.assign(m_wordbuff, m_wordlen);
				m_map[m_key] = m_val;
				parseState = EXPECT_KEY;
			}
			else if(parseState == EXPECT_KEY)
			{
				//valʹ��, or } ������
				//�ַ�val����" or '��ͷ�����ظ�����end
				//�����������
			}
			else
			{
				return false;
			}

			return true;
		}

	protected:
		char m_wordbuff[1024*4] ;
		int m_wordlen;
		NameValMap m_map;
		NameValMap::iterator m_mapit;
		string m_key;
		string m_val;
};
