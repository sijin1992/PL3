#ifndef __TIME_UTIL_H__
#define __TIME_UTIL_H__
//create by marszhang

#include <time.h>
#include <string>
#include <sys/time.h>

using namespace std;

//是否超过时间段（秒）, tv1,tv2是timeval
//tv1-tv2>=intervalS
#define TIMEVAL_SECOND_INTERVAL_PASSED(tv1, tv2, intervalS) ((tv1).tv_sec > (tv2).tv_sec+(intervalS) || ( (tv1).tv_sec == (tv2).tv_sec+(intervalS) && (tv1).tv_usec >= (tv2).tv_usec ))

class  CTimeUtil
{
public:
	//从2010到现在经过的天数
	static unsigned int DayFrom2010(time_t tTheDay);

	//根据time_t获得一个唯一的天数
	static unsigned short UniqDay(time_t t);

	
	//函数说明: 判断某个时间是否在两个时间点之间
	//函数返回: 0不在活动时间内  <0 错误  >0在活动时间内
	//函数参数: 前两个参数表示开始和结束时间，最后一个参数代表需要比较的时间,默认为0指当前时间
	//			szActBegin和szActEnd的形式如此: %Y-%m-%d %H:%M:%S 如2010-01-28 11:24:00
	static int	 BetweenTime(const char*  szActBegin, const char* szActEnd, time_t  timeNow = 0);

	//szTheDay 是精确到天的字符串表示 %Y-%m-%d 如 "2011-02-24"
	//timeNow默认是当前时间time(NULL),也可以输入
	//*pdaydiff 返回当前时间过几天到目标时间
	//比如szTheDay="2011-02-24"
	//如果现在是 2011-02-23的任意时刻， 那么返回1
	//如果现在是 2011-02-24的任意时刻， 那么返回0
	//如果现在是 2011-02-25的任意时刻， 那么返回-1
	//返回值 0=ok， -1=szTheDay时间格式有误
	static int DayDiff(int* pdaydiff,const char* szTheDay, time_t  timeNow = 0);

	//获取相隔的星期
	static int WeekDiff(time_t lastTime, time_t nowTime);

	//获取相隔的天数
	static int DayDiff(time_t lastTime, time_t nowTime);

	static string TimeString(time_t tTime);

	static string TimeString(struct timeval stTime);

	static time_t FromTimeString(const char *pszTimeStr);

	//明天0点的时间秒
	static time_t NextDayTime(time_t nowTime);

	//当前中国星期一0点的时间
	static time_t CurCnWeekTime(time_t nowTime);

	//当前中国当月月一号的时间
	static time_t CurCnMonthTime(time_t nowTime);

};

#endif
