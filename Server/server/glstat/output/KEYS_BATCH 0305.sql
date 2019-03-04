/*
Navicat MySQL Data Transfer

Source Server         : gl_24
Source Server Version : 50136
Source Host           : 10.10.1.24:3306
Source Database       : db_gl_cdkey

Target Server Type    : MYSQL
Target Server Version : 50136
File Encoding         : 65001

Date: 2015-02-28 13:20:58
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `KEYS_BATCH`
-- ----------------------------
DROP TABLE IF EXISTS `KEYS_BATCH`;
CREATE TABLE `KEYS_BATCH` (
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

-- ----------------------------
-- Records of KEYS_BATCH
-- ----------------------------
INSERT INTO `KEYS_BATCH` VALUES ('1', '1', '1', '1', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('2', '1', '1', '2', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('3', '1', '1', '3', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('4', '1', '1', '4', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('5', '1', '1', '5', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('6', '1', '1', '6', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('7', '1', '1', '7', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('8', '1', '1', '8', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('9', '1', '1', '9', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('10', '1', '1', '10', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('11', '1', '1', '11', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('12', '1', '1', '12', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('13', '1', '1', '13', '2015-02-27', '100000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('14', '1', '1', '14', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('15', '1', '1', '15', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('16', '1', '1', '16', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('17', '1', '1', '17', '2015-02-27', '50000', null, null, null, null);
INSERT INTO `KEYS_BATCH` VALUES ('18', '1', '1', '18', '2015-02-27', '600', null, null, null, null);
