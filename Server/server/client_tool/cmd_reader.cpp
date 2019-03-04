#include "cmd_reader.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <ncurses.h>
#include <ctype.h>
#include <fcntl.h>
#include <string.h>
#include <fstream>


CCmdReader::CCmdReader(std::istream &is, std::ostream &os, unsigned int maxHistoryCmd)
	:mInStream(is), mOutStream(os)
{
	mAliasFileName = "CmdReaderAlias";
	mHistoryFileName = "CmdReaderHistoryCmd";
	mMaxHistoryCmd = maxHistoryCmd;
	mHistoryCmdList.clear();
	mScrollIndex = 0;
	mFreSymbol = "[Cmd]:";
	mIsScrolling = false;
	mIsRereshed = false;
	loadAliasFromFile();
	loadHistoryFromFile();
	mInited = false;
	mIsOpened = false;
	mUseCurses = true;
}

CCmdReader::~CCmdReader()
{
	saveAliasToFile();
}

StringList CCmdReader::splitString(const std::string& str, const std::string &delimiter)
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

int CCmdReader::loadAliasFromFile()
{
	std::ifstream ifs(mAliasFileName.c_str(), std::ios::in);
	if( !ifs.is_open() )
	{
		return -1;	
	}
	const int buffLen = 1024;
	char buff[buffLen];
	std::string line;
	while( !ifs.eof() )
	{
		ifs.getline(buff, buffLen);
		line = buff;
		processCmd(line);
	}
	return 0;
}

void CCmdReader::saveAliasToFile()
{
	std::ofstream ofs(mAliasFileName.c_str(), std::ios::out | std::ios::trunc );
	if( !ofs.is_open() )
	{
		return;	
	}
	for(AliasMap::iterator it = mAliasMap.begin(); it != mAliasMap.end() ; it++)
	{
		ofs << "alias " << it->first << " = " << it->second << std::endl;
	}
}


int CCmdReader::loadHistoryFromFile()
{
	std::ifstream ifs(mHistoryFileName.c_str(), std::ios::in);
	if( !ifs.is_open() )
	{
		return -1;	
	}
	const int buffLen = 1024;
	char buff[buffLen];
	std::string line;
	while( !ifs.eof() )
	{
		ifs.getline(buff, buffLen);
		line = buff;
		pushCmdToHishtory(line);
	}
	return 0;
}

void CCmdReader::saveHistoryToFile()
{
	std::ofstream ofs(mHistoryFileName.c_str(), std::ios::out | std::ios::trunc );
	if( !ofs.is_open() )
	{
		return;	
	}
	for(CmdList::reverse_iterator it = mHistoryCmdList.rbegin(); it != mHistoryCmdList.rend() ; it++)
	{
		ofs << *it << std::endl;
	}
}


void CCmdReader::autoFill()
{
	const char *pStr = mBuff.c_str();
	int comCount = 0;
	std::string comStr;
	std::vector<std::string> strVec;
	unsigned int maxLength = 0;
	AliasMap::iterator it = mAliasMap.begin();
	AliasMap::iterator itEnd = mAliasMap.end();
	while( it != itEnd)
	{
		const char *pTempStr = it->first.c_str();
		if( strstr(pTempStr, pStr) == pTempStr )
		{
			comStr = pTempStr;
			comCount++;
			strVec.push_back(comStr);
			if( maxLength < comStr.size() )
			{
				maxLength = comStr.size();
			}
		}
		it++;
	}
	if( comCount == 1 && !comStr.empty() )
	{
		mBuff = comStr + " ";
		mInputIndex = mBuff.size();
	}
	else if(comCount > 0)
	{
		comStr = getCommStr(strVec);
		if( !comStr.empty() && comStr != mBuff )
		{
			mBuff = comStr;
			mInputIndex = mBuff.size();
			return;
		}
		mOutStream << std::endl;
		mOutStream << "\r";
		for(unsigned int i = 0; i < strVec.size(); i++)
		{
			mOutStream << strVec[i];
			if( i != 0 && i % 4 == 0 )
			{
				mOutStream << std::endl;
				mOutStream << "\r";
				continue;
			}
			for(unsigned int j = strVec[i].size(); j < maxLength; j++ )
			{                          
				mOutStream << " ";
			}
			mOutStream << "\t"; 
		}
		mOutStream << std::endl;
	}
}

std::string CCmdReader::getCommStr(const std::vector<std::string> &strVec)
{
	if( strVec.size() == 0 )
	{
		return "";
	}
	std::string comStr = strVec.at(0);
	unsigned int length = comStr.size();
	for( unsigned int i = 1; i < strVec.size(); i++ )
	{
		const std::string &str = strVec.at(i);
		for( unsigned int j = 0; j < length && j < str.size(); j++ )
		{
			if( comStr.at(j) != str.at(j) )
			{
				length = j;
				break;
			}
		}
	}
	comStr = comStr.substr(0, length);
	return comStr;
}

int CCmdReader::open()
{
	if( !mUseCurses ) return 0;
	if( mIsOpened ) return -1;
	initial();
	mIsOpened = true;
	return 0;
}

int CCmdReader::close()
{
	if( !mUseCurses ) return 0;
	if( !mIsOpened ) return -1;
	clean();
	mIsOpened = false;
	return 0;
}

std::string CCmdReader::readCmd()
{
	if( mBackupCmdList.size() != 0 )
	{
		mBuff = "";
		hookReciveCmd();
		return mBuff;
	}
	if( mUseCurses )
	{
		open();
		while(true)
		{	
			mInChar = getch();
			if( mInChar == '\n' )
			{
				break;
			}
			else if( mInChar == CHAR_BACK_SPACE )
			{
				doBackspace();
			}
			else if( mInChar == CHAR_LEFT_NAV )
			{
				doLeftNav();
			}
			else if( mInChar == CHAR_RIGHT_NAV )
			{
				doRightNav();
			}
			else if( mInChar == CHAR_UP_SCROLL )
			{
				doUpScroll();
			}
			else if( mInChar == CHAR_DOWN_SCROLL )
			{
				doDownScroll();
			}
			else if ( mInChar == CHAR_TAB )
			{
				doTab();
			}
			else if( isAvailableChar(mInChar) )
			{
				doPushChar(mInChar);
			}
			else
			{
				/*
				std::string str = charToString(mInChar);
				mInputIndex += str.size();
				mBuff += str;
				*/
			}
			updateOutStream();
		}
		close();
	}
	else
	{
		static char buff[1024];
		mInStream.getline(buff, 1023);
		mBuff = buff;
	}
	hookReciveCmd();
	return mBuff;
}

std::string CCmdReader::charToString(char ch)
{
	static const char* pBuff = "0123456789";
	std::string str;
	int number = ch;
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

int CCmdReader::replaceStringFirst(std::string& str, const std::string &replace, const std::string &delimiter)
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

void CCmdReader::setAlias(const std::string& alias, const std::string &refto)
{
	AliasMap::iterator it = mAliasMap.find(alias);
	if( it != mAliasMap.end() )
	{
		mAliasMap.erase(it);
	}
	mAliasMap.insert(std::make_pair(alias, refto));
	saveAliasToFile();
}

void CCmdReader::removeAlias(const std::string &alias)
{
	AliasMap::iterator it = mAliasMap.find(alias);
	if( it != mAliasMap.end() )
	{
		mAliasMap.erase(it);
		saveAliasToFile();
		mOutStream << "alias:" << alias << "removed" << std::endl;
	}
}

bool CCmdReader::isInterCmd(const std::string& cmd)
{
	if( cmd.compare(0, strlen("alias"), "alias") == 0 )
	{
		return true;
	}
	return false;
}

bool CCmdReader::isAlias(const std::string& cmd)
{
	StringList strList = splitString(cmd);
	if( strList.empty() )
	{
		return false;
	}
	std::string tempStr = *strList.begin();
	if( mAliasMap.find(tempStr) != mAliasMap.end() )
	{
		return true;
	}
	return false;
}

std::string CCmdReader::getAlias(const std::string& cmd)
{
	AliasMap::iterator it = mAliasMap.find(cmd);
	if( it != mAliasMap.end() )
	{
		return it->second;
	}
	else
	{
		return "";
	}

}

int CCmdReader::processCmd(const std::string& cmd)
{
	if( isInterCmd(cmd) )
	{
		processAliasCmd(cmd);
	}
	else if( isAlias(cmd) )
	{
		mBuff = explainAliasCmd(cmd);
		return 1;
	}
	else
	{
		return -1;
	}
	return 0;
}

void CCmdReader::removeBoundarySpace(std::string& str)
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

bool CCmdReader::isAvailableChar(char ch)
{
	return isalnum(ch) || isspace(ch) || ch == '=' || '%';
}


void CCmdReader::setCmdStr(const std::string &cmd)
{
	mBuff = cmd;
}

std::string CCmdReader::explainAliasCmd(const std::string& cmd)
{
	StringList strList = splitString(cmd);
	if( strList.empty() )
	{
		return "";
	}
	StringList::iterator it = strList.begin();
	std::string alias = *it;
	std::string refto = getAlias(alias);
	//mOutStream << "cmd:" << cmd << std::endl;
	//mOutStream << "refto1:" << refto << std::endl;
	//mOutStream << "refto2:" << refto << std::endl;
	it++;
	while( it != strList.end() )
	{
		if( replaceStringFirst(refto, *it, "%") <= 0 )
		{
			break;
		}
		//mOutStream << "refto%:" << refto << std::endl;
		it++;
	}

	while( it != strList.end() )
	{
		refto += " ";
		refto += *it;
		it++;
		//mOutStream << "refto%:" << refto << std::endl;
	}
	return refto;
}

void CCmdReader::processAliasCmd(const std::string& cmd)
{
	const char* pStrAlias = "alias";
	unsigned int len = strlen(pStrAlias);
	std::string alias;
	std::string refto;
	const char *pP1 = strstr(cmd.c_str(), pStrAlias);
	if( NULL == pP1 )
	{
		return;
	}
	std::string temp = cmd;
	removeBoundarySpace(temp);
	if( temp == "alias" )
	{
		mOutStream << "-<Alias List>-" << std::endl;
		for(AliasMap::iterator it = mAliasMap.begin(); it != mAliasMap.end() ; it++)
		{
			mOutStream << "alias " << it->first << " = " << it->second << std::endl;
		}
		return;
	}
		
	mOutStream << std::endl << "process Alias." << std::endl;
	const char *pP2 = strstr(cmd.c_str(), "=");
	if( NULL == pP2 )
	{
		mOutStream << "Set Alias:[key]=[value]" << std::endl;
		return;
	}

	int len2 = pP2 - pP1 - len;
	alias = cmd.substr(len, len2);
	refto = cmd.substr(pP2 - pP1 + 1, cmd.length() - (pP2 - pP1 + 1) );
	removeBoundarySpace(alias);
	
	if( isInterCmd(alias) )
	{
		return;
	}
	removeBoundarySpace(refto);
	if( refto == "0" )
	{
		removeAlias(alias);
	}
	else
	{
		setAlias(alias, refto);
	}
	mOutStream << "Set Alias:[" << alias << "]=[" << refto << "]" << std::endl;
}



void CCmdReader::initial()
{
	initscr();
	cbreak();
	nl();
	noecho();
	intrflush(stdscr, false);
	keypad(stdscr, true);
	mBuff.clear();
	mScrollIndex = 0;
	mInputIndex = 0;
	mOutStreamWidth = 0;
	if( !mIsRereshed )
	{
		mIsRereshed = true;
		refresh();
	}
	updateOutStream();
}
void CCmdReader::clean()
{
	endwin();
}

void CCmdReader::doBackspace()
{
	if( mInputIndex <= 0 )
	{
		return;
	}
	if( mInputIndex >= (int)mBuff.size() )
	{
		mBuff = mBuff.substr(0, mBuff.size() - 1);
	}
	else
	{
		mBuff = mBuff.substr(0, mInputIndex -1) + mBuff.substr(mInputIndex, mBuff.size() - mInputIndex);
	}
	mInputIndex--;
}

void CCmdReader::doLeftNav()
{
	if( mInputIndex > 0 )
	{
		mInputIndex--;
	}
}

void CCmdReader::doRightNav()
{
	if( mInputIndex < (int)mBuff.size() )
	{
		mInputIndex++;
	}
}

void CCmdReader::doUpScroll()
{
	if( mScrollIndex > (int)mHistoryCmdList.size() )
		return;
	std::string temp = getHistoryCmd(mScrollIndex);
	if( !mIsScrolling && !mBuff.empty() )
		pushBuffToHishtory();
	mBuff = temp;
	if( mScrollIndex < (int)mHistoryCmdList.size() )
	{
		mScrollIndex ++;
	}
	mInputIndex = mBuff.size();
	mIsScrolling = true;
}

void CCmdReader::doDownScroll()
{
	if( mScrollIndex < 0 || !mIsScrolling )
		return;
	std::string temp = getHistoryCmd(mScrollIndex - 1);
	mBuff = temp;
	if( mScrollIndex > 0 )
	{
		mScrollIndex--;
	}
	mInputIndex = mBuff.size();
	mIsScrolling = true;
}

void CCmdReader::doPushChar(char ch)
{
	if( mInputIndex >= (int)mBuff.size() )
	{
		mBuff.push_back(mInChar);
	}
	else
	{
		mBuff.insert(mInputIndex, 1, ch);
	}
	mInputIndex++;
	mIsScrolling = false;
}

void CCmdReader::doTab()
{
	autoFill();
}

void CCmdReader::hookReciveCmd()
{
	pushBuffToHishtory();
	splitBuffToBackupCmdList();
	if( mBackupCmdList.size() == 0 )
	{
		return;
	}
	mBuff = mBackupCmdList.front();
	mBackupCmdList.pop_front();
	if( mBuff.size() > 0 )
	{
		if( isalnum(*mBuff.begin()) )
		{
			if( processCmd(mBuff) == 0 )
				returnIngoreCmd();
		}
	}
}

void CCmdReader::updateOutStream()
{
	clearOutLine();
	fillBuffString();
}

void CCmdReader::clearOutLine()
{
	int width = mOutStreamWidth + mFreSymbol.size();
	mOutStream << '\r';
	for(int i= 0; i < width; i++ )
	{
		mOutStream << ' ';
	}
	for(int i= 0; i < width; i++ )
	{
		mOutStream << '\b';
	}
	mOutStream << '\r';
	mOutStreamWidth = 0;
}

std::string CCmdReader::getHistoryCmd(int index)
{
	int historySize = (int)mHistoryCmdList.size();
	std::string lastCmd("");
	if( index < 0 || index > historySize - 1 )
	{
		return lastCmd;
	}
	CmdList::iterator it = mHistoryCmdList.begin();
	std::advance(it, index);
	lastCmd = *it;
	return lastCmd;
}

void CCmdReader::fillBuffString(bool needRefitCursor)
{
	mOutStream << mFreSymbol;
	mOutStream << mBuff;
	mOutStreamWidth = mBuff.size();
	if(needRefitCursor)
		refitInputCursor();
	mOutStream.flush();
}
void CCmdReader::returnIngoreCmd()
{
	mBuff = "ignore";
}

void CCmdReader::moveInputCursor(int step)
{
	if( step >= 0 ) return;
	while( step++ < 0 )
	{
		mOutStream << '\b';
	}
}

void CCmdReader::refitInputCursor()
{
	int diff = mInputIndex - mOutStreamWidth;
	moveInputCursor(diff);
}
void CCmdReader::pushBuffToHishtory()
{
	pushCmdToHishtory(mBuff);
	saveHistoryToFile();
}

void CCmdReader::pushCmdToHishtory(const std::string &cmd)
{
	if( cmd.empty() || (mHistoryCmdList.size() > 0 && mHistoryCmdList.front() == cmd) )
	{
		return;
	}
	if( mHistoryCmdList.size() >= mMaxHistoryCmd )
	{
		mHistoryCmdList.erase(--mHistoryCmdList.end());	
	}
	mHistoryCmdList.push_front(cmd);
	
}

int CCmdReader::setUseCurses( bool flag /*= true*/ )
{
	mUseCurses = flag;
	return 0;
}

void CCmdReader::splitBuffToBackupCmdList()
{
	StringList strList = splitString(mBuff, ";");
	StringList::iterator it = strList.begin();
	StringList::iterator itEnd = strList.end();
	while( it != itEnd )
	{
		if( !(*it).empty() )
		{
			mBackupCmdList.push_back(*it);
		}
		it++;
	}
}
