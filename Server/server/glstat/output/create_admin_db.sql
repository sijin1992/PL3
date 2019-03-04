CREATE DATABASE IF NOT EXISTS db_star_admin DEFAULT CHARACTER SET utf8;
USE db_star_admin;

CREATE TABLE IF NOT EXISTS `T_ANNOUNCE` (
`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(100) NOT NULL COMMENT '标题',
  `content` varchar(1023) NOT NULL COMMENT '内容',
  `start_ts` datetime NOT NULL COMMENT '开始时间',
  `end_ts` datetime NOT NULL COMMENT '结束时间',
  `enabled` bit(1) NOT NULL COMMENT '是否启用',
  `module` int(11) NOT NULL DEFAULT '0' COMMENT '跳转模块',
  `disp_order` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '显示顺序',
  `img` varchar(1024) NOT NULL DEFAULT '' COMMENT '图片',
  `url_addr` varchar(1024) NOT NULL DEFAULT '',
  `activity_id` int(12) NOT NULL DEFAULT '0' COMMENT '活动公告',
  PRIMARY KEY (`id`),
  KEY `enabled` (`enabled`) USING BTREE,
  KEY `disp_order` (`disp_order`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_ANNOUNCE_SERVER` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
  `announce_id` int(10) unsigned NOT NULL COMMENT '公告编号',
  `site_id` int(10) unsigned NOT NULL COMMENT '区',
  `server_id` int(10) unsigned NOT NULL COMMENT '服',
  PRIMARY KEY (`id`),
  KEY `announce_id` (`announce_id`,`site_id`,`server_id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_GIFT_SEND_LIST` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '唯一编号',
  `app_id` int(11) unsigned NOT NULL COMMENT '申请编号',
  `user_id` varchar(33) NOT NULL COMMENT '用户编号',
  `user_name` varchar(33) NOT NULL COMMENT '用户名',
  `site` int(10) unsigned NOT NULL,
  `server` int(10) unsigned NOT NULL,
  `amount` int(11) DEFAULT NULL COMMENT '金额',
  `yuanbao` int(11) DEFAULT NULL COMMENT '元宝',
  `create_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  `status` tinyint(4) DEFAULT '0' COMMENT '=1表示已发送',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_GIFT_USER_LIST` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '唯一编号',
  `user_id` varchar(33) NOT NULL COMMENT '用户编号',
  `name` varchar(33) NOT NULL COMMENT '用户名',
  `site` int(10) NOT NULL,
  `server` int(10) NOT NULL,
  `comment` varchar(30) DEFAULT NULL COMMENT '备注',
  `last_amount` int(11) DEFAULT '0' COMMENT '上次发送金额',
  `last_yuanbao` int(11) DEFAULT '0' COMMENT '上次发送元宝',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_MAIL_APPLY` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `admin_id` int(11) unsigned NOT NULL COMMENT '申请者id',
  `admin_user` varchar(64) NOT NULL COMMENT '申请者姓名',
  `action_id` int(11) DEFAULT NULL COMMENT '审批者id',
  `action_user` varchar(64) DEFAULT NULL COMMENT '审批者姓名',
  `site_id` int(6) NOT NULL COMMENT '大区id',
  `server_id` int(6) NOT NULL COMMENT '服务器id',
  `mail_title` varchar(32) NOT NULL COMMENT '邮件标题',
  `mail_content` varchar(512) NOT NULL COMMENT '邮件内容',
  `receiver` text NOT NULL COMMENT '收件者',
  `attachment` text COMMENT '附件信息',
  `mail_options` varchar(256) DEFAULT NULL COMMENT '邮件选项',
  `flag` tinyint(4) DEFAULT NULL COMMENT '申请类型',
  `apply_status` smallint(2) NOT NULL DEFAULT '1' COMMENT '1:申请中 2:已经批准 3:打回',
  `create_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `approve_ts` datetime DEFAULT NULL COMMENT '审批时间',
  PRIMARY KEY (`id`),
  KEY `apply_status` (`apply_status`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_MAIL_SEND_LIST` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增编号',
  `app_id` int(11) NOT NULL COMMENT '申请编号',
  `receiver` varchar(64) NOT NULL COMMENT '收信人',
  `site_id` int(6) NOT NULL COMMENT '大区编号',
  `server_id` int(6) NOT NULL COMMENT '服务器',
  `mail_title` varchar(128) NOT NULL COMMENT '邮件标题',
  `mail_content` varchar(512) NOT NULL COMMENT '邮件内容',
  `attachment` text COMMENT '附件内容',
  `mail_options` varchar(256) DEFAULT NULL COMMENT '邮件选项',
  `send_status` smallint(2) NOT NULL DEFAULT '1' COMMENT '1:未发送 2:已发送 3:需要重新发送 <0:错误编码',
  `send_time` datetime DEFAULT NULL COMMENT '发送时间',
  `admin_user` varchar(128) DEFAULT NULL COMMENT '管理员姓名',
  `flag` smallint(6) DEFAULT NULL COMMENT '是否属于福利',
  `retry_times` int(11) DEFAULT '0' COMMENT '重发次数',
  `vtime` int(5) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `send_status` (`send_status`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_MODULE` (
  `id` int(10) unsigned NOT NULL COMMENT '编号',
  `name` varchar(45) NOT NULL COMMENT '模块',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_NOTIFY_MSG` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `msg` varchar(1023) NOT NULL,
  `status` bit(1) NOT NULL COMMENT '状态 0:未发布 1:已发布',
  `publish_ts` int(10) unsigned NOT NULL COMMENT '发布时间',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_NOTIFY_SERVER` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
  `msg_id` int(10) unsigned NOT NULL COMMENT '消息编号',
  `site_id` int(10) unsigned NOT NULL COMMENT '区',
  `server_id` int(10) unsigned NOT NULL COMMENT '服',
  PRIMARY KEY (`id`),
  KEY `msg` (`msg_id`,`site_id`,`server_id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE `T_SERVER` (
  `site_id` int(10) unsigned NOT NULL COMMENT '所属大区',
  `server_id` int(10) unsigned NOT NULL COMMENT '服务器编号ID',
  `area_id` varchar(33) NOT NULL,
  `name` varchar(45) NOT NULL COMMENT '服务器名',
  `url` varchar(128) NOT NULL COMMENT '服务器访问地址',
  `db_ip` varchar(128) NOT NULL COMMENT '服务器指向日志DB IP地址',
  `db_name` varchar(128) NOT NULL COMMENT '服务器指向日志DB 名称',
  `server_options` text COMMENT '服务器选项',
  `link` tinyint(4) DEFAULT '0' COMMENT '连接类型，=1表示软连接',
  `real_site` int(11) DEFAULT '0' COMMENT '链接的大区',
  `real_server` int(11) DEFAULT '0' COMMENT '链接的服务器',
  `status` int(11) DEFAULT '0' COMMENT '服务器状态',
  PRIMARY KEY (`site_id`,`server_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `T_SERVER_STAT` (
  `id` int(12) unsigned NOT NULL AUTO_INCREMENT,
  `date` varchar(32) NOT NULL,
  `site_id` int(12) NOT NULL DEFAULT '0',
  `server_id` int(12) NOT NULL DEFAULT '0',
  `server_name` varchar(32) NOT NULL,
  `dau` int(12) NOT NULL DEFAULT '0',
  `reg` int(12) NOT NULL DEFAULT '0',
  `amount` int(12) NOT NULL DEFAULT '0',
  `dpu` int(12) NOT NULL DEFAULT '0',
  `1dr` float NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_SITE` (
  `id` int(10) unsigned NOT NULL COMMENT '区编号',
  `name` varchar(45) NOT NULL COMMENT '区名',
  `url` varchar(128) DEFAULT NULL COMMENT '大区入口',
  `plat_type` int(11) DEFAULT NULL COMMENT '平台类型',
  `log_db_host` varchar(33) DEFAULT NULL,
  `log_db_name` varchar(33) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_SITE_PLAT` (
  `type` int(11) NOT NULL AUTO_INCREMENT COMMENT '平台类型',
  `name` varchar(128) NOT NULL DEFAULT 'UNKOWN' COMMENT '平台名称',
  PRIMARY KEY (`type`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_SYS_ACTIVITY` (
  `id` int(12) NOT NULL COMMENT '活动类型编号',
  `activity_name` varchar(128) DEFAULT NULL COMMENT '活动类型名称',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_SYS_CONSUME_TYPE` (
  `id` int(12) NOT NULL COMMENT '消费类型编号',
  `consume_type` varchar(128) DEFAULT NULL COMMENT '消费类型',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_TIMED_ACTIVITY` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '活动编号',
  `type` tinyint(3) unsigned NOT NULL COMMENT '活动类型 1:迎财神 2:充值返现 3:消费返现 4:兑换商城',
  `server_info` text COMMENT '区服信息',
  `start_ts` int(10) unsigned NOT NULL COMMENT '开始时间',
  `end_ts` int(10) unsigned NOT NULL COMMENT '结束时间',
  `status` tinyint(1) DEFAULT '1' COMMENT '是否提交生效1否2生效3删除',
  PRIMARY KEY (`id`),
  KEY `end_ts` (`end_ts`) USING BTREE,
  KEY `status` (`status`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `T_USER_FEEDBACK` (
  `id` int(12) NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `sq_id` int(12) NOT NULL COMMENT '在各自服务器中的自增ID',
  `site_id` int(6) NOT NULL COMMENT '大区',
  `server_id` int(6) NOT NULL COMMENT '服务器',
  `user_name` varchar(64) NOT NULL COMMENT '用户名',
  `feedback` varchar(512) DEFAULT NULL,
  `create_ts` int(12) NOT NULL COMMENT '时间戳',
  `act_status` smallint(2) NOT NULL DEFAULT '0' COMMENT '操作状态 0未处理 1已经处理',
  `op_user_id` int(12) DEFAULT '0' COMMENT '操作者id',
  `op_user_name` varchar(64) DEFAULT NULL COMMENT '操作者姓名',
  `op_content` varchar(512) DEFAULT NULL,
  `op_time` int(12) DEFAULT '0' COMMENT '回复时间',
  PRIMARY KEY (`id`),
  KEY `site_id` (`site_id`,`server_id`) USING BTREE,
  KEY `sq_id` (`sq_id`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `admin_log` (
  `id` int(12) NOT NULL AUTO_INCREMENT COMMENT '日志编号自增',
  `admin_id` int(12) NOT NULL COMMENT '操作员ID',
  `admin_name` varchar(64) DEFAULT NULL COMMENT '操作员姓名',
  `op_type` varchar(64) NOT NULL DEFAULT '0' COMMENT '操作类型',
  `op_subtype` varchar(64) DEFAULT '0' COMMENT '操作小类型',
  `op_username` varchar(64) DEFAULT NULL COMMENT '被操作者名称',
  `comments` varchar(128) DEFAULT NULL COMMENT '备注',
  `ip` varchar(32) DEFAULT NULL COMMENT '操作ip',
  `create_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `admin_name` (`admin_name`,`create_ts`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `admin_user` (
  `id` int(12) NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `username` varchar(128) DEFAULT NULL COMMENT '管理员姓名',
  `password` varchar(128) DEFAULT NULL COMMENT '管理员密码',
  `truename` varchar(128) DEFAULT NULL COMMENT '真名',
  `dept` varchar(128) DEFAULT NULL COMMENT '部门',
  `tel` varchar(20) DEFAULT NULL COMMENT '电话',
  `mobile` varchar(20) DEFAULT NULL COMMENT '手机',
  `email` varchar(64) DEFAULT NULL COMMENT '邮箱',
  `privileges` varchar(1024) DEFAULT NULL COMMENT '权限',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `tab_gl_channel` (
  `channel_id` varchar(255) NOT NULL DEFAULT '0',
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  `broad_cast` varchar(255) CHARACTER SET utf8 NOT NULL,
  `recharge` int(11) NOT NULL,
  `weichat` int(11) NOT NULL,
  `cdkey` int(11) NOT NULL,
  `site_list` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`channel_id`),
  KEY `channel_id` (`channel_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



GRANT SELECT ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
GRANT UPDATE ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
GRANT DELETE ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
GRANT INSERT ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
GRANT EXECUTE ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
GRANT ALL ON *.* TO ali2@'127.0.0.1' IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
