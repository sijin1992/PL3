USE db_star_log;

ALTER TABLE KPI_STAT_DAILY ADD COLUMN `rookie_count` INT DEFAULT NULL COMMENT '日导入' AFTER `regist_count`;

