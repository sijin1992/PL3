#include "../random.h"
#include <iostream>
#include <string.h>
using namespace std;

void test(CRandom& the, unsigned int times, unsigned int slots)
{
	unsigned int *results = new unsigned int [slots];
	memset(results, 0x0, sizeof(unsigned int)*slots);

	unsigned int i;
	for( i=0; i<times; ++i)
	{
		results[the.range(the.rand(), slots-1)]++;
	}

	cout << "times:" << times << endl;
	for( i=0; i<slots; ++i)
	{
		cout << "slots[" << i << "]:" << results[i] << endl;
	}

	delete[] results;
}

int main(int argc, char** argv)
{
	CRandom theRand;
	CRandom theRand1;

	cout << "sys rand:" << CRandom::sys_rand() << endl;

	cout << "rand first:" << theRand.rand() << endl;
	test(theRand, 10000, 100);

	cout << "myrand first:" << theRand1.myrand() << endl;
	test(theRand1, 10000, 100);

	theRand.seed(1);
	cout << "seed(1) rand():" << theRand.rand() << endl;
	test(theRand, 10000, 100);

	vector<unsigned int> weights;
	weights.push_back(1);
	weights.push_back(2);
	weights.push_back(3);
	weights.push_back(4);

	cout << "select idx from weights(1,2,3,4)" << endl;
	unsigned int idx = 0;
	for(unsigned int i=0; i<100; ++i)
	{
		theRand1.select(weights, idx);
		cout << "selected:" << idx << endl;
	}


	vector<unsigned int> selectedIdxes;

	cout << "select 2 idxes from weights(1,2,3,4)" << endl;
	for(unsigned int i=0; i<100; ++i)
	{
		selectedIdxes.clear();
		theRand1.select(weights, 2, selectedIdxes);
		cout << "selected:" << selectedIdxes[0] << " " << selectedIdxes[1] << endl;
	}
	
	cout << "select 4 idxes from weights(1,2,3,4)" << endl;
	theRand1.select(weights, 4, selectedIdxes);
	cout << "selected:" << selectedIdxes[0] << " " << selectedIdxes[1] << " " << selectedIdxes[2]<< " " << selectedIdxes[2] << endl;

	cout << "draw one in (20,30)" << endl;
	vector<unsigned int> probabilities;
	probabilities.push_back(20);
	probabilities.push_back(30);
	
	int selectNum;

	for(unsigned int i=0; i<100; ++i)
	{
		selectNum = theRand1.draw(probabilities, idx);
		if(selectNum > 0)
		{
			cout << idx;
		}
		else
		{
			cout << "none";
		}
		cout << endl;
	}

	cout << "draw in (20,30)" << endl;
	for(unsigned int i=0; i<100; ++i)
	{
		selectedIdxes.clear();
		selectNum = theRand1.draw(probabilities, selectedIdxes);
		if(selectNum > 0)
		{
			for(int j=0; j< selectNum; ++j)
				cout << selectedIdxes[j] << " ";
		}
		else
		{
			cout << "none";
		}
		cout << endl;
	}


	return 0;
}

