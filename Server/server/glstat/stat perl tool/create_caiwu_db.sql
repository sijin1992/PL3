CREATE DATABASE IF NOT EXISTS db_gl_caiwu;
USE db_gl_caiwu;

CREATE TABLE IF NOT EXISTS users ( 
	sid INT AUTO_INCREMENT KEY,
	areaid VARCHAR(33) NOT NULL,
	uid VARCHAR(65) COMMENT 'user acount',
	roleid VARCHAR(33) NOT NULL  COMMENT 'username',
	create_time TIMESTAMP NOT NULL COMMENT 'role create time', 
	vip	INT COMMENT 'cur vip level',
	ip VARCHAR(65) COMMENT 'regist ip',
	imei VARCHAR(65) COMMENT 'regist imei',
	lv INT DEFAULT '1' COMMENT 'cur level',
	gold INT DEFAULT '0' COMMENT 'cur yuanbao',
	goldex INT COMMENT 'ignore', 
	last_time DATETIME COMMENT 'last login time',

	UNIQUE(roleid)
);

CREATE TABLE IF NOT EXISTS login(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	areaid VARCHAR(33) NOT NULL,
	uid VARCHAR(65) COMMENT 'user acount',
	roleid VARCHAR(33) NOT NULL  COMMENT 'username',
	log_time DATETIME NOT NULL COMMENT 'role login time', 
	tag	VARCHAR(10) COMMENT 'logout/login',
	ip VARCHAR(65) COMMENT 'ip',
	imei VARCHAR(65) COMMENT 'imei',
	lv INT DEFAULT '1' COMMENT 'cur level when login',
	ts INT DEFAULT '0' COMMENT 'online time',
	time_stamp VARCHAR(32) NOT NULL COMMENT 'time stamp',

	UNIQUE(roleid, time_stamp)

);

CREATE TABLE IF NOT EXISTS gold(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	areaid VARCHAR(33) NOT NULL,
	uid VARCHAR(65) COMMENT 'user acount',
	roleid VARCHAR(33) NOT NULL  COMMENT 'username',
	log_time DATETIME NOT NULL COMMENT 'role trans time', 
	tag	VARCHAR(10) COMMENT 'deposit/get/use',
	item	VARCHAR(12) COMMENT 'itemid',
	remark INT COMMENT 'where',
	trans_qty INT NOT NULL COMMENT 'trans all yuanbao num',
	qty INT NOT NULL COMMENT 'trans real yuanbao num',
	confirm INT NOT NULL COMMENT 'Financial confirm trans yuanbao num',
	deposit_left INT NOT NULL COMMENT 'left deposit yuanbao num',
	total_left INT NOT NULL COMMENT 'total deposit yuanbao num',
	cur_yb INT NOT NULL COMMENT 'cur all yuanbao num',
	ip VARCHAR(65) COMMENT 'ip',
	imei VARCHAR(65) COMMENT 'imei',
	time_stamp VARCHAR(32) NOT NULL COMMENT 'time stamp',

	UNIQUE(roleid, remark, time_stamp)

);

CREATE TABLE IF NOT EXISTS pcu(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	areaid VARCHAR(33) NOT NULL,
	log_time DATETIME NOT NULL COMMENT 'role login time', 
	qty INT NOT NULL COMMENT 'online user num',

	UNIQUE(areaid, log_time)
);


CREATE TABLE IF NOT EXISTS gold_month(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	areaid VARCHAR(33) NOT NULL,
	uid VARCHAR(65) COMMENT 'user acount',
	roleid VARCHAR(33) NOT NULL  COMMENT 'username',
	log_time TIMESTAMP NOT NULL COMMENT 'role login time', 
	qty INT NOT NULL COMMENT 'user total yuanbao',
	time_stamp VARCHAR(32) NOT NULL COMMENT 'time stamp',

	UNIQUE(roleid, time_stamp)
);


