#include "StringHelper.h"
#include <string.h>
#include <sstream>
#include <iostream>
#include <stdio.h>
#include "log/log_stat.h"
#include "tosql.hpp"

StringHelper::StringHelper(void)
{
}


StringHelper::~StringHelper(void)
{
}

std::string StringHelper::intToString(int value )
{
	static const char* pBuff = "0123456789";
	std::string str;
	int number = value;
	do
	{
		int aMod = number % 10;
		str.push_back(pBuff[aMod]);
		number /= 10;
	}while(number > 0);
	std::string text;
	std::string::reverse_iterator reverseIt = str.rbegin();
	std::string::reverse_iterator reverseEnd = str.rend();
	while( reverseIt != reverseEnd )
	{
		text.push_back(*reverseIt);
		reverseIt++;
	}
	return text;
}

bool StringHelper::isStartWidth(const std::string& str, const std::string &tar)
{
	return strncmp(str.c_str(), tar.c_str(), tar.length()) == 0;
}

std::string StringHelper::connectString(const std::string& str1, const std::string &str2)
{
	return str1 + str2;
}

std::string StringHelper::getStringByIndex(const StringList& strList, int index)
{
	std::string str;
	if( strList.empty() || index >= (int)strList.size() )
	{
		return str;
	}
	StringList::const_iterator it = strList.begin();
	std::advance(it, index);
	str = *it;
	return str;
}

StringList StringHelper::splitString( const std::string& str, const std::string &delimiter /*= " "*/ )
{
	StringList strList;
	if( str.empty() ) return strList;
	std::string tempStr = str;
	removeBoundarySpace(tempStr);
	if( tempStr.empty() ) return strList;
	bool isEnd = false;
	while(!isEnd)
	{
		removeBoundarySpace(tempStr);
		std::string listItem = tempStr;
		int itemLen = 0;
		const char *pP0 = tempStr.c_str();
		const char *pP1 = strstr(pP0, delimiter.c_str());
		if( NULL != pP1 )
		{
			itemLen = pP1 - pP0;
			listItem = tempStr.substr(0, itemLen);
			int removeLen = itemLen + delimiter.length();
			tempStr = tempStr.substr(removeLen, tempStr.length() - removeLen);
		}
		else
		{
			isEnd = true;
		}
		removeBoundarySpace(listItem);
		strList.push_back(listItem);
	}
	return strList;
}

void StringHelper::splitStringIntoVec(StringVector &vec, const std::string& str, const std::string &delimiter)
{
	StringList list = splitString(str, delimiter);
	StringList::iterator it = list.begin();
	while( it != list.end() )
	{
		vec.push_back(*it);
		it++;
	}
}

int StringHelper::replaceStringFirst( std::string& str, const std::string &replace, const std::string &delimiter /*= "%"*/ )
{
	std::string tempStr;
	if(str.empty()) return -1;
	const char *pP0 = str.c_str();
	const char *pP1 = strstr(pP0, delimiter.c_str());
	if( NULL == pP1 )
	{
		return 0;
	}
	int preLen = pP1 - pP0;
	int delimLen = delimiter.length();
	tempStr = str.substr(0, preLen) + replace + str.substr(preLen + delimLen, str.length() - (preLen + delimLen));
	str = tempStr;
	return 1;
}

void StringHelper::removeBoundarySpace( std::string& str )
{
	//left
	while( !str.empty() && (*str.begin()) == ' ' )
	{
		str.erase(str.begin());
	}
	//right
	while( !str.empty() && (*str.rbegin()) == ' ' )
	{
		str.erase(str.length() - 1, 1);
	}
}

int StringHelper::toInt( const std::string& str )
{
	std::stringstream strStream;
	strStream << str;
	int value = 0;
	strStream >> value;
	return value;
}

std::string StringHelper::fromInt( int value )
{
	std::stringstream strStream;
	strStream << value;
	std::string str;
	strStream >> str;
	return str;
}

