#include "../process_manager.h"
#include <iostream>
#include <string.h>
#include <unistd.h>
using namespace std;

class MyProcess:public CProcessManager
{
public:
	virtual int entity(int argc, char *argv[])
	{
		cout << "process " << getpid() << endl;
		sleep(100);
		return 0;
	}
};

int main(int argc, char** argv)
{
	cout << "default seting" << endl;
	
	MyProcess process;
	process.run(argc, argv);
	
	return 0;
}

