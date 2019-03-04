#ifndef __HTML_CODING_H__
#define __HTML_CODING_H__
#include <string>
#include <iostream>
#include <sstream>
using namespace std;
class CHtmlCoding
{
	//编码过的字符串可以放到js变量的字符串中，并显示在页面上
public:
	static string simpleHtmlEncode(string src);
};
#endif

