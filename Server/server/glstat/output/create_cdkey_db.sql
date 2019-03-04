CREATE DATABASE IF NOT EXISTS db_gl_cdkey;
USE db_gl_cdkey;

GRANT SELECT ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;
GRANT EXECUTE ON *.* TO ali2 IDENTIFIED BY 'ali002';FLUSH PRIVILEGES;


CREATE TABLE IF NOT EXISTS `CDKEYS` (
  `sid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `cdkey` varchar(33) NOT NULL COMMENT 'CDKEY串',
  `batch` int(11) NOT NULL COMMENT '批次',
  `used` int(11) DEFAULT '0' COMMENT '已使用次数',
  PRIMARY KEY (`sid`),
  UNIQUE KEY `cdkey` (`cdkey`) USING HASH
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `KEYS_BATCH` (
  `batch` int(11) NOT NULL COMMENT '批次',
  `mutex` tinyint(4) NOT NULL DEFAULT '1' COMMENT '互斥性，同一批KEY是否互斥',
  `maxtimes` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '最大使用次数',
  `rewardid` int(11) NOT NULL COMMENT '奖励ID',
  `gen_date` date NOT NULL COMMENT '生产日期',
  `gen_count` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '生产数量',
  `active_begin` datetime DEFAULT NULL COMMENT '生效起始日期',
  `active_end` datetime DEFAULT NULL COMMENT '生效截止日期',
  `qudao` smallint(8) DEFAULT NULL COMMENT '渠道ID',
  `areaid` varchar(33) DEFAULT NULL COMMENT '区服ID',
  PRIMARY KEY (`batch`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `KEYS_GEN_LOG` (
  `sid` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `log_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '日志时间',
  `batch` int(11) NOT NULL COMMENT '批次',
  `key_len` int(11) NOT NULL COMMENT 'KEY长度',
  `gen_count` int(11) DEFAULT NULL COMMENT '生产数量',
  `all_count` int(11) DEFAULT NULL COMMENT '总数量',
  `gen_start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `gen_finish_time` datetime DEFAULT NULL COMMENT '完成时间',
  `gen_use_time` time DEFAULT NULL COMMENT '生产耗时',
  `total_key_count` int(11) DEFAULT NULL COMMENT '总KEY数量',
  `repeated_key_count` int(11) DEFAULT NULL COMMENT '重复次数',
  PRIMARY KEY (`sid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `KEYS_USER` (
  `sid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(33) NOT NULL COMMENT '用户ID',
  `cdkey` varchar(33) NOT NULL COMMENT 'CDKEY串',
  `batch` int(11) NOT NULL COMMENT '批次',
  `areaid` varchar(33) DEFAULT NULL COMMENT '服务器ID',
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '使用时间',
  PRIMARY KEY (`sid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

delimiter //
DROP FUNCTION IF EXISTS func_use_cdkey //
CREATE FUNCTION `func_use_cdkey`(_arg_cdkey VARCHAR(33), _arg_userid VARCHAR(33)) RETURNS int(11)
    MODIFIES SQL DATA
    DETERMINISTIC
    SQL SECURITY INVOKER
    COMMENT 'ret > 0, ret= rewardid, ret < 0 errorcode'
BEGIN
		DECLARE _arg_qudao INT DEFAULT 0;
		DECLARE _ret_value INT DEFAULT 0;
		CALL proc_use_cdkey(_arg_cdkey, _arg_userid, _arg_qudao, _ret_value);
		#返回值INT型，>0表示成功得到的奖励ID，-1表示没有此KEY, -2表示KEY次数用尽，-3表示KEY已经使用过同类型的KEY了
		#返回值INT型，-4表示无此批次，-5表示未到生效时间，-6表示已过期
		#返回值INT型，-7表示渠道不正确，-8表示服务器不正确，-9表示KEY奖励为空, -10内部错误
		RETURN _ret_value;
END
//	
delimiter ;

delimiter //
DROP PROCEDURE IF EXISTS proc_use_cdkey //
CREATE PROCEDURE `proc_use_cdkey`(IN _arg_cdkey VARCHAR(33), IN _arg_user_id VARCHAR(33), IN _arg_user_qudao INT, OUT _out_result INT)
   MODIFIES SQL DATA
   COMMENT 'ret > 0, ret= rewardid, ret < 0 errorcode'
BEGIN
	#Routine body goes here...
	#返回值INT型，>0表示成功得到的奖励ID，-1表示没有此KEY, -2表示KEY次数用尽，-3表示KEY已经使用过同类型的KEY了
	#返回值INT型，-4表示无此批次，-5表示未到生效时间，-6表示已过期
	#返回值INT型，-7表示渠道不正确，-8表示服务器不正确，-9表示KEY奖励为空, -10内部错误
	DECLARE _ret_value INT DEFAULT -1;
	
	#使用者信息
	#使用的CDKEY 
	DECLARE _user_cdkey VARCHAR(33) DEFAULT _arg_cdkey;
	#使用者的USERID
	DECLARE _user_id VARCHAR(33) DEFAULT _arg_user_id;
	#使用者的AREAID
	DECLARE _user_area_id VARCHAR(33) DEFAULT RIGHT(_user_id, 5);
	#使用者的渠道
	DECLARE _user_qudao INT DEFAULT _arg_user_qudao;

	#查询信息
	DECLARE _val_row_num INT DEFAULT 0;
	#KEY的信息
	DECLARE _val_key_batch, _val_key_used INT;
	#BATCH的信息
	DECLARE _val_mutex TINYINT;
	DECLARE _val_max_times, _val_reward_id, _val_qudao INT;
	DECLARE _val_area_id VARCHAR(33);
	DECLARE _val_active_begin, _val_active_end DATETIME;

	#当前时间
	DECLARE _cur_time DATETIME DEFAULT CURRENT_TIME();

	#数据操作信息
	DECLARE _occur_eror INT DEFAULT 0;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET _occur_eror = 1;

use_lable:REPEAT
		#查询KEY信息
		SELECT `batch`, `used` INTO _val_key_batch, _val_key_used FROM CDKEYS WHERE `cdkey` = _user_cdkey;
		SELECT FOUND_ROWS() INTO _val_row_num;
		#查看KEY是否存在
		IF _val_row_num <= 0 THEN
			SET _ret_value = -1; #没有此KEY
			LEAVE use_lable;
		END IF;

		#查询BATCH信息
		SELECT `mutex`, `maxtimes`, `rewardid`, `active_begin`, `active_end`, `qudao`, `areaid` INTO 
						_val_mutex, _val_max_times, _val_reward_id, _val_active_begin, _val_active_end, _val_qudao, _val_area_id 
					FROM KEYS_BATCH WHERE `batch` = `_val_key_batch`;
		SELECT FOUND_ROWS() INTO _val_row_num;
		#查看BATCH是否存在
		IF _val_row_num <= 0 THEN
			SET _ret_value = -4; #没有此BATCH
			LEAVE use_lable;
		END IF;
		
		#查看KEY是否生效
		IF _val_active_begin IS NOT NULL THEN
			IF _cur_time < _val_active_begin THEN
				SET _ret_value = -5; #KEY未到生效时间
				LEAVE use_lable;
			END IF;
		END IF;

		#查看KEY是否过期
		IF _val_active_end IS NOT NULL THEN
			IF _cur_time > _val_active_end THEN
				SET _ret_value = -6; #KEY已经过期
				LEAVE use_lable;
			END IF;
		END IF;
			
		#查看KEY是否有渠道限制
		IF _val_qudao IS NOT NULL AND _val_qudao <> 0 THEN
			IF _user_qudao <> _val_qudao THEN
				SET _ret_value = -7; #渠道不正确
				LEAVE use_lable;
			END IF;
		END IF;

		#查看KEY是否有服务器限制
		IF _val_area_id IS NOT NULL AND _val_area_id <> '' THEN
			IF STRCMP(_user_area_id, _val_area_id) <> 0 THEN
				SET _ret_value = -8; #服务器不正确
				LEAVE use_lable;
			END IF;
		END IF;

		#查看KEY次数是否被用完
		IF _val_max_times > 0 AND _val_key_used >= _val_max_times THEN
			SET _ret_value = -2; #KEY次数被用尽
			LEAVE use_lable;
		END IF;


		#查看KEY使用情况
		IF _val_mutex <> 0 THEN 	#互斥
			#查看是否用过同批次的KEY
			SELECT COUNT(*) INTO _val_row_num FROM KEYS_USER WHERE `uid` = _user_id AND `batch` = _val_key_batch;
			#用过
			IF _val_row_num > 0 THEN
				SET _ret_value = -3; #已经使用同批次的KEY了
				LEAVE use_lable;
			END IF;
		END IF;

		#查看奖励是否为空
		IF _val_reward_id <= 0 THEN
			SET _ret_value = -9; #奖励为空
			LEAVE use_lable;
		END IF;

		#KEY 可以使用
		
		#使用KEY
		#更新CDKEYS表
		UPDATE CDKEYS SET `used` = `used` + 1 WHERE `cdkey` = _user_cdkey;
		#插入使用记录表
		INSERT INTO KEYS_USER (`uid`, `cdkey`, `batch`, `areaid`) VALUES (_user_id, _user_cdkey, _val_key_batch, _user_area_id);
		
		IF _occur_eror <> 0 THEN
			SET _ret_value = -10; #SQL错误
			LEAVE use_lable;
		END IF;

		SET _ret_value = _val_reward_id;
		LEAVE use_lable;
	UNTIL 1 END REPEAT use_lable;

	#SELECT _ret_value;
	SET _out_result = _ret_value;
END
//	
delimiter ;



