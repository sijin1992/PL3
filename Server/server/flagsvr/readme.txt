flagsvr是为了解决好友列表状态位的查询问题而设计的。
可以批量查询,单独更新.
采用hash_map;
单个用户有1个int的存储，按位（bit）存储，以及2个字节的用户等级

配置说明如下
[FLAG_SVR]
DAEMON=1
LOCK=../lock/dbsvr.lock
LOG_PATH=../log
LOG_MODULE=flagsvr
;;对外交互的queue
LISTEN_QUEUE_ID=7 
;;hash配置
SHM_KEY=0x20071
USER_NUM=10000
HASH_NUM=1000

[LOGIC_DRIVER]
SAVE_LOGIC_IN_SHM=0
USE_TIMER=0
SERVER_ID=3.0.0.1