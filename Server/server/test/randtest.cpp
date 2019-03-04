#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>

void printval(int* count, int base)
{
	int max=0; 
	int min=base;
	long long total = 0;
	
	for(int i=0; i< base; ++i)
	{
		if(count[i] > max)
			max = count[i];

		if(count[i] < min)
			min = count[i];
			
		//printf("%d %d\r\n", i, count[i]);

		total += count[i];
	}

	
	double average = 0;
	double variance=0;
	if(base > 0)
	{
		average = total/double(base);

		for(int i=0; i< base; ++i)
		{
			variance += pow(count[i]-average,2);
		}
		
		variance /= base;
	}
	
	printf("max=%d min=%d variance=%e\r\n", max, min, variance);
}

int main(int argc, char** argv)
{
	int base = 100;
	if(argc > 1)
		base = atoi(argv[1]);


	int* count = new int[base];
	memset(count, 0, sizeof(int)*base);

	srand(time(NULL));

	//·Ö²¼
	for(int i=0; i<base*100; ++i)
	{
		++count[rand()%base];
	}

	printval(count, base);
	
	memset(count, 0, sizeof(int)*base);

	for(int i=0; i<base*100; ++i)
	{
		++count[(rand()%(base*10))/10];
	}

	printval(count, base);
		
	return 0;
}

