globalsvr是为了解决多玩家数据处理，数据广播问题而设计的。
主要针对PVP竞技场

配置说明如下
[GLOBAL_SVR]
DAEMON=1
LOCK=../lock/dbsvr.lock
LOG_PATH=../log
LOG_MODULE=globalsvr
;;对外交互的queue
LISTEN_QUEUE_ID= 
;;hash配置
SHM_KEY=0x20071
USER_NUM=10000
HASH_NUM=1000

[LOGIC_DRIVER]
SAVE_LOGIC_IN_SHM=0
USE_TIMER=0
SERVER_ID=3.0.0.1