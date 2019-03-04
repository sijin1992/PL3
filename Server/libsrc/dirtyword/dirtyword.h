#pragma once
#include <map>
#include <string>
#include <fstream>
#include <iostream>
#include <list>
//#define DEBUG
#include "../mem_alloc/trace_new.h"
#include "../codeset/codeset.h"
#include "../log/log.h"
using namespace std;

/*
#ifndef LOG
#define LOG_ERROR "error"
#define LOG_INFO "info"
#define LOG(loglevel, format, args...)  (printf("%s|%s|%d|"format"\r\n", loglevel,__FILE__,__LINE__,##args))
#endif
*/

class CUTFIterator
{
	private:
		int curIdx;
		int saveIdx;
		int strLen;
		const char* srcStr; //不做copy
		char buff[8];
		
	public:		
		CUTFIterator(const char* src, int len):curIdx(0), saveIdx(0), strLen(len), srcStr(src)
		{
		}

		void bind(const char* src, int len)
		{
			reset();
			strLen = len;
			srcStr = src;
		}

		void reset()
		{
			curIdx = 0;
			saveIdx = 0;
		}

		int getIdx()
		{
			return saveIdx;
		}

		char* getWord(int& len)
		{
			//最多6个字符
			len = 0;
			int i;
			saveIdx = curIdx;
			for(i=0; i<6; ++i)
			{
				if(curIdx >= strLen)
					return NULL;
				
				buff[i] = srcStr[curIdx++];
				if(buff[i] & 0x80) 
				{
					// 1xxx xxxx
					if(buff[i] & 0x40)
					{
						//11xx xxxx
						if(i!=0)
							return NULL;
						
						if(buff[i] & 0x20)
							if(buff[i] & 0x10)
								if(buff[i] & 0x08)
									if(buff[i] & 0x04)
										if(buff[i] & 0x02)
											return NULL;
										else
											len = 6; //1111 110x
									else
										len = 5; //1111 10xx
								else
									len = 4; //1111 0xxx
							else
								len = 3; //1110 xxxx
						else
							len = 2; //110x xxxx
					}
					else //后续字节
					{
						// 10xx xxxx
						if(i==0)
							return NULL;
						else if(i == len-1)
							break;
					}
				}
				else
				{
					//ascii字符0xxx xxxx 
					if(i!=0)
						return NULL;
					break;
				}
			}

			len = i+1;
			buff[len] = 0;
			return buff;
		}
};

struct DIRTY_WORD_UNIT
{
	DIRTY_WORD_UNIT()
	{
		buff[0] = 0;
		buffLen = 0;
	}

	char buff[8];
	int buffLen;

	int setBuff(const char* abuff, int abuffLen)
	{
		if(abuffLen >= (int)sizeof(buff))
		{
			return -1;
		}

		buffLen = abuffLen;
		memcpy(buff, abuff, buffLen);
		buff[buffLen] = 0;
		return 0;
	}

	bool equal(const char* abuff, int abuffLen)
	{
		if(abuffLen == buffLen)
		{
			for(int i=0; i<buffLen; ++i)
			{
				if(abuff[i] != buff[i])
					return false;
			}

			return true;
		}

		return false;
	}
};


class CDirtyWordNode
{
	public:
		int childNum;
		DIRTY_WORD_UNIT value;
		CDirtyWordNode* nextSibling;
		CDirtyWordNode* firstChild;
		CDirtyWordNode* parent;
		int end;

	CDirtyWordNode():childNum(0), nextSibling(NULL), firstChild(NULL), parent(NULL), end(0)
	{
	}

	~CDirtyWordNode()
	{
		CDirtyWordNode* child = firstChild;
		CDirtyWordNode* toDel;
		for(int i=0; i<childNum; ++i)
		{
			if(child)
			{
				toDel = child;
				child = child->nextSibling;
				TRACE_DEL(toDel);
			}
		}

		childNum = 0;
		firstChild = NULL;
		nextSibling = NULL;
		parent = NULL;
	}

	CDirtyWordNode* buildChild(const char* abuff, int abuffLen)
	{
		CDirtyWordNode* child = firstChild;
		for(int i=0; i<childNum; ++i)
		{
			if(!child) //数据不一致
			{
				return NULL;
			}

			if(child->value.equal(abuff, abuffLen))
			{
				return child;
			}

			child = child->nextSibling;
		}

		// insert to first
		child = TRACE_NEW(CDirtyWordNode);
		child->value.setBuff(abuff, abuffLen);
		child->nextSibling = firstChild;
		child->parent = this;
		firstChild = child;
		childNum++;

		return child;
	}

	void endChild()
	{
		CDirtyWordNode* child = firstChild;
		for(int i=0; i<childNum; ++i)
		{		
			if(!child) //数据不一致
			{
				return;
			}

			if(child->end == 1)
			{
				return;
			}

			child = child->nextSibling;
		}

		child = TRACE_NEW(CDirtyWordNode);
		child->nextSibling = firstChild;
		child->parent = this;
		child->end = 1;
		firstChild = child;
		childNum++;
	}

	void debug(ostream& out)
	{
		if(firstChild == NULL)
		{
			CDirtyWordNode* current= this;
			while(current!=NULL)
			{
				if(current->end)
					out << "end" << " <= ";
				else
					out << string(current->value.buff, current->value.buffLen) << " <= ";
				current = current->parent;
			}
			out << endl << endl;
		}
		else
		{
			CDirtyWordNode* child = firstChild;
			for(int i=0; i<childNum; ++i)
			{
				if(!child) //数据不一致
				{
					break;
				}

				child->debug(out);
				
				child = child->nextSibling;
			}
		}
	}


};

class CDirtyWord
{
	public:
		map<string, CDirtyWordNode*> treeMap;
		
		class CFilterTag
		{
			public:
				struct TAG_WORDIDX_NODE
				{
					int idxInSrc;
					int wordLen;
					TAG_WORDIDX_NODE* next;
				};
			public:
				TAG_WORDIDX_NODE* idxList;
				CDirtyWordNode* currentNode;

				CFilterTag()
				{
					idxList = NULL;
					currentNode = NULL;
				}

				CFilterTag(CDirtyWordNode* n, int idx, int len)
				{
					idxList = NULL;
					currentNode = n;
					addWordIdx(idx, len);
				}

				void replace(char* src, char replaceCh='*')
				{
					TAG_WORDIDX_NODE* p = idxList;
					while(p)
					{
						for(int i=0; i<p->wordLen; ++i)
						{
							src[p->idxInSrc+i] = replaceCh;
						}
						p = p->next;
					}
				}

				void release()
				{
					TAG_WORDIDX_NODE* p = idxList;
					TAG_WORDIDX_NODE* toDel;
					while(p)
					{
						toDel = p;
						p = p->next;
						TRACE_DEL(toDel);
					}
				}

				void addWordIdx(int idx, int len)
				{
					TAG_WORDIDX_NODE* p = TRACE_NEW(TAG_WORDIDX_NODE);
					p->idxInSrc = idx;
					p->wordLen = len;
					p->next = idxList;
					idxList = p;
				}

				void copyFrom(const CFilterTag& other)
				{
					currentNode = other.currentNode;
					TAG_WORDIDX_NODE* p = other.idxList;
					while(p)
					{
						addWordIdx(p->idxInSrc, p->wordLen);
						p = p->next;
					}
				}
		};

	public:
		enum CODE_TYPE
		{
			CODE_TYPE_UTF8=0,
			CODE_TYPE_GBK=1
		};

		int m_codeBuffMax;
		char* m_codeBuff;
		
	public:
		CDirtyWord(int maxCodingBuff=256)
		{
			m_codeBuffMax = maxCodingBuff;
			m_codeBuff = TRACE_NEW_ARRAY(char, m_codeBuffMax);
		}

		~CDirtyWord()
		{
			map<string, CDirtyWordNode*>::iterator mapit;
			for(mapit = treeMap.begin(); mapit != treeMap.end(); ++ mapit)
			{
				TRACE_DEL(mapit->second);
				mapit->second = NULL;
			}

			TRACE_DEL_ARRAY(m_codeBuff);
		}

		int init(const char* fileName, CODE_TYPE codeType = CODE_TYPE_UTF8)
		{
			ifstream inf(fileName);
			if(!inf.good())
			{
				LOG(LOG_ERROR, "open input_file[%s] get word fail", fileName);
				return -1;
			}
			
			int linenum = 0;
			const char* linec;
			while(!inf.eof())
			{
				 string linestr;
			        getline(inf, linestr);	
			        if(inf.fail() && !inf.eof())
			        {
					LOG(LOG_ERROR, "linenum[%d] fail", linenum+1);
					return -1;
			        }

				if(codeType == CODE_TYPE_GBK)
				{
					size_t buffFree = m_codeBuffMax-1;
					if(CCodeSet::gbk_utf8(linestr.c_str(), linestr.length(), m_codeBuff, buffFree)!=0)
					{
						LOG(LOG_ERROR, "linenum[%d] gbk to utf8 fail", linenum+1);
						return -1;
					}
					linec = m_codeBuff;
					m_codeBuff[m_codeBuffMax-1-buffFree] = 0;
				}
				else if(codeType == CODE_TYPE_UTF8)
				{
					linec = linestr.c_str();
				}
				else
				{
					LOG(LOG_ERROR, "m_codeType = %d not support", codeType);
					return -1;
				}
				
			        if(buildTree(linec)!=0)
			        {
					LOG(LOG_ERROR, "buildTree linenum[%d] fail", linenum+1);
			        	return -1;
			        }

				++linenum;
			}

			LOG(LOG_INFO, "dirty word init ok line=%d", linenum);
			inf.close();
			return 0;
		}

		void debug(ostream& out)
		{
			map<string, CDirtyWordNode*>::iterator mapit;
			for(mapit = treeMap.begin(); mapit != treeMap.end(); ++ mapit)
			{
				out << "---------------------------" << endl; 
				mapit->second->debug(out);
			}

			out << "==========end=========" << endl;
		}

		int filterUtf8(const char* src, int srclen, char* replaceBuf=NULL)
		{
			const char* asrc = src;
			int asrclen = srclen;
		
			CUTFIterator it(asrc, asrclen);
			int len;
			char* word;
			CDirtyWordNode* current;
			list<CFilterTag> tags;
			list<CFilterTag>::iterator tagIt;
			int replaced = 0;
			while( (word = it.getWord(len)) )
			{
				//空格之类的无视
				if(word[0] == '\t' || word[0] == ' ' || word[0] == '\r' || word[0] == '\n')
				{
					continue;
				}
				
				//先核对已保存的匹配
				if(!tags.empty())
				{
					list<CFilterTag> newtags;
					
					for(tagIt=tags.begin(); tagIt!=tags.end(); ++tagIt)
					{
						//自己是"*"，贪婪匹配不删除了
						bool selfIsStar = tagIt->currentNode->value.equal("*", 1);
						if(selfIsStar)
						{
							CFilterTag copytag;
							copytag.copyFrom(*tagIt);
							newtags.push_back(copytag);
						}
					
						current = tagIt->currentNode->firstChild;
						for(int j=0; j< tagIt->currentNode->childNum; ++j)
						{
							if(!current) 
							{
								break;
							}

							// *的特殊处理, 不迭代了，没必要支持"**"的叠加
							if(!selfIsStar && current->value.equal("*", 1))
							{
								//加入自己
								CFilterTag newtag;
								newtag.copyFrom(*tagIt);
								newtag.currentNode = current;
								newtags.push_back(newtag);
									
								//看子节点的匹配
								CDirtyWordNode* tmp = current->firstChild;
								for(int k=0; k<current->childNum; ++k)
								{
									if(!tmp)
										break;
									
									if(tmp->value.equal(word, len))
									{
										CFilterTag newtagchild;
										newtagchild.copyFrom(*tagIt);
										newtagchild.addWordIdx(it.getIdx(), len);
										newtagchild.currentNode = tmp;
										newtags.push_back(newtagchild);
									}
									
									tmp = tmp->nextSibling;
								}
							}

							if(current->value.equal(word, len))
							{
								CFilterTag newtag;
								newtag.copyFrom(*tagIt);
								newtag.addWordIdx(it.getIdx(), len);
								newtag.currentNode = current;
								newtags.push_back(newtag);
							}
							
							current = current->nextSibling;
						}
					}

					//清理旧的
					for(tagIt=tags.begin(); tagIt!=tags.end(); ++tagIt)
					{
						tagIt->release();
					}
					tags.swap(newtags);
				}

				//查新的匹配
				current = getTree(word, len);
				if(current)
				{
					tags.push_back(CFilterTag(current, it.getIdx(), len));
				}

				//检查匹配是否已经结束
				for(tagIt=tags.begin(); tagIt!=tags.end(); ++tagIt)
				{
					current = tagIt->currentNode->firstChild;
					for(int j=0; j< tagIt->currentNode->childNum; ++j)
					{
						if(!current) 
						{
							break;
						}

						if(current->end == 1)
						{
							//结束
							if(replaceBuf)
							{
								//不是同一个指针
								if(asrc != replaceBuf)
								{
									memcpy(replaceBuf, asrc, asrclen);
									replaceBuf[asrclen] = 0;
								}
								tagIt->replace(replaceBuf);
							}
							++replaced;
							break;
						}

						current = current->nextSibling;
					}
				}
				
			}

			//最后的释放
			for(tagIt=tags.begin(); tagIt!=tags.end(); ++tagIt)
			{
				tagIt->release();
			}

			return replaced;
		}

	private:
		CDirtyWordNode* getTree(const char* abuff, int abuffLen)
		{
			string key(abuff, abuffLen);
			map<string, CDirtyWordNode*>::iterator mapit = treeMap.find(key);
			if(mapit != treeMap.end())
			{
				return mapit->second;
			}

			return NULL;
		}
		
		int buildTree(const char* line)
		{
			int linelen = strlen(line);
			for(int i=linelen-1; i>=0; --i)
			{
				if(line[i] == '\n' || line[i] == '\r')
				{
					linelen--;
				}
				else
				{
					break;
				}
			}

			if(linelen == 0)
			{
				LOG(LOG_ERROR, "line[%s] empty line", line);
				return 0;
			}
			
			CUTFIterator it(line, linelen);
			int len;
			char* word = it.getWord(len);
			if(word == NULL)
			{
				LOG(LOG_ERROR, "line[%s] get word fail", line);
				return -1;
			}

			string key(word,len);
			CDirtyWordNode* curNode;
			map<string, CDirtyWordNode*>::iterator mapit = treeMap.find(key);
			if(mapit == treeMap.end())
			{
				curNode = TRACE_NEW(CDirtyWordNode);
				curNode->value.setBuff(word, len);
				treeMap.insert(make_pair(key, curNode));
			}
			else
			{
				curNode = mapit->second;
			}

			while((word=it.getWord(len)))
			{
				curNode = curNode->buildChild(word, len);
				if(curNode == NULL)
				{
					LOG(LOG_ERROR, "build child[%s] fail", word);
					return -1;
				}
			}

			//结束
			curNode->endChild();

			return 0;
		}
};


