flagsvr��Ϊ�˽�������б�״̬λ�Ĳ�ѯ�������Ƶġ�
����������ѯ,��������.
����hash_map;
�����û���1��int�Ĵ洢����λ��bit���洢���Լ�2���ֽڵ��û��ȼ�

����˵������
[FLAG_SVR]
DAEMON=1
LOCK=../lock/dbsvr.lock
LOG_PATH=../log
LOG_MODULE=flagsvr
;;���⽻����queue
LISTEN_QUEUE_ID=7 
;;hash����
SHM_KEY=0x20071
USER_NUM=10000
HASH_NUM=1000

[LOGIC_DRIVER]
SAVE_LOGIC_IN_SHM=0
USE_TIMER=0
SERVER_ID=3.0.0.1