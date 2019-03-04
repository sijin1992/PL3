#ifndef __RANDOM_H__
#define __RANDOM_H__

#include <vector>
using namespace std;

class CRandom
{
	public:
		CRandom();

		//Ĭ����pid��time�����ӣ����캯�������һ��
		void seed(unsigned int v = 0);
		
		//ֱ�ӵ���ϵͳrand
		static unsigned int sys_rand();
		//rand_r
		unsigned int rand();

		//��man rand�п�����posix�Ƽ�ʵ�ַ���
		unsigned int myrand();

		//��Ӧ�÷����У��Ƿ���myrand����rand_r����ʼֵ Ϊfalse
		void use_myrand(bool b);

		//��randֵӳ�䵽[min,max]�ϣ�Ϊ�˰�ȫmax<min �ͷ���min
		static unsigned int range(unsigned int randv, unsigned int max, unsigned int min=0);

		//���ѡȡn��idxes
		//weights ���룬����idx��Ȩ�أ�Ȩ��֮�Ͳ�Ҫ����unsigned int�����ֵ
		//n���룬Ҫѡ���idx����
		//selected_idxes ���ѡ�е�idx���ڲ��������
		//return ʵ��ѡ�еĸ���(n>weights.size())����weights.size()
		int select(vector<unsigned int>& weights, unsigned int n, vector<unsigned int>& selected_idxes);
		//ѡȡһ���ļ򵥰汾
		int select(vector<unsigned int>& weights, unsigned int& selected_idx);

		//�齱������idx������ʣ�������ֵ
		//probabilities ���ʱ�
		//���return=1 selected_idx ���س��е�
		//pro_unit ���ʵ�λ��Ĭ���ǰٷֱ�
		//return ʵ�ʳ��и���0��1
		int draw(vector<unsigned int>& probabilities, unsigned int& selected_idx, unsigned int pro_unit=100);

		//�齱��ÿ��idx�����������
		//��������ͬ��
		//limit=0�����Ƹ�����return <= limit
		int draw(vector<unsigned int>& probabilities, vector<unsigned int>& selected_idxes, unsigned int pro_unit=100, unsigned int limit=0);


	protected:
		unsigned int m_uiSeed;
		bool m_bmyrand;
};

#endif

