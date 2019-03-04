#include "client_interface.h"
#include <fstream>
using namespace std;

#include "proto/cmd_pve.pb.h"


char CClientInterface::m_sendBuff[MSG_BUFF_LIMIT];
char CClientInterface::m_recvBuff[MSG_BUFF_LIMIT];
string CClientInterface::m_argbuf;

//阻塞模式的入口
bool CClientInterface::run(int argc, char** argv) 
{
	Message* preq;
	if(!req_msg(argc, argv, preq))
	{
		help(*pout);
		return false;
	}
	
	Message* presp = resp_msg();
	if(send_and_recv(preq, presp, req_cmd() , resp_cmd()) != 0)
		return false;
	return true;
}

//只管发送
bool CClientInterface::send(int argc, char** argv)
{
	Message* preq;
	if(!req_msg(argc, argv, preq))
	{
		help(*pout);
		*pout << endl;
		return false;
	}
	
	unsigned int cmdReq = req_cmd();
	USER_NAME name;
	name.from_str(m_userName);

	if(preq && !preq->SerializeToArray(m_binreq.packet(), m_binreq.packet_len()))
	{
		(*pout) << "SerializeToArray fail" << endl;
		return false;
	}

	int sendLen  = preq?m_binreq.total_len(preq->ByteSize()):m_binreq.total_len(0);
	m_binreq.head()->format(name, cmdReq, sendLen);
	if(m_pTcp->send(m_binreq.buff(), sendLen) < 0)
	{
		(*pout) << "send fail|" << m_pTcp->errmsg() << endl;
		return false;
	}

	(*pout) << "send cmd=" << cmdReq << "(0x" << hex << cmdReq << dec << ") total_len=" << sendLen << " content=" << endl;
	if(preq)
		(*pout) << preq->DebugString() << endl;
	return true;
} 

//只管接收
bool CClientInterface::on_recv(CBinProtocol& theRespBin, ostream& os, int temp)
{
	Message* presp = resp_msg();
	USER_NAME name = theRespBin.head()->parse_name();
	int result = theRespBin.head()->parse_result();
	if(result != COMMON_RESULT_OK)
	{
		os << "result from head=" << m_binResp.head()->parse_result() << endl;
		return false;
	}

	if(presp)
	{
		presp->Clear();
		if( !presp->ParseFromArray(theRespBin.packet(), theRespBin.packet_len()))
		{
			os << "ParseFromArray fail" << endl;
			if(presp->ParsePartialFromArray(theRespBin.packet(), theRespBin.packet_len()))
			{
				os << "ParsePartialFromArray:" << endl;
				os << presp->DebugString() << endl;
			}
			return false;
		}
		os << presp->DebugString() << endl;
		os << "total_len:" << ((float)(theRespBin.packet_len())) / 1024 << "k" << endl;
		if(resp_cmd() ==CMD_PVE_RESP)
			{
		FightRcd rcd;
		rcd.CopyFrom(((PVE_RESP *)presp)->fight_rcd());
		char buff[4096];
		rcd.SerializeToArray(buff, 4096);
		int len = rcd.GetCachedSize();
		ofstream f("rcd",ios::binary);
		f.write(buff, len);
		f.close();}

		
//		if (temp == 1)
//		{
//			ofstream f("/tmp/a", ios::binary);
//			f.write(theRespBin.packet(), theRespBin.packet_len());
//			f.close();
//			ifstream f1("/tmp/a", ios::binary);
//			char* a = new char[theRespBin.packet_len()];
//			f1.read(a, theRespBin.packet_len());
//			delete[] a;
//			presp->Clear();
//			if( !presp->ParseFromArray(a, theRespBin.packet_len()))
//			{
//				os << "ParseFromArray fail" << endl;
//				if(presp->ParsePartialFromArray(a, theRespBin.packet_len()))
//				{
//					os << "ParsePartialFromArray:" << endl;
//					os << presp->DebugString() << endl;
//				}
//				return false;
//			}
//			os << "\n******\n" <<presp->DebugString() << "\n******" << endl;
//		}
	}

	hook_recved();
		
	return true;
}

int CClientInterface::send_and_recv(Message* preq, Message* presp, unsigned int cmdReq, unsigned int cmdResp)
{
	if(preq && !preq->SerializeToArray(m_binreq.packet(), m_binreq.packet_len()))
	{
		(*pout) << "SerializeToArray fail" << endl;
		return -1;
	}

	USER_NAME name;
	snprintf(name.val, sizeof(name.val), "%s", m_userName);
	int sendLen  = preq?m_binreq.total_len(preq->ByteSize()):m_binreq.total_len(0);
	m_binreq.head()->format(name, cmdReq, sendLen);

	if(m_pTcp->send(m_binreq.buff(), sendLen) < 0)
	{
		(*pout) << "send fail|" << m_pTcp->errmsg() << endl;
		return -1;
	}

	(*pout) << "send cmd=" << cmdReq << " total_len=" << sendLen << " content=" << endl;
	if(preq)
		(*pout) << preq->DebugString() << endl;

	if(m_pTcp->recieve(m_binResp.buff(), m_binResp.total_len(0)) < 0)
	{
		(*pout) << "recv head fail|" << m_pTcp->errmsg() << endl;
		return -1;
	}

	if(cmdResp != m_binResp.head()->parse_cmd())
	{
		(*pout) << "expect cmd(" << cmdResp << ") but recieve " << m_binResp.head()->parse_cmd() << endl;
		return -1;
	}

	if(m_binResp.head()->parse_result() != COMMON_RESULT_OK)
	{
		(*pout) << "result from head=" << m_binResp.head()->parse_result() << endl;
		return -1;
	}

	int len = m_binResp.head()->parse_len();

	(*pout) << "recved cmd=" << cmdResp << " total_len=" << len << endl;
	
	if(m_pTcp->recieve(m_binResp.packet(), len - m_binResp.total_len(0)) < 0)
	{
		(*pout) << "recv packet fail|" << m_pTcp->errmsg() << endl;
		return -1;
	}

	if(presp && !presp->ParseFromArray(m_binResp.packet(), len - m_binResp.total_len(0)))
	{
		(*pout) << "ParseFromArray fail|" << endl;
		return -1;
	}

	if(presp)
		(*pout) << presp->DebugString() << endl;

	return 0;
}


