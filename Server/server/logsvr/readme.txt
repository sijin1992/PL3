globalsvr��Ϊ�˽����������ݴ������ݹ㲥�������Ƶġ�
��Ҫ���PVP������

����˵������
[GLOBAL_SVR]
DAEMON=1
LOCK=../lock/dbsvr.lock
LOG_PATH=../log
LOG_MODULE=globalsvr
;;���⽻����queue
LISTEN_QUEUE_ID= 
;;hash����
SHM_KEY=0x20071
USER_NUM=10000
HASH_NUM=1000

[LOGIC_DRIVER]
SAVE_LOGIC_IN_SHM=0
USE_TIMER=0
SERVER_ID=3.0.0.1