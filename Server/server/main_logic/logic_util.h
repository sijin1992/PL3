#ifndef __LOGIC_UTIL_H__
#define __LOGIC_UTIL_H__
// 原则上尽可能将逻辑集中在此处，而不是扩散到框架中
#include<string>

#include "common/msg_define.h"

#include "proto/UserInfo.pb.h"
#include "proto/Item.pb.h"
#include "proto/Mail.pb.h"
#include "proto/AirShip.pb.h"
#include "proto/CmdLogin.pb.h"

#define MAX_EQUIP_NUM 8
#define MAX_ZHENXING 7

#define DATA_VER 25

int create_user(const USER_NAME& user_name, const RegistReq &req, UserInfo& user_info, ShipList& ship_list, ItemList& item_list, MailList& mail_list);
int update_user(const USER_NAME& user_name, UserInfo& user_info, ShipList& ship_list, ItemList& item_list, MailList& mail_list);

#endif // __LOGIC_UTIL_H__
