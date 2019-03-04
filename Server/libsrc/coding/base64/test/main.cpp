#include "../base64.h"
#include <iostream>
#include <string.h>
using namespace std;

int main(int argc, char** argv)
{
	{
		char src[256] = "abcdefg1911";
		char dst[256] = {0};
		char dst2[256] = {0};
		size_t len = 0;

		cout << "src:" << src << endl;

		len = sizeof(dst);
		base64_encode(src, strlen(src), dst, len);

		cout << "base64_encode len=" << len << ":" << dst << endl;

		len = sizeof(dst2);
		base64_decode(dst, strlen(dst), dst2, &len);

		cout << "base64_decode len=" << len << ":" << dst2 << endl;

		base64_type(0);

		len = sizeof(dst);
		base64_encode(src, strlen(src), dst,  len);

		cout << "base64_encode len=" << len << ":" << dst << endl;

		len = sizeof(dst2);
		base64_decode(dst, strlen(dst), dst2, &len);

		cout << "base64_decode len=" << len << ":" << dst2 << endl;
	
	}
	
	return 0;
}

