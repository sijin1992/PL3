<?php
/*游戏日志表集*/
/*家族贡献获得(用户ID，获得渠道，获得数量，剩余贡献)*/
$_LOG_TABLE_COLS['LOG_GET_JZGX'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_JZGX'] = array('uid' => '用户ID', 'where' => '获得渠道', 'num' => '获得数量', 'left' => '剩余贡献');

/*门派快照(门派ID，名称，等级，库银，绝学，创建时间)*/
$_LOG_TABLE_COLS['SNAP_MENPAI'] = '`mpid`, `name`, `level`, `gold`, `jx`, `ct`, `time_stamp`';
$_LOG_TABLE_COLS_DES['SNAP_MENPAI'] = array('mpid' => '门派ID', 'name' => '名称', 'level' => '等级', 'gold' => '库银', 'jx' => '绝学', 'ct' => '创建时间');

/*体力消耗(用户ID，消耗渠道，消耗数量，之前等级，之后等级，剩余体力)*/
$_LOG_TABLE_COLS['LOG_CAST_PHP'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `levelbefore`, `levelafter`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_CAST_PHP'] = array('uid' => '用户ID', 'where' => '消耗渠道', 'num' => '消耗数量', 'levelbefore' => '之前等级', 'levelafter' => '之后等级', 'left' => '剩余体力');

/*道具消耗(用户ID，消耗渠道，道具ID，消耗数量，剩余数量)*/
$_LOG_TABLE_COLS['LOG_CAST_ITEM'] = 'func_get_roleid(`uid`) as uid, `where`, `itemid`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_CAST_ITEM'] = array('uid' => '用户ID', 'where' => '消耗渠道', 'itemid' => '道具ID', 'num' => '消耗数量', 'left' => '剩余数量');

/*登录(用户ID，IP地址， MCC移动设备国家码，等级，账号，渠道)*/
$_LOG_TABLE_COLS['LOG_LOGIN'] = 'func_get_roleid(`uid`) as uid, `ip`, `mmc`, `level`, `acc`, `qd`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_LOGIN'] = array('uid' => '用户ID', 'ip' => 'IP地址', 'mmc' => 'MCC移动设备国家码', 'level' => '等级', 'acc' => '账号', 'qd' => '渠道');

/*道具获得(用户ID，获得渠道，道具ID，获得数量，剩余数量)*/
$_LOG_TABLE_COLS['LOG_GET_ITEM'] = 'func_get_roleid(`uid`) as uid, `where`, `itemid`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_ITEM'] = array('uid' => '用户ID', 'where' => '获得渠道', 'itemid' => '道具ID', 'num' => '获得数量', 'left' => '剩余数量');

/*设备(用户ID，终端机型，设备分辨率，所用操作系统，所用运营商，联网方式)*/
$_LOG_TABLE_COLS['LOG_DEVICE'] = 'func_get_roleid(`uid`) as uid, `stype`, `res`, `os`, `oper`, `cntype`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_DEVICE'] = array('uid' => '用户ID', 'stype' => '终端机型', 'res' => '设备分辨率', 'os' => '所用操作系统', 'oper' => '所用运营商', 'cntype' => '联网方式');

/*在线统计(在线人数，区服ID)*/
$_LOG_TABLE_COLS['LOG_ONLINE'] = '`olnum`, `areaid`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_ONLINE'] = array('olnum' => '在线人数', 'areaid' => '区服ID');

/*通关关卡(用户ID，通过关卡ID)*/
$_LOG_TABLE_COLS['LOG_PASS_GQ'] = 'func_get_roleid(`uid`) as uid, `gqid`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_PASS_GQ'] = array('uid' => '用户ID', 'gqid' => '通过关卡ID');

/*卡牌获得(用户ID，获得渠道，卡牌ID，获得数量)*/
$_LOG_TABLE_COLS['LOG_GET_CARD'] = 'func_get_roleid(`uid`) as uid, `where`, `carid`, `num`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_CARD'] = array('uid' => '用户ID', 'where' => '获得渠道', 'carid' => '卡牌ID', 'num' => '获得数量');

/*新手引导(用户ID，引导ID)*/
$_LOG_TABLE_COLS['LOG_GUIDE'] = 'func_get_roleid(`uid`) as uid, `gid`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GUIDE'] = array('uid' => '用户ID', 'gid' => '引导ID');

/*升级(用户ID，之前等级，之后等级）*/
$_LOG_TABLE_COLS['LOG_LEVEL_UP'] = 'func_get_roleid(`uid`) as uid, `levelbefore`, `levelafter`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_LEVEL_UP'] = array('uid' => '', 'levelbefore' => '', 'levelafter' => '');

/*银两消耗(用户ID，消耗渠道，消耗数量，剩余数量)*/
$_LOG_TABLE_COLS['LOG_CAST_GD'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_CAST_GD'] = array('uid' => '用户ID', 'where' => '消耗渠道', 'num' => '消耗数量', 'left' => '剩余数量');

/*功能使用(用户ID，功能ID)*/
$_LOG_TABLE_COLS['LOG_USE_GN'] = 'func_get_roleid(`uid`) as uid, `gnid`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_USE_GN'] = array('uid' => '用户ID', 'gnid' => '功能ID');

/*离线(用户ID，在线时间(秒)，账号)*/
$_LOG_TABLE_COLS['LOG_LOGOUT'] = 'func_get_roleid(`uid`) as uid, `oltime`, `acc`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_LOGOUT'] = array('uid' => '秒)', 'oltime' => '账号', 'acc' => '');

/*玩家快照(用户ID，昵称，渠道，等级，玩家经验，VIP等级，VIP经验，累计充值，累计付费，银币，元宝，体力，最大战斗力，角色状态，进阶等级，最高RANK，所属门派)*/
$_LOG_TABLE_COLS['SNAP_USER'] = 'func_get_roleid(`uid`) as uid, `nick`, `qd`, `lv`, `exp`, `viplv`, `vipscore`, `totaldep`, `totalrmb`, `gold`, `money`, `php`, `maxpower`, `state`, `stagelv`, `maxrank`, `menpai`, `acc`, `ip`, `mmc`, `regist_time`, `last_login_time`, `last_logout_time`, `time_stamp`';
$_LOG_TABLE_COLS_DES['SNAP_USER'] = array('uid' => '用户ID', 'nick' => '昵称', 'qd' => '渠道', 'lv' => '等级', 'exp' => '玩家经验', 'viplv' => 'VIP等级', 'vipscore' => 'VIP经验', 'totaldep' => '累计充值', 'totalrmb' => '累计付费', 'gold' => '银币', 'money' => '元宝', 'php' => '体力', 'maxpower' => '最大战斗力', 'state' => '角色状态', 'stagelv' => '进阶等级', 'maxrank' => '最高RANK', 'menpai' => '所属门派');

/*元宝消耗(用户ID，消耗渠道，消耗数量，真元宝数，财务确认金额，留存充值元宝，剩余总真元宝，剩余总元宝，账号，IP，MMC)*/
$_LOG_TABLE_COLS['LOG_CAST_YB'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `totalleft`, `acc`, `ip`, `mmc`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_CAST_YB'] = array('uid' => '用户ID', 'where' => '消耗渠道', 'num' => '消耗数量', 'totalleft' => '剩余总元宝', 'acc' => '账号', 'ip' => 'IP', 'mmc' => 'MMC');

/*充值(用户ID，充值金额，支付方式，是否首充，vip等级，vip积分，渠道)*/
$_LOG_TABLE_COLS['LOG_DEPOSIT'] = 'func_get_roleid(`uid`) as uid, `amount`, `paytype`, `isfirst`, `viplevel`, `vipscore`, `qd`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_DEPOSIT'] = array('uid' => '用户ID', 'amount' => '充值金额', 'paytype' => '支付方式', 'isfirst' => '是否首充', 'viplevel' => 'vip等级', 'vipscore' => 'vip积分', 'qd' => '渠道');

/*银两获得(用户ID，获得渠道，获得数量，剩余银两)*/
$_LOG_TABLE_COLS['LOG_GET_GD'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_GD'] = array('uid' => '用户ID', 'where' => '获得渠道', 'num' => '获得数量', 'left' => '剩余银两');

/*背包快照(用户ID，凯旋令，龙纹令，武魂，门派威望，门派奖章)*/
$_LOG_TABLE_COLS['SNAP_BAG'] = 'func_get_roleid(`uid`) as uid, `kxl`, `lwl`, `wh`, `mpww`, `mpjz`, `time_stamp`';
$_LOG_TABLE_COLS_DES['SNAP_BAG'] = array('uid' => '用户ID', 'kxl' => '凯旋令', 'lwl' => '龙纹令', 'wh' => '武魂', 'mpww' => '门派威望', 'mpjz' => '门派奖章');

/*元宝获得(用户ID，获得渠道，获得数量，真元宝数，财务确认金额，留存充值元宝，剩余总真元宝，剩余总元宝，账号，IP，MMC)*/
$_LOG_TABLE_COLS['LOG_GET_YB'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `totalleft`, `acc`, `ip`, `mmc`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_YB'] = array('uid' => '用户ID', 'where' => '获得渠道', 'num' => '获得数量', 'totalleft' => '剩余总元宝', 'acc' => '账号', 'ip' => 'IP', 'mmc' => 'MMC');

/*爬塔过关(用户ID，通过层数)*/
$_LOG_TABLE_COLS['LOG_PASS_WL'] = 'func_get_roleid(`uid`) as uid, `layer`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_PASS_WL'] = array('uid' => '用户ID', 'layer' => '通过层数');

/*注册(用户ID，IP地址， MCC移动设备国家码，账号，昵称，等级，渠道)*/
$_LOG_TABLE_COLS['LOG_REGIST'] = 'func_get_roleid(`uid`) as uid, `ip`, `mmc`, `acc`, `nick`, `lv`, `qd`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_REGIST'] = array('uid' => '用户ID', 'ip' => 'IP地址', 'mmc' => 'MCC移动设备国家码', 'acc' => '账号', 'nick' => '昵称', 'lv' => '等级', 'qd' => '渠道');

/*侠客获取(用户ID，消耗渠道，消耗卡牌ID，消耗数量，剩余数量)*/
$_LOG_TABLE_COLS['LOG_GET_XK'] = 'func_get_roleid(`uid`) as uid, `where`, `cardid`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_XK'] = array('uid' => '用户ID', 'where' => '消耗渠道', 'cardid' => '消耗卡牌ID', 'num' => '消耗数量', 'left' => '剩余数量');

/*使用CDKEY(用户ID，CDKEY)*/
$_LOG_TABLE_COLS['LOG_USE_CDKEY'] = 'func_get_roleid(`uid`) as uid, `cdkey`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_USE_CDKEY'] = array('uid' => '用户ID', 'cdkey' => 'CDKEY');

/*体力获得(用户ID，获得渠道，获得数量，剩余体力)*/
$_LOG_TABLE_COLS['LOG_GET_PHP'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_PHP'] = array('uid' => '用户ID', 'where' => '获得渠道', 'num' => '获得数量', 'left' => '剩余体力');

/*活动领取(用户ID，活动ID)*/
$_LOG_TABLE_COLS['LOG_ACT_REWARD'] = 'func_get_roleid(`uid`) as uid, `actid`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_ACT_REWARD'] = array('uid' => '用户ID', 'actid' => '活动ID');

