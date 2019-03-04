svr1-msg_queue1-|
svr2-msg_quque2-|--tcplinker1 <------> tcplinker2--|-msg_queue3-svr3
                                  |--> tcplinker3--|-msg_queue4-svr4
tcplinker实现多台物理机器上的msg_queue联通
通过des_svrID来寻址
基本配置如下,例如tcplinker1
[TCP_LINKER]
MSG_QUEUE_TOTAL=2 ;;绑定了2个queue
DES_TOTAL=2 ;;可以直接转发有2个tcplinker
LISTEN_IP= ;;监听ip
LISTEN_PORT= ;;监听port
READ_LIMIT_PER_QUEUE=10;;每个queue一个循环最大发送msg个数
;;svr set相关配置，svr set指的是一组可以相互替代的分布服务器
SVRSET_TOTAL=1;;svr set的总个数，可以为零
RANDOM_CMD_TOTAL=1;;采用在set中随机一台发送的命令总数
BROADCAST_CMD_TOTAL=1;;采用在set中广播发送的命令总数
ALIVE_CMD_TOTAL=1;;需要接收的keepalive命令的总数

[MSG_QUEUE_0] ;;queue1配置
QUEUE_GLOBE_ID=10 ;;见pipe_quque.ini的配置
BIND_SVR=1.0.0.1 ;;使用ip的标识方法，当收到的msg的desSvr=这个值，就发到绑定的queue
ACTIVE=1 ;;active指示打开pipe的方式

[MSG_QUEUE_1]
QUEUE_GLOBE_ID=10 ;;见pipe_quque.ini的配置
BIND_SVR=1.0.0.2 ;;使用ip的标识方法
ACTIVE=0 ;;active指示打开pipe的方式

[DES_0]
DES_IP=  ;;对方的ip
DES_PORT= ;;对方的port
BIND_SVR=1.0.0.3 ;;发送的msg的desSvr=这个值就转发到des_ip，port

[SVR_SET_0]
;;匹配模式为svrID & MASK == ID
ID=3.0.0.0 
;;=0没有timeout, >0timeout毫秒值，没有alive命令来更新
ALIVE_TIME_OUT_MS=0
SVR_TOTAL=2
SVR_ID_0=3.0.0.1
SVR_ID_1=3.0.0.2

[RANDOM_CMD_0]
CMD=0x100;;msg命令为0x100
MASK=255.255.255.0;;CMD & MASK 之后的值去 SVR_SET中找

[BROADCAST_CMD_0]
CMD=0x102
MASK=255.255.255.0

[ALIVE_CMD_0]
CMD=0x104
MASK=255.255.255.0