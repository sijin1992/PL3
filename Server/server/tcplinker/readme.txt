svr1-msg_queue1-|
svr2-msg_quque2-|--tcplinker1 <------> tcplinker2--|-msg_queue3-svr3
                                  |--> tcplinker3--|-msg_queue4-svr4
tcplinkerʵ�ֶ�̨��������ϵ�msg_queue��ͨ
ͨ��des_svrID��Ѱַ
������������,����tcplinker1
[TCP_LINKER]
MSG_QUEUE_TOTAL=2 ;;����2��queue
DES_TOTAL=2 ;;����ֱ��ת����2��tcplinker
LISTEN_IP= ;;����ip
LISTEN_PORT= ;;����port
READ_LIMIT_PER_QUEUE=10;;ÿ��queueһ��ѭ�������msg����
;;svr set������ã�svr setָ����һ������໥����ķֲ�������
SVRSET_TOTAL=1;;svr set���ܸ���������Ϊ��
RANDOM_CMD_TOTAL=1;;������set�����һ̨���͵���������
BROADCAST_CMD_TOTAL=1;;������set�й㲥���͵���������
ALIVE_CMD_TOTAL=1;;��Ҫ���յ�keepalive���������

[MSG_QUEUE_0] ;;queue1����
QUEUE_GLOBE_ID=10 ;;��pipe_quque.ini������
BIND_SVR=1.0.0.1 ;;ʹ��ip�ı�ʶ���������յ���msg��desSvr=���ֵ���ͷ����󶨵�queue
ACTIVE=1 ;;activeָʾ��pipe�ķ�ʽ

[MSG_QUEUE_1]
QUEUE_GLOBE_ID=10 ;;��pipe_quque.ini������
BIND_SVR=1.0.0.2 ;;ʹ��ip�ı�ʶ����
ACTIVE=0 ;;activeָʾ��pipe�ķ�ʽ

[DES_0]
DES_IP=  ;;�Է���ip
DES_PORT= ;;�Է���port
BIND_SVR=1.0.0.3 ;;���͵�msg��desSvr=���ֵ��ת����des_ip��port

[SVR_SET_0]
;;ƥ��ģʽΪsvrID & MASK == ID
ID=3.0.0.0 
;;=0û��timeout, >0timeout����ֵ��û��alive����������
ALIVE_TIME_OUT_MS=0
SVR_TOTAL=2
SVR_ID_0=3.0.0.1
SVR_ID_1=3.0.0.2

[RANDOM_CMD_0]
CMD=0x100;;msg����Ϊ0x100
MASK=255.255.255.0;;CMD & MASK ֮���ֵȥ SVR_SET����

[BROADCAST_CMD_0]
CMD=0x102
MASK=255.255.255.0

[ALIVE_CMD_0]
CMD=0x104
MASK=255.255.255.0