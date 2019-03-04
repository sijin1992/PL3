#ifndef __RANDOM_H__
#define __RANDOM_H__

#include <vector>
using namespace std;

class CRandom
{
	public:
		CRandom();

		//默认用pid和time做种子，构造函数会调用一次
		void seed(unsigned int v = 0);
		
		//直接调用系统rand
		static unsigned int sys_rand();
		//rand_r
		unsigned int rand();

		//从man rand中看到的posix推荐实现方法
		unsigned int myrand();

		//在应用方法中，是否用myrand代替rand_r，初始值 为false
		void use_myrand(bool b);

		//把rand值映射到[min,max]上，为了安全max<min 就返回min
		static unsigned int range(unsigned int randv, unsigned int max, unsigned int min=0);

		//随机选取n个idxes
		//weights 输入，各个idx的权重，权重之和不要超过unsigned int的最大值
		//n输入，要选择的idx个数
		//selected_idxes 输出选中的idx，内部会先清空
		//return 实际选中的个数(n>weights.size())返回weights.size()
		int select(vector<unsigned int>& weights, unsigned int n, vector<unsigned int>& selected_idxes);
		//选取一个的简单版本
		int select(vector<unsigned int>& weights, unsigned int& selected_idx);

		//抽奖，所有idx共享概率，概率总值
		//probabilities 概率表
		//如果return=1 selected_idx 返回抽中的
		//pro_unit 概率单位，默认是百分比
		//return 实际抽中个数0，1
		int draw(vector<unsigned int>& probabilities, unsigned int& selected_idx, unsigned int pro_unit=100);

		//抽奖，每个idx单独计算概率
		//参数定义同上
		//limit=0不限制个数，return <= limit
		int draw(vector<unsigned int>& probabilities, vector<unsigned int>& selected_idxes, unsigned int pro_unit=100, unsigned int limit=0);


	protected:
		unsigned int m_uiSeed;
		bool m_bmyrand;
};

#endif

