#include "../url_coding.h"
#include <iostream>
#include <string.h>
using namespace std;

int main(int argc, char** argv)
{
	const char* src = "a*(3asdf/+\"'";
	cout << "src:" << src << endl;

	string dst = CUrlCoding::escape(src);

	cout << "escape:" << dst << endl;

	string dst2 = 	CUrlCoding::unescape(dst);

	cout << "unescape:" << dst2 << endl;

	const char* src2 = "你好"; //GB也是两字节
	cout << "src2:" << src2 << endl;

	dst = CUrlCoding::escape(src2, true);

	cout << "escape:" << dst << endl;

	dst2 = 	CUrlCoding::unescape(dst);

	cout << "unescape:" << dst2 << endl;
	
	
	return 0;
}

