#include "../binary_util.h"
#include <iostream>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
using namespace std;

int main(int argc, char** argv)
{
/*
	int offset = 0;
	char buff[1024];
	memset(buff, 0x0, sizeof(buff));
	
	offset += CDRTool::WriteByte(buff+offset, (unsigned char)12);
	cout << "offset:" << offset << endl;
	offset += CDRTool::WriteShort(buff+offset, (short)232);
	cout << "offset:" << offset << endl;
	offset += CDRTool::WriteInt(buff+offset, (unsigned int)34534);
	cout << "offset:" << offset << endl;
	offset += CDRTool::WriteLong(buff+offset, (long)43454626);
	cout << "offset:" << offset << endl;

	cout << "checksum:" << CBinaryUtil::checksum(buff, offset) << endl;

	std::string  str = CBinaryUtil::bin_hex(buff, offset);

	cout << "to hex:" << str << endl;

	int size  = sizeof(buff) - offset;
	CBinaryUtil::hex_bin(str, buff+offset, size);
	cout << "recovered size:" << size << " checksum:" << CBinaryUtil::checksum(buff+offset, size) << endl;
	cout << CBinaryUtil::bin_hex(buff+offset, size) << endl;
*/
	if(argc < 2)
	{
		cout << argv[0] << " file" << endl;
		return 0;
	}
	
	int fd = open(argv[1], O_RDONLY, 0);
	if(fd < 0)
	{
		cout << "open fail " << strerror(errno) << endl;
		return 0;
	}

	char buff[1024];
	int ret = 0;
	do
	{
		int ret = read(fd, buff, sizeof(buff));
		if(ret < 0)
		{
			cout << "read fail" << endl;
			break;
		}
		
		cout << CBinaryUtil::bin_hex(buff, ret) << endl;
		
	}while(ret == sizeof(buff));

	close(fd);	
	return 0;
}

