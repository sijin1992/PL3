#include "../strutil.h"
#include <iostream>
#include <string.h>
using namespace std;

int main(int argc, char** argv)
{
	string s = " \tAsetd \r\n";
	cout << "[" << s << "]" << endl;

	
	cout << "[" << strutil::trimLeft(s) << "]" << endl;
	cout << "[" << strutil::trimRight(s) << "]" << endl;
	cout << "[" << strutil::trim(s) << "]" << endl;
	cout << "[" << strutil::toLower(s) << "]" << endl;
	cout << "[" << strutil::toUpper(s) << "]" << endl;
	cout << "[" << strutil::repeat('x',10) << "]" << endl;
	cout << "[" << strutil::repeat(s,2) << "]" << endl;
	cout << "[" << strutil::startsWith(s," ") << "]" << endl;
	cout << "[" << strutil::startsWith(s,"\t") << "]" << endl;
	cout << "[" << strutil::endsWith(s," ") << "]" << endl;
	cout << "[" << strutil::endsWith(s,"\n") << "]" << endl;
	cout << "[" << strutil::equalsIgnoreCase(s," \tAseTd \r\n") << "]" << endl;
	cout << "[" << strutil::equalsIgnoreCase(s," \tAsed \r\n") << "]" << endl;

	int i = parseString<int>("3");
	float f = parseString<float>("3.0");
	int x = parseHexString<int>("0xF4");
	bool b = parseString<bool>("false");
	cout << i << " "  << f << " " << x << " " << b << endl;
	cout << strutil::toString(12345) << endl;
	cout << strutil::toString(2.0) << endl;
	cout << toHexString(12345, 6) << endl;

	vector<string> ret = strutil::split("1|2|3|4|", "|");
	cout << strutil::jion(ret, "*") << endl;

	string xxx =  "abc$E$gie$E$i" ;
	cout << xxx << endl;
	cout << "replace $E$:" << strutil::replaceAll(xxx, "$E$", "X") << endl;

	cout << strutil::format("test format %d %f %s", 1, 2.0, "3") << endl;

	map<string, string> mapkv;
	string yyy="a=b&c=d";
	cout << "strtomap(" << yyy << ") =" <<  strutil::strToMap(mapkv, yyy.c_str()) << endl;
	cout <<  "restore:" << strutil::mapToStr(mapkv) << endl;

	string temp = "the a is $a# and the c is $c# and the fuck is $fuck# $a# $c# $fuck#";
	cout << strutil::replaceVariables(temp, mapkv, "$", "#") << endl;
	
	return 0;
}

