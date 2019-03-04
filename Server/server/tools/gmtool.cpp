#include <stdlib.h>
#include <iostream>
#include <string>

#include <fstream>
#include <sstream>

using namespace std;

#ifdef USE_CURL
#include "net/curlwrap.h"


class MyCurl:public CCurlEasyWrap
{
public:
	char buff[512];
	int idx;

	MyCurl()
	{
		clear();
	}

	void clear()
	{
		idx = 0;
		buff[0] = '\0';
	}

	string done()
	{
		buff[idx] = '\0';
		return buff;
	}

	virtual int writeFunction(char* bufptr, size_t size, size_t nitems)
	{
		int retsize = size*nitems;
		for(int i=0;  i<retsize; ++i)
		{
			if(idx < sizeof(buff)-1)
			{
				buff[idx++] = bufptr[i];
			}
			else
			{
				cout << "buff too small" << endl;
				return 0;
			}
		}

		return retsize;
	}
};
#else
	#include "net/tcpwrap.h"
	#include "string/strutil.h"

	int send_and_recv(string host, string url, string& retstr)
	{
		string addr;
		unsigned short port;

		strutil::Tokenizer token(host, ":");
		if(token.nextToken())
		{
			addr = token.getToken();
		}
		else
		{
			cout << "host=" << host.c_str() << endl;
			return -1;
		}
					
		if(token.nextToken())
		{
			port = atoi(token.getToken().c_str());
		}
		else
		{
			port = 80; //д╛хо
		}
	
		CTcpClientSocket sock;
		if(sock.init() !=0)
		{
			cout << sock.errmsg() << endl;
			return -1;
		}

		sock.set_snd_timeout(1);

		sock.set_rcv_timeout(1);
		
		if(sock.connect(addr, port) != 0)
		{
			cout << "connect" << sock.errmsg() << endl;
			return -1;
		}

		char req[1024];
		int reqlen = snprintf(req, sizeof(req),
			"GET %s HTTP/1.1\r\n"
			"Host: %s\r\n\r\n"
			, url.c_str(), addr.c_str());

		if(sock.write(req,reqlen) < 0)
		{
			cout << "write" << sock.errmsg() << endl;
			return -1;
		}

		const int respmax = 4096;
		char resp[respmax];
		int readlen = sock.read(resp,respmax-1); 
		if(readlen < 0)
		{
			cout << "read" << sock.errmsg() << endl;
			return -1;
		}
		else if(readlen == 0)
		{
			cout << "read peer closed" << endl;
			return -1;
		}

		resp[readlen] = 0;

		char* headend = strstr(resp, "\r\n\r\n");
		if(headend == NULL)
		{
			cout << "head end not found" << endl;
			return -1;
		}
		headend += 4;

		retstr= headend;
		return 0;
	}


#endif

void trip_line(string& str)
{
        size_t pos = str.rfind('\r');
        if(pos != string::npos)
        	str = str.substr(0, pos);
        else
        {
        	pos = str.rfind('\n');
        	if(pos != string::npos)
        		str = str.substr(0,pos);
        }
        	
}

int main(int argc, char** argv)
{
	if(argc < 5)
	{
		cout << argv[0] << " gmuser password host userFile [defaultQueryStr]" << endl;
		return 0;
	}

	string gmuser = argv[1];
	string password = argv[2];
	string host = argv[3];
	string userFile = argv[4];
	string defaultQueryStr;

	if(argc > 5)
	{
		defaultQueryStr = argv[5];
	}

#ifdef USE_CURL
	MyCurl curl;
	if(curl.init()!=0)
	{
		cout << "curl init fail" << endl;
		return 0;
	}

	curl.maxConnects(1);
	curl.forbidReuse();
	curl.useWriteFunction();
#endif

	int linenum = 0;
	
	ifstream inf(userFile.c_str());
	if(!inf.good())
	{
		cout << "open input_file " << userFile << " fail" << endl;
		return 0;
	}

	while(true)
	{
		 string linestr;
	        getline(inf, linestr);
	        if(inf.eof())
	        {
	               break;
	        }
	        else if(inf.fail())
	        {
			cout << "linenum[" << linenum+1 << "] fail" << endl;
			break;
	        }
	        
	        trip_line(linestr);

		istringstream instr(linestr);
		string user;
		string queryStr;
		instr >> user;
		if(instr.fail())
		{
			cout << "linenum[" << linenum+1 << "](" << linestr << ") parse fail (user)" << endl;
			break;
		}
		
		instr >> queryStr;
		if(instr.fail())
		{
			//cout << "linenum[" << linenum+1 << "](" << linestr << ") parse fail " << endl;
			queryStr = defaultQueryStr;
		}
		
		++linenum;


#ifdef USE_CURL
		string desturl = "http://"+host + "/xxx?gmuser="+ gmuser +"&gmkey="+password+
			"&customuser="+user+"&"+queryStr;
			
		curl.clear();
	     	curl.setURL(desturl.c_str());

	     	if(curl.perform()!=0)
	     	{
	     		cout << "FAIL|" << user << "|" << queryStr << "|perform" << endl;
	     	}
	     	else
	 	{
	 		string ret = curl.done();
	 		if(ret == "" || atoi(ret.c_str())!=0)
	 		{
	 			cout << "FAIL|" << user << "|" << queryStr << "|" << ret << endl;
	 		}
	 		else
	 		{
	 			cout << "OK|" << user << "|" << queryStr << endl;
	 		}
	 	}
#else
		string desturl = "/xxx?gmuser=";
		desturl += gmuser +"&gmkey="+password+
			"&customuser="+user+"&"+queryStr;
		string retstr;
		if(send_and_recv(host, desturl, retstr)!=0)
		{
			cout << "FAIL|" << user << "|" << queryStr << "|perform" << endl;
		}
		else
		{
	 		if(retstr == "" || atoi(retstr.c_str())!=0)
	 		{
	 			cout << "FAIL|" << user << "|" << queryStr << "|" << retstr << endl;
	 		}
	 		else
	 		{
	 			cout << "OK|" << user << "|" << queryStr << endl;
	 		}
		}
#endif
	}

	return 0;
}

