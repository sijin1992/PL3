#pragma once

#include <stdlib.h>
#include <string.h>
#include <iostream>

namespace marstree
{
	class CBinaryTree
	{
		public:
			class CVisitor
			{
				public:
					virtual int callback(const CBinaryTree* node, const CBinaryTree* pnode, int h) = 0;
					virtual ~CVisitor() {}
			};

			CBinaryTree()
			{
				left = NULL;
				right = NULL;
				parent = NULL;
				m_bvirtualroot = true;
			}

			~CBinaryTree()
			{
				release();
			}

			void release()
			{
				if(left!=NULL)
				{
					left->release();
					delete left;
					left = NULL;
				}

				if(right != NULL)
				{
					right->release();
					delete right;
					right = NULL;
				}
			}

			CBinaryTree* min()
			{
				CBinaryTree* tmp;
				if(m_bvirtualroot)
					tmp = left;
				else
					tmp = this;
				
				while(tmp && tmp->left != NULL)
				{
					tmp = tmp->left;
				}

				return tmp;
			}

			CBinaryTree* max()
			{
				CBinaryTree* tmp;
				if(m_bvirtualroot)
					tmp = left;
				else
					tmp = this;
				
				while(tmp && tmp->right != NULL)
				{
					tmp = tmp->right;
				}

				return tmp;
			}

			int del(int val)
			{
				CBinaryTree* tmp;
				if(m_bvirtualroot)
					tmp = left;
				else
					tmp = this;
				
				while(tmp)
				{
					if(val == tmp->val)
					{
						break;
					}
					else if(val < tmp->val)
					{
						tmp = tmp->left;
					}
					else 
					{
						tmp = tmp->right;
					}
				}

				if(tmp == NULL)
					return -1;

				return remove(tmp);
			}

			int insert(int val)
			{
				CBinaryTree* tmp;
				if(m_bvirtualroot)
					tmp = left;
				else
					tmp = this;

				if(tmp == NULL)
				{
					if(create_left(val)!=0)
						return -1;
					
					return 0;
				}
				
				while(tmp)
				{
					if(val == tmp->val)
						return 1; //exsit
					else if(val < tmp->val)
					{
						if(tmp->left != NULL)
							tmp = tmp->left;
						else
						{
							if(tmp->create_left(val)!=0)
								return -1;
							break;
						}
						
					}
					else
					{
						if(tmp->right != NULL)
							tmp = tmp->right;
						else
						{
							if(tmp->create_right(val)!=0)
								return -1;
							break;
						}
					}
				}
				
				return 0;
			}

			int for_each(CVisitor& visitor,CBinaryTree* parent, int way=0, int h=1)
			{
				if(m_bvirtualroot)
				{
					if(left == NULL)
						return 0;
					else
						return left->for_each(visitor, this, way, h);
				}
				
				int ret = 0;
				if(way == 0)
				{
					if(left != NULL)
					{
						ret = left->for_each(visitor, this, way, h+1);
						if(ret != 0)
							return -1;
					}

					ret = visitor.callback(this, parent, h);
					if(ret != 0)
						return -1;

					if(right != NULL)
					{
						ret = right->for_each(visitor, this, way, h+1);
						if(ret != 0)
							return -1;
					}
				}
				else
				{
					ret = visitor.callback(this, parent, h);
					if(ret != 0)
						return -1;
					
					if(left != NULL)
					{
						ret = left->for_each(visitor, this, way, h+1);
						if(ret != 0)
							return -1;
					}
					
					if(right != NULL)
					{
						ret = right->for_each(visitor, this, way, h+1);
						if(ret != 0)
							return -1;
					}
				}

				return ret;
			}

		protected:
			int create_left(int val)
			{
				left = new CBinaryTree();
				if(left == NULL)
					return -1;
				left->parent = this;
				left->val = val;
				left->m_bvirtualroot = false;
				return 0;
			}

			int create_right(int val)
			{
				right = new CBinaryTree();
				if(right == NULL)
					return -1;
				right->parent = this;
				right->val = val;
				right->m_bvirtualroot = false;
				return 0;
			}

			int remove(CBinaryTree* tmp)
			{
				CBinaryTree* papa = tmp->parent;
				CBinaryTree* newchild = NULL;
				CBinaryTree* replaced = NULL;
				if(tmp->left == NULL)
				{
					if(tmp->right != NULL)
					{
						newchild = tmp->right;
					}
				}
				else if(tmp->right == NULL) //left != null
				{
					newchild = tmp->left;
				}
				else
				{
					//合并左右树为新树
					newchild = new CBinaryTree(); 
					if(newchild == NULL)
						return -1; //不可恢复的错误
					
					replaced = tmp->right->min();
					newchild->val = replaced->val;
					newchild->m_bvirtualroot = false;
					newchild->left = tmp->left;
					tmp->left->parent = newchild;
					newchild->right = tmp->right;
					tmp->right->parent = newchild;
				}

				if(newchild)
					newchild->parent = papa;

				if(papa)
				{
					if(papa->left == tmp)
						papa->left = newchild;
					else
						papa->right = newchild;
				}

				tmp->right = NULL;
				tmp->left = NULL;
				delete tmp;

				if(replaced != NULL)
					return remove(replaced);
				else
					return 0;
			}

		public:
			int val;
			CBinaryTree* left;
			CBinaryTree* right;
			CBinaryTree* parent;
		protected:
			bool m_bvirtualroot;
	};


	class CHeap
	{
		public:
			CHeap(int size, bool ismax=true)
			{
				m_buff = new int[size+1];
				m_buffsize = size;
				m_ismax = ismax;
			}

			~CHeap()
			{
				if(m_buff != NULL)
				{
					delete[] m_buff;
					m_buff = NULL;
					m_buffsize = 0;
				}
			}

			void clear()
			{
				set_used(0);
			}

			int insert(int val)
			{
				if(!m_buff || used() >= m_buffsize)
				{
					return -1;
				}

				int idx = add_used();
				m_buff[idx] = val;
				
				return heapup(idx);
			}

			int insert(const int* valarray, int size)
			{
				for(int i=0; i<size; ++i)
				{
					if(insert(valarray[i]) !=0)
						return -1;
				}

				return 0;
			}

			int make_heap(const int* valarray, int size)
			{
				clear();
				memcpy(m_buff+1, valarray, size*sizeof(int));
				set_used(size);

				int pidx;
				for(int i=used(); i>0; i-=2)
				{
					pidx = parent(i);
					if(pidx == 0)
						break;
					heapdown(pidx);
				}

				return 0;
			}

			int get_top(int& top)
			{
				if(!m_buff || used() == 0)
				{
					return -1;
				}

				top = m_buff[1];
				m_buff[1] = m_buff[used()];
				sub_used();
				heapdown(1);
				return 0;
			}

			inline int* get_buff()
			{
				return m_buff;
			}


		protected:

			int heapdown(int rootidx)
			{
				int nowidx = rootidx;
				while(true)
				{
					int topidx = nowidx;
					int lidx = left(nowidx);
					int ridx = right(nowidx);
					if(m_ismax)
					{
						if(lidx > 0 && m_buff[topidx] < m_buff[lidx])
							topidx = lidx;
						if(ridx > 0 && m_buff[topidx] < m_buff[ridx])
							topidx = ridx;
					}
					else
					{
						if(lidx > 0 && m_buff[topidx] > m_buff[lidx])
							topidx = lidx;
						if(ridx > 0 && m_buff[topidx] > m_buff[ridx])
							topidx = ridx;
					}

					if(topidx == nowidx)
					{
						break; //no change
					}

					int tmp = m_buff[nowidx];
					m_buff[nowidx] = m_buff[topidx];
					m_buff[topidx] = tmp;

					nowidx = topidx;
				}
				return 0;
			}
			
			int heapup(int lastidx)
			{
				int cidx = lastidx;
				int pidx = parent(lastidx);
				while(pidx > 0)
				{
					if( (m_ismax && m_buff[cidx] > m_buff[pidx]) 
						|| (!m_ismax && m_buff[cidx] < m_buff[pidx]) )
					{
						int tmp = m_buff[pidx];
						m_buff[pidx] = m_buff[cidx];
						m_buff[cidx] = tmp;
						cidx = pidx;
						pidx = parent(cidx);
					}
					else
					{
						break;
					}
				}
				return 0;
			}
			
			inline int parent(int idx)
			{
				return idx/2;
			}

			inline int left(int idx)
			{
				if(2*idx > used())
				{
					return -1;
				}
				
				return 2*idx;
			}

			inline int right(int idx)
			{
				if(2*idx+1 > used())
				{
					return -1;
				}
				return 2*idx+1;
			}

			inline int used()
			{
				return m_buff[0];
			}

			inline int add_used(int i=1)
			{
				m_buff[0] += i;
				return m_buff[0];
			}

			inline void set_used(int i)
			{
				m_buff[0] = i;
			}

			inline void sub_used()
			{
				--(m_buff[0]);
			}
			
		protected:
			int* m_buff;
			int m_buffsize;
			bool m_ismax;
	};


	class CAVLTree
	{
		public:
			class CVisitor
			{
				public:
					virtual int callback(const CAVLTree* node, const CAVLTree* pnode, int h) = 0;
					virtual ~CVisitor() {}
			};

			CAVLTree()
			{
				left = NULL;
				right = NULL;
				m_bvirtualroot = true;
				height = 1;
			}

			~CAVLTree()
			{
				release();
			}

			void release()
			{
				if(left!=NULL)
				{
					left->release();
					delete left;
					left = NULL;
				}

				if(right != NULL)
				{
					right->release();
					delete right;
					right = NULL;
				}
			}

			CAVLTree* min()
			{
				CAVLTree* tmp;
				if(m_bvirtualroot)
					tmp = left;
				else
					tmp = this;
				
				while(tmp && tmp->left != NULL)
				{
					tmp = tmp->left;
				}

				return tmp;
			}

			CAVLTree* max()
			{
				CAVLTree* tmp;
				if(m_bvirtualroot)
					tmp = left;
				else
					tmp = this;
				
				while(tmp && tmp->right != NULL)
				{
					tmp = tmp->right;
				}

				return tmp;
			}

			int del(int val)
			{
				if(!m_bvirtualroot) //只有root可以insert
				{
					return -1;
				}
				
				if(!left)
				{
					return -1;
				}

				left = inner_del(left, val);
				if(!left)
					return -1;
				return 0;
			}

			int hold_child(CAVLTree* c)
			{
				if(!m_bvirtualroot || c->is_root())
					return -1;
				release();
				left = c;
				return 0;	
			}

			int insert(int val)
			{
				if(!m_bvirtualroot) //只有root可以insert
				{
					return -1;
				}
				
				if(!left)
				{
					create_left(val);
					return 0;
				}

				left = inner_insert(left, val);
				if(!left)
					return -1;
				
				//std::cout << "insert result " << left->val << std::endl;
				return 0;
			}

			int for_each(CVisitor& visitor, CAVLTree* parent ,int way=0, int h=1)
			{
				if(m_bvirtualroot)
				{
					if(left == NULL)
						return 0;
					else
						return left->for_each(visitor, this, way, h);
				}
				
				int ret = 0;
				if(way == 0)
				{
					if(left != NULL)
					{
						ret = left->for_each(visitor, this, way, h+1);
						if(ret != 0)
							return -1;
					}

					ret = visitor.callback(this, parent, h);
					if(ret != 0)
						return -1;

					if(right != NULL)
					{
						ret = right->for_each(visitor, this, way, h+1);
						if(ret != 0)
							return -1;
					}
				}
				else
				{
					ret = visitor.callback(this,parent,  h);
					if(ret != 0)
						return -1;
					
					if(left != NULL)
					{
						ret = left->for_each(visitor, this, way, h+1);
						if(ret != 0)
							return -1;
					}
					
					if(right != NULL)
					{
						ret = right->for_each(visitor, this, way, h+1);
						if(ret != 0)
							return -1;
					}
				}

				return ret;
			}


			inline bool is_root()
			{
				return m_bvirtualroot;
			}

		protected:

			CAVLTree* inner_insert(CAVLTree* root, int val)
			{
				CAVLTree* ret = root;
				
				if(val == root->val)
					return NULL;
				
				if(val < root->val)
				{
					if(root->left)
					{
						root->left = inner_insert(root->left, val);
						if(!(root->left))
							return NULL;
						
						if(get_balance(root) == 2)
						{
							if(val < root->left->val)
								ret = r_rotate(root);
							else
								ret = lr_rotate(root);
						}
					}
					else
					{
						root->create_left(val);
						get_balance(root);
					}
				}
				else
				{
					if(root->right)
					{
						root->right = inner_insert(root->right, val);
						if(!(root->right))
							return NULL;
						if(get_balance(root) == -2)
						{
							if(val < root->right->val)
								ret = rl_rotate(root);
							else
								ret = l_rotate(root);
						}
					}
					else
					{
						root->create_right(val);
						get_balance(root);
					}
				}
				
				return ret;
			}

			CAVLTree* inner_del(CAVLTree* root, int val)
			{
				if(root->val == val)
				{
					return inner_remove(root);
				}
				
				if(val < root->val)
				{
					if(root->left)
					{
						root->left = inner_del(root->left, val);
					}
				}
				else 
				{
					if(root->right)
					{
						root->right = inner_del(root->right, val);
					}
				}

				return inner_rotate(root);
			}

			CAVLTree* inner_find_left(CAVLTree* root, int& leftval)
			{
				CAVLTree* ret = NULL;
				if(root->left)
				{
					ret = inner_find_left(root->left, leftval);
					ret = inner_rotate(ret);
				}
				else
				{
					leftval = root->val;
					ret = inner_remove(root);
				}

				return ret;
			}

			CAVLTree* inner_remove(CAVLTree* root)
			{
				CAVLTree* ret = NULL;
				if(root->right)
				{
					int newval;
					root->right = inner_find_left(root->right, newval);
					root->val = newval;
					ret = inner_rotate(root);
				}
				else
				{
					ret = root->left;
					root->left=NULL;
					delete root;
				}

				return ret;
			}
				
			int create_left(int val)
			{
				left = new CAVLTree();
				if(left == NULL)
					return -1;
				left->val = val;
				left->m_bvirtualroot = false;
				return 0;
			}

			int create_right(int val)
			{
				right = new CAVLTree();
				if(right == NULL)
					return -1;
				right->val = val;
				right->m_bvirtualroot = false;
				return 0;
			}

			inline int get_balance(CAVLTree* node)
			{
				int leftheight = 0;
				int rightheight = 0;
				if(node->left)
					leftheight = node->left->height;
				if(node->right)
					rightheight = node->right->height;

				int balance = leftheight - rightheight;
				if(balance < 0)
					node->height = rightheight+1;
				else
					node->height = leftheight+1;

				//std::cout << node->val << " height=" << node->height << " b=" << balance << std::endl;
				
				return balance;
			}

			CAVLTree* r_rotate(CAVLTree* tree)
			{
				CAVLTree* l = tree->left;
				CAVLTree* lr = l->right;
				//std::cout << "r_rotate " << tree->val << "->" << l->val << std::endl;
				tree->left = lr;
				l->right = tree;
				get_balance(tree);
				get_balance(l);
				return l;
			}

			CAVLTree* l_rotate(CAVLTree* tree)
			{
				CAVLTree* r = tree->right;
				CAVLTree* rl = r->left;
				//std::cout << "l_rotate " << tree->val << "->" << r->val << std::endl;
				tree->right = rl;
				r->left = tree;
				get_balance(tree);
				get_balance(r);
				return r;
			}

			CAVLTree* lr_rotate(CAVLTree* tree)
			{
				tree->left = l_rotate(tree->left);
				return r_rotate(tree);
			}

			CAVLTree* rl_rotate(CAVLTree* tree)
			{
				tree->right = r_rotate(tree->right);
				return l_rotate(tree);
			}

			CAVLTree* inner_rotate(CAVLTree* root)
			{
				CAVLTree* ret = root;
				int b= get_balance(root);
				if(b == 2)
				{
					if(val < root->left->val)
						ret = r_rotate(root);
					else
						ret = lr_rotate(root);
				}
				if(b == -2)
				{
					if(val < root->right->val)
						ret = rl_rotate(root);
					else
						ret = l_rotate(root);
				}

				return ret;
			}

		public:
			int val;
			CAVLTree* left;
			CAVLTree* right;
			int height;
		protected:
			bool m_bvirtualroot;	
	};
}

