#ifndef __CMD_READER_H__
#define __CMD_READER_H__
#include <iostream>
#include <string>
#include <list>
#include <map>
#include <vector>

#define CHAR_ENTER '\n'
#define CHAR_BACK_SPACE 7
#define CHAR_UP_SCROLL 3
#define CHAR_DOWN_SCROLL 2
#define CHAR_LEFT_NAV 4
#define CHAR_RIGHT_NAV 5
#define CHAR_TAB 9
typedef std::list<std::string> CmdList;
typedef std::list<std::string> StringList;
typedef std::map<std::string, std::string> AliasMap;
class CCmdReader
{
public:
	CCmdReader(std::istream &is, std::ostream &os, unsigned int maxHistoryCmd = 100);
	~CCmdReader();
	int setUseCurses(bool flag = true);
	int open();
	int close();
	std::string readCmd();
	std::string charToString(char ch);
	StringList splitString(const std::string& str, const std::string &delimiter = " ");
	int replaceStringFirst(std::string& str, const std::string &replace, const std::string &delimiter = "%");
	void setAlias(const std::string& alias, const std::string &refto);
	void removeAlias(const std::string &alias);
	bool isInterCmd(const std::string& cmd);

	bool isAlias(const std::string& cmd);
	std::string getAlias(const std::string& cmd);
	int processCmd(const std::string& cmd);
	void removeBoundarySpace(std::string& str);
	bool isAvailableChar(char ch);

	void setCmdStr(const std::string &cmd);
protected:
	void initial();
	void clean();
	void doBackspace();
	void doLeftNav();
	void doRightNav();
	void doUpScroll();
	void doDownScroll();
	void doPushChar(char ch);
	void doTab();
	void hookReciveCmd();
	void updateOutStream();
	void clearOutLine();
	void fillBuffString(bool needRefitCursor = true);
	void returnIngoreCmd();

	int loadAliasFromFile();
	void saveAliasToFile();

	int loadHistoryFromFile();
	void saveHistoryToFile();
	
	void autoFill();

	std::string getCommStr(const std::vector<std::string> &strVec);

private:
	std::string getHistoryCmd(int index);
	void moveInputCursor(int step);
	void refitInputCursor();
	void pushBuffToHishtory();
	void pushCmdToHishtory(const std::string &cmd);
	std::string explainAliasCmd(const std::string& cmd);
	void splitBuffToBackupCmdList();
	void processAliasCmd(const std::string& cmd);
protected:
	std::istream &mInStream;
	std::ostream &mOutStream;
	char mInChar;
	std::string mBuff;
	unsigned int mMaxHistoryCmd;
	CmdList mHistoryCmdList;
	int mScrollIndex;
	int mInputIndex;
	bool mIsScrolling;
	int mInited;
	std::string mFreSymbol;
	int mOutStreamWidth;
	bool mIsRereshed;
	AliasMap mAliasMap;
	CmdList mInterCmd;
	CmdList mBackupCmdList;
	bool mIsOpened;
	bool mUseCurses;
	std::string mAliasFileName;
	std::string mHistoryFileName;
};

#endif
