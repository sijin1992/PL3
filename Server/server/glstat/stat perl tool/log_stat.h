#ifndef __LOG_STAT_H__
#define __LOG_STAT_H__

#ifndef LOG
#define LOG
#endif

#ifndef CELL_LOG
#define CELL_LOG LOG
#endif

#ifndef LOG_STAT
#define LOG_STAT LOG_RECORD
#endif

/************************************************************************/
/* �ϱ�ͳ������,��ʽ: ʱ���|���̺�|�ļ���|�к�|�û���|ͳ������|������ʽ����	*/
/* 2014110514:50:23.137467|21692|login.cpp|214|fflala|LOGIN|result=0|platform=2|viplevel=8,year=1 */
/* LOG_STAT_DATA ����username���û�ID��:const char*������datatype(ͳ������):const char*, ����format,args...��ʽ���� */
/************************************************************************/

#ifdef WIN32
	#define LOG_STAT_DATA(userid, stattype, format, ...) CELL_LOG(LOG_STAT, "%s|%s|"format"|end", stattype, userid, __VA_ARGS__);
#else
	#define LOG_STAT_DATA(userid, stattype, format, args...) CELL_LOG(LOG_STAT, "%s|%s|"format"|end", stattype, userid, ##args);
#endif
/************************************************************************/
/*	ͳ�����Ͷ���                                                        */
/************************************************************************/
/*TypeBegin*/
//ע��
#define STAT_REGIST		"REGIST"
//��¼
#define STAT_LOGIN		"LOGIN"
//��ֵ
#define STAT_DEPOSIT	"DEPOSIT"
//����
#define STAT_LOGOUT		"LOGOUT"
//����
#define STAT_LEVEL_UP	"LEVEL_UP"
//�豸
#define STAT_DEVICE		"DEVICE"
//����ͳ��
#define STAT_ONLINE		"ONLINE"
//Ԫ������
#define STAT_CAST_YB	"CAST_YB"
//��������
#define STAT_CAST_GD	"CAST_GD"
//��������
#define STAT_CAST_ITEM	"CAST_ITEM"
//��������
#define STAT_CAST_PHP	"CAST_PHP"
//���ͻ�ȡ
#define STAT_GET_XK		"GET_XK"
//Ԫ�����
#define STAT_GET_YB		"GET_YB"
//�������
#define STAT_GET_GD		"GET_GD"
//���ƻ��
#define STAT_GET_CARD	"GET_CARD"
//�������
#define STAT_GET_PHP	"GET_PHP"
//���幱�׻��
#define STAT_GET_JZGX	"GET_JZGX"
//���߻��
#define STAT_GET_ITEM	"GET_ITEM"
//ͨ�عؿ�
#define STAT_PASS_GQ	"PASS_GQ"
//��������
#define STAT_PASS_WL	"PASS_WL"
//����ʹ��
#define STAT_USE_GN		"USE_GN"
//���ȡ
#define STAT_ACT_REWARD	"ACT_REWARD"
//��������
#define STAT_GUIDE		"GUIDE"
//��ҿ���
#define STAT_USER		"USER"
//ʹ��CDKEY
#define STAT_USE_CDKEY	"USE_CDKEY"

#define STAT_LOG_PVE	"PVE"

#define STAT_LOG_BUILD	"BUILD"

#define STAT_LOG_RES	"RES"

#define STAT_LOG_SHIP	"SHIP"

#define STAT_LOG_BUY_ITEM	"BUY_ITEM"

#define STAT_LOG_USE_MONEY	"USE_MONEY"

#define STAT_LOG_CAST_OD	"CAST_OD"


//
/*TypeEnd*/
/************************************************************************/
/*		��ݼ�¼��                                                       */
/************************************************************************/
/*RecBegin*/

//ע��(�û�ID��IP��ַ�� MCC�ƶ��豸�����룬�˺�)
#define LOG_STAT_REGIST(uid, ip, mmc, acc) \
	LOG_STAT_DATA(uid, STAT_REGIST, "%s|%s|%s", ip, mmc, acc);

//��¼(�û�ID��IP��ַ�� MCC�ƶ��豸�����룬�ȼ����˺�)
#define LOG_STAT_LOGIN(uid, ip, mmc, level, acc) \
	LOG_STAT_DATA(uid, STAT_LOGIN, "%s|%s|%d|%s", ip, mmc, level, acc);

//��ֵ(�û�ID����ֵ��֧����ʽ���Ƿ��׳䣬vip�ȼ���vip����)
#define LOG_STAT_DEPOSIT(uid, amount, paytype, isfirst, viplevel, vipscore) \
	LOG_STAT_DATA(uid, STAT_DEPOSIT, "%d|%d|%d|%d|%d", amount, paytype, isfirst, viplevel, vipscore);

//����(�û�ID������ʱ��(��)���˺�)
#define LOG_STAT_LOGOUT(uid, oltime, acc) \
	LOG_STAT_DATA(uid, STAT_LOGOUT, "%ld|%s", oltime, acc);

//����(�û�ID��֮ǰ�ȼ���֮��ȼ���
#define LOG_STAT_LEVEL_UP(uid, levelbefore, levelafter) \
	LOG_STAT_DATA(uid, STAT_LEVEL_UP, "%d|%d", levelbefore, levelafter);

//�豸(�û�ID���ն˻��ͣ��豸�ֱ��ʣ����ò���ϵͳ��������Ӫ�̣�������ʽ)
#define LOG_STAT_DEVICE(uid, stype, res, os, oper, cntype) \
	LOG_STAT_DATA(uid, STAT_DEVICE, "%s|%s|%s|%s|%s", stype, res, os, oper, cntype);

//����ͳ��(��������������ID)
#define LOG_STAT_ONLINE(olnum, areaid) \
	LOG_STAT_DATA(STAT_ONLINE, STAT_ONLINE, "%d|%s", olnum, areaid);

//Ԫ������(�û�ID������������������������Ԫ����������ȷ�Ͻ������ֵԪ����ʣ������Ԫ����ʣ����Ԫ�����˺ţ�IP��MMC)
#define LOG_STAT_CAST_YB(uid, where, num, real, confirm, depleft, realleft, totalleft, acc, ip, mmc) \
	LOG_STAT_DATA(uid, STAT_CAST_YB, "%d|%d|%d|%d|%d|%d|%d|%s|%s|%s", where, num, real, confirm, depleft, realleft, totalleft, acc, ip, mmc);

//��������(�û�ID����������������������ʣ������)
#define LOG_STAT_CAST_GD(where, num, left) \
	LOG_STAT_DATA(uid, STAT_CAST_GD, "%d|%d|%d", where, num, left);

//��������(�û�ID����������������ID������������ʣ������)
#define LOG_STAT_CAST_ITEM(where, itemid, num, left) \
	LOG_STAT_DATA(uid, STAT_CAST_ITEM, "%d|%d|%d|%d", where, itemid, num, left);

//��������(�û�ID����������������������֮ǰ�ȼ���֮��ȼ���ʣ������)
#define LOG_STAT_CAST_PHP(where, num, levelbefore, levelafter, left) \
	LOG_STAT_DATA(uid, STAT_CAST_PHP, "%d|%d|%d|%d|%d", where, num, levelbefore, levelafter, left);

//���ͻ�ȡ(�û�ID���������������Ŀ���ID������������ʣ������)
#define LOG_STAT_GET_XK(uid, where, cardid, num, left) \
	LOG_STAT_DATA(uid, STAT_GET_XK, "%d|%d|%d|%d", where, cardid, num, left);

//Ԫ�����(�û�ID����������������������Ԫ����������ȷ�Ͻ������ֵԪ����ʣ������Ԫ����ʣ����Ԫ�����˺ţ�IP��MMC)
#define LOG_STAT_GET_YB(uid, where, num, real, confirm, depleft, realleft, totalleft, acc, ip, mmc) \
	LOG_STAT_DATA(uid, STAT_GET_YB, "%d|%d|%d|%d|%d|%d|%d|%s|%s|%s", where, num, real, confirm, depleft, realleft, totalleft, acc, ip, mmc);

//�������(�û�ID��������������������ʣ������)
#define LOG_STAT_GET_GD(uid, where, num, left) \
	LOG_STAT_DATA(uid, STAT_GET_GD, "%d|%d|%d", where, num, left);

//���ƻ��(�û�ID���������������ID���������)
#define LOG_STAT_GET_CARD(uid, where, carid, num) \
	LOG_STAT_DATA(uid, STAT_GET_CARD, "%d|%d|%d", where, carid, num);

//�������(�û�ID��������������������ʣ������)
#define LOG_STAT_GET_PHP(uid, where, num, left) \
	LOG_STAT_DATA(uid, STAT_GET_PHP, "%d|%d|%d", where, num, left);

//���幱�׻��(�û�ID��������������������ʣ�๱��)
#define LOG_STAT_GET_JZGX(uid, where, num, left) \
	LOG_STAT_DATA(uid, STAT_GET_JZGX, "%d|%d|%d", where, num, left);

//���߻��(�û�ID���������������ID�����������ʣ������)
#define LOG_STAT_GET_ITEM(where, itemid, num, left) \
	LOG_STAT_DATA(uid, STAT_GET_ITEM, "%d|%d|%d|%d", where, itemid, num, left);

//ͨ�عؿ�(�û�ID��ͨ���ؿ�ID)
#define LOG_STAT_PASS_GQ(uid, gqid) \
	LOG_STAT_DATA(uid, STAT_PASS_GQ, "%d", gqid);

//��������(�û�ID��ͨ������)
#define LOG_STAT_PASS_WL(uid, layer) \
	LOG_STAT_DATA(uid, STAT_PASS_WL, "%d", layer);

//����ʹ��(�û�ID������ID)
#define LOG_STAT_USE_GN(uid, gnid) \
	LOG_STAT_DATA(uid, STAT_USE_GN, "%d", gnid);

//���ȡ(�û�ID���ID)
#define LOG_STAT_ACT_REWARD(uid, actid) \
	LOG_STAT_DATA(uid, STAT_ACT_REWARD, "%d", actid);

//��������(�û�ID������ID)
#define LOG_STAT_GUIDE(uid, gid) \
	LOG_STAT_DATA(uid, STAT_GUIDE, "%d", gid);

//��ҿ���(�û�ID���ǳƣ��������ȼ�����Ҿ��飬VIP�ȼ���VIP���飬�ۼƳ�ֵ�����ң�Ԫ������������ɫ״̬�����ս����)
#define LOG_STAT_USER(uid, nick, qd, lv, exp, viplv, vipscore, totaldep, gold, money, php, state, maxpower) \
	LOG_STAT_DATA(uid, STAT_USER, "%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d", nick, qd, lv, exp, viplv, vipscore, totaldep, gold, money, php, state, maxpower);

//ʹ��CDKEY(�û�ID��CDKEY)
#define LOG_STAT_USE_CDKEY(uid, cdkey) \
	LOG_STAT_DATA(uid, STAT_USE_CDKEY, "%s", cdkey);

//����(�û�ID������ID)
#define LOG_STAT_LOG_PVE(uid, id) \
	LOG_STAT_DATA(uid, STAT_LOG_PVE, "%d", id);

//��������(�û�ID������ID,�����ȼ�)
#define LOG_STAT_LOG_BUILD(uid, id, level) \
	LOG_STAT_DATA(uid, STAT_LOG_BUILD, "%d|%d", id, level);

//��Դ(�û�ID����ԴID,��������,������)
#define LOG_STAT_LOG_RES(uid, id, add, num) \
	LOG_STAT_DATA(uid, STAT_LOG_RES, "%d|%d|%d", id, add, num);

//�ɴ�(�û�ID���ɴ�ID, �ɴ��ȼ�)
#define LOG_STAT_LOG_SHIP(uid, id, level) \
	LOG_STAT_DATA(uid, STAT_LOG_SHIP, "%d|%d", id, level);

//�̳ǹ������(�û�ID������ID,��������,ʹ�����õ�)
#define LOG_STAT_LOG_BUY_ITEM(uid, id, num, money) \
	LOG_STAT_DATA(uid, STAT_LOG_BUY_ITEM, "%d|%d|%d", id, num, money);

//ʹ�����õ�(�û�ID������, ����)
#define LOG_STAT_LOG_USE_MONEY(uid, type, num) \
	LOG_STAT_DATA(uid, STAT_LOG_USE_MONEY, "%d|%d", type, num);

/*RecEnd*/

#endif

