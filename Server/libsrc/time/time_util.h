#ifndef __TIME_UTIL_H__
#define __TIME_UTIL_H__
//create by marszhang

#include <time.h>
#include <string>
#include <sys/time.h>

using namespace std;

//�Ƿ񳬹�ʱ��Σ��룩, tv1,tv2��timeval
//tv1-tv2>=intervalS
#define TIMEVAL_SECOND_INTERVAL_PASSED(tv1, tv2, intervalS) ((tv1).tv_sec > (tv2).tv_sec+(intervalS) || ( (tv1).tv_sec == (tv2).tv_sec+(intervalS) && (tv1).tv_usec >= (tv2).tv_usec ))

class  CTimeUtil
{
public:
	//��2010�����ھ���������
	static unsigned int DayFrom2010(time_t tTheDay);

	//����time_t���һ��Ψһ������
	static unsigned short UniqDay(time_t t);

	
	//����˵��: �ж�ĳ��ʱ���Ƿ�������ʱ���֮��
	//��������: 0���ڻʱ����  <0 ����  >0�ڻʱ����
	//��������: ǰ����������ʾ��ʼ�ͽ���ʱ�䣬���һ������������Ҫ�Ƚϵ�ʱ��,Ĭ��Ϊ0ָ��ǰʱ��
	//			szActBegin��szActEnd����ʽ���: %Y-%m-%d %H:%M:%S ��2010-01-28 11:24:00
	static int	 BetweenTime(const char*  szActBegin, const char* szActEnd, time_t  timeNow = 0);

	//szTheDay �Ǿ�ȷ������ַ�����ʾ %Y-%m-%d �� "2011-02-24"
	//timeNowĬ���ǵ�ǰʱ��time(NULL),Ҳ��������
	//*pdaydiff ���ص�ǰʱ������쵽Ŀ��ʱ��
	//����szTheDay="2011-02-24"
	//��������� 2011-02-23������ʱ�̣� ��ô����1
	//��������� 2011-02-24������ʱ�̣� ��ô����0
	//��������� 2011-02-25������ʱ�̣� ��ô����-1
	//����ֵ 0=ok�� -1=szTheDayʱ���ʽ����
	static int DayDiff(int* pdaydiff,const char* szTheDay, time_t  timeNow = 0);

	//��ȡ���������
	static int WeekDiff(time_t lastTime, time_t nowTime);

	//��ȡ���������
	static int DayDiff(time_t lastTime, time_t nowTime);

	static string TimeString(time_t tTime);

	static string TimeString(struct timeval stTime);

	static time_t FromTimeString(const char *pszTimeStr);

	//����0���ʱ����
	static time_t NextDayTime(time_t nowTime);

	//��ǰ�й�����һ0���ʱ��
	static time_t CurCnWeekTime(time_t nowTime);

	//��ǰ�й�������һ�ŵ�ʱ��
	static time_t CurCnMonthTime(time_t nowTime);

};

#endif
