<?php
/*��Ϸ��־��*/
/*���幱�׻��(�û�ID��������������������ʣ�๱��)*/
$_LOG_TABLE_COLS['LOG_GET_JZGX'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_JZGX'] = array('uid' => '�û�ID', 'where' => '�������', 'num' => '�������', 'left' => 'ʣ�๱��');

/*���ɿ���(����ID�����ƣ��ȼ�����������ѧ������ʱ��)*/
$_LOG_TABLE_COLS['SNAP_MENPAI'] = '`mpid`, `name`, `level`, `gold`, `jx`, `ct`, `time_stamp`';
$_LOG_TABLE_COLS_DES['SNAP_MENPAI'] = array('mpid' => '����ID', 'name' => '����', 'level' => '�ȼ�', 'gold' => '����', 'jx' => '��ѧ', 'ct' => '����ʱ��');

/*��������(�û�ID����������������������֮ǰ�ȼ���֮��ȼ���ʣ������)*/
$_LOG_TABLE_COLS['LOG_CAST_PHP'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `levelbefore`, `levelafter`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_CAST_PHP'] = array('uid' => '�û�ID', 'where' => '��������', 'num' => '��������', 'levelbefore' => '֮ǰ�ȼ�', 'levelafter' => '֮��ȼ�', 'left' => 'ʣ������');

/*��������(�û�ID����������������ID������������ʣ������)*/
$_LOG_TABLE_COLS['LOG_CAST_ITEM'] = 'func_get_roleid(`uid`) as uid, `where`, `itemid`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_CAST_ITEM'] = array('uid' => '�û�ID', 'where' => '��������', 'itemid' => '����ID', 'num' => '��������', 'left' => 'ʣ������');

/*��¼(�û�ID��IP��ַ�� MCC�ƶ��豸�����룬�ȼ����˺ţ�����)*/
$_LOG_TABLE_COLS['LOG_LOGIN'] = 'func_get_roleid(`uid`) as uid, `ip`, `mmc`, `level`, `acc`, `qd`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_LOGIN'] = array('uid' => '�û�ID', 'ip' => 'IP��ַ', 'mmc' => 'MCC�ƶ��豸������', 'level' => '�ȼ�', 'acc' => '�˺�', 'qd' => '����');

/*���߻��(�û�ID���������������ID�����������ʣ������)*/
$_LOG_TABLE_COLS['LOG_GET_ITEM'] = 'func_get_roleid(`uid`) as uid, `where`, `itemid`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_ITEM'] = array('uid' => '�û�ID', 'where' => '�������', 'itemid' => '����ID', 'num' => '�������', 'left' => 'ʣ������');

/*�豸(�û�ID���ն˻��ͣ��豸�ֱ��ʣ����ò���ϵͳ��������Ӫ�̣�������ʽ)*/
$_LOG_TABLE_COLS['LOG_DEVICE'] = 'func_get_roleid(`uid`) as uid, `stype`, `res`, `os`, `oper`, `cntype`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_DEVICE'] = array('uid' => '�û�ID', 'stype' => '�ն˻���', 'res' => '�豸�ֱ���', 'os' => '���ò���ϵͳ', 'oper' => '������Ӫ��', 'cntype' => '������ʽ');

/*����ͳ��(��������������ID)*/
$_LOG_TABLE_COLS['LOG_ONLINE'] = '`olnum`, `areaid`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_ONLINE'] = array('olnum' => '��������', 'areaid' => '����ID');

/*ͨ�عؿ�(�û�ID��ͨ���ؿ�ID)*/
$_LOG_TABLE_COLS['LOG_PASS_GQ'] = 'func_get_roleid(`uid`) as uid, `gqid`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_PASS_GQ'] = array('uid' => '�û�ID', 'gqid' => 'ͨ���ؿ�ID');

/*���ƻ��(�û�ID���������������ID���������)*/
$_LOG_TABLE_COLS['LOG_GET_CARD'] = 'func_get_roleid(`uid`) as uid, `where`, `carid`, `num`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_CARD'] = array('uid' => '�û�ID', 'where' => '�������', 'carid' => '����ID', 'num' => '�������');

/*��������(�û�ID������ID)*/
$_LOG_TABLE_COLS['LOG_GUIDE'] = 'func_get_roleid(`uid`) as uid, `gid`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GUIDE'] = array('uid' => '�û�ID', 'gid' => '����ID');

/*����(�û�ID��֮ǰ�ȼ���֮��ȼ���*/
$_LOG_TABLE_COLS['LOG_LEVEL_UP'] = 'func_get_roleid(`uid`) as uid, `levelbefore`, `levelafter`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_LEVEL_UP'] = array('uid' => '', 'levelbefore' => '', 'levelafter' => '');

/*��������(�û�ID����������������������ʣ������)*/
$_LOG_TABLE_COLS['LOG_CAST_GD'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_CAST_GD'] = array('uid' => '�û�ID', 'where' => '��������', 'num' => '��������', 'left' => 'ʣ������');

/*����ʹ��(�û�ID������ID)*/
$_LOG_TABLE_COLS['LOG_USE_GN'] = 'func_get_roleid(`uid`) as uid, `gnid`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_USE_GN'] = array('uid' => '�û�ID', 'gnid' => '����ID');

/*����(�û�ID������ʱ��(��)���˺�)*/
$_LOG_TABLE_COLS['LOG_LOGOUT'] = 'func_get_roleid(`uid`) as uid, `oltime`, `acc`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_LOGOUT'] = array('uid' => '��)', 'oltime' => '�˺�', 'acc' => '');

/*��ҿ���(�û�ID���ǳƣ��������ȼ�����Ҿ��飬VIP�ȼ���VIP���飬�ۼƳ�ֵ���ۼƸ��ѣ����ң�Ԫ�������������ս��������ɫ״̬�����׵ȼ������RANK����������)*/
$_LOG_TABLE_COLS['SNAP_USER'] = 'func_get_roleid(`uid`) as uid, `nick`, `qd`, `lv`, `exp`, `viplv`, `vipscore`, `totaldep`, `totalrmb`, `gold`, `money`, `php`, `maxpower`, `state`, `stagelv`, `maxrank`, `menpai`, `acc`, `ip`, `mmc`, `regist_time`, `last_login_time`, `last_logout_time`, `time_stamp`';
$_LOG_TABLE_COLS_DES['SNAP_USER'] = array('uid' => '�û�ID', 'nick' => '�ǳ�', 'qd' => '����', 'lv' => '�ȼ�', 'exp' => '��Ҿ���', 'viplv' => 'VIP�ȼ�', 'vipscore' => 'VIP����', 'totaldep' => '�ۼƳ�ֵ', 'totalrmb' => '�ۼƸ���', 'gold' => '����', 'money' => 'Ԫ��', 'php' => '����', 'maxpower' => '���ս����', 'state' => '��ɫ״̬', 'stagelv' => '���׵ȼ�', 'maxrank' => '���RANK', 'menpai' => '��������');

/*Ԫ������(�û�ID������������������������Ԫ����������ȷ�Ͻ������ֵԪ����ʣ������Ԫ����ʣ����Ԫ�����˺ţ�IP��MMC)*/
$_LOG_TABLE_COLS['LOG_CAST_YB'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `totalleft`, `acc`, `ip`, `mmc`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_CAST_YB'] = array('uid' => '�û�ID', 'where' => '��������', 'num' => '��������', 'totalleft' => 'ʣ����Ԫ��', 'acc' => '�˺�', 'ip' => 'IP', 'mmc' => 'MMC');

/*��ֵ(�û�ID����ֵ��֧����ʽ���Ƿ��׳䣬vip�ȼ���vip���֣�����)*/
$_LOG_TABLE_COLS['LOG_DEPOSIT'] = 'func_get_roleid(`uid`) as uid, `amount`, `paytype`, `isfirst`, `viplevel`, `vipscore`, `qd`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_DEPOSIT'] = array('uid' => '�û�ID', 'amount' => '��ֵ���', 'paytype' => '֧����ʽ', 'isfirst' => '�Ƿ��׳�', 'viplevel' => 'vip�ȼ�', 'vipscore' => 'vip����', 'qd' => '����');

/*�������(�û�ID��������������������ʣ������)*/
$_LOG_TABLE_COLS['LOG_GET_GD'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_GD'] = array('uid' => '�û�ID', 'where' => '�������', 'num' => '�������', 'left' => 'ʣ������');

/*��������(�û�ID��������������꣬�������������ɽ���)*/
$_LOG_TABLE_COLS['SNAP_BAG'] = 'func_get_roleid(`uid`) as uid, `kxl`, `lwl`, `wh`, `mpww`, `mpjz`, `time_stamp`';
$_LOG_TABLE_COLS_DES['SNAP_BAG'] = array('uid' => '�û�ID', 'kxl' => '������', 'lwl' => '������', 'wh' => '���', 'mpww' => '��������', 'mpjz' => '���ɽ���');

/*Ԫ�����(�û�ID����������������������Ԫ����������ȷ�Ͻ������ֵԪ����ʣ������Ԫ����ʣ����Ԫ�����˺ţ�IP��MMC)*/
$_LOG_TABLE_COLS['LOG_GET_YB'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `totalleft`, `acc`, `ip`, `mmc`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_YB'] = array('uid' => '�û�ID', 'where' => '�������', 'num' => '�������', 'totalleft' => 'ʣ����Ԫ��', 'acc' => '�˺�', 'ip' => 'IP', 'mmc' => 'MMC');

/*��������(�û�ID��ͨ������)*/
$_LOG_TABLE_COLS['LOG_PASS_WL'] = 'func_get_roleid(`uid`) as uid, `layer`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_PASS_WL'] = array('uid' => '�û�ID', 'layer' => 'ͨ������');

/*ע��(�û�ID��IP��ַ�� MCC�ƶ��豸�����룬�˺ţ��ǳƣ��ȼ�������)*/
$_LOG_TABLE_COLS['LOG_REGIST'] = 'func_get_roleid(`uid`) as uid, `ip`, `mmc`, `acc`, `nick`, `lv`, `qd`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_REGIST'] = array('uid' => '�û�ID', 'ip' => 'IP��ַ', 'mmc' => 'MCC�ƶ��豸������', 'acc' => '�˺�', 'nick' => '�ǳ�', 'lv' => '�ȼ�', 'qd' => '����');

/*���ͻ�ȡ(�û�ID���������������Ŀ���ID������������ʣ������)*/
$_LOG_TABLE_COLS['LOG_GET_XK'] = 'func_get_roleid(`uid`) as uid, `where`, `cardid`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_XK'] = array('uid' => '�û�ID', 'where' => '��������', 'cardid' => '���Ŀ���ID', 'num' => '��������', 'left' => 'ʣ������');

/*ʹ��CDKEY(�û�ID��CDKEY)*/
$_LOG_TABLE_COLS['LOG_USE_CDKEY'] = 'func_get_roleid(`uid`) as uid, `cdkey`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_USE_CDKEY'] = array('uid' => '�û�ID', 'cdkey' => 'CDKEY');

/*�������(�û�ID��������������������ʣ������)*/
$_LOG_TABLE_COLS['LOG_GET_PHP'] = 'func_get_roleid(`uid`) as uid, `where`, `num`, `left`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_GET_PHP'] = array('uid' => '�û�ID', 'where' => '�������', 'num' => '�������', 'left' => 'ʣ������');

/*���ȡ(�û�ID���ID)*/
$_LOG_TABLE_COLS['LOG_ACT_REWARD'] = 'func_get_roleid(`uid`) as uid, `actid`, `time_stamp`';
$_LOG_TABLE_COLS_DES['LOG_ACT_REWARD'] = array('uid' => '�û�ID', 'actid' => '�ID');

