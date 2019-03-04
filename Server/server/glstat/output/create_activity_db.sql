CREATE DATABASE IF NOT EXISTS db_gl_cdkey;
USE db_gl_cdkey;

CREATE TABLE IF NOT EXISTS `T_ACTIVITY_DEPOSIT_USER` (
  `sid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(33) DEFAULT NULL,
  `TotalGet` int(11) DEFAULT NULL,
  `RealYB` int(11) DEFAULT NULL,
  `FakeYB` int(11) DEFAULT NULL,
  `AreaID` varchar(5) NOT NULL DEFAULT '',
  `EndDate` date DEFAULT NULL,
  `RewardFlag` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`sid`),
  UNIQUE KEY `uid` (`uid`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=2429 DEFAULT CHARSET=utf8;

CREATE TABLE  IF NOT EXISTS `T_ACTIVITY_REWARD_USER` (
  `sid` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `uid` varchar(33) NOT NULL COMMENT '账号',
  `areaid` varchar(33) DEFAULT NULL,
  `acc` varchar(33) DEFAULT NULL,
  `log_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录时间',
  PRIMARY KEY (`sid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


DELIMITER //
DROP FUNCTION IF EXISTS `func_get_roleid` //
CREATE FUNCTION `func_get_roleid`(_arg_userid VARCHAR(33)) RETURNS varchar(33) CHARSET utf8
    DETERMINISTIC
    COMMENT 'return roleid trim the areaid'
RETURN LEFT(_arg_userid, LENGTH(_arg_userid)-5);
//
DELIMITER ;

DELIMITER //
DROP FUNCTION IF EXISTS `func_get_areaid` //
CREATE FUNCTION `func_get_areaid`(_arg_userid VARCHAR(33)) RETURNS varchar(33) CHARSET utf8
    DETERMINISTIC
    COMMENT 'return areaid trim the roleid'
RETURN RIGHT(_arg_userid, 5);
//
DELIMITER ;

DELIMITER //
DROP PROCEDURE IF EXISTS `proc_get_activity_reward` //
CREATE PROCEDURE `proc_get_activity_reward`(IN _arg_acc VARCHAR(33), IN _arg_uid VARCHAR(33), IN _arg_actid INT, OUT Result INT, OUT TotalScore INT, OUT SubScore1 INT)
    READS SQL DATA
    COMMENT 'ret=0 OK, ret=-1,failed'
BEGIN
	#Routine body goes here...
	DECLARE _user_acc VARCHAR(33) DEFAULT _arg_acc;
	DECLARE _user_id VARCHAR(33) DEFAULT _arg_uid;
	DECLARE _user_roleid VARCHAR(33) DEFAULT func_get_roleid(_arg_uid);
	DECLARE _user_area_id VARCHAR(33) DEFAULT func_get_areaid(_user_id);
	DECLARE _ret_value INT DEFAULT 0;
	DECLARE _out_result INT DEFAULT -2;
	DECLARE _out_total_get INT DEFAULT 0;
	DECLARE _out_real_yb INT DEFAULT 0;
	

	#过滤服务器
	DECLARE _filter_areaid_1 VARCHAR(33) DEFAULT '03';

	#数据操作信息
	DECLARE _occur_eror INT DEFAULT 0;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET _occur_eror = 1;

get_label:REPEAT
	
		#在过滤列表中
		IF LEFT(_user_area_id,2) = _filter_areaid_1 THEN
			SET _ret_value = -1; #在服务器过滤列表中
			LEAVE get_label;
		END IF;

		#查询领奖信息
		IF EXISTS(SELECT * FROM T_ACTIVITY_REWARD_USER WHERE `uid` = _user_roleid) THEN
			SET _ret_value = -2; #已经领过奖励了
			LEAVE get_label;
		END IF;

/*
		#查询资格信息
		IF NOT EXISTS(SELECT * FROM T_ACTIVITY_DEPOSIT_USER WHERE `Acc` = _user_acc) THEN
			SET _ret_val = -1; #没有资格
			LEAVE get_label;
		END IF;
*/
		#查询资格信息
		SELECT `uid`, `TotalGet`, `RealYB`, `FakeYB`, AreaID, EndDate INTO @_uid, _out_total_get, _out_real_yb, @_fake_yb, @_area_id, @_enddate FROM T_ACTIVITY_DEPOSIT_USER WHERE `uid` = _user_roleid;
		SELECT FOUND_ROWS() INTO @_found_row;
		IF @_found_row = 0 THEN
			SET _ret_value = -1; #没有资格
			LEAVE get_label;
		END IF;

		#插入奖励信
		INSERT IGNORE INTO T_ACTIVITY_REWARD_USER (`uid`, `acc`, `areaid`) VALUES (_user_roleid, _user_acc, func_get_areaid(_user_id));
		#是否出错
		IF _occur_eror <> 0 THEN
			SET _ret_value = -3; #SQL错误
			LEAVE get_label;
		END IF;
		
		SET _ret_value = 0;
		#结果
		LEAVE get_label;
	UNTIL 1 END REPEAT get_label;

	SET _out_result = _ret_value;
	#SELECT _out_result AS Result, _out_total_get AS TotalScore, _out_real_yb AS SubScore1;

	SET Result = _out_result;
	SET TotalScore = _out_total_get;
	SET SubScore1 = _out_real_yb;
	#SELECT _ret_value;

END
//
DELIMITER ;
