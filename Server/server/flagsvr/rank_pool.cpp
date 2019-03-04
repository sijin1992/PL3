#include "rank_pool.h"

int qsort_callback_biger(const void * pa, const void * pb)
{
	RANK_UNIT* a = (RANK_UNIT*)pa;
	RANK_UNIT* b = (RANK_UNIT*)pb;
	if(a->key > b->key)
		return -1;
	else if(a->key < b->key)
		return 1;
	else
	{
		if(a->thetime.tv_sec < b->thetime.tv_sec
			|| (a->thetime.tv_sec == b->thetime.tv_sec && a->thetime.tv_usec < b->thetime.tv_usec))
			return -1;
		else
			return 1;
	}
}

int qsort_callback_smaller(const void * pa, const void * pb)
{
	RANK_UNIT* a = (RANK_UNIT*)pa;
	RANK_UNIT* b = (RANK_UNIT*)pb;
	if(a->key < b->key)
		return -1;
	else if(a->key > b->key)
		return 1;
	else
	{
		if(a->thetime.tv_sec < b->thetime.tv_sec
			|| (a->thetime.tv_sec == b->thetime.tv_sec && a->thetime.tv_usec < b->thetime.tv_usec))
			return -1;
		else
			return 1;
	}
}

