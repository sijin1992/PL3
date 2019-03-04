#ifndef __UNIQ_ID_H__
#define __UNIQ_ID_H__

template<typename IDTYPE>
class CUniqID
{
public:
	//�������������ʱ�����ظ��Ŀ��ܣ����Ǹ���Ӧ�ò���
	CUniqID()
	{
		m_id = 1;
		m_maxUsed = 0;
	}
	
	//����set_used����������get_id֮ǰ
	void set_used(IDTYPE id)
	{
		if(id > m_maxUsed)
		{
			m_maxUsed = id;
		}
		m_id = m_maxUsed+1;
	}
	
	IDTYPE get_id()
	{
		return m_id++;
	}
	
protected:
	IDTYPE m_maxUsed;
	IDTYPE m_id;
};

#endif
