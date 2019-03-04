#include "../time_util.h"
#include <iostream>
#include <string.h>
using namespace std;

int main(int argc, char** argv)
{
	time_t nt = time(NULL);
	string nows = CTimeUtil::TimeString(nt) ;
	cout << "time " << nt << endl;
	cout << "now is " << nows << endl;
	cout << "value is " << CTimeUtil::FromTimeString(nows.c_str()) << endl;
	

	cout << "DayFrom2010=" << CTimeUtil::DayFrom2010(nt) << endl;
	cout << "UniqDay=" << CTimeUtil::UniqDay(nt) << endl;
	cout << "BetweenTime(2011-05-10 15:00:00, 2011-05-10 15:30:00) " << CTimeUtil::BetweenTime("2011-05-10 15:00:00", "2011-05-10 15:30:00") << endl;
	int daydiff = 0;
	if(CTimeUtil::DayDiff(&daydiff, "2011-05-10") == 0)
		cout <<  "DayDiff(2011-05-10)" << daydiff << endl;
	if(CTimeUtil::DayDiff(&daydiff, "2011-04-10") == 0)
		cout <<  "DayDiff(2011-04-10)" << daydiff << endl;
	if(CTimeUtil::DayDiff(&daydiff, "2011-06-10") == 0)
		cout <<  "DayDiff(2011-06-10)" << daydiff << endl;


	return 0;
}

