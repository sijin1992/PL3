#include "../obj_pool.h"
#include <iostream>
#include <string.h>
using namespace std;

class CTestA
{
public:
	CTestA()
	{
		m_id = 0;
	}
public:
	int m_id;
};

class CTestB
{
public:
	CTestB()
	{
		m_id = 9;
	}
public:
	int m_id;
};

int main(int argc, char** argv)
{
	CObjPools::HANDLE handleA;
	CObjPools::HANDLE handleB;
	if(POOL_INIT(handleA, CTestA, 1) !=0)
	{
		cout << "init fail" << POOL_ERRMSG << endl;
		return 0;
	}

	if(!CHECK_HANDLE(handleA, CTestA))
	{
		cout << "handle not match class" << endl;
		return 0;
	}

	//应该ok
	CTestA* p = (CTestA*)POOL_ALLOC(handleA);
	if(p == NULL)
	{
		cout << "allocA fail " << POOL_ERRMSG << endl;
	}
	else
	{
		cout << "allocA ok" << endl;
		POOL_DEBUG(cout);
	}

	//应该错误
	CTestB* pb = POOL_ALLOC_CHECKED(handleA, CTestB);
	if(pb == NULL)
	{
		cout << "allocB fail " << POOL_ERRMSG << endl;
	}
	else
	{
		cout << "allocB ok" << endl;
	}

	//handleB没有初始化，应该错误
	pb = (CTestB*)POOL_ALLOC(handleB);
	if(pb == NULL)
	{
		cout << "allocB fail " << POOL_ERRMSG << endl;
	}
	else
	{
		cout << "allocB ok" << endl;
	}

	if(POOL_INIT(handleB, CTestB, 10) !=0)
	{
		cout << "init fail" << POOL_ERRMSG << endl;
		return 0;
	}

	//应该ok
	pb = (CTestB*)POOL_ALLOC(handleB);
	if(p == NULL)
	{
		cout << "allocB fail " << POOL_ERRMSG << endl;
	}
	else
	{
		cout << "allocB ok" << endl;
		POOL_DEBUG(cout);
	}

	//再申请下
	cout << "---------------------------------------------------" << endl;
	POOL_ALLOC(handleA);
	POOL_ALLOC(handleB);
	POOL_DEBUG(cout);

	//free
	cout << "---------------------------------------------------" << endl;
	POOL_FREE(handleA, p);
	POOL_FREE(handleB, pb);
	POOL_DEBUG(cout);

	cout << "---------------------------------------------------" << endl;
	//应该没有影响
	POOL_FREE(handleB, p);
	POOL_DEBUG(cout);

	cout << "---------------------------------------------------" << endl;
	POOL_ALLOC(handleA);
	POOL_DEBUG(cout);

	cout << "---------------------------------------------------" << endl;
	POOL_CLEAR(handleA);
	POOL_DEBUG(cout);

	cout << "---------------------------------------------------" << endl;
	if(POOL_ALLOC(handleA) == NULL)
	{
		cout << "alloc after clear " << POOL_ERRMSG << endl;
	}

	CTestB* b = new(POOL_ALLOC(handleB)) CTestB;
	cout << "placement new obj=" << b->m_id << endl;

	return 0;
}

