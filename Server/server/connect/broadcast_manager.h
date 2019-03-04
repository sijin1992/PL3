#ifndef __BROADCAST_MANAGER_H__
#define __BROADCAST_MANAGER_H__

#include "net/epoll_wrap.h"
#include <list>
#include <vector>
typedef CEpollWrap::FDINFO_MAP_TYPE FDInfoMap;
typedef CEpollWrap::FDINFO FDInfo;

struct BroadcastInfo
{
	const char *buff;
	size_t len;
	int flag;
	std::vector<int> fds;
	std::vector<unsigned long long> sessions;
	int cur_idx;
};
typedef std::list<BroadcastInfo> BroadcastList;

class CBroadcastManager
{
public:
	CBroadcastManager();
	~CBroadcastManager();
	void setMaxUserPerBC(int maxUserPerBC);
	void addBroadcast(const char *buff, size_t len, int flag);
	bool needBroadcast();
	int doBroadcast(CEpollWrap *pEpoll, int proArg = 0);
protected:

private:
	int mMaxUserPerBC;
	BroadcastList mBroadcastList;
};

#endif
