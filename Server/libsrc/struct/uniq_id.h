#ifndef __UNIQ_ID_H__
#define __UNIQ_ID_H__

template<typename IDTYPE>
class CUniqID
{
public:
	//类型上限溢出的时候有重复的可能，但是概率应该不大
	CUniqID()
	{
		m_id = 1;
		m_maxUsed = 0;
	}
	
	//所有set_used操作必须在get_id之前
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
