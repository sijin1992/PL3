#include "../common/bin_protocol.h"
#include <iostream>
#include <sstream>
#include <fstream>
#include "proto/CmdLogin.pb.h"
using namespace std;

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		cout << argv[0] << " outputfile" << endl;
		return 0;
	}

	ofstream out(argv[1]);
	if(!out.good())
	{
		cout << "open " << argv[1] << " fail" << endl;
		return 0;
	}

	RegistReq req;
	req.set_rolename("mars");
	req.set_cardid(13);
	char buff[1024];
	CBinProtocol binpro;
	binpro.bind(buff, sizeof(buff));

	if(!req.SerializeToArray(binpro.packet(), binpro.packet_len()) )
	{
		cout << "SerializeToArray fail" << endl;
		return 0;
	}

	int len = binpro.total_len(req.GetCachedSize());

	string userstr = "1234567890123456";
	USER_NAME user;
	user.from_str(userstr);
	binpro.head()->format(user, CMD_REGIST_REQ, len);

	out.write(buff, len);

	out.close();

	return 1;
}


