#include "../html_coding.h"
#include <iostream>
#include <string.h>
using namespace std;

int main(int argc, char** argv)
{
	const char* src = "<script type=\"text/javascript\" src=\"http://top.oa.com/js/jquery-1.4.2.min.extend.js\"></script>";
	cout << "src:" << src << endl;

	string dst = CHtmlCoding::simpleHtmlEncode(src);

	cout << "simpleHtmlEncode:" << dst << endl;

	
	return 0;
}

