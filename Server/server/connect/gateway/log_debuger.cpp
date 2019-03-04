#include "log_adapter.h"

int main(int argc, char** argv)
{
	if(argc < 4)
	{
		cout << "cmd=1 svrip openid openkey" << endl;
		cout << "cmd=2 svrip rawtext" << endl;
		cout << "cmd=3 svrip onlinenum" << endl;
		return -1;
	}

	int cmd = atoi(argv[1]);
	string thissvrip = argv[2];
	
	CQQLogAdapter loger;
	int debug = 1;
	LOG_CONFIG logconfig;
	logconfig.logPath = ".";
	logconfig.defaultModule = "logtool";
	LOG_CONFIG_SET(logconfig);
	LOG_OPEN_DEFAULT(NULL);
	
	int ret = loger.init(thissvrip, &debug);
	if(ret != 0)
	{
		cout << "init fail" << endl;
		return -1;
	}
	
	if(cmd == 1)
	{
		if(argc < 5)
		{
			return -1;
		}

		string openid = argv[3];
		string openkey = argv[4];

		ret = loger.regist_log(loger.get_svrip(), openid, openkey, "");
		if(ret != 0)
		{
			cout << "regist log fail" << endl;
//			return -1;
		}

		ret = loger.login_log(loger.get_svrip(), openid, openkey, 5);
		if(ret != 0)
		{
			cout << "login log fail" << endl;
//			return -1;
		}

		ret = loger.logout_log(loger.get_svrip(), openid, openkey, 1);
		if(ret != 0)
		{
			cout << "logout log fail" << endl;
//			return -1;
		}

		ret = loger.pay_log(loger.get_svrip(), openid, openkey, 110, 601, 1, 3,5);
		if(ret != 0)
		{
			cout << "pay_log fail" << endl;
//			return -1;
		}
	}
	else if(cmd == 2)
	{
		if(argc < 4)
			return -1;
			
		ostringstream os;
		os << argv[3];
		ret = loger.write_baselog(os);
		if(ret != 0)
		{
			cout << "write_baselog fail" << endl;
			return -1;
		}
	}
	else if(cmd == 3)
	{
		if(argc < 4)
		{
			cout << "cmd=3 svrip onlinenum" << endl;
			return -1;
		}
		ret = loger.stat_log(atoi(argv[3]), true);
		if(ret != 0)
		{
			cout << "logout log fail" << endl;
		}
		else
		{
			cout << "onlinenum=" << atoi(argv[3]) << endl;
		}
	}
	
	return 0;
}

