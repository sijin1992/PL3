--[[
    这个文件注册所有的消息
    格式是：
    reg[cmd] = "file:module"
    cmd = 数字的，不重复的命令号
    file = 不包含后缀名的文件名,用来表示state(每个lua文件被加载到独立的state中)
    module = 模块名。多个相关模块可能会放在一个文件中，用module分开
        一个module对应一组函数:
            module_feature:获取这个处理模块特征，比如所需数据
            module_do_logic:模块实际处理函数
]]

----
reg = {}
reg[0x1020] = {regist_init_ship_feature, regist_init_ship_do_logic}
reg[0x1022] = {is_online_feature, is_online_do_logic}
reg[0x1024] = {guide_step_feature, guide_step_do_logic}
reg[0x1026] = {update_res_feature, update_res_do_logic}
reg[0x1028] = {aid_award_feature, aid_award_do_logic}
reg[0x1030] = {get_strength_feature, get_strength_do_logic}
reg[0x1032] = {add_strength_feature, add_strength_do_logic}
reg[0x1050] = {get_knight_bag_feature, get_knight_bag_do_logic}
reg[0x1052] = {get_item_package_feature, get_item_package_do_logic}
reg[0x1054] = {update_timestamp_feature, update_timestamp_do_logic}
reg[0x1058] = {client_code_set_feature, client_code_set_do_logic}
reg[0x105a] = {get_extdata_at5am_feature, get_extdata_at5am_do_logic}
reg[0x105c] = {get_huodong_flag_feature, get_huodong_flag_do_logic}

reg[0x1038] = {planet_get_feature, planet_get_do_logic}
reg[0x103a] = {planet_collect_feature, planet_collect_do_logic}
reg[0x103c] = {pvp_video_feature, pvp_video_do_logic}
reg[0x103e] = {planet_speed_up_feature, planet_speed_up_do_logic}
reg[0x1040] = {planet_ruins_feature, planet_ruins_do_logic}
reg[0x1042] = {planet_move_base_feature, planet_move_base_do_logic}
reg[0x1044] = {planet_ride_back_feature, planet_ride_back_do_logic}
reg[0x1046] = {planet_raid_feature, planet_raid_do_logic}
reg[0x1048] = {planet_mark_feature, planet_mark_do_logic}

reg[0x104a] = {planet_shield_base_feature, planet_shield_base_do_logic}
reg[0x104c] = {planet_tower_feature, planet_tower_do_logic}
reg[0x104e] = {planet_wangzuo_title_feature, planet_wangzuo_title_logic}

reg[0x105e] = {open_chest_feature, open_chest_do_logic}
reg[0x1060] = {sell_item_feature, sell_item_do_logic}
reg[0x1062] = {get_tili_reward_feature, get_tili_reward_do_logic}
reg[0x1064] = {open_gift_feature, open_gift_do_logic}
reg[0x1066] = {reflesh_qy_feature, reflesh_qy_do_logic}
reg[0x1068] = {get_qy_feature, get_qy_do_logic}
reg[0x106a] = {del_qy_feature, del_qy_do_logic}

reg[0x10fe] = {ship_fix_feature, ship_fix_do_logic}
reg[0x1100] = {get_ship_list_feature, get_ship_list_do_logic}
reg[0x1102] = {change_lineup_feature, change_lineup_do_logic}
reg[0x1104] = {change_weapon_feature, change_weapon_do_logic}
reg[0x1106] = {ship_develope_feature, ship_develope_do_logic}
reg[0x1108] = {blueprint_develope_feature, blueprint_develope_do_logic}
reg[0x110a] = {ship_create_feature, ship_create_do_logic}
reg[0x110c] = {ship_remove_feature, ship_remove_do_logic}
reg[0x110e] = {ship_equip_feature, ship_equip_do_logic}

reg[0x1110] = {trade_get_money_feature, trade_get_money_do_logic}
reg[0x1112] = {weapon_upgrade_feature, weapon_upgrade_do_logic}

reg[0x1114] = {get_home_feature, get_home_do_logic}
reg[0x1116] = {get_resource_feature, get_resource_do_logic}
reg[0x1118] = {upgrade_resource_feature, upgrade_resource_do_logic}
reg[0x111a] = {remove_resource_feature, remove_resource_do_logic}
reg[0x111c] = {cancel_build_feature, cancel_build_do_logic}
reg[0x111e] = {speed_up_build_feature, speed_up_build_do_logic}

reg[0x1120] = {upgrade_technology_feature, upgrade_technology_do_logic}
reg[0x1122] = {get_technology_feature, get_technology_do_logic}
reg[0x1124] = {speed_up_technology_feature, speed_up_technology_do_logic}

reg[0x112e] = {equip_create_feature, equip_create_do_logic}
reg[0x1130] = {equip_strength_feature, equip_strength_do_logic}
reg[0x1132] = {ship_break_feature, ship_break_do_logic}
reg[0x1134] = {equip_resolve_feature, equip_resolve_do_logic}
reg[0x1136] = {ship_add_exp_feature, ship_add_exp_do_logic}
reg[0x1138] = {resolve_blueprint_feature, resolve_blueprint_do_logic}
reg[0x1140] = {ship_add_energy_exp_feature, ship_add_energy_exp_do_logic}
reg[0x1142] = {ship_lock_energy_time_feature, ship_lock_energy_time_do_logic}

reg[0x1150] = {equip_levelup_feature, equip_levelup_do_logic}
reg[0x1152] = {equip_starup_feature, equip_starup_do_logic}
reg[0x1154] = {equip_purify_feature, equip_purify_do_logic}
reg[0x1156] = {equip_refine_feature, equip_refine_do_logic}
reg[0x1158] = {equip_recoin_feature, equip_recoin_do_logic}
reg[0x115a] = {equip_enchase_feature, equip_enchase_do_logic}

reg[0x1160] = {gem_equip_feature, gem_equip_do_logic}
reg[0x1162] = {mix_gem_feature, mix_gem_do_logic}

reg[0x1168] = {mj_equip_feature, mj_equip_do_logic}
reg[0x116a] = {mj_levelup_feature, mj_levelup_do_logic}
reg[0x1166] = {mj_mix_feature, mj_mix_do_logic}
reg[0x116c] = {mj_jinjie_feature, mj_jinjie_do_logic}

reg[0x1070] = {skill_levelup_feature, skill_levelup_do_logic}

reg[0x1072] = {open_book_feature, open_book_do_logic}
reg[0x1074] = {book_levelup_feature, book_levelup_do_logic}

reg[0x1076] = {open_lover_feature, open_lover_do_logic}
reg[0x1078] = {lover_levelup_feature, lover_levelup_do_logic}

reg[0x107a] = {money2gold_feature, money2gold_do_logic}
reg[0x107c] = {money2hp_feature, money2hp_do_logic}
reg[0x107e] = {ship_lottery_feature, ship_lottery_do_logic}
reg[0x108a] = {choujiang_huodong_feature, choujiang_huodong_do_logic}

reg[0x1080] = {task_list_feature, task_list_do_logic}
reg[0x1082] = {task_reward_feature, task_reward_do_logic}
reg[0x1084] = {get_chengjiu_reward_feature, get_chengjiu_reward_do_logic}
reg[0x1086] = {get_daily_reward_feature, get_daily_reward_do_logic}
reg[0x1088] = {get_vip_reward_feature, get_vip_reward_do_logic}


reg[0x1200] = {fight_feature, fight_do_logic}

reg[0x1210] = {pve_get_reward_feature, pve_get_reward_do_logic}
reg[0x1212] = {pve_watchshow_feature, pve_watchshow_do_logic}
reg[0x1214] = {pve_clear_feature, pve_clear_do_logic}
reg[0x1216] = {pve_jingying_reset_feature, pve_jingying_reset_do_logic}
reg[0x1218] = {special_stage_feature, special_stage_do_logic}

reg[0x1250] = {pve2_reset_feature, pve2_reset_do_logic}
reg[0x1252] = {pve2_get_enemy_feature, pve2_get_enemy_do_logic}
reg[0x1254] = {pve2_set_zhenxing_feature, pve2_set_zhenxing_do_logic}
reg[0x1256] = {pve2_fight_feature, pve2_fight_do_logic}
reg[0x1258] = {pve2_get_reward_feature, pve2_get_reward_do_logic}
reg[0x125a] = {pve2_select_buff_feature, pve2_select_buff_do_logic}
reg[0x125c] = {pve2_reflesh_shop_feature, pve2_reflesh_shop_do_logic}
reg[0x125e] = {pve2_shopping_feature, pve2_shopping_do_logic}

reg[0x1274] = {trial_get_reward_feature,trial_get_reward_do_logic}
reg[0x1276] = {trial_add_ticket_feature,trial_add_ticket_do_logic}
reg[0x1278] = {trial_get_times_feature,trial_get_times_do_logic}
reg[0x1280] = {trial_area_feature, trial_area_do_logic}
reg[0x1282] = {trial_get_building_info_feature, trial_get_building_info_do_logic}
reg[0x1284] = {trial_pve_start_feature,trial_pve_start_do_logic}
reg[0x1286] = {trial_pve_end_feature,trial_pve_end_do_logic}

--排行榜
reg[0x1300] = {rank_feature, rank_do_logic}

--竞技场
reg[0x1320] = {arena_info_feature, arena_info_do_logic}
reg[0x1322] = {arena_challenge_feature, arena_challenge_do_logic}
reg[0x1324] = {arena_add_times_feature, arena_add_times_do_logic}
reg[0x1326] = {arena_get_daily_reward_feature, arena_get_daily_reward_do_logic}
reg[0x1328] = {arena_title_feature, arena_title_do_logic}
--世界BOSS

reg[0x1350] = {wboss_get_userinfo_feature, wboss_get_userinfo_do_logic}
reg[0x1352] = {wboss_get_rank_reward_list_feature, wboss_get_rank_reward_list_do_logic}
reg[0x1354] = {wboss_attack_feature, wboss_attack_do_logic}
reg[0x1356] = {wboss_rank_feature, wboss_rank_do_logic}

--杯赛
reg[0x1360] = {wlzb_reg_feature, wlzb_reg_do_logic}
reg[0x1362] = {wlzb_rcd_feature, wlzb_rcd_do_logic}
reg[0x1364] = {wlzb_get_fight_info_feature, wlzb_get_fight_info_do_logic}
reg[0x1366] = {wlzb_reward_feature, wlzb_reward_do_logic}
reg[0x1368] = {wlzb_reward_list_feature, wlzb_reward_list_do_logic}
--reg[0x120a] = "cmd_pve:test1"

reg[0x1400] = {get_mail_list_feature, get_mail_list_do_logic}
reg[0x1402] = {read_mail_feature, read_mail_do_logic}
reg[0x1404] = {del_mail_feature, del_mail_do_logic}
reg[0x1406] = {send_mail_feature, send_mail_do_logic}
reg[0x1408] = {read_mail_list_feature, read_mail_list_do_logic}

reg[0x141e] = {get_friends_info_feature, get_friends_info_do_logic}
reg[0x1420] = {apply_friend_feature, apply_friend_do_logic}
reg[0x1422] = {accept_friend_feature, accept_friend_do_logic}
reg[0x1426] = {remove_friend_feature, remove_friend_do_logic}
reg[0x1428] = {black_list_feature, black_list_do_logic}
reg[0x1430] = {talk_list_feature, talk_list_do_logic}
reg[0x1432] = {friend_add_tili_feature, friend_add_tili_do_logic}
reg[0x1434] = {friend_read_tili_feature, friend_read_tili_do_logic}

reg[0x1450] = {get_activity_list_feature, get_activity_list_do_logic}
reg[0x1452] = {activity_change_feature, activity_change_do_logic}
reg[0x1454] = {activity_sign_in_feature, activity_sign_in_do_logic}
reg[0x1456] = {activity_first_recharge_feature, activity_first_recharge_do_logic}
reg[0x1458] = {activity_recharge_feature, activity_recharge_do_logic}
reg[0x145a] = {activity_credit_return_feature, activity_credit_return_do_logic}
reg[0x145c] = {activity_consume_feature, activity_consume_do_logic}
reg[0x145e] = {activity_seven_days_feature, activity_seven_days_do_logic}
reg[0x1460] = {activity_online_feature, activity_online_do_logic}
reg[0x1462] = {activity_power_feature, activity_power_do_logic}
reg[0x1464] = {activity_growth_fund_feature, activity_growth_fund_do_logic}
reg[0x1466] = {activity_invest_feature, activity_invest_do_logic}
reg[0x1468] = {activity_change_ship_feature, activity_change_ship_do_logic}
reg[0x146a] = {activity_month_sign_feature, activity_month_sign_do_logic}
reg[0x146c] = {activity_vip_pack_feature, activity_vip_pack_do_logic}
reg[0x1470] = {activity_every_day_feature, activity_every_day_do_logic}
reg[0x1472] = {activity_turntable_feature, activity_turntable_do_logic}
reg[0x1474] = {activity_advanced_money_feature, activity_advanced_money_do_logic}
reg[0x1476] = {activity_exchange_item_feature, activity_exchange_item_do_logic}

reg[0x1530] = {cjsz_exchange_list_feature, cjsz_exchange_list_do_logic}

reg[0x1512] = {cjsz_reward_feature, cjsz_reward_do_logic}
reg[0x1514] = {cjsz_total_sw_feature, cjsz_total_sw_do_logic}
reg[0x1516] = {day7_gift_feature, day7_gift_do_logic}
reg[0x1518] = {level_gift_feature, level_gift_do_logic}
reg[0x151a] = {get_newtask_feature, get_newtask_do_logic}
reg[0x151c] = {newtask_reward_feature, newtask_reward_do_logic}
reg[0x151e] = {chat_feature, chat_do_logic}
reg[0x1522] = {get_cz_rank_feature, get_cz_rank_do_logic}
reg[0x1524] = {get_chat_log_feature, get_chat_log_do_logic}

reg[0x1532] = {get_ljcz_feature, get_ljcz_do_logic}
reg[0x1534] = {get_dbcz_feature, get_dbcz_do_logic}
reg[0x1536] = {get_login_feature, get_login_do_logic}
reg[0x1538] = {get_xffl_feature, get_xffl_do_logic}
reg[0x153a] = {ljcz_reward_feature, ljcz_reward_do_logic}
reg[0x153c] = {dbcz_reward_feature, dbcz_reward_do_logic}
reg[0x153e] = {lxdl_reward_feature, lxdl_reward_do_logic}
reg[0x1540] = {xffl_reward_feature, xffl_reward_do_logic}
reg[0x1542] = {new_level_feature, new_level_do_logic}
reg[0x1544] = {new_level_reward_feature, new_level_reward_do_logic}
reg[0x1546] = {duihuan_info_feature, duihuan_info_do_logic}
reg[0x1548] = {duihuan_feature, duihuan_do_logic}
reg[0x154a] = {get_ljxffl_feature, get_ljxffl_do_logic}
reg[0x154c] = {ljxffl_reward_feature, ljxffl_reward_do_logic}

reg[0x1550] = {huodong_list_feature, huodong_list_do_logic}

reg[0x1554] = {Get_TOPAct_feature, Get_TOPAct_do_logic}

reg[0x1600] = {create_group_feature, create_group_do_logic}
reg[0x1602] = {get_group_feature, get_group_do_logic}
reg[0x1604] = {group_contribute_feature, group_contribute_do_logic}
reg[0x1606] = {group_levelup_feature, group_levelup_do_logic}
reg[0x1608] = {group_tech_levelup_feature, group_tech_levelup_do_logic}
reg[0x160a] = {group_get_tech_feature, group_get_tech_do_logic}
reg[0x160c] = {group_join_condition_feature, group_join_condition_do_logic}
reg[0x160e] = {group_join_req_feature, group_join_req_do_logic}
reg[0x1610] = {group_allow_feature, group_allow_do_logic}
reg[0x1612] = {group_exit_feature, group_exit_do_logic}
reg[0x1614] = {group_kick_feature, group_kick_do_logic}
reg[0x1616] = {group_job_feature, group_job_do_logic}
reg[0x1618] = {group_disband_feature, group_disband_do_logic}
reg[0x161a] = {group_search_feature, group_search_do_logic}
reg[0x161c] = {group_refresh_shop_feature, group_refresh_shop_do_logic}
reg[0x161e] = {group_shopping_feature, group_shopping_do_logic}
reg[0x1620] = {group_broadcast_feature, group_broadcast_do_logic}
reg[0x1622] = {group_contribute_cd_feature, group_contribute_cd_do_logic}

reg[0x1624] = {group_help_list_feature, group_help_list_do_logic}
reg[0x1626] = {group_request_help_feature, group_request_help_do_logic}
reg[0x1628] = {group_help_feature, group_help_do_logic}

reg[0x1630] = {group_pve_get_info_feature, group_pve_get_info_do_logic}
reg[0x1632] = {group_pve_feature, group_pve_do_logic}
reg[0x1634] = {group_pve_ok_feature, group_pve_ok_do_logic}
reg[0x1636] = {group_pve_add_times_feature, group_pve_add_times_do_logic}
reg[0x1638] = {group_pve_reward_feature, group_pve_reward_do_logic}

reg[0x1640] = {group_invite_feature, group_invite_do_logic}
reg[0x1642] = {group_worship_feature, group_worship_do_logic}

reg[0x1700] = {mpz_get_info_feature,	mpz_get_info_do_logic}
reg[0x1702] = {mpz_get_rcd_feature,		mpz_get_rcd_do_logic}
reg[0x1704] = {mpz_master_reg_feature,	mpz_master_reg_do_logic}
reg[0x1706] = {mpz_mem_reg_feature,		mpz_mem_reg_do_logic}

reg[0x1710] = {tianji_info_feature,	tianji_info_do_logic}
reg[0x1712] = {tianji_feature,		tianji_do_logic}
reg[0x1714] = {tianji_reward_feature,		tianji_reward_do_logic}
reg[0x1716] = {tianji_reward_info_feature,	tianji_reward_info_do_logic}


reg[0x171a] = {shop_buy_feature, shop_buy_do_logic}
reg[0x171c] = {shop_time_item_list_feature, shop_time_item_list_do_logic}

reg[0x1730] = {slave_sync_data_feature, slave_sync_data_do_logic}
reg[0x1732] = {slave_get_res_feature, slave_get_res_do_logic}
reg[0x1734] = {slave_free_feature, slave_free_do_logic}
reg[0x1736] = {slave_show_feature, slave_show_do_logic}
reg[0x1738] = {slave_work_feature, slave_work_do_logic}
reg[0x173A] = {slave_fawn_on_feature, slave_fawn_on_do_logic}
reg[0x173C] = {slave_help_feature, slave_help_do_logic}
reg[0x173E] = {slave_search_feature, slave_search_do_logic}
reg[0x1740] = {slave_add_times_feature, slave_add_times_do_logic}
reg[0x1742] = {slave_attack_feature, slave_attack_do_logic}

reg[0x1830] = {building_upgrade_feature, building_upgrade_do_logic}
reg[0x1832] = {building_update_feature, building_update_do_logic}
reg[0x1834] = {building_upgrade_speed_up_feature, building_upgrade_speed_up_do_logic}
reg[0x1836] = {build_queue_add_feature, build_queue_add_do_logic}
reg[0x1838] = {build_queue_remove_feature, build_queue_remove_do_logic}

reg[0x19fa] = {get_other_user_info_list_feature, get_other_user_info_list_do_logic}
reg[0x19fc] = {get_other_user_info_feature, get_other_user_info_do_logic}

reg[0x19fe] = {client_gm_feature, client_gm_do_logic}

reg[0x2000] = {gm_fight_sim_feature, gm_fight_sim_do_logic}
reg[0x2002] = {gm_add_item_feature, gm_add_item_do_logic}

reg[0x18ff] = {test_add_money_feature, test_add_money_do_logic}


reg[0x151e] = {chat_feature, chat_do_logic}
reg[0x205] = {server_broadcast_feature, server_broadcast_do_logic}
--reg[0x5001] = "test:test"


