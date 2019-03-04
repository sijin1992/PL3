CREATE DATABASE IF NOT EXISTS db_gl_sdk_game DEFAULT CHARACTER SET utf8;
USE db_gl_sdk_game;

CREATE TABLE IF NOT EXISTS `T_GUESS` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plat_type` int(10) unsigned NOT NULL COMMENT '平台',
  `device_code` varchar(255) NOT NULL COMMENT '设备号',
  `account_type` varchar(127) NOT NULL COMMENT '账户类型guess,facebook,google',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `has_bind` tinyint(4) DEFAULT NULL COMMENT '是否绑定',
  `bind_time` datetime DEFAULT NULL COMMENT '绑定时间',
  `bind_user_id` int(11) DEFAULT NULL COMMENT '绑定的UID',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_ORDER_APP` (
  `trans_id` varchar(128) NOT NULL,
  `product_id` varchar(128) NOT NULL COMMENT '商品编号',
  `user_id` int(12) unsigned NOT NULL COMMENT '玩家编号',
  `site_id` smallint(5) unsigned NOT NULL COMMENT '区',
  `server_id` smallint(5) unsigned NOT NULL COMMENT '服',
  `create_ts` int(10) unsigned NOT NULL COMMENT '创建时间',
  `checking_amount` float unsigned NOT NULL DEFAULT '0' COMMENT '对账金额',
  PRIMARY KEY (`trans_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_ORDER_GOOGLE` (
  `order_id` varchar(128) NOT NULL COMMENT '订单号',
  `product_id` varchar(128) NOT NULL COMMENT '商品编号',
  `user_id` int(12) unsigned NOT NULL COMMENT '玩家编号',
  `site_id` smallint(5) unsigned NOT NULL COMMENT '区',
  `server_id` smallint(5) unsigned NOT NULL COMMENT '服',
  `create_ts` int(10) unsigned NOT NULL COMMENT '创建时间',
  `checking_amount` float unsigned NOT NULL DEFAULT '0' COMMENT '对账金额',
  PRIMARY KEY (`order_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_ORDER_PP` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增编号',
  `user_id` int(12) unsigned NOT NULL COMMENT '玩家编号',
  `site_id` smallint(5) unsigned NOT NULL COMMENT '区',
  `server_id` smallint(5) unsigned NOT NULL COMMENT '服',
  `create_ts` int(10) unsigned NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_ORDER_WEGAME` (
  `order_id` varchar(128) NOT NULL COMMENT '订单编号',
  `plat_type` tinyint(4) NOT NULL COMMENT '平台',
  `plat_acc_id` varchar(128) NOT NULL COMMENT '平台ID',
  `user_id` int(12) DEFAULT NULL,
  `site_id` smallint(5) unsigned NOT NULL COMMENT '区',
  `server_id` smallint(5) unsigned NOT NULL COMMENT '服',
  `amount` int(10) unsigned NOT NULL COMMENT '花费的金额',
  `game_money` int(10) unsigned NOT NULL COMMENT '购买游戏币',
  `card_id` varchar(64) NOT NULL DEFAULT '' COMMENT '月卡ID',
  `other_item` varchar(256) NOT NULL DEFAULT '' COMMENT '其他物品',
  `create_ts` int(10) unsigned NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`order_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_ROLE` (
  `role_id` varchar(64) NOT NULL COMMENT '角色ID',
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `site_id` int(6) NOT NULL COMMENT '大区ID',
  `server_id` int(6) NOT NULL COMMENT '服务器ID',
  `role_name` varchar(128) NOT NULL COMMENT '角色名称',
  `role_sex` tinyint(4) DEFAULT '0' COMMENT '性别(女=0，默认)',
  `regist_time` datetime DEFAULT NULL COMMENT '创建时间',
  `last_login_time` datetime DEFAULT NULL COMMENT '上次登录时间',
  `last_login_ip` varchar(64) DEFAULT NULL COMMENT '上次登录IP',
  `last_update_time` datetime DEFAULT NULL COMMENT '上次更新时间',
  `is_reported` tinyint(4) DEFAULT NULL COMMENT '是否上传',
  `report_time` datetime DEFAULT NULL COMMENT '上传时间',
  PRIMARY KEY (`role_id`),
  KEY `userid` (`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_USER` (
  `user_id` int(12) NOT NULL AUTO_INCREMENT COMMENT '用户id，自增',
  `plat_type` smallint(5) unsigned NOT NULL DEFAULT '1' COMMENT '所属类型 1:好好玩',
  `plat_account_id` varchar(128) NOT NULL COMMENT '平台账号ID',
  `user_key` varchar(64) DEFAULT NULL COMMENT '用户KEY，游戏登录用',
  `regist_time` datetime DEFAULT '0000-00-00 00:00:00',
  `last_login_time` datetime DEFAULT '0000-00-00 00:00:00' COMMENT '上次登录时间',
  `last_login_ip` varchar(64) DEFAULT NULL COMMENT '上次登录IP',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `plat_id` (`plat_type`,`plat_account_id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_USER_CHARGE` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `user_id` int(12) NOT NULL COMMENT '玩家ID',
  `site_id` int(11) NOT NULL DEFAULT '0' COMMENT '大区ID',
  `server_id` int(11) NOT NULL DEFAULT '0' COMMENT '服务器ID',
  `plat_type` smallint(6) NOT NULL DEFAULT '0' COMMENT '平台类型',
  `plat_acc_id` varchar(128) NOT NULL COMMENT '平台用户名',
  `order_id` varchar(128) NOT NULL DEFAULT '' COMMENT '订单号',
  `product_id` varchar(64) DEFAULT '0' COMMENT '商品ID',
  `amount` int(11) NOT NULL DEFAULT '0' COMMENT '充值金额',
  `check_amount` decimal(11,2) DEFAULT NULL,
  `game_money` int(11) DEFAULT NULL COMMENT '总游戏币',
  `base_money` int(11) DEFAULT NULL COMMENT '基础游戏币',
  `card_id` int(11) DEFAULT NULL COMMENT '月卡ID',
  `self_defined` tinyint(4) DEFAULT '0' COMMENT '自定义充值',
  `other_item` varchar(256) DEFAULT NULL COMMENT '其他物品',
  `pay_channel` varchar(32) DEFAULT NULL COMMENT '支付渠道',
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '充值时间',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `create_ts` (`time`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_USER_CHARGE_COMP` (
  `sid` int(11) NOT NULL AUTO_INCREMENT COMMENT '记录ID，自增长',
  `charge_id` int(11) DEFAULT '0' COMMENT '支付ID,对应T_USER_CHARGE表的id',
  `user_id` int(11) DEFAULT NULL COMMENT '用户ID',
  `site_id` int(11) DEFAULT NULL COMMENT '大区ID',
  `server_id` int(11) DEFAULT NULL COMMENT '服务器ID',
  `order_id` varchar(128) DEFAULT NULL COMMENT '订单号',
  `product_id` varchar(64) DEFAULT NULL COMMENT '商品Id',
  `amount` int(11) DEFAULT NULL COMMENT '金额',
  `game_money` int(11) DEFAULT NULL COMMENT '游戏币',
  `base_money` int(11) DEFAULT NULL COMMENT '基础游戏币',
  `card_id` int(11) DEFAULT NULL COMMENT '月卡Id',
  `self_defined` tinyint(4) DEFAULT '0' COMMENT '自定义充值',
  `other_item` varchar(256) DEFAULT NULL COMMENT '其他物品',
  `pay_channel` varchar(33) DEFAULT NULL COMMENT '支付渠道',
  `status` int(11) DEFAULT '0' COMMENT '支付状态',
  `is_comped` tinyint(4) DEFAULT '0' COMMENT '是否已经补偿',
  `pay_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '支付时间',
  `last_comp_time` datetime DEFAULT NULL COMMENT '上次补偿时间',
  `try_comp_times` int(11) DEFAULT '0' COMMENT '尝试补偿次数',
  PRIMARY KEY (`sid`),
  UNIQUE KEY `charge_id` (`charge_id`) USING BTREE
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_USER_FROZEN` (
  `sid` int(11) NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `site_id` int(11) DEFAULT NULL COMMENT '大区号',
  `server_id` int(11) DEFAULT NULL,
  `nick` varchar(64) DEFAULT NULL COMMENT '角色名',
  `status` tinyint(4) DEFAULT '1' COMMENT '状态=0，表示正常>0表示冻结',
  `reason` text COMMENT '冻结原因',
  `duration` int(11) DEFAULT NULL COMMENT '冻结时间(秒数)',
  `begin_time` datetime DEFAULT NULL COMMENT '起始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `freeze_er` varchar(256) DEFAULT NULL COMMENT '冻结操作者',
  `unfreeze_er` varchar(256) DEFAULT NULL COMMENT '解冻操作者',
  `unfreeze_reason` text COMMENT '解冻原因 ',
  `unfreeze_time` datetime DEFAULT NULL COMMENT '解冻时间',
  PRIMARY KEY (`sid`),
  UNIQUE KEY `userid` (`user_id`) USING BTREE
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_USER_GENERATEKEY` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plat_type` int(10) unsigned NOT NULL COMMENT '平台',
  `device_code` varchar(255) NOT NULL COMMENT '设备号',
  `account_type` varchar(127) NOT NULL COMMENT '账户类型guess,facebook,google',
  `create_ts` int(11) NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_USER_MACHINE_CODE` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增编号',
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `m_code` varchar(64) DEFAULT '1' COMMENT '机器码',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_WEGAME_FBG` (
  `id` int(12) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `plat_id` varchar(128) NOT NULL COMMENT '平台ID',
  `unique_id` varchar(50) NOT NULL COMMENT '应用唯一ID',
  `email` varchar(50) NOT NULL COMMENT 'email',
  `account_type` varchar(50) NOT NULL COMMENT '账户类型 facebook,google',
  `token` varchar(50) DEFAULT NULL COMMENT 'TOKEN',
  `reg_ts` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `plat_id` (`plat_id`),
  KEY `unique_id` (`unique_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_WEGAME_REPORT_CHARGE` (
  `sid` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `report_id` int(11) NOT NULL COMMENT '上传的ID',
  `user_id` int(12) NOT NULL COMMENT '用户ID',
  `server_id` int(11) NOT NULL DEFAULT '0' COMMENT '服务器ID',
  `plat_acc_id` varchar(128) NOT NULL COMMENT '平台用户名',
  `order_id` varchar(128) NOT NULL DEFAULT '' COMMENT '订单号',
  `check_amount` decimal(10,0) DEFAULT NULL COMMENT '提交金额',
  `pay_channel` varchar(32) DEFAULT NULL COMMENT '支付渠道',
  `report_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上报时间',
  `report_status` smallint(6) DEFAULT '1' COMMENT '上报状态，上报中=1，上报完毕=2，出错=0',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `errcode` int(11) DEFAULT NULL COMMENT '上报出错编码',
  `errmsg` varchar(128) DEFAULT NULL COMMENT '上报出错信息',
  PRIMARY KEY (`sid`),
  UNIQUE KEY `report_id` (`report_id`) USING BTREE,
  KEY `order_id` (`order_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_WEGAME_USER` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增编号',
  `account` varchar(50) NOT NULL COMMENT 'wegame账号',
  `acc_id` varchar(32) NOT NULL COMMENT '账号ID',
  `time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '添加时间',
  PRIMARY KEY (`id`),
  KEY `wegame` (`account`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;


delimiter //
DROP FUNCTION IF EXISTS func_get_wegame_charge_report_id //
CREATE FUNCTION `func_get_wegame_charge_report_id`() RETURNS int(11)
    READS SQL DATA
BEGIN
	#Routine body goes here...
	SELECT max(`report_id`) INTO @_max_report_id FROM T_WEGAME_REPORT_CHARGE;
	IF @_max_report_id IS NULL
	THEN
		SET @_max_report_id = 0;
	END IF;
	RETURN @_max_report_id;
END
//
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS P_REGISTER //
CREATE PROCEDURE `P_REGISTER`(IN p_plat_type SMALLINT UNSIGNED,
 IN p_plat_account_id VARCHAR(128),
 IN p_user_key VARCHAR(64))
    MODIFIES SQL DATA
l_pro:BEGIN
	DECLARE v_user_id INT UNSIGNED;
	DECLARE v_user_key VARCHAR(64);
	#SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
	# 1, 'e', '1dsadsad'
	SET v_user_id = 0;
	SELECT `user_id`, `user_key` INTO v_user_id, v_user_key FROM `T_USER` where `plat_type` = p_plat_type and `plat_account_id` = p_plat_account_id LIMIT 1;
	IF (FOUND_ROWS() > 0)
	THEN
		SELECT '1203' AS `code`, v_user_id as `user_id`, v_user_key as `user_key`;
		#ROLLBACK;
		LEAVE l_pro;
	END IF;
	
	INSERT INTO `T_USER`
	(`plat_type`, `plat_account_id`, `user_key`, `regist_time`) 
	VALUES
	(p_plat_type, p_plat_account_id, p_user_key, FROM_UNIXTIME(UNIX_TIMESTAMP()));

	SELECT `user_id`, `user_key` INTO v_user_id, v_user_key FROM `T_USER` where `plat_type` = p_plat_type and `plat_account_id` = p_plat_account_id LIMIT 1;
	IF (FOUND_ROWS() > 0)
	THEN
		SELECT '0000' AS `code`, v_user_id as `user_id`, v_user_key as `user_key`;
		#ROLLBACK;
		LEAVE l_pro;
	END IF;

	SELECT '1204' AS `code`, v_user_id as `user_id`, p_user_key as `user_key`;
END
//
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS P_REGISTER_ROLE //
CREATE PROCEDURE `P_REGISTER_ROLE`(IN p_role_id VARCHAR(64),
 IN p_user_id INT,
 IN p_site_id INT, IN p_server_id INT, IN p_role_name VARCHAR(128), IN p_role_sex TINYINT, IN p_ip VARCHAR(64), IN p_regist_time LONG)
    MODIFIES SQL DATA
l_pro:BEGIN
	DECLARE v_role_id VARCHAR(64);
	#DECLARE v_role_role VARCHAR(128);
	#SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
	# 1, 'e', '1dsadsad'
	SET v_role_id = 0;
	SELECT `role_id` INTO v_role_id FROM `T_ROLE` where `role_id` = p_role_id LIMIT 1;
	IF (FOUND_ROWS() > 0)
	THEN
		SELECT '1301' AS `code`, v_role_id as `v_role_id`;
		#ROLLBACK;
		LEAVE l_pro;
	END IF;
	
	INSERT INTO `T_ROLE`
	(`role_id`, `user_id`, `site_id`, `server_id`, `role_name`, `role_sex`, `regist_time`, `last_login_ip`) 
	VALUES
	(p_role_id, p_user_id, p_site_id, p_server_id, p_role_name, p_role_sex, FROM_UNIXTIME(p_regist_time), p_ip);

	SELECT `role_id` INTO v_role_id FROM `T_ROLE` where `role_id` = p_role_id LIMIT 1;
	IF (FOUND_ROWS() > 0)
	THEN
		SELECT '0000' AS `code`, v_role_id as `v_role_id`;
		#ROLLBACK;
		LEAVE l_pro;
	END IF;

	SELECT '1302' AS `code`, v_role_id as `v_role_id`;
END
//
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS P_WEGAME_REPORTE_CHARGE //
CREATE PROCEDURE `P_WEGAME_REPORTE_CHARGE`()
BEGIN
	#Routine body goes here...
	DECLARE _i_plat_type INT DEFAULT 25; #WEGMAE平台类型
	DECLARE _s_pay_channel_1 VARCHAR(16) DEFAULT 'app'; #支付通道APP
	DECLARE _s_pay_channel_2 VARCHAR(16) DEFAULT 'google'; #支付通道APP
	
	SET @_max_repote_id = func_get_wegame_charge_report_id();
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_wegame_order;
	CREATE TEMPORARY TABLE _tmp_t_wegame_order AS 
				SELECT `id`, `user_id`, `site_id`, `server_id`, `plat_acc_id`, `role_name`, `order_id`, `amount`, `check_amount`, `game_money`, `card_id`, 
								IF(`card_id`=0, '', IF(`card_id`=1, 'month', 'forever')) AS other_item, `pay_channel`, `time`, UNIX_TIMESTAMP(`time`) AS stamp 
								FROM (SELECT * FROM T_USER_CHARGE WHERE `id` > @_max_repote_id
								AND `plat_type` = _i_plat_type AND `pay_channel` IN (_s_pay_channel_1, _s_pay_channel_2)) 
								AS A LEFT JOIN T_ROLE AS B 
								USING(user_id, site_id, server_id) LIMIT 5; 



	SELECT COUNT(*) AS found_num, MAX(`id`) AS max_report_id, MIN(`id`) AS min_report_id FROM _tmp_t_wegame_order;
	SELECT * FROM _tmp_t_wegame_order;
	#插入记录
	IF( FOUND_ROWS() > 0 ) THEN
		INSERT IGNORE INTO T_WEGAME_REPORT_CHARGE(`report_id`, `user_id`, `server_id`, `plat_acc_id`, `order_id`, `check_amount`, `pay_channel`, `report_status`) 
					SELECT `id` AS report_id, `user_id`, `server_id`, `plat_acc_id`, `order_id`, `check_amount`, `pay_channel`, 1 FROM _tmp_t_wegame_order;
	END IF;

	DROP TEMPORARY TABLE IF EXISTS _tmp_t_wegame_order;
END
//
delimiter ;
