#include "broadcast_manager.h"
#include "log/log.h"

#include <string.h>

extern unsigned int gDebugFlag;

CBroadcastManager::CBroadcastManager()
{
	mMaxUserPerBC = 100;
}

CBroadcastManager::~CBroadcastManager()
{
	BroadcastList::iterator it = mBroadcastList.begin();
	BroadcastList::iterator itEnd = mBroadcastList.end();
	while( it != itEnd )
	{
		BroadcastInfo &pBroad = *it;
		it++;
		delete[] pBroad.buff;
	}
	mBroadcastList.clear();
}

void CBroadcastManager::setMaxUserPerBC(int maxUserPerBC)
{
	mMaxUserPerBC = maxUserPerBC;
}

void CBroadcastManager::addBroadcast( const char *buff, size_t len, int flag)
{
	if(len > 0)
	{
		char *t_buff = new char[len];
		memcpy(t_buff, buff, len);
		BroadcastInfo broadcast;
		broadcast.cur_idx = -1;
		broadcast.buff = t_buff;
		broadcast.len = len;
		broadcast.flag = flag;
		mBroadcastList.push_back(broadcast);
	}
}

bool CBroadcastManager::needBroadcast()
{
	return mBroadcastList.size() > 0;
}

int CBroadcastManager::doBroadcast( CEpollWrap *pEpoll, int proArg /*= 0*/ )
{
	if( !needBroadcast() )
	{
		LOG(LOG_DEBUG, "NOT need Broadcast");
		return -1;
	}
	if( NULL == pEpoll )
	{
		LOG(LOG_DEBUG, "NULL == pEpoll");
		return -1;
	}
	BroadcastInfo &broadcast = mBroadcastList.front();

	if( broadcast.cur_idx == -1 )
	{
		broadcast.cur_idx = 0;
		broadcast.fds.clear();
		broadcast.sessions.clear();
		FDInfoMap &fdMap = pEpoll->getmap();
		FDInfoMap::iterator it = fdMap.begin();
		FDInfoMap::iterator itEnd = fdMap.end();
		while( it != itEnd )
		{
			FDInfo &fdInfo = it->second;
			it++;
			if( fdInfo.type == CEpollWrap::TYPE_LISTEN )
			{
				continue;
			}
			int fd = fdInfo.fd;
			unsigned long long session = fdInfo.sessionID.id;
			broadcast.fds.push_back(fd);
			broadcast.sessions.push_back(session);
		}
	}
	
	if( broadcast.cur_idx >= 0 )
	{
		int curIdx = broadcast.cur_idx;
		int fdNum = broadcast.fds.size();
		int sessionNum = broadcast.sessions.size();
		if( fdNum != sessionNum )
		{
			LOG(LOG_ERROR, "fdNum:%d != sessionNum:%d", fdNum, sessionNum);
			return -1;
		}
		if( fdNum - curIdx > mMaxUserPerBC ) //超过最大广播量
		{
			fdNum = mMaxUserPerBC + curIdx;
		}
		if( sessionNum - curIdx > mMaxUserPerBC ) //超过最大广播量
		{
			sessionNum = mMaxUserPerBC + curIdx;
		}
		if( fdNum != sessionNum )
		{
			LOG(LOG_ERROR, "fdNum2:%d != sessionNum2:%d", fdNum, sessionNum);
			return -1;
		}
		if( fdNum <= curIdx )
		{
			//LOG(LOG_ERROR, "fdNum:%d <= curIdx:%d, end", fdNum, curIdx);
			delete[] broadcast.buff;
			mBroadcastList.pop_front();
			return 0;
		}
		for(int i = curIdx; i < fdNum; ++i)
		{
			int ret = pEpoll->write_packet(broadcast.fds[i], broadcast.sessions[i],
				broadcast.buff, broadcast.len);

			if(ret != 0)
			{
				LOG(LOG_ERROR,"m_pepoll->write_packet %d %s", ret, pEpoll->errmsg());
				continue;
			}
		}
		broadcast.cur_idx = fdNum;
	}
	return 0;
}

