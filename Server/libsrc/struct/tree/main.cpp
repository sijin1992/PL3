#include "binarytree.h"
#include <iostream>
#include "visitor.h"

using namespace std;
using namespace marstree;



static void rand_fill_array(int* array, int size, int mod=0)
{
	for(int i=0; i<size; ++i)
	{
		if(mod)
			array[i] = rand()%mod;
		else
			array[i] = rand();
	}
}

static void output_array(int* array, int size)
{
	for(int i=0; i<size; ++i)
	{
		cout << array[i] <<  " ";
	}

	cout << endl;
}

int main(int argc, char** argv)
{
	srand(time(NULL));

#if 1
	#if 0
	CBinaryTree tree;
	CVisitorCout<CBinaryTree> visitor;
	#else
	CAVLTree tree;
	CVisitorCout<CAVLTree> visitor;
	#endif
	if(argc > 1)
	{
		for(int i=1; i<argc; ++i)
		{
			int val = atoi(argv[i]);
			cout << "insert(" << val << ")=" << tree.insert(val) << endl;
		}
	}
	else
	{
		for(int i=0; i<10; ++i)
		{
			int val = rand()%1000;
			cout << "insert(" << val << ")=" << tree.insert(val) << endl;
			visitor.clean();
			tree.for_each(visitor, NULL, 1);
			visitor.display();
			cout << endl << endl;
		}
	}

	//tree.for_each(visitor, NULL, 1);
	//visitor.display();


	int a;
	while(cin >> a)
	{
		if(tree.del(a)!=0)
		{
			cout << "fail" << endl;
			break;
		}
		visitor.clean();
		tree.for_each(visitor, NULL, 1);
		visitor.display();
	}
#else
	CVisitorCout<CBinaryTree> visitor;

	int aa[10];
	rand_fill_array(aa, 10, 1000);
	int ab[10] ;
	rand_fill_array(ab, 10, 1000);

	CHeap heap(21);
	cout << "make heap: ";
	output_array(aa, 10);
	heap.make_heap(aa, 10);
	visitor.showheap(heap.get_buff());
	cout << "insert: ";
	output_array(ab, 10);
	heap.insert(ab, 10);
	visitor.showheap(heap.get_buff());
	cout << "insert: " << ab[5] << endl;
	heap.insert(ab[5]);
	visitor.showheap(heap.get_buff());

#endif 

	
	return 0;
}

