USE db_star_log;

ALTER TABLE T_SERVER 
ADD COLUMN `server_options` text COMMENT '服务器选项' AFTER `db_name`,
ADD COLUMN `link` tinyint(4) DEFAULT '0' COMMENT '连接类型，=1表示软连接' AFTER `server_options`,
ADD COLUMN `real_site` int(11) DEFAULT '0' COMMENT '链接的大区' AFTER `link`;

