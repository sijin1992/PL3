#ifndef  __ALL_CLIENT_H__
#define __ALL_CLIENT_H__


#include "client_interface.h"
#include "client_login.h"
#include "client_logout.h"
#include "client_regist.h"
#include "client_heartbeat.h"

#include "client_sync.h"

#include "client_test.h"
#include "client_pve.h"
#include "client_knight.h"
#include "client_user.h"
#include "client_equip.h"
#include "client_skill.h"
#include "client_pvp.h"
#include "client_mail.h"
#include "client_huodong.h"
#include "client_trial.h"
#include "client_wboss.h"
#include "client_group.h"
#include "client_server.h"
#include "client_gm.h"
#include "client_robmine.h"

typedef map<int, CClientInterface*> CLIENT_MAP;

class CAllClient
{
public:
	static void fill_req_map(CLIENT_MAP& themap)
	{
		themap[CMD_LOGIN_REQ] = new CClientLogin;
		themap[CMD_LOGOUT_REQ] = new CClientLogout;
		themap[CMD_REGIST_REQ] = new CClientRegist;
		themap[CMD_HEART_BEAT_REQ] = new CClientHeartBeat;
		themap[CMD_USERLOG_REQ] = new CClientUserLog;

		themap[CMD_MOVE_IN_ROOM_REQ] = new CClientMove;


		themap[CMD_PVE_REQ] = new CClientPVE;
		themap[CMD_PVE_REQ+10] = new CClientPVEt;
		themap[CMD_SPECIAL_STAGE_REQ] = new CClientSpStage;
		themap[CMD_GET_KNIGHT_BAG_REQ] = new CClientGetKnight;
		themap[CMD_KNIGHT_LEVELUP_REQ] = new CClientKnightLevUp;
		themap[CMD_KNIGHT_EVOLUTION_UP_REQ] = new CClientKnightEvolutionUp;
		themap[CMD_KNIGHT_ENLIST_REQ] = new CClientKnightEnlist;
//		themap[CMD_QIANNENG_REQ] = new CClientKnightQianNengUp;
		
		themap[CMD_SET_ZHENXING_REQ] = new CClientSetZhenxing;
		themap[CMD_EQUIP_LEVELUP_REQ] = new CClientEquipLevUp;
		themap[CMD_EQUIP_STARUP_REQ]= new CClientEquipStarUp;
		themap[CMD_LEAD_STARUP_REQ]= new CClientLeadStarUp;
		themap[CMD_SKILL_LEVELUP_REQ] = new CClientSkillLevUp;

		themap[CMD_GET_ITEM_PACKAGE_REQ] = new CClientGetItem;
		themap[CMD_PVE_GET_REWARD_REQ] = new CClientPVEget_reward;
		themap[CMD_PVE_WATCH_SHOW_REQ] = new CClientPVEWatchShow;
		themap[CMD_PVE_CLEAR_REQ] = new CClientPVEClear;
		themap[CMD_PVE2_RESET_REQ] = new CClientPVE2Reset;
		themap[CMD_PVE2_SET_ZHENXING_REQ] = new CClientPVE2SetZhenxing;
		themap[CMD_PVE2_GET_ENEMY_REQ] = new CClientPVE2GetEnemy;
		themap[CMD_PVE2_FIGHT_REQ] = new CClientPVE2Fight;
		themap[CMD_PVE2_GET_REWARD_REQ] = new CClientPVE2GetReward;
		themap[CMD_PVE2_SELECT_BUFF_REQ] = new CClientPVE2SelectBuff;
		themap[CMD_PVE2_REFLESH_SHOP_REQ] = new CClientPVE2RefleshShop;
		themap[CMD_PVE2_SHOPPING_REQ] = new CClientPVE2Shopping;
		themap[CMD_PVE_RESET_JINGYING_REQ] = new CClientJingyingReset;

		themap[CMD_PVE_TRIAL_INFO_REQ] = new CClientPVETrialInfo;
		themap[CMD_PVE_TRIAL_START_REQ] = new CClientPVETrialStart;
		
		themap[CMD_PVP_GET_RANKING_LIST_REQ] = new CClientPVPGetTarget;
		themap[CMD_PVP_RANKING_TOPN_REQ] = new CClientPVPGetTop50;
		themap[CMD_PVP_RANKING_SELF_REQ] = new CClientPVPGetSelf;
		themap[CMD_PVP_GET_DETAIL_REQ] = new CClientPVPGetDetail;
		themap[CMD_PVP_GET_PVPINFO_REQ] = new CClientPVPGetPVPInof;
		themap[CMD_PVP_GET_RCD_REQ] = new CClientPVPGetRcd;
		themap[CMD_PVP_REFLESH_SHOP_REQ] = new CClientPVPRefleshShop;
		themap[CMD_PVP_SHOPPING_REQ] = new CClientPVPShopping;
		themap[CMD_PVP_MONEY2CHANCE_REQ] = new CClientPVPMoney2Chance;

		themap[CMD_WBOSS_USER_INFO_GET_REQ] = new CClientWBossUserInfo;
		themap[CMD_WBOSS_GET_RANK_REWARD_LIST_REQ] = new CClientWBossRankRewardList;
		themap[CMD_WBOSS_ATTACK_REQ] = new CClientWBossAttack;
		themap[CMD_WBOSS_RANK_REQ] = new CClientWBossRank;

		themap[CMD_WLZB_REG_REQ] = new CClientWlzbReg;
		themap[CMD_WLZB_RCD_REQ] = new CClientWlzbRcd;
		themap[CMD_WLZB_GET_FIGHT_INFO_REQ] = new CClientWlzbSelf;
		themap[CMD_WLZB_REWARD_REQ] = new CClientWlzbReward;
		themap[CMD_WLZB_GET_REWARD_LIST_REQ] = new CClientWlzbRewardList;

		themap[CMD_OPEN_BOOK_REQ] = new CClientOpenBook;
		themap[CMD_BOOK_LEVELUP_REQ] = new CClientBookLevelUp;
		themap[CMD_OPEN_LOVER_REQ] = new CClientOpenLover;
		themap[CMD_LOVER_LEVELUP_REQ] = new CClientLoverLevelUp;
		themap[CMD_UPDATE_TIMESTAMP_REQ] = new CClientUpdateTimestamp;

		themap[CMD_OPEN_CHEST_REQ] = new CClientOpenChest;
		themap[CMD_SELL_ITEM_REQ] = new CClientSellItem;
		themap[CMD_TILI_REWARD_REQ] = new CClientGetTiliReward;
		themap[CMD_USE_ITEM_REQ] = new CClientUseItem;

		themap[CMD_TAKE_TASK_REQ] = new CClientTakeTask;
		themap[CMD_GET_TASK_REWARD_REQ] = new CClientGetTaskReward;
		themap[CMD_GET_CHENGJIU_REWARD_REQ] = new CClientGetChengjiuReward;
        themap[CMD_GET_DAILY_REWARD_REQ] = new CClientGetDailyReward;
		themap[CMD_GET_VIP_REWARD_REQ] = new CClientGetVipReward;

		themap[CMD_GET_TASK_LIST_REQ] = new CClientGetTaskList;

		themap[CMD_GONG_EQUIP_REQ] = new CClientGongEquip;
		themap[CMD_GONG_MERGE_REQ] = new CClientGongMerge;
		themap[CMD_GONG_MIX_REQ] = new CClientGongMix;
		themap[CMD_MIJI_EQUIP_REQ] = new CClientMJEquip;
		themap[CMD_MIJI_LEVELUP_REQ] = new CClientMJLevelup;
		themap[CMD_MIJI_MIX_REQ] = new CClientMJMix;
		themap[CMD_MIJI_JINJIE_REQ] = new CClientMJJinjie;

		themap[CMD_MONEY2GOLD_REQ] = new CClientMoney2Gold;
		themap[CMD_MONEY2HP_REQ] = new CClientMoney2HP;
		themap[CMD_CHOUJIANG_REQ] = new CClientChouJiang;
		themap[CMD_CHOUJIANG_HUODONG_REQ] = new CClientChoujiangHuodong;
		
		themap[CMD_PVP_REQ] = new CClientPVPFight;

		themap[CMD_GET_MAIL_LIST_REQ] = new CClientGetMailList;
		themap[CMD_READ_MAIL_REQ] = new CClientReadMail;
//		themap[10086] = new CClientShuapotian;

        themap[CMD_HUODONG_LIST_REQ] = new CClientHuodongList;
        themap[CMD_HUODONG_CAISHENDAO_REQ] = new CClientCaishendao;
        themap[CMD_CANGJIAN_GET_SHOPLIST_REQ] = new CClientCangjianGetShopList;
        themap[CMD_CANGJIAN_SHOPPING_REQ] = new CClientCangjianShopping;		
		themap[CMD_CANGJIAN_SHENGWANG_SHOPPING_REQ] = new CClientCangjianShengwangShopping;
		themap[CMD_QIANDAO_REQ] = new CClientQiandao;
		themap[CMD_GET_CZFL_REQ] = new CClientGetCzfl;
		themap[CMD_CZFL_REQ] = new CClientCzflReward;
		themap[CMD_CJSZ_TOP50_REQ] = new CClientCjszTop50;
		themap[CMD_CJSZ_REWARD_REQ] = new CClientCjszReward;
		themap[CMD_CJSZ_TOTAL_SW_REQ] = new CClientCjszTotalSW;
		themap[CMD_CJSZ_EXCNANGE_LIST_REQ] = new CClientCjszExchangeList;
		themap[CMD_CDKEY_REQ] = new CClientCDKeyGift;

		themap[CMD_CLIENT_CODE_SET_REQ] = new CClientSetCode;
		themap[CMD_GET_EXTDATA_AT_5AM_REQ] = new CClientGetExtdataAt5am;
		themap[CMD_GET_HUODONG_FLAG_REQ] = new CClientGetHuodongFlag;

		themap[CMD_XY_REFLESH_REQ] = new CClientXYReflesh;
		themap[CMD_XY_SHOPPING_REQ] = new CClientXYShopping;
		themap[CMD_TRANSFORM_REQ] = new CClientXYTransform;
		themap[CMD_VIP_SHOPPING_REQ] = new CClientVIPShopping;

		themap[CMD_CHAT_REQ] = new CClientChat;

		themap[CMD_REFLESH_QIYU_REQ] = new CClientRefleshQy;
		themap[CMD_GET_QIYU_REQ] = new CClientGetQy;

		themap[CMD_LEIJI_CHONGZHI_REQ] = new CClientLjcz;
		themap[CMD_DANBI_CHONGZHI_REQ] = new CClientDbcz;
		themap[CMD_LOGIN_HUODONG_REQ] = new CClientLoginHuodong;
		themap[CMD_XIAOFEI_REQ] = new CClientXffl;
		themap[CMD_LEIJI_CHONGZHI_REWARD_REQ] = new CClientLjczReward;
		themap[CMD_DANBI_CHONGZHI_REWARD_REQ] = new CClientDbczReward;
		themap[CMD_LOGIN_REWARD_REQ] = new CClientLoginHuodongReward;
		themap[CMD_XIAOFEI_REWARD_REQ] = new CClientXfflReward;

		themap[CMD_GET_TOP_ACT_REQ] = new CClientGetTOPAct;

		themap[0x18ff] = new CClientTest;

		themap[CMD_GET_CHONGZHI_LIST_REQ] = new CClientGetChongzhiList;

		themap[CMD_WXJY_REQ] = new CClientWXJY;

		themap[CMD_GET_GROUP_REQ] = new CClientGetGroup;
		themap[CMD_CREATE_GROUP_REQ] = new CClientCreateGroup;
		themap[CMD_GROUP_JUAN_REQ] = new CClientGroupJuan;
		themap[CMD_GROUP_LEVELUP_REQ] = new CClientGroupLevelup;
		themap[CMD_GROUP_JUEXUE_REQ] = new CClientGroupJuexue;
		themap[CMD_GROUP_BROADCAST_REQ]= new CClientGroupBroadcast;
		themap[CMD_GROUP_WXJY_REQ]= new CClientGroupWXJY;
		themap[CMD_GROUP_PVE_RESET_REQ]= new CClientGroupPVEReset;
		themap[CMD_GROUP_PVE_REQ]= new CClientGroupPVE;
		themap[CMD_GROUP_REWARD_ASK_REQ] = new CClientGroupAskReward;
		themap[CMD_GROUP_REWARD_ALLOT_REQ] = new CClientGroupAllotReward;
		themap[CMD_GROUP_RESET_SELF_PVE_REQ] = new CClientGroupResetSelfPVE;
		themap[CMD_GROUP_SEARCH_REQ] = new CClientGroupSearch;
		themap[CMD_GROUP_JOIN_REQ] = new CClientGroupJoinReq;
		themap[CMD_GROUP_ALLOW_JOIN_REQ] = new CClientGroupAllowJoin;
		themap[CMD_GROUP_EXIT_REQ] = new CClientGroupExit;
		themap[CMD_GROUP_KICK_REQ] = new CClientGroupKick;
		themap[CMD_GROUP_MASTER_REQ] = new CClientGroupMaster;
		themap[CMD_GROUP_DISBAND_REQ] = new CClientGroupDisband;

		themap[CMD_MPZ_GET_REQ] = new CClientMpzGetInfo;			//拉取服务器信息	
		themap[CMD_MPZ_GET_RCD_REQ] = new CClientMpzVideo;				//拉取战斗记录	
		themap[CMD_MPZ_MASTER_REG_REQ] = new CClientMpzSign;			//会长提交战场信息
		themap[CMD_MPZ_MEM_REG_REQ] = new CClientMpzMemSign;			//门派成员报名

		themap[CMD_GET_CZ_RANK_REQ] = new CClientGetCzRank;
		themap[CMD_NEW_LEVEL_REQ] = new CClientNewLevel;
		themap[CMD_NEW_LEVEL_REWARD_REQ] = new CClientNewLevelReward;
		themap[CMD_DUIHUAN_INFO_REQ] = new CClientDuihuanInfo;
		themap[CMD_DUIHUAN_REQ] = new CClientDuihuan;

		themap[CMD_TIANJI_GET_REQ] = new CClientTianJiInfo;
		themap[CMD_TIANJI_REQ] = new CClientTianJi;
		themap[CMD_TIANJI_REWARD_INFO_REQ] = new CClientTianJiRewardInfo;
		themap[CMD_TIANJI_REWARD_REQ] = new CClientTianJiReward;

		themap[CMD_LIMITSHOP_INFO_REQ] = new CClientLimitShopInfo;
		themap[CMD_LIMITSHOP_REQ] = new CClientLimitShop;

		themap[CMD_MINE_GET_REQ] = new CClientMineGetInfo;
		themap[CMD_MINE_ROB_REQ] = new CClientMineRob;
		themap[CMD_MINE_CHANGE_REQ] = new CClientMineSearch;
		themap[CMD_MINE_SET_FIGHTLIST_REQ] = new CClientMineSetFightList;
		themap[CMD_MINE_GET_JINGLI_REQ] = new CClientMineGetJingLi;
		themap[CMD_MINE_REWARD_REQ] = new CClientMineReward;
		themap[CMD_MINE_GET_RCD_REQ] = new CClientMineGetRcd;
		themap[CMD_MINE_GET_ENEMYLIST_REQ] = new CClientMineGetEnemylist;

		themap[CMD_HTTPCB_BROADCAST_REQ] = new CClientServerBroadcast;
		themap[CMD_QIANNENG_REQ] = new CClientQianNengUp;
		themap[CMD_GM_GET_USER_SNAP_REQ] = new CClientGMGetUserSnap;
	}

	static void fill_resp_map(CLIENT_MAP& themap)
	{
		themap[CMD_LOGIN_RESP] = new CClientLogin;
		themap[CMD_LOGOUT_RESP] = new CClientLogout;
		themap[CMD_HEART_BEAT_RESP] = new CClientHeartBeat;


		themap[CMD_TEST + 1] = new CClientTest;

		themap[CMD_SYNC_ROOM_RESP] = new CClientSync;
		themap[CMD_ROOM_SYNC_ON_LOGIN] = new CClientSyncOnLogin;

		themap[CMD_PVE_RESP] = new CClientPVE;
		themap[CMD_PVE_RESP+10] = new CClientPVEt;
		themap[CMD_SPECIAL_STAGE_RESP] = new CClientSpStage;
		themap[CMD_GET_KNIGHT_BAG_RESP] = new CClientGetKnight;
		themap[CMD_KNIGHT_LEVELUP_RESP] = new CClientKnightLevUp;
		themap[CMD_KNIGHT_EVOLUTION_UP_RESP] = new CClientKnightEvolutionUp;
		themap[CMD_KNIGHT_ENLIST_RESP] = new CClientKnightEnlist;
		//themap[CMD_QIANNENG_RESP] = new CClientKnightQianNengUp;
		
		themap[CMD_SET_ZHENXING_RESP] = new CClientSetZhenxing;
		themap[CMD_EQUIP_LEVELUP_RESP] = new CClientEquipLevUp;
		themap[CMD_EQUIP_STARUP_RESP]= new CClientEquipStarUp;
		themap[CMD_LEAD_STARUP_RESP]= new CClientLeadStarUp;
		themap[CMD_SKILL_LEVELUP_RESP] = new CClientSkillLevUp;

		themap[CMD_GET_ITEM_PACKAGE_RESP] = new CClientGetItem;
		//themap[CMD_USER_LEVELUP_RESP] = new CClientUserLevelup;

		themap[CMD_TASK_REFLEASH_RESP] = new CClientTaskReflesh;
		themap[CMD_NOTIFY_REFLESH_RESP] = new CClientNotify;
		
		themap[CMD_PVE_GET_REWARD_RESP] = new CClientPVEget_reward;
		themap[CMD_PVE_WATCH_SHOW_RESP] = new CClientPVEWatchShow;
		themap[CMD_PVE_CLEAR_RESP] = new CClientPVEClear;
		themap[CMD_PVE2_RESET_RESP] = new CClientPVE2Reset;
		themap[CMD_PVE2_SET_ZHENXING_RESP] = new CClientPVE2SetZhenxing;
		themap[CMD_PVE2_GET_ENEMY_RESP] = new CClientPVE2GetEnemy;
		themap[CMD_PVE2_FIGHT_RESP] = new CClientPVE2Fight;
		themap[CMD_PVE2_GET_REWARD_RESP] = new CClientPVE2GetReward;
		themap[CMD_PVE2_SELECT_BUFF_RESP] = new CClientPVE2SelectBuff;
		themap[CMD_PVE2_REFLESH_SHOP_RESP] = new CClientPVE2RefleshShop;
		themap[CMD_PVE2_SHOPPING_RESP] = new CClientPVE2Shopping;
		themap[CMD_PVE_RESET_JINGYING_RESP] = new CClientJingyingReset;
		
		themap[CMD_PVE_TRIAL_INFO_RESP] = new CClientPVETrialInfo;
		themap[CMD_PVE_TRIAL_START_RESP] = new CClientPVETrialStart;

		themap[CMD_PVP_GET_RANKING_LIST_RESP] = new CClientPVPGetTarget;
		themap[CMD_PVP_RANKING_TOPN_RESP] = new CClientPVPGetTop50;
		themap[CMD_PVP_RANKING_SELF_RESP] = new CClientPVPGetSelf;
		themap[CMD_PVP_GET_DETAIL_RESP] = new CClientPVPGetDetail;
		themap[CMD_PVP_GET_PVPINFO_RESP] = new CClientPVPGetPVPInof;
		themap[CMD_PVP_GET_RCD_RESP] = new CClientPVPGetRcd;
		themap[CMD_PVP_REFLESH_SHOP_RESP] = new CClientPVPRefleshShop;
		themap[CMD_PVP_SHOPPING_RESP] = new CClientPVPShopping;
		themap[CMD_PVP_MONEY2CHANCE_RESP] = new CClientPVPMoney2Chance;

		themap[CMD_WBOSS_USER_INFO_GET_RESP] = new CClientWBossUserInfo;
		themap[CMD_WBOSS_GET_RANK_REWARD_LIST_RESP] = new CClientWBossRankRewardList;
		themap[CMD_WBOSS_ATTACK_RESP] = new CClientWBossAttack;
		themap[CMD_WBOSS_RANK_RESP] = new CClientWBossRank;

		themap[CMD_WLZB_REG_RESP] = new CClientWlzbReg;
		themap[CMD_WLZB_RCD_RESP] = new CClientWlzbRcd;
		themap[CMD_WLZB_GET_FIGHT_INFO_RESP] = new CClientWlzbSelf;
		themap[CMD_WLZB_REWARD_RESP] = new CClientWlzbReward;
		themap[CMD_WLZB_GET_REWARD_LIST_RESP] = new CClientWlzbRewardList;

		themap[CMD_OPEN_BOOK_RESP] = new CClientOpenBook;
		themap[CMD_BOOK_LEVELUP_RESP] = new CClientBookLevelUp;
		themap[CMD_OPEN_LOVER_RESP] = new CClientOpenLover;
		themap[CMD_LOVER_LEVELUP_RESP] = new CClientLoverLevelUp;
		themap[CMD_UPDATE_TIMESTAMP_RESP] = new CClientUpdateTimestamp;

		themap[CMD_OPEN_CHEST_RESP] = new CClientOpenChest;
		themap[CMD_SELL_ITEM_RESP] = new CClientSellItem;
		themap[CMD_TILI_REWARD_RESP] = new CClientGetTiliReward;
		themap[CMD_USE_ITEM_RESP] = new CClientUseItem;

		themap[CMD_TAKE_TASK_RESP] = new CClientTakeTask;
		themap[CMD_GET_TASK_REWARD_RESP] = new CClientGetTaskReward;
		themap[CMD_GET_CHENGJIU_REWARD_RESP] = new CClientGetChengjiuReward;
        themap[CMD_GET_DAILY_REWARD_RESP] = new CClientGetDailyReward;
		themap[CMD_GET_VIP_REWARD_RESP] = new CClientGetVipReward;

		themap[CMD_GET_TASK_LIST_RESP] = new CClientGetTaskList;

		themap[CMD_GONG_EQUIP_RESP] = new CClientGongEquip;
		themap[CMD_GONG_MERGE_RESP] = new CClientGongMerge;
		themap[CMD_GONG_MIX_RESP] = new CClientGongMix;
		themap[CMD_MIJI_EQUIP_RESP] = new CClientMJEquip;
		themap[CMD_MIJI_LEVELUP_RESP] = new CClientMJLevelup;
		themap[CMD_MIJI_MIX_RESP] = new CClientMJMix;
		themap[CMD_MIJI_JINJIE_RESP] = new CClientMJJinjie;

		themap[CMD_MONEY2GOLD_RESP] = new CClientMoney2Gold;
		themap[CMD_MONEY2HP_RESP] = new CClientMoney2HP;
		themap[CMD_CHOUJIANG_RESP] = new CClientChouJiang;
		themap[CMD_CHOUJIANG_HUODONG_RESP] = new CClientChoujiangHuodong;

		themap[CMD_PVP_RESP] = new CClientPVPFight;

		themap[CMD_GET_MAIL_LIST_RESP] = new CClientGetMailList;
		themap[CMD_READ_MAIL_RESP] = new CClientReadMail;

        themap[CMD_HUODONG_LIST_RESP] = new CClientHuodongList;
        themap[CMD_HUODONG_CAISHENDAO_RESP] = new CClientCaishendao;
        themap[CMD_CANGJIAN_GET_SHOPLIST_RESP] = new CClientCangjianGetShopList;
        themap[CMD_CANGJIAN_SHOPPING_RESP] = new CClientCangjianShopping;
		themap[CMD_CANGJIAN_SHENGWANG_SHOPPING_RESP] = new CClientCangjianShengwangShopping;
		themap[CMD_QIANDAO_RESP] = new CClientQiandao;
		themap[CMD_GET_CZFL_RESP] = new CClientGetCzfl;
		themap[CMD_CZFL_RESP] = new CClientCzflReward;
		themap[CMD_CJSZ_TOP50_RESP] = new CClientCjszTop50;
		themap[CMD_CJSZ_REWARD_RESP] = new CClientCjszReward;
		themap[CMD_CJSZ_TOTAL_SW_RESP] = new CClientCjszTotalSW;
		themap[CMD_CJSZ_EXCNANGE_LIST_RESP] = new CClientCjszExchangeList;
		themap[CMD_CDKEY_RESP] = new CClientCDKeyGift;

		themap[CMD_CLIENT_CODE_SET_RESP] = new CClientSetCode;
		themap[CMD_GET_EXTDATA_AT_5AM_RESP] = new CClientGetExtdataAt5am;
		themap[CMD_GET_HUODONG_FLAG_RESP] = new CClientGetHuodongFlag;

		themap[CMD_XY_REFLESH_RESP] = new CClientXYReflesh;
		themap[CMD_XY_SHOPPING_RESP] = new CClientXYShopping;
		themap[CMD_TRANSFORM_RESP] = new CClientXYTransform;
		themap[CMD_VIP_SHOPPING_RESP] = new CClientVIPShopping;

		themap[CMD_CHAT_RESP] = new CClientChat;
		
		themap[CMD_GM_RESP] = new CClientTest;
		themap[CMD_ADD_MONEY_CALLBACK] = new CClientUserAddMoneyCB;
		themap[CMD_CHAT_MSG] = new CClientChatMsg;

		themap[CMD_LEIJI_CHONGZHI_RESP] = new CClientLjcz;
		themap[CMD_DANBI_CHONGZHI_RESP] = new CClientDbcz;
		themap[CMD_LOGIN_HUODONG_RESP] = new CClientLoginHuodong;
		themap[CMD_XIAOFEI_RESP] = new CClientXffl;
		themap[CMD_LEIJI_CHONGZHI_REWARD_RESP] = new CClientLjczReward;
		themap[CMD_DANBI_CHONGZHI_REWARD_RESP] = new CClientDbczReward;
		themap[CMD_LOGIN_REWARD_RESP] = new CClientLoginHuodongReward;
		themap[CMD_XIAOFEI_REWARD_RESP] = new CClientXfflReward;

		themap[CMD_REFLESH_QIYU_RESP] = new CClientRefleshQy;
		themap[CMD_GET_QIYU_RESP] = new CClientGetQy;

		themap[CMD_GET_TOP_ACT_RESP] = new CClientGetTOPAct;
		
		themap[CMD_GET_CHONGZHI_LIST_RESP] = new CClientGetChongzhiList;

		themap[CMD_WXJY_RESP] = new CClientWXJY;

		themap[CMD_GET_GROUP_RESP] = new CClientGetGroup;
		themap[CMD_CREATE_GROUP_RESP] = new CClientCreateGroup;
		themap[CMD_GROUP_JUAN_RESP] = new CClientGroupJuan;
		themap[CMD_GROUP_LEVELUP_RESP] = new CClientGroupLevelup;
		themap[CMD_GROUP_JUEXUE_RESP] = new CClientGroupJuexue;
		themap[CMD_GROUP_BROADCAST_RESP]= new CClientGroupBroadcast;
		themap[CMD_GROUP_WXJY_RESP]= new CClientGroupWXJY;
		themap[CMD_GROUP_PVE_RESET_RESP]= new CClientGroupPVEReset;
		themap[CMD_GROUP_PVE_RESP]= new CClientGroupPVE;
		themap[CMD_GROUP_REWARD_ASK_RESP] = new CClientGroupAskReward;
		themap[CMD_GROUP_REWARD_ALLOT_RESP] = new CClientGroupAllotReward;
		themap[CMD_GROUP_RESET_SELF_PVE_RESP] = new CClientGroupResetSelfPVE;
		themap[CMD_GROUP_SEARCH_RESP] = new CClientGroupSearch;
		themap[CMD_GROUP_JOIN_RESP] = new CClientGroupJoinReq;
		themap[CMD_GROUP_ALLOW_JOIN_RESP] = new CClientGroupAllowJoin;
		themap[CMD_GROUP_EXIT_RESP] = new CClientGroupExit;
		themap[CMD_GROUP_KICK_RESP] = new CClientGroupKick;
		themap[CMD_GROUP_MASTER_RESP] = new CClientGroupMaster;
		themap[CMD_GROUP_DISBAND_RESP] = new CClientGroupDisband;

		themap[CMD_MPZ_GET_RESP] = new CClientMpzGetInfo;
		themap[CMD_MPZ_GET_RCD_RESP] = new CClientMpzVideo;	
		themap[CMD_MPZ_MASTER_REG_RESP] = new CClientMpzSign;
		themap[CMD_MPZ_MEM_REG_RESP] = new CClientMpzMemSign;

		themap[CMD_GROUP_UPDATE] = new CClientGroupUpdate;

		themap[CMD_GET_CZ_RANK_RESP] = new CClientGetCzRank;
		themap[CMD_NEW_LEVEL_RESP] = new CClientNewLevel;
		themap[CMD_NEW_LEVEL_REWARD_RESP] = new CClientNewLevelReward;
		themap[CMD_DUIHUAN_INFO_RESP] = new CClientDuihuanInfo;
		themap[CMD_DUIHUAN_RESP] = new CClientDuihuan;

		themap[CMD_TIANJI_GET_RESP] = new CClientTianJiInfo;
		themap[CMD_TIANJI_RESP] = new CClientTianJi;
		themap[CMD_TIANJI_REWARD_INFO_RESP] = new CClientTianJiRewardInfo;
		themap[CMD_TIANJI_REWARD_RESP] = new CClientTianJiReward;

		themap[CMD_LIMITSHOP_INFO_RESP] = new CClientLimitShopInfo;
		themap[CMD_LIMITSHOP_RESP] = new CClientLimitShop;

		themap[CMD_MINE_GET_RESP] = new CClientMineGetInfo;
		themap[CMD_MINE_ROB_RESP] = new CClientMineRob;
		themap[CMD_MINE_CHANGE_RESP] = new CClientMineSearch;
		themap[CMD_MINE_SET_FIGHTLIST_RESP] = new CClientMineSetFightList;
		themap[CMD_MINE_GET_JINGLI_RESP] = new CClientMineGetJingLi;
		themap[CMD_MINE_REWARD_RESP] = new CClientMineReward;
		themap[CMD_MINE_GET_RCD_RESP] = new CClientMineGetRcd;
		themap[CMD_MINE_GET_ENEMYLIST_RESP] = new CClientMineGetEnemylist;

		themap[CMD_HTTPCB_BROADCAST_RESP] = new CClientServerBroadcast;
		themap[CMD_GM_GET_USER_SNAP_RESP] = new CClientGMGetUserSnap;
		themap[CMD_QIANNENG_RESP] = new CClientQianNengUp;
	}
};

#endif

