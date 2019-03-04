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
/* 上报统计数据,格式: 时间戳|进程号|文件名|行号|用户名|统计类型|其他格式数据	*/
/* 2014110514:50:23.137467|21692|login.cpp|214|fflala|LOGIN|result=0|platform=2|viplevel=8,year=1 */
/* LOG_STAT_DATA 参数username（用户ID）:const char*，参数datatype(统计类型):const char*, 参数format,args...格式数据 */
/************************************************************************/

#ifdef WIN32
	#define LOG_STAT_DATA(userid, stattype, format, ...) CELL_LOG(LOG_STAT, "%s|%s|"format"|end", stattype, userid, __VA_ARGS__);
#else
	#define LOG_STAT_DATA(userid, stattype, format, args...) CELL_LOG(LOG_STAT, "%s|%s|"format"|end", stattype, userid, ##args);
#endif
/************************************************************************/
/*	统计类型定义                                                        */
/************************************************************************/
/*TypeBegin*/
//注册
#define STAT_REGIST		"REGIST"
//登录
#define STAT_LOGIN		"LOGIN"
//充值
#define STAT_DEPOSIT	"DEPOSIT"
//离线
#define STAT_LOGOUT		"LOGOUT"
//升级
#define STAT_LEVEL_UP	"LEVEL_UP"
//设备
#define STAT_DEVICE		"DEVICE"
//在线统计
#define STAT_ONLINE		"ONLINE"
//元宝消耗
#define STAT_CAST_YB	"CAST_YB"
//银两消耗
#define STAT_CAST_GD	"CAST_GD"
//道具消耗
#define STAT_CAST_ITEM	"CAST_ITEM"
//体力消耗
#define STAT_CAST_PHP	"CAST_PHP"
//侠客获取
#define STAT_GET_XK		"GET_XK"
//元宝获得
#define STAT_GET_YB		"GET_YB"
//银两获得
#define STAT_GET_GD		"GET_GD"
//卡牌获得
#define STAT_GET_CARD	"GET_CARD"
//体力获得
#define STAT_GET_PHP	"GET_PHP"
//家族贡献获得
#define STAT_GET_JZGX	"GET_JZGX"
//道具获得
#define STAT_GET_ITEM	"GET_ITEM"
//通关关卡
#define STAT_PASS_GQ	"PASS_GQ"
//爬塔过关
#define STAT_PASS_WL	"PASS_WL"
//功能使用
#define STAT_USE_GN		"USE_GN"
//活动领取
#define STAT_ACT_REWARD	"ACT_REWARD"
//新手引导
#define STAT_GUIDE		"GUIDE"
//玩家快照
#define STAT_USER		"USER"
//使用CDKEY
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
/*		快捷记录宏                                                       */
/************************************************************************/
/*RecBegin*/

//注册(用户ID，IP地址， MCC移动设备国家码，账号)
#define LOG_STAT_REGIST(uid, ip, mmc, acc) \
	LOG_STAT_DATA(uid, STAT_REGIST, "%s|%s|%s", ip, mmc, acc);

//登录(用户ID，IP地址， MCC移动设备国家码，等级，账号)
#define LOG_STAT_LOGIN(uid, ip, mmc, level, acc) \
	LOG_STAT_DATA(uid, STAT_LOGIN, "%s|%s|%d|%s", ip, mmc, level, acc);

//充值(用户ID，充值金额，支付方式，是否首充，vip等级，vip积分)
#define LOG_STAT_DEPOSIT(uid, amount, paytype, isfirst, viplevel, vipscore) \
	LOG_STAT_DATA(uid, STAT_DEPOSIT, "%d|%d|%d|%d|%d", amount, paytype, isfirst, viplevel, vipscore);

//离线(用户ID，在线时间(秒)，账号)
#define LOG_STAT_LOGOUT(uid, oltime, acc) \
	LOG_STAT_DATA(uid, STAT_LOGOUT, "%ld|%s", oltime, acc);

//升级(用户ID，之前等级，之后等级）
#define LOG_STAT_LEVEL_UP(uid, levelbefore, levelafter) \
	LOG_STAT_DATA(uid, STAT_LEVEL_UP, "%d|%d", levelbefore, levelafter);

//设备(用户ID，终端机型，设备分辨率，所用操作系统，所用运营商，联网方式)
#define LOG_STAT_DEVICE(uid, stype, res, os, oper, cntype) \
	LOG_STAT_DATA(uid, STAT_DEVICE, "%s|%s|%s|%s|%s", stype, res, os, oper, cntype);

//在线统计(在线人数，区服ID)
#define LOG_STAT_ONLINE(olnum, areaid) \
	LOG_STAT_DATA(STAT_ONLINE, STAT_ONLINE, "%d|%s", olnum, areaid);

//元宝消耗(用户ID，消耗渠道，消耗数量，真元宝数，财务确认金额，留存充值元宝，剩余总真元宝，剩余总元宝，账号，IP，MMC)
#define LOG_STAT_CAST_YB(uid, where, num, real, confirm, depleft, realleft, totalleft, acc, ip, mmc) \
	LOG_STAT_DATA(uid, STAT_CAST_YB, "%d|%d|%d|%d|%d|%d|%d|%s|%s|%s", where, num, real, confirm, depleft, realleft, totalleft, acc, ip, mmc);

//银两消耗(用户ID，消耗渠道，消耗数量，剩余数量)
#define LOG_STAT_CAST_GD(where, num, left) \
	LOG_STAT_DATA(uid, STAT_CAST_GD, "%d|%d|%d", where, num, left);

//道具消耗(用户ID，消耗渠道，道具ID，消耗数量，剩余数量)
#define LOG_STAT_CAST_ITEM(where, itemid, num, left) \
	LOG_STAT_DATA(uid, STAT_CAST_ITEM, "%d|%d|%d|%d", where, itemid, num, left);

//体力消耗(用户ID，消耗渠道，消耗数量，之前等级，之后等级，剩余体力)
#define LOG_STAT_CAST_PHP(where, num, levelbefore, levelafter, left) \
	LOG_STAT_DATA(uid, STAT_CAST_PHP, "%d|%d|%d|%d|%d", where, num, levelbefore, levelafter, left);

//侠客获取(用户ID，消耗渠道，消耗卡牌ID，消耗数量，剩余数量)
#define LOG_STAT_GET_XK(uid, where, cardid, num, left) \
	LOG_STAT_DATA(uid, STAT_GET_XK, "%d|%d|%d|%d", where, cardid, num, left);

//元宝获得(用户ID，获得渠道，获得数量，真元宝数，财务确认金额，留存充值元宝，剩余总真元宝，剩余总元宝，账号，IP，MMC)
#define LOG_STAT_GET_YB(uid, where, num, real, confirm, depleft, realleft, totalleft, acc, ip, mmc) \
	LOG_STAT_DATA(uid, STAT_GET_YB, "%d|%d|%d|%d|%d|%d|%d|%s|%s|%s", where, num, real, confirm, depleft, realleft, totalleft, acc, ip, mmc);

//银两获得(用户ID，获得渠道，获得数量，剩余银两)
#define LOG_STAT_GET_GD(uid, where, num, left) \
	LOG_STAT_DATA(uid, STAT_GET_GD, "%d|%d|%d", where, num, left);

//卡牌获得(用户ID，获得渠道，卡牌ID，获得数量)
#define LOG_STAT_GET_CARD(uid, where, carid, num) \
	LOG_STAT_DATA(uid, STAT_GET_CARD, "%d|%d|%d", where, carid, num);

//体力获得(用户ID，获得渠道，获得数量，剩余体力)
#define LOG_STAT_GET_PHP(uid, where, num, left) \
	LOG_STAT_DATA(uid, STAT_GET_PHP, "%d|%d|%d", where, num, left);

//家族贡献获得(用户ID，获得渠道，获得数量，剩余贡献)
#define LOG_STAT_GET_JZGX(uid, where, num, left) \
	LOG_STAT_DATA(uid, STAT_GET_JZGX, "%d|%d|%d", where, num, left);

//道具获得(用户ID，获得渠道，道具ID，获得数量，剩余数量)
#define LOG_STAT_GET_ITEM(where, itemid, num, left) \
	LOG_STAT_DATA(uid, STAT_GET_ITEM, "%d|%d|%d|%d", where, itemid, num, left);

//通关关卡(用户ID，通过关卡ID)
#define LOG_STAT_PASS_GQ(uid, gqid) \
	LOG_STAT_DATA(uid, STAT_PASS_GQ, "%d", gqid);

//爬塔过关(用户ID，通过层数)
#define LOG_STAT_PASS_WL(uid, layer) \
	LOG_STAT_DATA(uid, STAT_PASS_WL, "%d", layer);

//功能使用(用户ID，功能ID)
#define LOG_STAT_USE_GN(uid, gnid) \
	LOG_STAT_DATA(uid, STAT_USE_GN, "%d", gnid);

//活动领取(用户ID，活动ID)
#define LOG_STAT_ACT_REWARD(uid, actid) \
	LOG_STAT_DATA(uid, STAT_ACT_REWARD, "%d", actid);

//新手引导(用户ID，引导ID)
#define LOG_STAT_GUIDE(uid, gid) \
	LOG_STAT_DATA(uid, STAT_GUIDE, "%d", gid);

//玩家快照(用户ID，昵称，渠道，等级，玩家经验，VIP等级，VIP经验，累计充值，银币，元宝，体力，角色状态，最大战斗力)
#define LOG_STAT_USER(uid, nick, qd, lv, exp, viplv, vipscore, totaldep, gold, money, php, state, maxpower) \
	LOG_STAT_DATA(uid, STAT_USER, "%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d", nick, qd, lv, exp, viplv, vipscore, totaldep, gold, money, php, state, maxpower);

//使用CDKEY(用户ID，CDKEY)
#define LOG_STAT_USE_CDKEY(uid, cdkey) \
	LOG_STAT_DATA(uid, STAT_USE_CDKEY, "%s", cdkey);

//副本(用户ID，副本ID)
#define LOG_STAT_LOG_PVE(uid, id) \
	LOG_STAT_DATA(uid, STAT_LOG_PVE, "%d", id);

//建筑升级(用户ID，建筑ID,建筑等级)
#define LOG_STAT_LOG_BUILD(uid, id, level) \
	LOG_STAT_DATA(uid, STAT_LOG_BUILD, "%d|%d", id, level);

//资源(用户ID，资源ID,增加数量,总数量)
#define LOG_STAT_LOG_RES(uid, id, add, num) \
	LOG_STAT_DATA(uid, STAT_LOG_RES, "%d|%d|%d", id, add, num);

//飞船(用户ID，飞船ID, 飞船等级)
#define LOG_STAT_LOG_SHIP(uid, id, level) \
	LOG_STAT_DATA(uid, STAT_LOG_SHIP, "%d|%d", id, level);

//商城购买道具(用户ID，道具ID,道具数量,使用信用点)
#define LOG_STAT_LOG_BUY_ITEM(uid, id, num, money) \
	LOG_STAT_DATA(uid, STAT_LOG_BUY_ITEM, "%d|%d|%d", id, num, money);

//使用信用点(用户ID，类型, 数量)
#define LOG_STAT_LOG_USE_MONEY(uid, type, num) \
	LOG_STAT_DATA(uid, STAT_LOG_USE_MONEY, "%d|%d", type, num);

/*RecEnd*/

#endif

