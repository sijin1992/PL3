#ifndef __STRING_HELPER_H__
#define __STRING_HELPER_H__
#include <string>
#include <list>
#include <vector>
typedef std::list<std::string> StringList;
typedef std::vector<std::string> StringVector;
class StringHelper
{
public:
	StringHelper(void);
	~StringHelper(void);
	static std::string intToString(int value);
	static bool isStartWidth(const std::string& str, const std::string &tar);
	static std::string connectString(const std::string& str1, const std::string &str2);
	static std::string getStringByIndex(const StringList& strList, int index);
	static StringList splitString(const std::string& str, const std::string &delimiter = " ");
	static void splitStringIntoVec(StringVector &vec, const std::string& str, const std::string &delimiter = " ");
	static int replaceStringFirst(std::string& str, const std::string &replace, const std::string &delimiter = "%");
	static void removeBoundarySpace(std::string& str);
	static int toInt(const std::string& str);
	static std::string fromInt(int value);
	//实现由PERL脚本生成
	static int toSql(const StringVector &vec, char *buff, unsigned &size);
	static const char *getStamp(const std::string &logStamp);
	static const char *str(const StringVector &vec, int index);
	static const char *getAreaID(const StringVector &vec, int index);
};

#endif
