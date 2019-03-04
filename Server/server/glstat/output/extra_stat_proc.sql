CREATE DATABASE IF NOT EXISTS db_star_log DEFAULT CHARACTER SET utf8;
USE db_star_log;


delimiter //
DROP PROCEDURE IF EXISTS proc_stat_cost_yb //
CREATE PROCEDURE `proc_stat_cost_yb`()
BEGIN
	#Routine body goes here...

	SET @stat_date = CURDATE();
	SET @max_vip = 3;

	DROP TEMPORARY TABLE IF EXISTS _tmp_t_cost_yb;
	CREATE TEMPORARY TABLE _tmp_t_cost_yb AS SELECT * FROM LOG_CAST_YB WHERE DATE(`time_stamp`) = @stat_date;

	DROP TEMPORARY TABLE IF EXISTS _tmp_t_where;
	CREATE TEMPORARY TABLE _tmp_t_where AS SELECT DISTINCT(`where`) AS remark FROM _tmp_t_cost_yb ORDER BY remark ASC;

	DROP TEMPORARY TABLE IF EXISTS _tmp_t_cost_yb_user;
	CREATE TEMPORARY TABLE _tmp_t_cost_yb_user AS SELECT a.*, b.viplv FROM _tmp_t_cost_yb AS a LEFT JOIN SNAP_USER AS b USING(uid);

	#初始化TEMP表
	DROP TABLE IF EXISTS TEMP_TABLE_STAT;
	CREATE TABLE IF NOT EXISTS TEMP_TABLE_STAT (`viplv` INT, `where` INT, `count` INT, sum_yb_num FLOAT, avg_yb_num FLOAT);
	

	SET @vip = 0;

vip_repeat: REPEAT
		
		INSERT INTO TEMP_TABLE_STAT SELECT `viplv`, `where`, COUNT(`where`) AS count, SUM(`num`)AS sum_yb_num, AVG(`num`) AS avg_yb_num FROM _tmp_t_cost_yb_user WHERE `viplv` = @vip GROUP BY `where`;
	
		SET @vip = @vip + 1;
	UNTIL @vip > @max_vip END REPEAT;
	SELECT * FROM TEMP_TABLE_STAT;
	#SELECT * from _tmp_t_cost_yb_user;
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_cost_yb_user;
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_where;
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_cost_yb;
END
//	
delimiter ;

delimiter //
DROP PROCEDURE IF EXISTS proc_stat_copy_yb_duration //
CREATE PROCEDURE `proc_stat_copy_yb_duration`(IN _arg_begin_time DATETIME, IN _arg_end_time DATETIME)
BEGIN
	#Routine body goes here...

	SET @begin_date = _arg_begin_time;
	SET @end_date = _arg_end_time;

	DROP TEMPORARY TABLE IF EXISTS _tmp_t_cost_yb;
	CREATE TEMPORARY TABLE _tmp_t_cost_yb AS SELECT * FROM LOG_CAST_YB WHERE TIMESTAMP(`time_stamp`) BETWEEN @begin_date AND @end_date;

	#初始化TEMP表
	DROP TABLE IF EXISTS TEMP_TABLE_STAT_DURATION;
	CREATE TABLE IF NOT EXISTS TEMP_TABLE_STAT_DURATION AS SELECT `where`, COUNT(`uid`) AS count, COUNT(DISTINCT `uid`) AS nop, SUM(`num`)AS sum_yb_num, AVG(`num`) AS avg_yb_num FROM _tmp_t_cost_yb GROUP BY `where` ORDER BY count DESC;

	
	SELECT * FROM TEMP_TABLE_STAT_DURATION;

	#SELECT * from _tmp_t_cost_yb_user;
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_cost_yb;

END
//	
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS proc_stat_user_cost //
CREATE PROCEDURE `proc_stat_user_cost`()
BEGIN
	#Routine body goes here...
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_stat_users;
	CREATE TEMPORARY TABLE _tmp_t_stat_users (`sid` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `uid` VARCHAR(33), `rolename` VARCHAR(33));
	
	INSERT INTO _tmp_t_stat_users (`rolename`) VALUES 
		('龙的孤独'), ('久游番番'), ('久游满楼'), ('久游墨水'), ('三剑'), ('倾世灬清风'), ('狄良俊'), ('丿苍神'), ('久游云中歌'), ('久游最牛X'), ('纪承运');

	#SELECT * FROM _tmp_t_stat_users;

	#UPDATE _tmp_t_stat_users, SNAP_USER SET _tmp_t_stat_users.uid = SNAP_USER.uid WHERE _tmp_t_stat_users.rolename = SNAP_USER.nick;

	UPDATE _tmp_t_stat_users, SNAP_USER SET _tmp_t_stat_users.uid = SNAP_USER.uid WHERE SNAP_USER.sid = _tmp_t_stat_users.sid;
	
	SELECT * FROM _tmp_t_stat_users;

	DROP TEMPORARY TABLE IF EXISTS _tmp_t_user_cost;
	CREATE TEMPORARY TABLE _tmp_t_user_cost AS SELECT a.*, b.`where`, b.num, b.`real` FROM _tmp_t_stat_users AS a LEFT JOIN LOG_CAST_YB b USING(`uid`);

	#初始化TEMP表
	DROP TABLE IF EXISTS TEMP_TABLE_STAT;
	CREATE TABLE IF NOT EXISTS TEMP_TABLE_STAT (`uid` VARCHAR(33), `rolename` VARCHAR(33), `where` INT, `count` INT, sum_yb_num FLOAT, avg_yb_num FLOAT);
	
	#SELECT DISTINCT(`sid`) AS sid FROM _tmp_t_stat_users;
	SELECT MAX(`sid`), MIN(`sid`) INTO @max_sid, @min_sid FROM _tmp_t_stat_users;
	#SELECT @max_sid, @min_sid;
	SET @cur_sid = @min_sid;

user_repeat: REPEAT
		
		SELECT `uid` INTO @userid FROM _tmp_t_stat_users WHERE `sid` = @cur_sid;
		
		INSERT INTO TEMP_TABLE_STAT SELECT `uid`, `rolename`, `where`, COUNT(`where`) AS count, SUM(`num`)AS sum_yb_num, AVG(`num`) AS avg_yb_num FROM _tmp_t_user_cost WHERE `uid` = @userid GROUP BY `where`;
	
		SET @cur_sid = @cur_sid + 1;

	UNTIL @cur_sid > @max_sid END REPEAT;
	SELECT * FROM TEMP_TABLE_STAT;
END
//	
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS proc_stat_liushi_user //
CREATE PROCEDURE `proc_stat_liushi_user`()
_start_label:BEGIN
	#Routine body goes here...

	DECLARE _stat_liushi_days INT DEFAULT 2;
	DECLARE _arg_areaid VARCHAR(33) DEFAULT '00001';

	IF( LENGTH(_arg_areaid) <> 5 ) 
	THEN 
		SELECT "_arg_areaid LENGTH NEED 5";
		LEAVE _start_label;
	END IF;

	SET @_areaid = _arg_areaid;
	SET @_cur_date = CURDATE();
	SET @_regist_end_date = DATE_SUB(@_cur_date,INTERVAL _stat_liushi_days DAY);

	#查询信息注册
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_all;		
	CREATE TEMPORARY TABLE _tmp_t_regist_all AS SELECT DISTINCT(`uid`) as uid, DATE(`time_stamp`) as regist_date FROM LOG_REGIST WHERE `areaid` = @_areaid HAVING regist_date <= DATE(@_regist_end_date);

	#登录信息
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_login_all;		
	CREATE TEMPORARY TABLE _tmp_t_login_all AS SELECT `uid`, MAX(DATE(`time_stamp`)) as last_login_date FROM LOG_LOGIN WHERE `areaid` = @_areaid GROUP BY `uid`;

	#流失用户
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_liushi_all;		
	CREATE TEMPORARY TABLE _tmp_t_liushi_all AS SELECT DISTINCT(a.uid), a.regist_date, b.last_login_date, DATEDIFF(@_cur_date, b.last_login_date) AS days FROM _tmp_t_regist_all as a LEFT JOIN _tmp_t_login_all as b USING(uid) HAVING days IS NULL OR days >= _stat_liushi_days;

	#PVE进度
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_pve_pass_all;		
	CREATE TEMPORARY TABLE _tmp_t_pve_pass_all AS SELECT `uid`, MAX(`gqid`) AS maxgqid FROM LOG_PASS_GQ GROUP BY `uid`;

	/*
	SELECT * FROM _tmp_t_regist_all ORDER BY regist_date DESC;
	SELECT * FROM _tmp_t_login_all;
	SELECT * FROM _tmp_t_liushi_all  ORDER BY regist_date DESC;
	*/
	
	#初始化TEMP表
	DROP TABLE IF EXISTS TEMP_TABLE_STAT;
	CREATE TABLE TEMP_TABLE_STAT  AS 
	SELECT a.*, c.nick, c.lv, c.viplv, c.vipscore, c.guide_step, b.maxgqid FROM _tmp_t_liushi_all AS a JOIN _tmp_t_pve_pass_all AS b JOIN SNAP_USER as c ON a.uid = b.uid AND a.uid = c.uid;

	SELECT * FROM TEMP_TABLE_STAT;
	
END
//	
delimiter ;
