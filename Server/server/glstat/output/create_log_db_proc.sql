CREATE DATABASE IF NOT EXISTS db_star_log DEFAULT CHARACTER SET utf8;
USE db_star_log;

delimiter //
DROP PROCEDURE IF EXISTS proc_auto_stat_kpi //
CREATE PROCEDURE `proc_auto_stat_kpi`()
BEGIN
	CALL proc_stat_kpi_yesterday;
END
//	
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS proc_daily_stat_server //
CREATE PROCEDURE `proc_daily_stat_server`(IN _arg_areaid VARCHAR(33), IN _arg_date DATE)
    MODIFIES SQL DATA
_start_label:BEGIN
	#Routine body goes here...
IF( LENGTH(_arg_areaid) <> 5 ) 
THEN 
	SELECT "_arg_areaid LENGTH NEED 5";
	LEAVE _start_label;
END IF;

SELECT DATE_FORMAT(_arg_date, '%Y') INTO @_date_year;
IF( @_date_year < 2014 ) 
THEN 
	SELECT "_arg_date not a valid date";
	LEAVE _start_label;
END IF;

SET @_areaid = _arg_areaid;
SET @_stat_date = _arg_date;
#SET @_stat_date = DATE_SUB(CURDATE(),INTERVAL 1 DAY);
SET @_regist_date = @_stat_date;
SET @_login_date = @_stat_date;
SET @_regist_date_r2 = DATE_SUB(@_regist_date,INTERVAL 1 DAY);
SET @_regist_date_r3 = DATE_SUB(@_regist_date,INTERVAL 2 DAY);
SET @_regist_date_r7 = DATE_SUB(@_regist_date,INTERVAL 6 DAY);
SET @_regist_date_r14 = DATE_SUB(@_regist_date,INTERVAL 13 DAY);
SET @_regist_date_r30 = DATE_SUB(@_regist_date,INTERVAL 29 DAY);
SET @_deposit_date = @_regist_date;
SET @_online_date = @_stat_date;

#注册
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist;
CREATE TEMPORARY TABLE _tmp_t_regist AS SELECT DISTINCT(uid) FROM LOG_REGIST WHERE DATE(`time_stamp`) = DATE(@_regist_date) and `areaid` = @_areaid;

#之前注册ROLEID
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_roleid;
#CREATE TEMPORARY TABLE _tmp_t_regist_roleid AS SELECT DISTINCT(func_get_roleid(`uid`)) AS roleid FROM LOG_REGIST WHERE DATE(`time_stamp`) < DATE(@_regist_date);

#登录
DROP TEMPORARY TABLE IF EXISTS _tmp_t_login;
CREATE TEMPORARY TABLE _tmp_t_login AS SELECT DISTINCT(uid) FROM LOG_LOGIN WHERE DATE(`time_stamp`) = DATE(@_login_date) and `areaid` = @_areaid;

#留存登录
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_r2;
CREATE TEMPORARY TABLE _tmp_t_regist_r2 AS SELECT DISTINCT(uid) FROM LOG_REGIST WHERE DATE(`time_stamp`) = DATE(@_regist_date_r2) and `areaid` = @_areaid;

DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_r3;
CREATE TEMPORARY TABLE _tmp_t_regist_r3 AS SELECT DISTINCT(uid) FROM LOG_REGIST WHERE DATE(`time_stamp`) = DATE(@_regist_date_r3) and `areaid` = @_areaid;

DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_r7;
CREATE TEMPORARY TABLE _tmp_t_regist_r7 AS SELECT DISTINCT(uid) FROM LOG_REGIST WHERE DATE(`time_stamp`) = DATE(@_regist_date_r7) and `areaid` = @_areaid;

DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_r14;
CREATE TEMPORARY TABLE _tmp_t_regist_r14 AS SELECT DISTINCT(uid) FROM LOG_REGIST WHERE DATE(`time_stamp`) = DATE(@_regist_date_r14) and `areaid` = @_areaid;

DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_r30;
CREATE TEMPORARY TABLE _tmp_t_regist_r30 AS SELECT DISTINCT(uid) FROM LOG_REGIST WHERE DATE(`time_stamp`) = DATE(@_regist_date_r30) and `areaid` = @_areaid;

#充值
DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;
CREATE TEMPORARY TABLE _tmp_t_deposit AS SELECT * FROM LOG_DEPOSIT WHERE DATE(`time_stamp`) = DATE(@_deposit_date) and `areaid` = @_areaid;

#在线统计
DROP TEMPORARY TABLE IF EXISTS _tmp_t_online;
CREATE TEMPORARY TABLE _tmp_t_online AS SELECT * FROM LOG_ONLINE WHERE DATE(`time_stamp`) = DATE(@_online_date) and `areaid` = @_areaid;


#查看临时表
/*
SELECT * FROM _tmp_t_regist;
SELECT * FROM _tmp_t_login;
SELECT * FROM _tmp_t_deposit;
SELECT DISTINCT(uid) FROM _tmp_t_deposit;
SELECT * FROM _tmp_t_deposit WHERE `isfirst` = 1;
SELECT * FROM _tmp_t_online;
SELECT * FROM _tmp_t_regist_roleid;
*/



#统计

#注册用户数，登录用户数，充值用户数
SELECT count(*) INTO @_regist_count FROM _tmp_t_regist;
SELECT count(*) INTO @_login_count FROM _tmp_t_login;
SELECT count(DISTINCT(uid)) INTO @_deposit_count FROM _tmp_t_deposit;
#纯新进用户数,之前没有注册过
#SELECT count(*) INTO @_rookie_count FROM _tmp_t_regist WHERE NOT EXISTS(SELECT * FROM _tmp_t_regist_roleid WHERE `roleid` = func_get_roleid(`uid`));
SET @_rookie_count = @_regist_count;

#SELECT * FROM _tmp_t_regist WHERE NOT EXISTS(SELECT * FROM _tmp_t_regist_roleid WHERE `roleid` = func_get_roleid(`uid`));

#活跃用户数
SELECT count(*) INTO @_active_count FROM (SELECT * FROM _tmp_t_login UNION DISTINCT SELECT * FROM _tmp_t_regist) as _LOGIN_AND_REGIST;

#留存
SELECT count(*) INTO @_drr2_regist_count FROM _tmp_t_regist_r2;
SELECT count(*) INTO @_drr3_regist_count FROM _tmp_t_regist_r3;
SELECT count(*) INTO @_drr7_regist_count FROM _tmp_t_regist_r7;
SELECT count(*) INTO @_drr14_regist_count FROM _tmp_t_regist_r14;
SELECT count(*) INTO @_drr30_regist_count FROM _tmp_t_regist_r30;

SELECT count(*) INTO @_drr2_count FROM _tmp_t_regist_r2 as a JOIN _tmp_t_login as b ON a.uid = b.uid;
SELECT count(*) INTO @_drr3_count FROM _tmp_t_regist_r3 as a JOIN _tmp_t_login as b ON a.uid = b.uid;
SELECT count(*) INTO @_drr7_count FROM _tmp_t_regist_r7 as a JOIN _tmp_t_login as b ON a.uid = b.uid;
SELECT count(*) INTO @_drr14_count FROM _tmp_t_regist_r14 as a JOIN _tmp_t_login as b ON a.uid = b.uid;
SELECT count(*) INTO @_drr30_count FROM _tmp_t_regist_r30 as a JOIN _tmp_t_login as b ON a.uid = b.uid;

#在线人数
SELECT AVG(`olnum`),  MAX(`olnum`) INTO @_acu, @_pcu FROM _tmp_t_online;

#收入
SELECT SUM(`amount`) INTO @_income_amount FROM _tmp_t_deposit;

#注册付费
SELECT COUNT(DISTINCT uid) INTO @_regist_deposit_count FROM (SELECT DISTINCT(uid) FROM _tmp_t_deposit ) AS A JOIN _tmp_t_regist AS B USING(uid);

#查看中间变量
#SELECT @_regist_count, @_rookie_count, @_login_count, @_active_count, @_deposit_count, @_drr2_count, @_drr3_count, @_drr7_count;

#计算
SET @_deposit_perct = @_deposit_count / @_active_count * 100;
SET @_drr2_perct = @_drr2_count / @_drr2_regist_count * 100;
SET @_drr3_perct = @_drr3_count / @_drr3_regist_count * 100;
SET @_drr7_perct = @_drr7_count / @_drr7_regist_count * 100;
SET @_drr14_perct = @_drr14_count / @_drr14_regist_count * 100;
SET @_drr30_perct = @_drr30_count / @_drr30_regist_count * 100;

SET @_arpu = @_income_amount / @_active_count;
SET @_arppu = @_income_amount / @_deposit_count;

#格式化
SET @_deposit_perct = FORMAT(@_deposit_perct, 2) + 0;
SET @_drr2_perct = FORMAT(@_drr2_perct, 2) + 0;
SET @_drr3_perct = FORMAT(@_drr3_perct, 2) + 0;
SET @_drr7_perct = FORMAT(@_drr7_perct, 2) + 0;
SET @_drr14_perct = FORMAT(@_drr14_perct, 2) + 0;
SET @_drr30_perct = FORMAT(@_drr30_perct, 2) + 0;
SET @_arpu = FORMAT(@_arpu, 2) + 0;

SET @_acu = FLOOR(@_acu);
SET @_arppu = FLOOR(@_arppu);

#结果输出

#更新1天前
#SELECT DATE(@_regist_date_r2), @_drr2_regist_count, @_drr2_count, @_drr2_perct;
UPDATE KPI_STAT_DAILY SET `drr2_perct` = @_drr2_perct WHERE `areaid` = @_areaid AND `stat_date` = DATE(@_regist_date_r2);

#更新2天前
#SELECT DATE(@_regist_date_r3), @_drr3_regist_count, @_drr3_count, @_drr3_perct;
UPDATE KPI_STAT_DAILY SET `drr3_perct` = @_drr3_perct WHERE `areaid` = @_areaid AND `stat_date` = DATE(@_regist_date_r3);

#更新6天前
#SELECT DATE(@_regist_date_r7), @_drr7_regist_count, @_drr7_count, @_drr7_perct;
UPDATE KPI_STAT_DAILY SET `drr7_perct` = @_drr7_perct WHERE `areaid` = @_areaid AND `stat_date` = DATE(@_regist_date_r7);

#更新13天前
#SELECT DATE(@_regist_date_r14), @_drr14_regist_count, @_drr14_count, @_drr14_perct;
UPDATE KPI_STAT_DAILY SET `drr14_perct` = @_drr14_perct WHERE `areaid` = @_areaid AND `stat_date` = DATE(@_regist_date_r14);

#更新29天前
#SELECT DATE(@_regist_date_r30), @_drr30_regist_count, @_drr30_count, @_drr30_perct;
UPDATE KPI_STAT_DAILY SET `drr30_perct` = @_drr30_perct WHERE `areaid` = @_areaid AND `stat_date` = DATE(@_regist_date_r30);

#结果输出
SET @_now_date = CAST(@_stat_date AS CHAR);
SELECT @_areaid, @_now_date, @_regist_count, @_rookie_count, @_active_count, @_acu, @_pcu, @_income_amount, @_arpu, @_arppu, @_regist_deposit_count, @_deposit_count, @_deposit_perct;

INSERT IGNORE INTO KPI_STAT_DAILY (`areaid`, `stat_date`, `regist_count`, `rookie_count`, `active_count`, `acu`, `pcu`, `income_amount`, `arpu`, `arppu`, `regist_deposit_count`, `deposit_count`, `deposit_perct`) 
	VALUES (@_areaid, @_now_date, @_regist_count, @_rookie_count, @_active_count, @_acu, @_pcu, @_income_amount, @_arpu, @_arppu, @_regist_deposit_count, @_deposit_count, @_deposit_perct) 
	ON DUPLICATE KEY UPDATE `regist_count` = VALUES(`regist_count`), `rookie_count` = VALUES(`rookie_count`), `active_count` = VALUES(`active_count`), `acu` = VALUES(`acu`), `pcu` = VALUES(`pcu`), 
															`income_amount` = VALUES(`income_amount`), `arpu` = VALUES(`arpu`), `arppu` = VALUES(`arppu`), 
															`regist_deposit_count` = VALUES(`regist_deposit_count`), `deposit_count` = VALUES(`deposit_count`), `deposit_perct` = VALUES(`deposit_perct`);
	

DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_roleid;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_login;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_r2;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_r3;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_r7;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_r14;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_r30;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_online;


END
//	
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS proc_monthly_stat_server //
CREATE PROCEDURE `proc_monthly_stat_server`(IN _arg_areaid VARCHAR(33), IN _arg_date DATE)
    MODIFIES SQL DATA
_start_label:BEGIN
	#Routine body goes here...
IF( LENGTH(_arg_areaid) <> 5 ) 
THEN 
	SELECT "_arg_areaid LENGTH NEED 5";
	LEAVE _start_label;
END IF;

SELECT DATE_FORMAT(_arg_date, '%Y') INTO @_date_year;
IF( @_date_year < 2014 ) 
THEN 
	SELECT "_arg_date not a valid date";
	LEAVE _start_label;
END IF;

SET @_areaid = _arg_areaid;
SET @_stat_date = _arg_date;
#SET @_stat_date = DATE_SUB(CURDATE(),INTERVAL 1 DAY);
#统计到哪天
SET @_stat_date_end = @_stat_date;
SET @_stat_month = DATE_FORMAT(@_stat_date_end, '%m');
SET @_stat_day = DATE_FORMAT(@_stat_date_end, '%e');
#统计从哪天开始
SET @_stat_date_start = DATE_SUB(@_stat_date_end, INTERVAL @_stat_day-1 DAY);
#SELECT DATE(@_stat_date_end), @_stat_month, @_stat_day, DATE(@_stat_date_start);

#注册
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist;
CREATE TEMPORARY TABLE _tmp_t_regist AS SELECT DISTINCT(`uid`) FROM LOG_REGIST WHERE DATE(`time_stamp`) BETWEEN DATE(@_stat_date_start) AND DATE(@_stat_date_end) AND `areaid` = @_areaid;

#登录
DROP TEMPORARY TABLE IF EXISTS _tmp_t_login;
CREATE TEMPORARY TABLE _tmp_t_login AS SELECT DISTINCT(`uid`) FROM LOG_LOGIN WHERE DATE(`time_stamp`) BETWEEN DATE(@_stat_date_start) AND DATE(@_stat_date_end) AND `areaid` = @_areaid;

#充值
DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;
CREATE TEMPORARY TABLE _tmp_t_deposit AS SELECT * FROM LOG_DEPOSIT WHERE DATE(`time_stamp`) BETWEEN DATE(@_stat_date_start) AND DATE(@_stat_date_end) AND `areaid` = @_areaid;

#在线统计
DROP TEMPORARY TABLE IF EXISTS _tmp_t_online;
CREATE TEMPORARY TABLE _tmp_t_online AS SELECT * FROM LOG_ONLINE WHERE DATE(`time_stamp`) BETWEEN DATE(@_stat_date_start) AND DATE(@_stat_date_end) and `areaid` = @_areaid;


#查看临时表
/*
SELECT * FROM _tmp_t_regist;
SELECT * FROM _tmp_t_login;
SELECT * FROM _tmp_t_deposit;
SELECT DISTINCT(uid) FROM _tmp_t_deposit;
SELECT * FROM _tmp_t_deposit WHERE `isfirst` = 1;
SELECT * FROM _tmp_t_online;
*/
#统计

#注册用户数，登录用户数，充值用户数
SELECT count(*) INTO @_regist_count FROM _tmp_t_regist;
SELECT count(*) INTO @_login_count FROM _tmp_t_login;
SELECT count(DISTINCT(uid)) INTO @_deposit_count FROM _tmp_t_deposit;

#活跃用户数
SELECT count(*) INTO @_active_count FROM (SELECT * FROM _tmp_t_login UNION DISTINCT SELECT * FROM _tmp_t_regist) as _LOGIN_AND_REGIST;

#在线人数
SELECT AVG(`olnum`),  MAX(`olnum`) INTO @_acu, @_pcu FROM _tmp_t_online;

#收入
SELECT SUM(`amount`) INTO @_income_amount FROM _tmp_t_deposit;

#查看中间变量
#SELECT @_regist_count, @_login_count, @_active_count, @_deposit_count;

#计算
SET @_deposit_perct = @_deposit_count / @_active_count * 100;
SET @_arpu = @_income_amount / @_active_count;
SET @_arppu = @_income_amount / @_deposit_count;

#格式化
SET @_deposit_perct = FORMAT(@_deposit_perct, 2) + 0;
SET @_arpu = FORMAT(@_arpu, 2) + 0;

SET @_acu = FLOOR(@_acu);
SET @_arppu = FLOOR(@_arppu);

#结果输出
SET @_now_date = CAST(@_stat_date_end AS CHAR);
SET @_month_start_date = CAST(@_stat_date_start AS CHAR);
SET @_month_end_date = CAST(LAST_DAY(@_stat_date_end) AS CHAR);
SET @_year_month = CAST(DATE_FORMAT(@_stat_date_end, '%Y-%m') AS CHAR);

SELECT @_year_month, @_month_start_date, @_month_end_date, @_now_date, @_regist_count, @_active_count, @_acu, @_pcu, @_income_amount, @_arpu, @_arppu, @_deposit_count, @_deposit_perct;


INSERT IGNORE INTO KPI_STAT_MONTHLY (`areaid`, `year_month`, `begin_date`, `end_date`, `stat_date`, `regist_count`, `active_count`, `acu`, `pcu`, `income_amount`, `arpu`, `arppu`, `deposit_count`, `deposit_perct`) 
	VALUES (@_areaid, @_year_month, @_month_start_date, @_month_end_date, @_now_date, @_regist_count, @_active_count, @_acu, @_pcu, @_income_amount, @_arpu, @_arppu, @_deposit_count, @_deposit_perct) 
	ON DUPLICATE KEY UPDATE `stat_date` = VALUES(`stat_date`), `regist_count` = VALUES(`regist_count`), `active_count` = VALUES(`active_count`), `acu` = VALUES(`acu`), `pcu` = VALUES(`pcu`), 
															`income_amount` = VALUES(`income_amount`), `deposit_count` = VALUES(`deposit_count`), `arpu` = VALUES(`arpu`), 
															`arppu` = VALUES(`arppu`), `deposit_perct`  = VALUES(`deposit_perct`);
	

DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_login;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_online;


END
//	
delimiter ;

delimiter //
DROP PROCEDURE IF EXISTS proc_weekly_stat_server //
CREATE PROCEDURE `proc_weekly_stat_server`(IN _arg_areaid VARCHAR(33), IN _arg_date DATE)
    MODIFIES SQL DATA
_start_label:BEGIN
	#Routine body goes here...
IF( LENGTH(_arg_areaid) <> 5 ) 
THEN 
	SELECT "_arg_areaid LENGTH NEED 5";
	LEAVE _start_label;
END IF;

SELECT DATE_FORMAT(_arg_date, '%Y') INTO @_date_year;
IF( @_date_year < 2014 ) 
THEN 
	SELECT "_arg_date not a valid date";
	LEAVE _start_label;
END IF;

SET @_areaid = _arg_areaid;
SET @_stat_date = _arg_date;
#SET @_stat_date = DATE_SUB(CURDATE(),INTERVAL 1 DAY);
#统计到哪天
SET @_stat_date_end = @_stat_date;
SET @_stat_week_day = DATE_FORMAT(@_stat_date_end, '%w');
SET @_stat_week_day = IF(@_stat_week_day = 0, 7, @_stat_week_day);
#统计从哪天开始
SET @_stat_date_start = DATE_SUB(@_stat_date_end, INTERVAL @_stat_week_day-1 DAY);
#SELECT DATE(@_stat_date_end), @_stat_week_day, DATE(@_stat_date_start);

SET @_cond_date_end_wr1 = DATE_SUB(@_stat_date_start, INTERVAL 1 DAY);
SET @_cond_date_start_wr1 = DATE_SUB(@_cond_date_end_wr1, INTERVAL 6 DAY);

#SELECT DATE(@_cond_date_end_wr1), @_stat_week_day, DATE(@_cond_date_start_wr1);

#注册
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist;
CREATE TEMPORARY TABLE _tmp_t_regist AS SELECT DISTINCT(`uid`) FROM LOG_REGIST WHERE DATE(`time_stamp`) BETWEEN DATE(@_stat_date_start) AND DATE(@_stat_date_end) AND `areaid` = @_areaid;

#登录
DROP TEMPORARY TABLE IF EXISTS _tmp_t_login;
CREATE TEMPORARY TABLE _tmp_t_login AS SELECT DISTINCT(`uid`) FROM LOG_LOGIN WHERE DATE(`time_stamp`) BETWEEN DATE(@_stat_date_start) AND DATE(@_stat_date_end) AND `areaid` = @_areaid;

#充值
DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;
CREATE TEMPORARY TABLE _tmp_t_deposit AS SELECT * FROM LOG_DEPOSIT WHERE DATE(`time_stamp`) BETWEEN DATE(@_stat_date_start) AND DATE(@_stat_date_end) AND `areaid` = @_areaid;

#本周忠实用户
DROP TEMPORARY TABLE IF EXISTS _tmp_t_lealty_users;
CREATE TEMPORARY TABLE _tmp_t_lealty_users AS SELECT `uid`, COUNT(DISTINCT DATE(`log_time`)) AS login_days FROM LOG_LOGIN WHERE DATE(`time_stamp`) BETWEEN DATE(@_stat_date_start) AND DATE(@_stat_date_end) AND `areaid` = @_areaid GROUP BY `uid` HAVING login_days >= 3;

#上周注册用户
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_wr1;
CREATE TEMPORARY TABLE _tmp_t_regist_wr1 AS SELECT DISTINCT(`uid`) FROM LOG_REGIST WHERE DATE(`time_stamp`) BETWEEN DATE(@_cond_date_start_wr1) AND DATE(@_cond_date_end_wr1) and `areaid` = @_areaid;

#上周登录用户
DROP TEMPORARY TABLE IF EXISTS _tmp_t_login_wr1;
CREATE TEMPORARY TABLE _tmp_t_login_wr1 AS SELECT DISTINCT(`uid`) FROM LOG_LOGIN WHERE DATE(`time_stamp`) BETWEEN DATE(@_cond_date_start_wr1) AND DATE(@_cond_date_end_wr1) and `areaid` = @_areaid;

#上周流失用户
DROP TEMPORARY TABLE IF EXISTS _tmp_t_liushi_wr1;
CREATE TEMPORARY TABLE _tmp_t_liushi_wr1 AS SELECT DISTINCT(`uid`) FROM _tmp_t_login_wr1 WHERE `uid` NOT IN (SELECT `uid` FROM _tmp_t_login);



#查看临时表

/*
SELECT * FROM _tmp_t_regist;
SELECT * FROM _tmp_t_login;
SELECT * FROM _tmp_t_deposit;

SELECT DISTINCT(uid) FROM _tmp_t_deposit;
SELECT * FROM _tmp_t_deposit WHERE `isfirst` = 1;
*/
/*
SELECT * FROM _tmp_t_login_wr1;
SELECT * FROM _tmp_t_regist_wr1;
SELECT * FROM _tmp_t_lealty_users;
SELECT * FROM _tmp_t_liushi_wr1;
*/

#统计

#注册用户数，登录用户数，充值用户数
SELECT count(*) INTO @_regist_count FROM _tmp_t_regist;
SELECT count(*) INTO @_login_count FROM _tmp_t_login;
SELECT count(DISTINCT(uid)) INTO @_deposit_count FROM _tmp_t_deposit;

#上周的流失人数
SELECT count(*) INTO @_liushi_wr1 FROM _tmp_t_liushi_wr1;

#上周的付费流失人数
SELECT count(*) INTO @_liushi_paid_wr1 FROM _tmp_t_liushi_wr1 as a JOIN `SNAP_USER` as b ON a.uid = b.uid WHERE b.money > 0;

#上周的注册人数
SELECT count(*) INTO @_regist_count_wr1 FROM _tmp_t_regist_wr1;

#上周的登录人数
SELECT count(*) INTO @_login_count_wr1 FROM _tmp_t_login_wr1;

#活跃用户数
SELECT count(*) INTO @_active_count FROM (SELECT * FROM _tmp_t_login UNION DISTINCT SELECT * FROM _tmp_t_regist) as _LOGIN_AND_REGIST;

#上周新用户留存
SELECT count(*) INTO @_wrr1_count FROM _tmp_t_regist_wr1 as a JOIN _tmp_t_login as b ON a.uid = b.uid;

#收入
SELECT SUM(`amount`) INTO @_income_amount FROM _tmp_t_deposit;

#首充人数
SELECT COUNT(DISTINCT uid), AVG(`amount`) INTO @_first_deposit_count, @_first_deposit_avg FROM _tmp_t_deposit WHERE `isfirst` = 1;

#本周忠实用户数
SELECT count(*) INTO @_lealty_count FROM _tmp_t_lealty_users;

#查看中间变量
#SELECT @_regist_count, @_login_count, @_active_count, @_deposit_count, @_wrr1_count, @_first_deposit_count, @_first_deposit_avg;

#计算

SET @_liushi_wr1_perct = @_liushi_wr1 / @_regist_count_wr1 * 100;
SET @_liushi_paid_wr1_perct = @_liushi_paid_wr1 / @_regist_count_wr1 * 100;

#格式化
SET @_first_deposit_avg = FORMAT(@_first_deposit_avg, 2) + 0;
SET @_liushi_wr1_perct = FORMAT(@_liushi_wr1_perct, 2) + 0;
SET @_liushi_paid_wr1_perct = FORMAT(@_liushi_paid_wr1_perct, 2) + 0;


#结果输出
SET @_begin_date_wr1 = CAST(@_cond_date_start_wr1 AS CHAR);
SET @_end_date_wr1 = CAST(@_cond_date_end_wr1 AS CHAR);

#上周
#SELECT @_begin_date_wr1, @_end_date_wr1, @_regist_count_wr1, @_login_count_wr1, @_liushi_wr1, @_liushi_paid_wr1, @_liushi_wr1_perct, @_liushi_paid_wr1_perct;

SET @_now_date = CAST(@_stat_date_end AS CHAR);
SET @_week_start_date = CAST(@_stat_date_start AS CHAR);
SET @_week_end_date = CAST(DATE_ADD(@_stat_date_start, INTERVAL 6 DAY) AS CHAR);

#本周
SELECT @_week_start_date, @_week_end_date, @_now_date, @_stat_week_day, @_regist_count, @_active_count, @_wrr1_count, @_lealty_count, @_income_amount, @_first_deposit_avg;

#更新上周
UPDATE KPI_STAT_WEEKLY SET `liushi_wr1_perct` = @_liushi_wr1_perct, `liushi_paid_wr1_perct` = @_liushi_paid_wr1_perct, `wrr1_count` = @_wrr1_count WHERE `areaid` = @_areaid AND `begin_date` = DATE(@_begin_date_wr1);

#更新本周
INSERT IGNORE INTO KPI_STAT_WEEKLY (`areaid`, `begin_date`, `end_date`, `stat_date`, `week_day`, `regist_count`, `active_count`, `lealty_count`, `income_amount`, `first_deposit_avg`) 
	VALUES (@_areaid, @_week_start_date, @_week_end_date, @_now_date, @_stat_week_day, @_regist_count, @_active_count, @_lealty_count, @_income_amount, @_first_deposit_avg) 
	ON DUPLICATE KEY UPDATE `week_day` = VALUES(`week_day`), `stat_date` = VALUES(`stat_date`), `regist_count` = VALUES(`regist_count`), `active_count` = VALUES(`active_count`), `wrr1_count` = VALUES(`wrr1_count`), 
															`lealty_count` = VALUES(`lealty_count`), `income_amount` = VALUES(`income_amount`), `first_deposit_avg` = VALUES(`first_deposit_avg`);

DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_login;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;

DROP TEMPORARY TABLE IF EXISTS _tmp_t_lealty_users;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_wr1;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_login_wr1;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_liushi_wr1;


END
//	
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS proc_daily_stat_liucun //
CREATE PROCEDURE `proc_daily_stat_liucun`(IN _arg_date DATE)
    MODIFIES SQL DATA
_start_label:BEGIN
	#Routine body goes here...

SELECT DATE_FORMAT(_arg_date, '%Y') INTO @_date_year;
IF( @_date_year < 2014 ) 
THEN 
	SELECT "_arg_date not a valid date";
	LEAVE _start_label;
END IF;

SET @_stat_date = _arg_date;
#SET @_stat_date = DATE_SUB(CURDATE(),INTERVAL 1 DAY);
SET @_regist_date = @_stat_date;
SET @_login_date = @_stat_date;
SET @_regist_date_r2 = DATE_SUB(@_regist_date,INTERVAL 1 DAY);
SET @_regist_date_r3 = DATE_SUB(@_regist_date,INTERVAL 2 DAY);
SET @_regist_date_r7 = DATE_SUB(@_regist_date,INTERVAL 6 DAY);
SET @_regist_date_r14 = DATE_SUB(@_regist_date,INTERVAL 13 DAY);
SET @_regist_date_r30 = DATE_SUB(@_regist_date,INTERVAL 29 DAY);

#1,'%','2015-03-10'

#玩家用户快照
DROP TEMPORARY TABLE IF EXISTS _tmp_t_user_days;
CREATE TEMPORARY TABLE IF NOT EXISTS _tmp_t_user_days AS SELECT `uid`, `regist_time`, `last_login_time`, DATEDIFF(@_login_date, `last_login_time`) as days FROM SNAP_USER;

#当天登录玩家
DROP TEMPORARY TABLE IF EXISTS _tmp_t_user_login;
CREATE TEMPORARY TABLE IF NOT EXISTS _tmp_t_user_login AS SELECT `uid`, `regist_time`, `last_login_time`, `days` FROM _tmp_t_user_days WHERE `days` <= 0;

#查看临时表
#SELECT * FROM _tmp_t_user_days;
#SELECT * FROM _tmp_t_user_login;

#SELECT * FROM _tmp_t_user_days WHERE DATEDIFF(`regist_time`, @_stat_date) = 0;
#统计当天总注册数
SELECT count(*) INTO @_regist_count FROM _tmp_t_user_days WHERE DATE(`regist_time`) = @_stat_date;


#统计1天前注册玩家，在_login_date的注册和情况
SELECT count(*) INTO @_drr2_regist_count FROM _tmp_t_user_days WHERE DATE(`regist_time`) = @_regist_date_r2;
SELECT count(*) INTO @_drr2_liucun_count FROM _tmp_t_user_login WHERE DATE(`regist_time`) = @_regist_date_r2;

#统计2天前注册玩家，在_login_date的注册和情况
SELECT count(*) INTO @_drr3_regist_count FROM _tmp_t_user_days WHERE DATE(`regist_time`) = @_regist_date_r3;
SELECT count(*) INTO @_drr3_liucun_count FROM _tmp_t_user_login WHERE DATE(`regist_time`) = @_regist_date_r3;

#统计6天前注册玩家，在_login_date的注册和情况
SELECT count(*) INTO @_drr7_regist_count FROM _tmp_t_user_days WHERE DATE(`regist_time`) = @_regist_date_r7;
SELECT count(*) INTO @_drr7_liucun_count FROM _tmp_t_user_login WHERE DATE(`regist_time`) = @_regist_date_r7;

#统计13天前注册玩家，在_login_date的注册和情况
SELECT count(*) INTO @_drr14_regist_count FROM _tmp_t_user_days WHERE DATE(`regist_time`) = @_regist_date_r14;
SELECT count(*) INTO @_drr14_liucun_count FROM _tmp_t_user_login WHERE DATE(`regist_time`) = @_regist_date_r14;

#统计29天前注册玩家，在_login_date的注册和情况
SELECT count(*) INTO @_drr30_regist_count FROM _tmp_t_user_days WHERE DATE(`regist_time`) = @_regist_date_r30;
SELECT count(*) INTO @_drr30_liucun_count FROM _tmp_t_user_login WHERE DATE(`regist_time`) = @_regist_date_r30;


#查看中间变量
#SELECT @_regist_count;

#计算
SET @_drr2_perct = @_drr2_liucun_count / @_drr2_regist_count * 100;
SET @_drr3_perct = @_drr3_liucun_count / @_drr3_regist_count * 100;
SET @_drr7_perct = @_drr7_liucun_count / @_drr7_regist_count * 100;
SET @_drr14_perct = @_drr14_liucun_count / @_drr14_regist_count * 100;
SET @_drr30_perct = @_drr30_liucun_count / @_drr30_regist_count * 100;

#格式化
SET @_drr2_perct = FORMAT(@_drr2_perct, 2) + 0;
SET @_drr3_perct = FORMAT(@_drr3_perct, 2) + 0;
SET @_drr7_perct = FORMAT(@_drr7_perct, 2) + 0;
SET @_drr14_perct = FORMAT(@_drr14_perct, 2) + 0;
SET @_drr30_perct = FORMAT(@_drr30_perct, 2) + 0;

#结果输出

#更新1天前
#SELECT DATE(@_regist_date_r2), @_drr2_regist_count, @_drr2_liucun_count, @_drr2_perct;
UPDATE KPI_STAT_DAILY_LIUCUN SET `drr2_perct` = @_drr2_perct WHERE `stat_date` = DATE(@_regist_date_r2);

#更新2天前
#SELECT DATE(@_regist_date_r3), @_drr3_regist_count, @_drr3_liucun_count, @_drr3_perct;
UPDATE KPI_STAT_DAILY_LIUCUN SET `drr3_perct` = @_drr3_perct WHERE `stat_date` = DATE(@_regist_date_r3);

#更新6天前
#SELECT DATE(@_regist_date_r7), @_drr7_regist_count, @_drr7_liucun_count, @_drr7_perct;
UPDATE KPI_STAT_DAILY_LIUCUN SET `drr7_perct` = @_drr7_perct WHERE `stat_date` = DATE(@_regist_date_r7);

#更新13天前
#SELECT DATE(@_regist_date_r14), @_drr14_regist_count, @_drr14_liucun_count, @_drr14_perct;
UPDATE KPI_STAT_DAILY_LIUCUN SET `drr14_perct` = @_drr14_perct WHERE `stat_date` = DATE(@_regist_date_r14);

#更新29天前
#SELECT DATE(@_regist_date_r30), @_drr30_regist_count, @_drr30_liucun_count, @_drr30_perct;
UPDATE KPI_STAT_DAILY_LIUCUN SET `drr30_perct` = @_drr30_perct WHERE  `stat_date` = DATE(@_regist_date_r30);

#结果输出
SET @_now_date = CAST(@_stat_date AS CHAR);
SELECT @_now_date, @_regist_count;
INSERT IGNORE INTO KPI_STAT_DAILY_LIUCUN (`stat_date`, `regist_count`) VALUES (@_now_date, @_regist_count)
	ON DUPLICATE KEY UPDATE `regist_count` = VALUES(`regist_count`);
	

DROP TEMPORARY TABLE IF EXISTS _tmp_t_user_days;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_user_login;

END
//	
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS proc_daily_stat_deposit //
CREATE PROCEDURE `proc_daily_stat_deposit`(IN _arg_date DATE)
    MODIFIES SQL DATA
_start_label:BEGIN
	#Routine body goes here...

SELECT DATE_FORMAT(_arg_date, '%Y') INTO @_date_year;
IF( @_date_year < 2014 ) 
THEN 
	SELECT "_arg_date not a valid date";
	LEAVE _start_label;
END IF;

SET @_stat_date = _arg_date;

#充值
DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;
CREATE TEMPORARY TABLE _tmp_t_deposit AS SELECT * FROM LOG_DEPOSIT WHERE DATE(`time_stamp`) = DATE(@_stat_date);

#分组
DROP TEMPORARY TABLE IF EXISTS _tmp_t_amount_group;
CREATE TEMPORARY TABLE _tmp_t_amount_group AS SELECT `amount`, COUNT(`uid`) AS times, COUNT(DISTINCT `uid`) AS nop, SUM(`amount`) AS total, DATE(@_stat_date) AS stat_date  
	FROM _tmp_t_deposit GROUP BY `amount` ORDER BY `amount` ASC;

#删除原有的
DELETE FROM KPI_STAT_DAILY_DEPOSIT WHERE `stat_date` = @_stat_date;

#插入新的
INSERT IGNORE INTO KPI_STAT_DAILY_DEPOSIT SELECT * FROM _tmp_t_amount_group;
#SELECT * FROM _tmp_t_amount_group;

DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_amount_group;

END
//	
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS proc_stat_kpi //
CREATE PROCEDURE `proc_stat_kpi`(IN _arg_stat_date DATE)
BEGIN
	#Routine body goes here...
	DECLARE _areaid VARCHAR(33);
	DECLARE _done INT DEFAULT 0;
	
	DECLARE _cursor_areaid CURSOR FOR SELECT DISTINCT(`areaid`) FROM SNAP_USER;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET _done = 1;

	SET @_stat_date = _arg_stat_date;

	OPEN _cursor_areaid;
do_area:REPEAT
		FETCH _cursor_areaid INTO _areaid;
		IF ( LENGTH(_areaid) <> 5 )
		THEN 
				ITERATE do_area;
		END IF;
		IF NOT _done THEN
			CALL proc_daily_stat_server(_areaid, @_stat_date);
			CALL proc_weekly_stat_server(_areaid, @_stat_date);
			CALL proc_monthly_stat_server(_areaid, @_stat_date);
		END IF;
	UNTIL _done END REPEAT;


END
//	
delimiter ;

delimiter //
DROP PROCEDURE IF EXISTS proc_stat_kpi_daily //
CREATE PROCEDURE `proc_stat_kpi_daily`(IN _arg_stat_date DATE)
BEGIN
	#Routine body goes here...
	DECLARE _areaid VARCHAR(33);
	DECLARE _done INT DEFAULT 0;
	
	DECLARE _cursor_areaid CURSOR FOR SELECT DISTINCT(`areaid`) FROM SNAP_USER;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET _done = 1;

	SET @_stat_date = _arg_stat_date;

	OPEN _cursor_areaid;
do_area:REPEAT
		FETCH _cursor_areaid INTO _areaid;
		IF ( LENGTH(_areaid) <> 5 )
		THEN 
				ITERATE do_area;
		END IF;
		IF NOT _done THEN
			CALL proc_daily_stat_server(_areaid, @_stat_date);
		END IF;
	UNTIL _done END REPEAT;


END
//	
delimiter ;



delimiter //
DROP PROCEDURE IF EXISTS proc_stat_caiwu_gold //
CREATE PROCEDURE `proc_stat_caiwu_gold`(IN _arg_areaid VARCHAR(33), IN _arg_roleid VARCHAR(33), IN _arg_from_date DATE, IN _arg_to_date DATE, IN _arg_start_row INT, IN _arg_count INT)
_start_label:BEGIN
	#Routine body goes here...
IF( LENGTH(_arg_areaid) <> 5 ) 
THEN 
	SELECT "_arg_areaid LENGTH NEED 5";
	LEAVE _start_label;
END IF;

DROP TEMPORARY TABLE IF EXISTS _t_temp_caiwu_gold;
CREATE TEMPORARY TABLE IF NOT EXISTS _t_temp_caiwu_gold AS
(SELECT `areaid`, `acc` as uid, func_get_roleid(`uid`) AS roleid, IF(`where`=50,1,2) as tag, `where` as remark, `num` as trans_qty, `real` as qty, `confirm`, `depleft` as `deposit_left`, `realleft` as `total_left`, `totalleft` as `cur_yb`, `ip`, `time_stamp` FROM LOG_GET_YB 
WHERE `real` > 0 AND `areaid` = _arg_areaid AND func_get_roleid(`uid`) LIKE _arg_roleid AND DATE(`time_stamp`) BETWEEN _arg_from_date AND _arg_to_date)
UNION
(SELECT `areaid`, `acc` as uid, func_get_roleid(`uid`) AS roleid, 3 as tag, `where` as remark, -`num` as trans_qty, -`real` as qty, `confirm`, `depleft` as `deposit_left`, `realleft` as `total_left`, `totalleft` as `cur_yb`, `ip`, `time_stamp` FROM LOG_CAST_YB 
WHERE `real` > 0 AND `areaid` = _arg_areaid AND func_get_roleid(`uid`) LIKE _arg_roleid AND DATE(`time_stamp`) BETWEEN _arg_from_date AND _arg_to_date)
ORDER BY `time_stamp` ASC;

#SELECT COUNT(*) INTO @totalCount FROM _t_temp_caiwu_gold;
SELECT COUNT(*) FROM _t_temp_caiwu_gold;
SET @startRow = _arg_start_row ;
SET @rowCount = _arg_count;
#SELECT @str FROM _t_temp_caiwu_gold;
PREPARE STMT1 FROM 'SELECT * FROM _t_temp_caiwu_gold LIMIT ?, ?';
EXECUTE STMT1 USING @startRow, @rowCount;

DEALLOCATE PREPARE STMT1;


#'00001', 'lm033', '2013-01-01', '2016-01-01', '1'
#SET @str = ' SELECT * FROM _t_temp_caiwu_gold';
#EXECUTE(@str);
#EXECUTE(' SELECT ' + _arg_select_cond + ' FROM _t_temp_caiwu_gold');

END
//	
delimiter ;

delimiter //
DROP PROCEDURE IF EXISTS proc_stat_hourly_deposit //
CREATE PROCEDURE `proc_stat_hourly_deposit`(IN _arg_begin_date DATE, IN _arg_end_date DATE, IN _arg_start_row INT, IN _arg_count INT)
    MODIFIES SQL DATA
_start_label:BEGIN
	#Routine body goes here...

SELECT DATE_FORMAT(_arg_begin_date , '%Y') INTO @_date_year;
IF( @_date_year < 2014 ) 
THEN 
	SELECT "_arg_begin_date not a valid date";
	LEAVE _start_label;
END IF;

SELECT DATE_FORMAT(_arg_end_date , '%Y') INTO @_date_year;
IF( @_date_year < 2014 ) 
THEN 
	SELECT "_arg_end_date not a valid date";
	LEAVE _start_label;
END IF;

#'2015-03-21','2015-03-24', 0, 4

SET @_begin_time = _arg_begin_date;
SET @_end_time = DATE_ADD(_arg_end_date, INTERVAL 1 DAY);

#SELECT TIMESTAMP(@_begin_time), TIMESTAMP(@_end_time);

#充值
DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;
CREATE TEMPORARY TABLE _tmp_t_deposit AS SELECT *, DATE_FORMAT((`time_stamp`), '%Y-%m-%d %H:00:00') AS 'date_hour' FROM LOG_DEPOSIT WHERE TIMESTAMP(`time_stamp`) BETWEEN @_begin_time AND @_end_time;

#SELECT * FROM _tmp_t_deposit;

#分组
DROP TEMPORARY TABLE IF EXISTS _tmp_t_hour_group;
CREATE TEMPORARY TABLE _tmp_t_hour_group AS SELECT `date_hour`, COUNT(`uid`) AS times, COUNT(DISTINCT `uid`) AS nop, SUM(`amount`) AS total
	FROM _tmp_t_deposit GROUP BY `date_hour` ORDER BY `date_hour` DESC;

#SELECT * FROM _tmp_t_hour_group;
SELECT COUNT(*) FROM _tmp_t_hour_group;

SET @_start_row = _arg_start_row ;
SET @_row_count = _arg_count;
#SELECT @str FROM _t_temp_caiwu_gold;
PREPARE STMT1 FROM 'SELECT * FROM _tmp_t_hour_group LIMIT ?, ?';
EXECUTE STMT1 USING @_start_row, @_row_count;

DEALLOCATE PREPARE STMT1;


DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_hour_group;

END
//	
delimiter ;

delimiter //
DROP PROCEDURE IF EXISTS proc_slim_data //
CREATE PROCEDURE `proc_slim_data`(IN _arg_end_day DATE)
    MODIFIES SQL DATA
    COMMENT 'slim db data'
BEGIN

	DELETE FROM LOG_CAST_ITEM WHERE `log_time` < _arg_end_day;
	DELETE FROM LOG_CAST_PHP WHERE `log_time` < _arg_end_day;
	DELETE FROM LOG_CAST_GD WHERE `log_time` < _arg_end_day;

	DELETE FROM LOG_GET_GD WHERE `log_time` < _arg_end_day;
	DELETE FROM LOG_GET_ITEM WHERE `log_time` < _arg_end_day;
	DELETE FROM LOG_GET_PHP WHERE `log_time` < _arg_end_day;

END
//	
delimiter ;

delimiter //
DROP PROCEDURE IF EXISTS proc_stat_cost_yb //
CREATE PROCEDURE `proc_stat_cost_yb`()
BEGIN
	#Routine body goes here...

	SET @stat_date = CURDATE();
	SET @max_vip = 10;

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
	SELECT a.*, c.nick, c.lv, c.viplv, c.vipscore, c.guide_step, b.maxgqid FROM _tmp_t_liushi_all AS a  JOIN _tmp_t_pve_pass_all AS b JOIN SNAP_USER as c ON a.uid = b.uid AND a.uid = c.uid;

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
	SELECT a.*, c.nick, c.lv, c.viplv, c.vipscore, c.guide_step, b.maxgqid FROM _tmp_t_liushi_all AS a  JOIN _tmp_t_pve_pass_all AS b JOIN SNAP_USER as c ON a.uid = b.uid AND a.uid = c.uid;

	SELECT * FROM TEMP_TABLE_STAT;
	
END
//
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS proc_stat_liushi_user_2 //
CREATE PROCEDURE `proc_stat_liushi_user_2`(IN _arg_areaid VARCHAR(33), IN _arg_nday INT)
_start_label:BEGIN
	

	DECLARE _stat_liushi_days INT DEFAULT _arg_nday;
	#DECLARE _arg_areaid VARCHAR(33) DEFAULT '00001';

	IF( LENGTH(_arg_areaid) <> 5 ) 
	THEN 
		SELECT "_arg_areaid LENGTH NEED 5";
		LEAVE _start_label;
	END IF;

	SET @_areaid = _arg_areaid;
	SET @_cur_date = CURDATE();
	SET @_regist_end_date = DATE_SUB(@_cur_date,INTERVAL _stat_liushi_days DAY);

	
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist_all;		
	CREATE TEMPORARY TABLE _tmp_t_regist_all AS SELECT DISTINCT(`uid`) as uid, DATE(`time_stamp`) as regist_date FROM LOG_REGIST HAVING regist_date <= DATE(@_regist_end_date);

	
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_login_all;		
	CREATE TEMPORARY TABLE _tmp_t_login_all AS SELECT `uid`, MAX(DATE(`time_stamp`)) as last_login_date FROM LOG_LOGIN GROUP BY `uid`;

	
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_liushi_all;		
	CREATE TEMPORARY TABLE _tmp_t_liushi_all AS SELECT DISTINCT(a.uid), a.regist_date, b.last_login_date, DATEDIFF(@_cur_date, b.last_login_date) AS days FROM _tmp_t_regist_all as a LEFT JOIN _tmp_t_login_all as b USING(uid);

	
	DROP TEMPORARY TABLE IF EXISTS _tmp_t_pve_pass_all;		
	CREATE TEMPORARY TABLE _tmp_t_pve_pass_all AS SELECT `uid`, MAX(`gqid`) AS maxgqid FROM LOG_PASS_GQ GROUP BY `uid`;

	
	
	
	DROP TABLE IF EXISTS TEMP_TABLE_STAT;
	CREATE TABLE TEMP_TABLE_STAT  AS 
	SELECT a.*, c.nick, c.lv, c.viplv, c.vipscore, c.guide_step, b.maxgqid FROM _tmp_t_liushi_all AS a  LEFT JOIN _tmp_t_pve_pass_all AS b ON a.uid = b.uid JOIN SNAP_USER as c ON a.uid = c.uid ORDER BY a.uid DESC;

	SELECT * FROM TEMP_TABLE_STAT;
	
END
//
delimiter ;


delimiter //
DROP PROCEDURE IF EXISTS proc_report_stat_server //
CREATE PROCEDURE `proc_report_stat_server`(IN _arg_areaid VARCHAR(33), IN _arg_date DATE)
    MODIFIES SQL DATA
_start_label:BEGIN
	#Routine body goes here...
IF( LENGTH(_arg_areaid) <> 5 ) 
THEN 
	SELECT "_arg_areaid LENGTH NEED 5";
	LEAVE _start_label;
END IF;

SELECT DATE_FORMAT(_arg_date, '%Y') INTO @_date_year;
IF( @_date_year < 2014 ) 
THEN 
	SELECT "_arg_date not a valid date";
	LEAVE _start_label;
END IF;

#'69001','2015-06-17'

SET @_areaid = _arg_areaid;
#SET @_stat_date = _arg_date;
SET @_stat_date = CURDATE();
#SET @_stat_date = DATE_SUB(CURDATE(),INTERVAL 1 DAY);
SET @_regist_date = @_stat_date;
SET @_login_date = @_stat_date;
SET @_yesterday = DATE_SUB(@_stat_date, INTERVAL 1 DAY);
SET @_deposit_date = @_regist_date;
SET @_online_date = @_stat_date;

#注册
DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist;
CREATE TEMPORARY TABLE _tmp_t_regist AS SELECT DISTINCT(uid) FROM LOG_REGIST WHERE DATE(`time_stamp`) = DATE(@_regist_date) and `areaid` = @_areaid;

#登录
DROP TEMPORARY TABLE IF EXISTS _tmp_t_login;
CREATE TEMPORARY TABLE _tmp_t_login AS SELECT DISTINCT(uid) FROM LOG_LOGIN WHERE DATE(`time_stamp`) = DATE(@_login_date) and `areaid` = @_areaid;

#充值
DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;
CREATE TEMPORARY TABLE _tmp_t_deposit AS SELECT * FROM LOG_DEPOSIT WHERE DATE(`time_stamp`) = DATE(@_deposit_date) and `areaid` = @_areaid;


#统计

#注册用户数，登录用户数，充值用户数
SELECT count(*) INTO @_regist_count FROM _tmp_t_regist;
SELECT count(*) INTO @_login_count FROM _tmp_t_login;
SELECT count(DISTINCT(uid)) INTO @_deposit_count FROM _tmp_t_deposit;

#活跃用户数
SELECT count(*) INTO @_active_count FROM (SELECT * FROM _tmp_t_login UNION DISTINCT SELECT * FROM _tmp_t_regist) as _LOGIN_AND_REGIST;

#当前在线人数
SELECT `olnum` INTO @_online_count FROM LOG_ONLINE WHERE DATE(`time_stamp`) = DATE(@_online_date) and `areaid` = @_areaid ORDER BY `sid` DESC LIMIT 1;

#收入
SELECT SUM(`amount`) INTO @_income_amount FROM _tmp_t_deposit;

#注册付费
SELECT COUNT(DISTINCT uid) INTO @_regist_deposit_count FROM (SELECT DISTINCT(uid) FROM _tmp_t_deposit ) AS A JOIN _tmp_t_regist AS B USING(uid);

#总注册
SELECT COUNT(DISTINCT uid) INTO @_regist_total_count FROM LOG_REGIST WHERE `areaid` = @_areaid;

#SELECT DATE(@_regist_date_r2), @_drr2_regist_count, @_drr2_count, @_drr2_perct;
SET @_ystd_regist_count = 0;
SET @_ystd_active_count = 0;
SET @_ystd_deposit_count = 0;
SET @_ystd_income_amount = 0;
SELECT `regist_count`, `active_count`, `deposit_count`, `income_amount` INTO @_ystd_regist_count, @_ystd_active_count, @_ystd_deposit_count, @_ystd_income_amount FROM KPI_STAT_DAILY WHERE `areaid` = @_areaid AND `stat_date` = @_yesterday;


#查看中间变量
#SELECT @_regist_count, @_active_count, @_deposit_count, @_regist_deposit_count, @_income_amount, @_regist_total_count, @_online_count, @_ystd_regist_count, @_ystd_active_count, @_ystd_deposit_count, @_ystd_income_amount;

#计算

#格式化

#结果输出
SET @_now_time = CONCAT(@_stat_date,' ',CURRENT_TIME());
SELECT @_areaid as server_id, @_now_time as stat_time, @_regist_count as regist_count, @_active_count as active_count,
	@_deposit_count as deposit_count, @_regist_deposit_count as regist_deposit_count, @_regist_total_count as regist_total_count,
	@_income_amount as income_amount,@_online_count as online_count, @_ystd_regist_count as ystd_regist_count, 
	@_ystd_active_count as ystd_active_count, @_ystd_deposit_count as ystd_deposit_count, @_ystd_income_amount as ystd_income_amount;


DROP TEMPORARY TABLE IF EXISTS _tmp_t_regist;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_login;
DROP TEMPORARY TABLE IF EXISTS _tmp_t_deposit;


END
//	
delimiter ;

delimiter //
DROP PROCEDURE IF EXISTS proc_stat_kpi_yesterday //
CREATE PROCEDURE `proc_stat_kpi_yesterday`()
BEGIN
	#Routine body goes here...
	SET @__date = DATE_SUB(CURDATE(), INTERVAL 1 DAY);
	CALL proc_stat_kpi(@__date);
	CALL proc_daily_stat_liucun(@__date);
	CALL proc_daily_stat_deposit(@__date);
END
//	
delimiter ;

delimiter //
DROP EVENT IF EXISTS `event_kpi_stat_daily`//
CREATE EVENT IF NOT EXISTS `event_kpi_stat_daily` ON SCHEDULE EVERY 1 DAY STARTS '2015-01-13 00:05:00' ON COMPLETION PRESERVE ENABLE DO CALL proc_auto_stat_kpi
//	
delimiter ;

delimiter //
DROP EVENT IF EXISTS `event_kpi_stat_today`//
CREATE EVENT IF NOT EXISTS `event_kpi_stat_today` ON SCHEDULE EVERY 10 MINUTE STARTS '2015-01-13 00:10:00' ON COMPLETION PRESERVE ENABLE DO CALL proc_stat_kpi_today
//	
delimiter ;

