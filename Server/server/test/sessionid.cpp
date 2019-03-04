#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

typedef union tagUnSessionID
{
	unsigned long long id;
	struct
	{
		unsigned int ip;
		unsigned short port;
		unsigned short seq;
	}tcpaddr; 
}UN_SESSION_ID;

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		printf("%s sessionid\r\n", argv[0]);
		return -1;
	}

	UN_SESSION_ID se;
	se.id = strtoull(argv[1], NULL, 10);

	in_addr st;
	st.s_addr = se.tcpaddr.ip;

	printf(" ip=%s port=%d seq=%d\r\n",
		inet_ntoa(st), se.tcpaddr.port, se.tcpaddr.seq);
	
	return 0;
}

