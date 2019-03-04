#include "../fixedsize_allocator.h" 
#include <iostream>
#include <sstream>

using namespace std;


class CMyVisitor: public CFixedsizeAllocator::CNodeVisitor
{
	public:
		CMyVisitor():count(0),po(&cout) {}
		virtual int visit(void* p, int idx, unsigned int size) 
		{
			++count;
			(*po) << "visit idx(" << idx << ")" << endl;
			return RET_CONTINUE;
		}

		void set_output(ostream *p)
		{
			po = p;
		}
		
		int count;
		ostream* po;
};

int main(int argc , char** argv)
{
	CFixedsizeAllocator alloc, alloc1;
	CFixedsizeAllocator::CNodeInfo nodeinfo(3, 10);

	MEMSIZE size = alloc.calculate_size(nodeinfo);

	cout << "calculate_size({3,10}) = " << size << endl;

	void* pointer;
	int idx, idx1;

	int ret = alloc.alloc(pointer);
	cout << "alloc before bind: ret = " << ret << endl;

	ret = alloc.free(idx);
	cout << "free before bind: ret = " << ret << endl;

	char* pstart = new char[size];

	ret = alloc.bind(pstart, size, nodeinfo);
	cout << "bind not format: ret = " << ret << endl;

	ret = alloc.bind(pstart, size, nodeinfo, true);
	cout << "bind format: ret = " << ret << endl;


	if(ret == CFixedsizeAllocator::SUCCESS)
	{
		alloc.dump(cout);

		ret = alloc.bind(pstart, size, nodeinfo);
		cout << "bind twice: ret = " << ret << endl;

		ret = alloc.alloc(pointer);
		cout << "alloc pointer: ret = " << ret << endl;
		alloc.dump(cout);

		ret = alloc.alloc(idx);
		cout << "alloc idx: ret = " << ret << endl;

		alloc.dump(cout);

		ret = alloc.alloc(idx1);
		cout << "alloc idx1: ret = " << ret << endl;

		ret = alloc.free(idx1);
		cout << "free idx1: ret = " << ret << endl;

		alloc.dump(cout);

		ret = alloc.free(idx);
		cout << "free idx: ret = " << ret << endl;

		alloc.dump(cout);

		ret = alloc.free((char*)pointer-1);
		cout << "free wrong point: ret = " << ret << endl;

		ret = alloc.free(pointer);
		cout << "free point: ret = " << ret << endl;

		alloc.dump(cout);

		ret = alloc.free(pointer);
		cout << "free point again: ret = " << ret << endl;

		alloc.dump(cout);

	}


	ret = alloc1.bind(pstart, size-2, nodeinfo);
	cout << "new bind not format with small size: ret = " << ret << endl;

	nodeinfo.uiSize = 1;
	ret = alloc1.bind(pstart, size-2,nodeinfo);
	cout << "new bind not format with wrong info: ret = " << ret << endl;

	nodeinfo.uiSize = 0;
	ret = alloc1.bind(pstart, size, nodeinfo);
	cout << "new bind not format: ret = " << ret << endl;
 	alloc.dump(cout);


	ret = alloc.alloc(idx);
	cout << "new alloc idx: ret = " << ret << endl;
	alloc.dump(cout);

 	CMyVisitor  ovisitor;
 	ovisitor.set_output(&cout);
 	alloc1.for_each_usednode(&ovisitor);
 	cout << "visited " << ovisitor.count << " total" << endl;


	ret = alloc.free(idx);
	cout << "new free idx: ret = " << ret << endl;
	alloc.dump(cout);
	
	delete[] pstart;
	
	return 0;
}

