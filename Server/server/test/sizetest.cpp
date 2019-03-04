#include <stdio.h>
#include <stdlib.h>

#define USER_NAME_LEN 32
#define USER_NAME_BYTE_LEN (USER_NAME_LEN/2)
#define USER_KEY_LEN 128
#define USER_NAME_BUFF_LEN (USER_NAME_LEN+1)
#define USER_KEY_BUFF_LEN (USER_KEY_LEN+1)

#pragma pack(push)

#pragma pack(1)
struct ONLINE_CACHE_UNIT
{
	int userState; //״̬���Ա��������
	int loginTime; //��¼ʱ��
	int lastActiveTime; //�ϴλʱ��
	unsigned int selfCheckTimerID; //���߼��Ķ�ʱ��id
	unsigned int userip;
	unsigned int userdomain;
	char userkey[USER_KEY_BUFF_LEN];
	char reserve[103];
};
#pragma pack(pop)


int main(int argc, char** argv)
{
	printf("%lu\r\n", sizeof(ONLINE_CACHE_UNIT));
	return 0;
}

