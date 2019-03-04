#ifndef __MEM_GUARD_H__
#define __MEM_GUARD_H__
#include <vector>
using namespace std;

class CMemGuard
{
public:
	~CMemGuard()
	{
		del();
	}
	
	inline void add(char* p)
	{
		m_v.push_back(p);
	}

	inline void del()
	{
		for(unsigned int i=0; i<m_v.size(); ++i)
		{
			delete[] m_v[i];
		}

		m_v.clear();
	}
	
protected:
	vector<char*> m_v;
};

#endif

