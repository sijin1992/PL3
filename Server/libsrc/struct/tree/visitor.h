#pragma once

#include "binarytree.h"
#include <iostream>
using namespace std;
using namespace marstree;

template<typename TREE_TYPE>
class CVisitorCout: public TREE_TYPE::CVisitor
{
public:
	static const int H_MAX=6;
	static const int W_MAX=32;
	
	CVisitorCout()
	{
		clean();
	}

	~CVisitorCout() {}

	void clean()
	{
		for(int i=0; i<H_MAX; ++i)
		{
			for(int j=0; j<W_MAX; ++j)
				show[i][j] = -1;
		}
		hmax = 0;
	}
		
	int callback(const TREE_TYPE* node, const TREE_TYPE* pnode, int h)
	{
		if(h == 1)
		{
			show[h-1][0] = node->val;
		}
		else if(h <= H_MAX)
		{
			int parentval = pnode->val;
			
			for(int i=0; i<wmax(h); ++i)
			{
				if(parentval == show[h-2][i])
				{
					if(pnode->left == node)
						show[h-1][2*i] = node->val;
					else
						show[h-1][2*i+1] = node->val;
				}
			}
		}

		if(hmax < h)
			hmax = h;
		return 0;
	}

	int showheap(const int* heap)
	{
		int last=1;
		int h=1;
		int size = heap[0];
		for(int i=1; i<=size; ++i)
		{
			if(i > last)
			{
				last = last*2+1;
				++h;
			}

			int row = i-last/2;

			if(h <= H_MAX && row <=W_MAX)
			{
				show[h-1][row-1] = heap[i];
			}
		}

		hmax=h;

		display();

		return 0;
	}

	int wmax(int h)
	{
		int ret = 1;
		for(int i=1; i<h; ++i)
		{
			ret *= 2;
		}

		return ret;
	}

	void display()
	{
		if(hmax > H_MAX)
			hmax = H_MAX;

		int startgap = 0;
		int nodegap = 4;
		for(int i=hmax; i>0; --i)
		{
			int j;
			if(i!=hmax)
			{
				startgap += nodegap/2;
				nodegap *= 2;
				
				coutsp(startgap);
				for(j=0; j<wmax(i); ++j)
				{
					cout << '|';
					coutsp(nodegap-1);
				}
				cout << endl;
			}

			coutsp(startgap);
			for(j=0; j<wmax(i); ++j)
			{
				if(show[i-1][j] < 0)
					coutsp(nodegap);
				else
				{
					int n = printf("%d", show[i-1][j]);
					coutsp(nodegap-n);
				}
			}

			cout << endl;

			if(i != 1)
			{
				coutsp(startgap);
				for(j=0; j<wmax(i); ++j)
				{
					cout << '|';
					coutsp(nodegap-1);
				}
				cout << endl;

				coutsp(startgap);
				for(j=0; j<wmax(i); ++j)
				{
					if(j%2==0)
						coutsp(nodegap+1, '-');
					else
						coutsp(nodegap-1);
				}
				cout << endl;
			}

		}
	}
protected:
	void coutsp(int w, char c=' ')
	{
		for(int i=0; i<w; ++i)
		{
			cout << c;
		}
	}

protected:
	int show[H_MAX][W_MAX];
	int hmax;
};

