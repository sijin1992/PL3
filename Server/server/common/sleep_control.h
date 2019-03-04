#ifndef __SLEEP_CONTROL_H__
#define __SLEEP_CONTROL_H__

#include <unistd.h>

class CSleepControl
{
	public:
		/**
		* �����߼����£������л���ֵsleep_base, work���� �Ѿ������Ĵ������ڳ���rate_per_work��ÿ�ι�����sleep��ʱ��ó�ʵ��sleepʱ��
		* ������ʹ���֮��ģ�ͨ������delay֪ͨ��delay_max��delayʱ�佫��ͣ����ֱ��delay max
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
	 	* @summary: ���ӹ����˼���ѭ��
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
	 	* @summary: ִ��˯�ߣ�˯��0-sleep_max ΢��
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
					//����˯�ˣ������ɻ�
				}
				else
				{
					usleep(sleep_base-work_total*sleep_rate_per_work);
				}
			}
			
			work_total = 0;
	 	}

	 	/*
	 	* @summary: �趨����
	 	* @param:max ���˯��ʱ��us(΢��)
	 	* @param:rate_per_work work valueÿ����1�����ٵ�˯��ʱ��us(΢��)
	 	*/
		inline void setparam(int base, int rate_per_work, int delay_max)
		{
			sleep_base = base;
			sleep_rate_per_work = rate_per_work;
			sleep_delay_max = delay_max;
		}
		
	protected:
		int work_total;
		//Ӧ���ǿ������õ�
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

