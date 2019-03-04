#ifndef LOGIC_INFO_H_
#define LOGIC_INFO_H_
#include <string>

struct logic_info
{
	std::string ip;
	int port;
	std::string version;
	std::vector<int> idx_list;
	std::vector<std::string> centre_ip_list;
	std::vector<int> centre_port_list;
	int max_client;
	int unrecharge;
	int anti_cdkey;
	int anti_weichat;
	std::string global_httpcb_ip;
	int global_httpcb_port;
	std::string global_httpcb_ip_2;
	int global_httpcb_port_2;
	int cb_port;
	int max_reg;
    int cur_reg;
	std::vector<std::string> old_versions;
};

extern logic_info g_logic_info;

#endif // LOGIC_INFO_H_
