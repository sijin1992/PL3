CREATE DATABASE IF NOT EXISTS db_star_log DEFAULT CHARACTER SET utf8;
USE db_star_log;

CREATE TABLE IF NOT EXISTS `LOG_GET_JZGX`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`num` INT,
	`left` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `SNAP_MENPAI`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	`areaid` VARCHAR(32) NOT NULL,
	`mpid` VARCHAR(32),
	`name` VARCHAR(32),
	`level` INT,
	`gold` INT,
	`jx` INT,
	`ct` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_CAST_PHP`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`num` INT,
	`levelbefore` INT,
	`levelafter` INT,
	`left` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_CAST_ITEM`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`itemid` INT,
	`num` INT,
	`left` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_LOGIN`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`ip` VARCHAR(65),
	`mmc` VARCHAR(32),
	`level` INT,
	`acc` VARCHAR(65),
	`qd` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_GET_ITEM`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`itemid` INT,
	`num` INT,
	`left` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_DEVICE`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`stype` VARCHAR(32),
	`res` VARCHAR(32),
	`os` VARCHAR(32),
	`oper` VARCHAR(32),
	`cntype` VARCHAR(32),
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_ONLINE`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`olnum` INT,
	`areaid` VARCHAR(32) NOT NULL,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_PASS_GQ`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`gqid` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_GET_CARD`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`carid` INT,
	`num` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_GUIDE`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`gid` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_LEVEL_UP`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`levelbefore` INT,
	`levelafter` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_CAST_GD`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`num` INT,
	`left` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_USE_GN`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`gnid` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_LOGOUT`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`oltime` VARCHAR(32),
	`acc` VARCHAR(65),
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `SNAP_USER`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`nick` VARCHAR(32),
	`qd` VARCHAR(32),
	`lv` INT,
	`exp` INT,
	`viplv` INT,
	`vipscore` INT,
	`totaldep` INT,
	`totalrmb` INT,
	`gold` INT,
	`money` INT,
	`php` INT,
	`maxpower` INT,
	`state` INT,
	`stagelv` INT,
	`maxrank` INT,
	`menpai` VARCHAR(32),
	`acc` VARCHAR(65) COMMENT 'user plat account',
	`ip` VARCHAR(65) COMMENT 'user login ip',
	`mmc` VARCHAR(32) COMMENT 'user login mmc',
	`guide_step` INT COMMENT 'new player guide step',
	`regist_time` DATETIME COMMENT 'regist time',
	`last_login_time` DATETIME COMMENT 'last login time',
	`last_logout_time` DATETIME COMMENT 'last logout time',
	`time_stamp` VARCHAR(32) COMMENT 'time stamp',

	UNIQUE(`uid`)

) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_CAST_YB`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`num` INT,
	`real` INT,
	`confirm` INT,
	`depleft` INT,
	`realleft` INT,
	`totalleft` INT,
	`acc` VARCHAR(65),
	`ip` VARCHAR(65),
	`mmc` VARCHAR(32),
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_DEPOSIT`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`amount` INT,
	`paytype` INT,
	`isfirst` INT,
	`viplevel` INT,
	`vipscore` INT,
	`qd` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_GET_GD`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`num` INT,
	`left` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `SNAP_BAG`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`kxl` INT,
	`lwl` INT,
	`wh` INT,
	`mpww` INT,
	`mpjz` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_GET_YB`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`num` INT,
	`real` INT,
	`confirm` INT,
	`depleft` INT,
	`realleft` INT,
	`totalleft` INT,
	`acc` VARCHAR(65),
	`ip` VARCHAR(65),
	`mmc` VARCHAR(32),
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_PASS_WL`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`layer` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_REGIST`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`ip` VARCHAR(65),
	`mmc` VARCHAR(32),
	`acc` VARCHAR(65),
	`nick` VARCHAR(32),
	`lv` INT,
	`qd` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_GET_XK`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`cardid` INT,
	`num` INT,
	`left` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_USE_CDKEY`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`cdkey` VARCHAR(32),
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_GET_PHP`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`where` INT,
	`num` INT,
	`left` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `LOG_ACT_REWARD`(
	sid INT AUTO_INCREMENT PRIMARY KEY,
	log_time TIMESTAMP NOT NULL,
	`areaid` VARCHAR(32) NOT NULL,
	`uid` VARCHAR(33) NOT NULL,
	`actid` INT,
	`time_stamp` VARCHAR(32) COMMENT 'time stamp'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `USER_AREA` (
  `sid` int(11) NOT NULL AUTO_INCREMENT,
  `acc` varchar(65) NOT NULL COMMENT '玩家账号',
  `last_login_areaid` varchar(32) DEFAULT NULL COMMENT '上次登录服务器',
  `regist_areaids` varchar(256) DEFAULT NULL COMMENT '所有注册的服务器',
  `all_login_areaids` text COMMENT '所有最近登录的服务器ID时间信息',
  PRIMARY KEY (`sid`),
  UNIQUE KEY `acc` (`acc`) USING HASH
) ENGINE=MyISAM AUTO_INCREMENT=703 DEFAULT CHARSET=utf8;


DELIMITER //
DROP TRIGGER IF EXISTS TRG_USER_REG //
CREATE TRIGGER `TRG_USER_REG` AFTER INSERT ON `LOG_REGIST`
FOR EACH ROW
BEGIN

	INSERT INTO SNAP_USER SET `regist_time` = TIMESTAMP(NEW.time_stamp), `time_stamp` = NEW.time_stamp, `areaid` = func_get_areaid(NEW.uid), `uid` = NEW.uid, `ip` = NEW.ip, `mmc` = NEW.mmc, `acc` = NEW.acc, `nick` = NEW.nick, `lv` = NEW.lv, `qd` = NEW.qd;
	INSERT IGNORE INTO USER_AREA (`acc`, `last_login_areaid`, `regist_areaids`, `all_login_areaids`) VALUES (NEW.acc, func_get_areaid(NEW.uid), func_get_areaid(NEW.uid), func_last_areaid('',func_get_areaid(NEW.uid))) ON DUPLICATE KEY UPDATE `last_login_areaid` = func_get_areaid(NEW.uid), `all_login_areaids` = func_last_areaid(`all_login_areaids`, func_get_areaid(NEW.uid)), `regist_areaids` = func_concat_areaid(`regist_areaids`, VALUES(`regist_areaids`));

END;
//
DELIMITER ;
DELIMITER //
DROP TRIGGER IF EXISTS TRG_USER_LOGIN //
CREATE TRIGGER `TRG_USER_LOGIN` AFTER INSERT ON `LOG_LOGIN`
FOR EACH ROW
BEGIN

	UPDATE SNAP_USER SET `ip` = NEW.ip, `mmc` = NEW.mmc, `lv` = NEW.level, `acc` = NEW.acc, `last_login_time` = TIMESTAMP(NEW.time_stamp), `time_stamp` = NEW.time_stamp WHERE `uid` = NEW.uid;
	INSERT IGNORE INTO USER_AREA (`acc`, `last_login_areaid`, `regist_areaids`, `all_login_areaids`) VALUES (NEW.acc, func_get_areaid(NEW.uid), func_get_areaid(NEW.uid), func_last_areaid('',func_get_areaid(NEW.uid))) ON DUPLICATE KEY UPDATE `last_login_areaid` = func_get_areaid(NEW.uid), `all_login_areaids` = func_last_areaid(`all_login_areaids`, func_get_areaid(NEW.uid));

END;
//
DELIMITER ;
DELIMITER //
DROP TRIGGER IF EXISTS TRG_USER_LOGOUT //
CREATE TRIGGER TRG_USER_LOGOUT AFTER INSERT ON LOG_LOGOUT
FOR EACH ROW
BEGIN

	UPDATE SNAP_USER SET `last_logout_time` = TIMESTAMP(NEW.time_stamp), `time_stamp` = NEW.time_stamp WHERE `uid` = NEW.uid;

END;
//
DELIMITER ;
DELIMITER //
DROP TRIGGER IF EXISTS TRG_USER_GUIDE //
CREATE TRIGGER TRG_USER_GUIDE AFTER INSERT ON LOG_GUIDE
FOR EACH ROW
BEGIN

	UPDATE SNAP_USER SET `guide_step` = NEW.gid, `time_stamp` = NEW.time_stamp WHERE `uid` = NEW.uid;

END;
//
DELIMITER ;

delimiter //
DROP FUNCTION IF EXISTS func_get_areaid //
CREATE FUNCTION func_get_areaid (_arg_userid VARCHAR(33))
	RETURNS VARCHAR(33)
	DETERMINISTIC
	COMMENT 'return areaid trim the roleid'
	RETURN RIGHT(_arg_userid, 5);
	//
//	
delimiter ;


delimiter //
DROP FUNCTION IF EXISTS func_get_roleid //
CREATE FUNCTION func_get_roleid (_arg_userid VARCHAR(33))
	RETURNS VARCHAR(33)
	DETERMINISTIC
	COMMENT 'return roleid trim the areaid'
	RETURN LEFT(_arg_userid, LENGTH(_arg_userid)-5);
	//
//	
delimiter ;


delimiter //
DROP FUNCTION IF EXISTS func_get_userid //
CREATE FUNCTION func_get_userid (_arg_roleid VARCHAR(33), _arg_areaid VARCHAR(33))
	RETURNS VARCHAR(33)
	DETERMINISTIC
	COMMENT 'return roleid trim the areaid'
	RETURN CONCAT(_arg_roleid, _arg_areaid);
	//
//	
delimiter ;



delimiter //
DROP FUNCTION IF EXISTS func_concat_areaid //
CREATE FUNCTION func_concat_areaid (`_src_areaids` varchar(255),`_new_areaid` varchar(33))
	RETURNS varchar(255) CHARSET utf8
    NO SQL
    COMMENT 'return areaidlist contain the newareaid'
BEGIN
	#Routine body goes here...
	DECLARE _is_find INT DEFAULT -1;
	IF LENGTH(_new_areaid) <> 5 THEN
		RETURN _src_areaids;
	END IF;
	IF _src_areaids = '' THEN
		RETURN _new_areaid;
	END IF;
	IF LENGTH(_src_areaids) >= 250 THEN
		RETURN _src_areaids;
	END IF;

	SELECT FIND_IN_SET(_new_areaid, _src_areaids) INTO _is_find;
	IF _is_find = 0 THEN
		SET _src_areaids = CONCAT_WS(',', _src_areaids,_new_areaid);
	END IF;
	RETURN _src_areaids;
END
//
delimiter ;


delimiter //
DROP FUNCTION IF EXISTS func_last_areaid //
CREATE FUNCTION `func_last_areaid`(`_src_areaids` TEXT, `_new_areaid` TEXT) RETURNS text CHARSET utf8
    NO SQL
    COMMENT 'return areaidlist contain the newareaid'
BEGIN
	
	DECLARE _is_find INT DEFAULT -1;
	IF LENGTH(_new_areaid) <> 5 THEN
		RETURN _src_areaids;
	END IF;
	IF _src_areaids = '' THEN
		RETURN CONCAT(_new_areaid, '-', UNIX_TIMESTAMP());
	END IF;

	
	
	IF LENGTH(_src_areaids) >= 256 THEN
		SET @pos = LOCATE(',', _src_areaids);
		SET _src_areaids = SUBSTRING(_src_areaids, @pos);
	END IF;
	SET @search_str = CONCAT(_new_areaid, '-');

		
	SET @pos_start = LOCATE(@search_str, _src_areaids);
	SET @pos_end = 0;
	IF @pos_start > 0 THEN
		SET @pos_end = LOCATE(',', _src_areaids, @pos_start);
		IF @pos_end > 0 THEN
			SET _src_areaids = CONCAT(LEFT(_src_areaids, @pos_start-1), SUBSTRING(_src_areaids, @pos_end+1));
		ELSE
			SET _src_areaids = LEFT(_src_areaids, @pos_start-2);
		END IF;
	END IF;
	IF _src_areaids = '' THEN
		SET _src_areaids = CONCAT(_new_areaid, '-', UNIX_TIMESTAMP());
	ELSE
		SET _src_areaids = CONCAT_WS(',', _src_areaids, CONCAT(_new_areaid, '-', UNIX_TIMESTAMP()));
	END IF;

	RETURN _src_areaids;
END
//
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS proc_clear_db_by_area //
CREATE PROCEDURE `proc_clear_db_by_area`(IN _areaid VARCHAR(33))
   MODIFIES SQL DATA
   COMMENT 'clear log db'
BEGIN
	DELETE FROM LOG_GET_JZGX WHERE `areaid` = _areaid;
	DELETE FROM SNAP_MENPAI WHERE `areaid` = _areaid;
	DELETE FROM LOG_CAST_PHP WHERE `areaid` = _areaid;
	DELETE FROM LOG_CAST_ITEM WHERE `areaid` = _areaid;
	DELETE FROM LOG_LOGIN WHERE `areaid` = _areaid;
	DELETE FROM LOG_GET_ITEM WHERE `areaid` = _areaid;
	DELETE FROM LOG_DEVICE WHERE `areaid` = _areaid;
	DELETE FROM LOG_ONLINE WHERE `areaid` = _areaid;
	DELETE FROM LOG_PASS_GQ WHERE `areaid` = _areaid;
	DELETE FROM LOG_GET_CARD WHERE `areaid` = _areaid;
	DELETE FROM LOG_GUIDE WHERE `areaid` = _areaid;
	DELETE FROM LOG_LEVEL_UP WHERE `areaid` = _areaid;
	DELETE FROM LOG_CAST_GD WHERE `areaid` = _areaid;
	DELETE FROM LOG_USE_GN WHERE `areaid` = _areaid;
	DELETE FROM LOG_LOGOUT WHERE `areaid` = _areaid;
	DELETE FROM SNAP_USER WHERE `areaid` = _areaid;
	DELETE FROM LOG_CAST_YB WHERE `areaid` = _areaid;
	DELETE FROM LOG_DEPOSIT WHERE `areaid` = _areaid;
	DELETE FROM LOG_GET_GD WHERE `areaid` = _areaid;
	DELETE FROM SNAP_BAG WHERE `areaid` = _areaid;
	DELETE FROM LOG_GET_YB WHERE `areaid` = _areaid;
	DELETE FROM LOG_PASS_WL WHERE `areaid` = _areaid;
	DELETE FROM LOG_REGIST WHERE `areaid` = _areaid;
	DELETE FROM LOG_GET_XK WHERE `areaid` = _areaid;
	DELETE FROM LOG_USE_CDKEY WHERE `areaid` = _areaid;
	DELETE FROM LOG_GET_PHP WHERE `areaid` = _areaid;
	DELETE FROM LOG_ACT_REWARD WHERE `areaid` = _areaid;

END
//
delimiter ;

GRANT SELECT ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
GRANT UPDATE ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
GRANT DELETE ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
GRANT INSERT ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
GRANT EXECUTE ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
