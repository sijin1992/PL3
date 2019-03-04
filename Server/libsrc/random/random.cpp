#include "random.h"
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>
#include <list>

CRandom::CRandom()
{
	m_bmyrand = false;
	seed();
}

void CRandom::seed(unsigned int v)
{
	if( v==0)
	{
		struct timeval tpstime;
		gettimeofday(&tpstime,NULL);
		m_uiSeed = (getpid() << 16) + (tpstime.tv_usec & 0xFFFF);
	}
	else
		m_uiSeed = v;
}

unsigned int CRandom::sys_rand()
{
	return ::rand();
}

unsigned int CRandom::rand()
{
	return rand_r(&m_uiSeed);
}


unsigned int CRandom::myrand()
{
	m_uiSeed = m_uiSeed * 1103515245 + 12345;
	return((unsigned)(m_uiSeed/65536) % 32768);
}

void CRandom::use_myrand(bool b)
{
	m_bmyrand = b;
}

unsigned int CRandom::range(unsigned int randv, unsigned int max, unsigned int min)
{
	if(max <= min)
	{
		return min;
	}

	return min + (int) ((max-min+1) * (randv/(RAND_MAX + 1.0)));
}

int CRandom::select(vector<unsigned int>& weights, unsigned int n, vector<unsigned int>& selected_idxes)
{
	//初始化
	selected_idxes.clear();
	unsigned int total = 0;
	unsigned int size = weights.size();
	list<unsigned int> left_idxes;
	list<unsigned int>::iterator leftIt;
	if(n >= size)
	{
		//oh shit
		for(unsigned int i=0;i<size; ++i)
		{
			selected_idxes.push_back(i);
		}

		return size;
	}

	for(unsigned int i=0;i<size; ++i)
	{
		left_idxes.push_back(i);
	}

	for(unsigned int j=0; j<n; ++j)
	{
		total = 0;
		unsigned int randv = 0;
		for(leftIt = left_idxes.begin(); leftIt != left_idxes.end(); ++leftIt)
		{
			total += weights[*leftIt];
		}

		if(total == 0)  //有问题的
			break;

		if(m_bmyrand)
		{
			randv = range(myrand(), total-1);
		}
		else
		{
			randv = range(rand_r(&m_uiSeed), total-1);
		}
		
		for(leftIt = left_idxes.begin(); leftIt != left_idxes.end(); ++leftIt)
		{
			if(randv < weights[*leftIt])
			{
				selected_idxes.push_back(*leftIt); //返回一个
				break;	
			}

			randv -= weights[*leftIt];
		}

		if(leftIt != left_idxes.end()) //必须的
		{
			left_idxes.erase(leftIt);
		}
		else
		{
			break; //应该走不到这里
		}
	}
	return selected_idxes.size();
}

int CRandom::select(vector<unsigned int>& weights, unsigned int& selected_idx)
{
	unsigned int total = 0;
	unsigned int size = weights.size();
	for(unsigned int i=0;i<size; ++i)
	{
		total += weights[i];
	}
	
	unsigned int randv = 0;
	if(m_bmyrand)
	{
		randv = range(myrand(), total-1);
	}
	else
	{
		randv = range(rand_r(&m_uiSeed), total-1);
	}

	for(unsigned int i=0;i<size; ++i)
	{
		if(randv < weights[i])
		{
			selected_idx = i;
			return 1;
		}

		randv -= weights[i];
	}

	return 0;
}

int CRandom::draw(vector<unsigned int>& probabilities, unsigned int& selected_idx, unsigned int pro_unit)
{
	unsigned int randv = 0;
	if(m_bmyrand)
	{
		randv = range(myrand(), pro_unit-1);
	}
	else
	{
		randv = range(rand_r(&m_uiSeed), pro_unit-1);
	}

	for(unsigned int i=0;i<probabilities.size(); ++i)
	{
		if(randv < probabilities[i])
		{
			selected_idx = i;
			return 1;
		}
		
		randv -= probabilities[i];
	}

	return 0;
}

int CRandom::draw(vector<unsigned int>& probabilities, vector<unsigned int>& selected_idxes, unsigned int pro_unit, unsigned int limit)
{
	unsigned int randv = 0;
	unsigned int num = 0;
	selected_idxes.clear();
	for(unsigned int i=0;i<probabilities.size() && (limit==0 || num < limit); ++i)
	{
		if(m_bmyrand)
		{
			randv = range(myrand(), pro_unit-1);
		}
		else
		{
			randv = range(rand_r(&m_uiSeed), pro_unit-1);
		}

		if(randv < probabilities[i])
		{
			selected_idxes.push_back(i);
			++num;
		}
	}

	return num;
}


