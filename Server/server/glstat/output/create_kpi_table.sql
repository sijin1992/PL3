USE db_star_log;

#`stat_date`, `regist_count`, `active_count`, `drr2_perct`, `drr3_perct`, `drr7_perct`, `acu`, `pcu`, `income_amount`, `first_deposit_count`, `arpu`, `arppu`, `deposit_perct`

CREATE TABLE IF NOT EXISTS KPI_STAT_DAILY(
  `areaid` varchar(33) NOT NULL COMMENT '服务器标识',
  `stat_date` date NOT NULL COMMENT '统计日期',
  `regist_count` int(11) DEFAULT NULL COMMENT '注册人数',
  `rookie_count` INT DEFAULT NULL COMMENT '日导入',
  `active_count` int(11) DEFAULT NULL COMMENT '活跃人数',
  `drr2_perct` float DEFAULT NULL COMMENT '2日留存',
  `drr3_perct` float DEFAULT NULL COMMENT '3日留存',
  `drr7_perct` float DEFAULT NULL COMMENT '7日留存',
  `drr14_perct` float DEFAULT NULL COMMENT '14日留存',
  `drr30_perct` float DEFAULT NULL COMMENT '30日留存',
  `acu` float DEFAULT NULL COMMENT '平均在线人数',
  `pcu` float DEFAULT NULL COMMENT '最高在线人数',
  `income_amount` float DEFAULT NULL COMMENT '收入金额',
  `arpu` float DEFAULT NULL COMMENT '每用户平均收益',
  `arppu` float DEFAULT NULL COMMENT '每付费用户平均收益',
  `regist_deposit_count` int(11) DEFAULT NULL COMMENT '注册充值人数',
  `deposit_count` int(11) DEFAULT NULL COMMENT '充值人数',
  `deposit_perct` float DEFAULT NULL COMMENT '付费渗透率',
  PRIMARY KEY (`areaid`,`stat_date`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS KPI_STAT_WEEKLY(
	`areaid`	VARCHAR(33) NOT NULL COMMENT '服务器标识',
	`begin_date` DATE NOT NULL COMMENT '开始日期',
	`end_date` DATE NOT NULL COMMENT '结束日期',
	`stat_date` DATE NOT NULL COMMENT '统计日期',
	`week_day` INT NOT NULL COMMENT '统计的星期1~7',
	`regist_count` INT COMMENT '周注册人数',
	`active_count` INT COMMENT '周活跃人数',
	`wrr1_count` INT COMMENT '周留存新用户',
	`lealty_count` FLOAT COMMENT '周忠实用户数',
	`income_amount` FLOAT COMMENT '收入金额',
	`first_deposit_avg` FLOAT COMMENT '平均首充金额',
	`liushi_wr1_perct` FLOAT COMMENT '周流失率',
	`liushi_paid_wr1_perct` FLOAT COMMENT '周付费用户流失率',

	PRIMARY KEY pk(`areaid`, `begin_date`)

) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS KPI_STAT_MONTHLY(
  `areaid` varchar(33) NOT NULL COMMENT '服务器标识',
  `year_month` varchar(12) NOT NULL COMMENT '年月',
  `begin_date` date NOT NULL COMMENT '统计日期',
  `end_date` date NOT NULL COMMENT '结束日期',
  `stat_date` date NOT NULL COMMENT '统计日期',
  `regist_count` int(11) DEFAULT NULL COMMENT '注册人数',
  `active_count` int(11) DEFAULT NULL COMMENT '活跃人数',
  `acu` float DEFAULT NULL COMMENT '平均在线人数',
  `pcu` float DEFAULT NULL COMMENT '最高在线人数',
  `income_amount` float DEFAULT NULL COMMENT '收入金额',
  `arpu` float DEFAULT NULL COMMENT '每用户平均收益',
  `arppu` float DEFAULT NULL COMMENT '每付费用户平均收益',
  `deposit_count` int(11) DEFAULT NULL COMMENT '充值人数',
  `deposit_perct` float DEFAULT NULL COMMENT '付费渗透率',
  PRIMARY KEY (`areaid`,`year_month`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS KPI_STAT_DAILY_LIUCUN (
  `stat_date` date NOT NULL COMMENT '统计日期',
  `regist_count` int(11) DEFAULT '0' COMMENT '注册人数',
  `drr2_perct` float DEFAULT NULL COMMENT '2日留存',
  `drr3_perct` float DEFAULT NULL COMMENT '3日留存',
  `drr7_perct` float DEFAULT NULL COMMENT '7日留存',
  `drr14_perct` float DEFAULT NULL COMMENT '14日留存',
  `drr30_perct` float DEFAULT NULL COMMENT '30日留存',
  PRIMARY KEY (`stat_date`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS KPI_STAT_DAILY_DEPOSIT (
  `amount` int(11) NOT NULL DEFAULT '0' COMMENT '金额',
  `times` int(11) DEFAULT '0' COMMENT '次数',
  `nop` int(11) DEFAULT '0' COMMENT '人数',
  `total` int(11) DEFAULT NULL COMMENT '总额',
  `stat_date` date NOT NULL DEFAULT '0000-00-00' COMMENT '统计日期',
  PRIMARY KEY (`amount`,`stat_date`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

