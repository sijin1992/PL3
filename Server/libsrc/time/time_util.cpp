#include "time_util.h"
#include <string.h>
#include <stdio.h>
unsigned int CTimeUtil::DayFrom2010(time_t tTheDay)
{
	tm BASE_TIME_T; //2010-1-1 00:00:00
	memset((char*)&BASE_TIME_T, 0, sizeof(BASE_TIME_T));
	BASE_TIME_T.tm_sec = 0;
	BASE_TIME_T.tm_min = 0;
	BASE_TIME_T.tm_hour = 0;
	BASE_TIME_T.tm_mday = 1;
	BASE_TIME_T.tm_mon = 1-1; //0-11
	BASE_TIME_T.tm_year = 2010 -1900;
	BASE_TIME_T.tm_isdst = 0; //不要夏令时
	time_t tBase = mktime(&BASE_TIME_T);
	return (tTheDay>tBase)?(tTheDay-tBase)/86400:0;
}

unsigned short CTimeUtil::UniqDay(time_t t)
{
    struct tm tm;
    localtime_r(&t,&tm);

    return (tm.tm_year-110)*1000 + tm.tm_yday;
}


//add by kevin at 2010-01-28
//函数说明: 判断某个时间是否在两个时间点之间
//函数返回: 0不在活动时间内  <0 错误  >0在活动时间内
//函数参数: 前两个参数表示开始和结束时间，最后一个参数代表需要比较的时间,默认为0指当前时间
//			szActBegin和szActEnd的形式如此: %Y-%m-%d %H:%M:%S 如2010-01-28 11:24:00
int	 CTimeUtil::BetweenTime(const char*  szActBegin, const char* szActEnd, time_t  timeNow /*= 0*/)
{
	if(szActBegin == NULL || szActEnd == NULL)
	{
		return -1;
	}

	struct tm  act_time;
	time_t	now =  (timeNow == 0 ? time(NULL) : timeNow );		
	
	time_t   act_beg, act_end;
	
	if(NULL == strptime(szActBegin,"%Y-%m-%d %H:%M:%S",&act_time))
	{
		return -2;
	}
	act_beg = mktime(&act_time);

	
	if(NULL == strptime(szActEnd,"%Y-%m-%d %H:%M:%S",&act_time))
	{
		return -3;
	}
	act_end = mktime(&act_time);

	
	//查看是否在活动时间内
	if(now>act_beg  && now < act_end)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

//add by marszhang at 2011-02-23
//判断日期间的天数差
//szFrom和szTo%Y-%m-%d 如2010-01-28
//szTo 可以默认为当前时间
int CTimeUtil::DayDiff(int* pdaydiff,const char* szTheDay, time_t  timeNow /*= 0*/)
{
	struct tm now,theday;
	time_t t_tmp,t_now,t_theday;
	memset(&now, 0 ,sizeof(now));
	memset(&theday, 0 ,sizeof(theday));
	if(strptime(szTheDay, "%Y-%m-%d", &theday) == NULL)
	{
		return -1;
	}
	t_theday = mktime(&theday);
	
	if(timeNow == 0)
	{
		t_tmp = time(NULL);
	}
	else
	{
		t_tmp = timeNow;
	}

	//对齐时间
	localtime_r(&t_tmp, &now);
	now.tm_sec = 0;
	now.tm_min = 0;
	now.tm_hour = 0;
	t_now = mktime(&now);


	if(t_theday >= t_now)
	{
		*pdaydiff = (t_theday - t_now)/(24*3600);
	}
	else
	{
		*pdaydiff = 0-(t_now - t_theday)/(24*3600);
	}

	return 0;
}


int CTimeUtil::WeekDiff(time_t lastTime, time_t nowTime)
{
	return (CurCnWeekTime(nowTime) - CurCnWeekTime(lastTime)) / (86400 * 7);
}

int CTimeUtil::DayDiff(time_t lastTime, time_t nowTime)
{
	return (NextDayTime(nowTime) - NextDayTime(lastTime)) / 86400;
}

time_t CTimeUtil::FromTimeString(const char *pszTimeStr)
{
	struct tm stTime;
	memset(&stTime, 0, sizeof(stTime));
	strptime(pszTimeStr, "%Y-%m-%d %H:%M:%S", &stTime);
	return mktime(&stTime);
}

string CTimeUtil::TimeString(time_t tTime)
{
	char szTimeStringBuff[32];
	memset(szTimeStringBuff,0,sizeof(szTimeStringBuff));
	struct tm * ptm = localtime(&tTime);
	strftime(szTimeStringBuff, sizeof(szTimeStringBuff), "%Y-%m-%d %H:%M:%S", ptm);

	return szTimeStringBuff;
}

string CTimeUtil::TimeString(struct timeval stTime)
{
	//允许最多20个参数
	char szTimeStringBuff[32];
	struct tm * ptm = localtime(&stTime.tv_sec);
	int year = 1900 + ptm->tm_year; //从1900年开始的年数
	int month = ptm->tm_mon + 1; //从0开始的月数
	int day = ptm->tm_mday; //从1开始的天数
	int hour = ptm->tm_hour; //从0开始的小时数
	int min = ptm->tm_min; //从0开始的分钟数
	int sec = ptm->tm_sec; //从0开始的秒数

	snprintf(szTimeStringBuff, sizeof(szTimeStringBuff), "%04d-%02d-%02d %02d:%02d:%02d.%06ld", year, month, day, hour, min, sec, stTime.tv_usec);

	return szTimeStringBuff;
}

time_t CTimeUtil::NextDayTime(time_t nowTime)
{
	struct tm* ptm = localtime(&nowTime);
	ptm->tm_hour = 0;
	ptm->tm_min = 0;
	ptm->tm_sec = 0;
	return mktime(ptm)+86400;
}

time_t CTimeUtil::CurCnWeekTime(time_t nowTime)
{
	struct tm* ptm = localtime(&nowTime);
	int wkDay = ptm->tm_wday;
	ptm->tm_hour = 0;
	ptm->tm_min = 0;
	ptm->tm_sec = 0;
	time_t newTime = mktime(ptm);
	//如果是礼拜天，往前推一个礼拜
	if( wkDay == 0 )
	{
		wkDay = 7;
	}
	newTime -= 86400 * (wkDay -1);
	return newTime;
}


//当前中国当月月一号的时间
time_t CTimeUtil::CurCnMonthTime(time_t nowTime)
{
	struct tm* ptm = localtime(&nowTime);
	int mDay = ptm->tm_mday;
	ptm->tm_hour = 0;
	ptm->tm_min = 0;
	ptm->tm_sec = 0;
	time_t newTime = mktime(ptm);
	newTime -= 86400 * (mDay -1);
	return newTime;
}

