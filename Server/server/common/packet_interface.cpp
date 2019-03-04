#include "packet_interface.h"
#include "binary/binary_util.h"

CBinPackInterface::CBinPackInterface()
{
	m_bindFlag = NULL;
}
void CBinPackInterface::bind_flag(int* flag)
{
	m_bindFlag = flag;
}

int CBinPackInterface::get_packet_len(const char* buff, unsigned int buffLen, unsigned int& packetLen) 
{
	if(buffLen < sizeof(BIN_PRO_HEADER))
	{
		if(m_bindFlag && *m_bindFlag)
		{
			LOG(LOG_DEBUG, "size(%d)<HEAD_SIZE(%lu) need more", buffLen, sizeof(BIN_PRO_HEADER));
		}
		return RET_PACKET_NEED_MORE_BYTES;
	}
	m_phead = (BIN_PRO_HEADER *)buff;
	if(!m_phead->valid())
	{
		if(m_bindFlag && *m_bindFlag)
		{
			LOG(LOG_DEBUG, "recvlen=%d|headLen=%lu|%s",  buffLen, sizeof(BIN_PRO_HEADER), CBinaryUtil::bin_hex(buff, sizeof(BIN_PRO_HEADER)).c_str());
		}
		return RET_PACKET_NOT_VALID;
	}


	packetLen = m_phead->parse_len();
	if(m_bindFlag && *m_bindFlag)
	{
		LOG(LOG_DEBUG, "get_packet_len(buffLen=%u) parse_len=%u | %s", buffLen, packetLen, CBinaryUtil::bin_hex(buff, buffLen).c_str());
	}

	return RET_OK;
}

int CBinPackInterfaceNormal::get_packet_len(const char* buff, unsigned int buffLen, unsigned int& packetLen)
{
	//for twg
	if(buffLen >= TWG_HTTP_HEAD_LEN && strncmp(buff, TWG_HTTP_HEAD, TWG_HTTP_HEAD_LEN) == 0)
	{
		packetLen = buffLen;
		return RET_OK;
	}

	if(buffLen < sizeof(BIN_PRO_HEADER))
	{
		if(m_bindFlag && *m_bindFlag)
		{
			LOG(LOG_DEBUG, "size(%d)<HEAD_SIZE(%lu) need more", buffLen, sizeof(BIN_PRO_HEADER));
		}
		return RET_PACKET_NEED_MORE_BYTES;
	}
	
	m_phead = (BIN_PRO_HEADER *)buff;
	if(!m_phead->valid())
	{
		if(m_bindFlag && *m_bindFlag)
		{
			LOG(LOG_DEBUG, "recvlen=%d|headLen=%lu|%s",  buffLen, sizeof(BIN_PRO_HEADER), CBinaryUtil::bin_hex(buff, sizeof(BIN_PRO_HEADER)).c_str());
		}
		return RET_PACKET_NOT_VALID;
	}

	packetLen = m_phead->parse_len();
	if(m_bindFlag && *m_bindFlag)
	{
		LOG(LOG_DEBUG, "get_packet_len(buffLen=%u) parse_len=%u | %s", buffLen, packetLen, CBinaryUtil::bin_hex(buff, buffLen).c_str());
	}

	return RET_OK;
}

CEndPackInterface::CEndPackInterface(const char* endFlag, unsigned int endFlagLen)
{
	m_endLen = endFlagLen;
	m_endFlag = new char[m_endLen];
	memcpy(m_endFlag, endFlag, m_endLen);
}

CEndPackInterface::~CEndPackInterface()
{
	delete[] m_endFlag;
}

int CEndPackInterface::get_packet_len(const char* buff, unsigned int buffLen, unsigned int& packetLen) 
{
	if(buffLen < m_endLen)
		return RET_PACKET_NEED_MORE_BYTES;

	//自后向前匹配，end不会太长，所以不做优化了
	const char* buffend = (buff+buffLen-1);
	const char* cur = buffend-m_endLen+1; //可能匹配的最后一个位置
	bool found = false;
	unsigned int pos = 0;
	for(unsigned int i=0; i<buffLen-m_endLen; ++i, --cur)
	{
		for(pos = 0; pos < m_endLen; ++pos)
		{
			if(cur[pos] != m_endFlag[pos])
			{
				break;
			}
		}
		
		if(pos == m_endLen)
		{
			found = true;
			break;
		}
	}

	if(found)
	{
		packetLen = cur - buff;
		return RET_OK;
	}

	return RET_PACKET_NEED_MORE_BYTES;
}


int CRawPackInterface::get_packet_len(const char* buff, unsigned int buffLen, unsigned int& packetLen) 
{
	packetLen = buffLen;
	return RET_OK;
}

