#ifndef __SLEEP_CONTROL_H__
#define __SLEEP_CONTROL_H__

#include <unistd.h>

class CSleepControl
{
	public:
		/**
		* 控制逻辑如下，首先有基础值sleep_base, work设置 已经工作的次数，在乘以rate_per_work，每次工作少sleep的时间得出实际sleep时间
		* 如果发送错误之类的，通过调用delay通知，delay_max，delay时间将不停翻倍直到delay max
		*/
		
	 	CSleepControl()
		{
			work_total = 0;
			sleep_base = default_sleep_base;
			sleep_rate_per_work = default_sleep_rate_per_work;
			sleep_delay_now = 0;
			is_delay = 0;
			sleep_delay_max = default_delay_max;
		}

	 	/*
	 	* @summary: 增加工作了几个循环
	 	*/
	 	inline void work(int work_value)
		{
			work_total += work_value;
		}

		inline void delay()
		{
			is_delay = 1;
			if(sleep_delay_now == 0)
				sleep_delay_now = sleep_base;
			else
			{
				sleep_delay_now = sleep_delay_now*2;
				if(sleep_delay_now > sleep_delay_max)
				{
					sleep_delay_now = sleep_delay_max;
				}
			}
		}

		inline void cancel_delay()
		{
			is_delay = 0;
			sleep_delay_now = 0;
		}

	 	/*
	 	* @summary: 执行睡眠，睡眠0-sleep_max 微秒
	 	*/
		inline void sleep()
	 	{
			if(is_delay)
			{
				usleep(sleep_delay_now);
			}
			else
			{
				if(work_total*sleep_rate_per_work >= sleep_base)
				{
					//不用睡了，继续干活
				}
				else
				{
					usleep(sleep_base-work_total*sleep_rate_per_work);
				}
			}
			
			work_total = 0;
	 	}

	 	/*
	 	* @summary: 设定参数
	 	* @param:max 最长的睡眠时间us(微秒)
	 	* @param:rate_per_work work value每增加1，减少的睡眠时间us(微秒)
	 	*/
		inline void setparam(int base, int rate_per_work, int delay_max)
		{
			sleep_base = base;
			sleep_rate_per_work = rate_per_work;
			sleep_delay_max = delay_max;
		}
		
	protected:
		int work_total;
		//应该是可以配置的
		int sleep_base;
		int sleep_rate_per_work;
		int sleep_delay_now;
		int is_delay;
		int sleep_delay_max;

		static const int default_sleep_base = 1000;
		static const int default_sleep_rate_per_work = 50;
		static const int default_delay_max = 1000000;
};
	
#endif

