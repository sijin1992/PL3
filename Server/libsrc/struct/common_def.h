#ifndef __COMMON_DEF_H__
#define __COMMON_DEF_H__

#define PRINTF_FORMAT_FOR_SIZE_T "%lu"

struct ERROR_INFO
{
	char errstrmsg[256];
	int errcode;
	ERROR_INFO()
	{
		errstrmsg[0] = 0;
		errcode = 0;
	}
};

#endif

