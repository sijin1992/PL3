int StringHelper::toSql(const StringVector &vec, char *buff, unsigned &size)
{
	memset(buff, 0, size);
	if( vec.size() < 4 )
	{
		return -1;
	}
	std::string statType = vec[4];

	if (statType == STAT_GET_JZGX ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_GET_JZGX (`time_stamp`, `areaid`, `uid`, `where`, `num`, `left`) VALUES ('%s', '%s', '%s', %s, %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8));
	}
	else if (statType == STAT_MENPAI ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO SNAP_MENPAI (`time_stamp`, `areaid`, `mpid`, `name`, `level`, `gold`, `jx`, `ct`) VALUES ('%s', '%s', '%s', '%s', %s, %s, %s, %s) ON DUPLICATE KEY UPDATE `time_stamp` = VALUES(`time_stamp`), `areaid` = VALUES(`areaid`), `mpid` = VALUES(`mpid`), `name` = VALUES(`name`), `level` = VALUES(`level`), `gold` = VALUES(`gold`), `jx` = VALUES(`jx`), `ct` = VALUES(`ct`)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9), str(vec, 10));
	}
	else if (statType == STAT_CAST_PHP ) 
	{
		return -1;
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_CAST_PHP (`time_stamp`, `areaid`, `uid`, `where`, `num`, `levelbefore`, `levelafter`, `left`) VALUES ('%s', '%s', '%s', %s, %s, %s, %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9), str(vec, 10));
	}
	else if (statType == STAT_CAST_ITEM ) 
	{
		return -1;
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_CAST_ITEM (`time_stamp`, `areaid`, `uid`, `where`, `itemid`, `num`, `left`) VALUES ('%s', '%s', '%s', %s, %s, %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9));
	}
	else if (statType == STAT_LOGIN ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_LOGIN (`time_stamp`, `areaid`, `uid`, `ip`, `mmc`, `level`, `acc`, `qd`) VALUES ('%s', '%s', '%s', '%s', '%s', %s, '%s', %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9), str(vec, 10));
	}
	else if (statType == STAT_GET_ITEM ) 
	{
		return -1;
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_GET_ITEM (`time_stamp`, `areaid`, `uid`, `where`, `itemid`, `num`, `left`) VALUES ('%s', '%s', '%s', %s, %s, %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9));
	}
	else if (statType == STAT_DEVICE ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_DEVICE (`time_stamp`, `areaid`, `uid`, `stype`, `res`, `os`, `oper`, `cntype`) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9), str(vec, 10));
	}
	else if (statType == STAT_ONLINE ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_ONLINE (`time_stamp`, `olnum`, `areaid`) VALUES ('%s', %s, '%s')",
			getStamp(vec[0]), str(vec, 6), str(vec, 7));
	}
	else if (statType == STAT_PASS_GQ ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_PASS_GQ (`time_stamp`, `areaid`, `uid`, `gqid`) VALUES ('%s', '%s', '%s', %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6));
	}
	else if (statType == STAT_GET_CARD ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_GET_CARD (`time_stamp`, `areaid`, `uid`, `where`, `carid`, `num`) VALUES ('%s', '%s', '%s', %s, %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8));
	}
	else if (statType == STAT_GUIDE ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_GUIDE (`time_stamp`, `areaid`, `uid`, `gid`) VALUES ('%s', '%s', '%s', %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6));
	}
	else if (statType == STAT_LEVEL_UP ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_LEVEL_UP (`time_stamp`, `areaid`, `uid`, `levelbefore`, `levelafter`) VALUES ('%s', '%s', '%s', %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7));
	}
	else if (statType == STAT_CAST_GD ) 
	{
		return -1;
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_CAST_GD (`time_stamp`, `areaid`, `uid`, `where`, `num`, `left`) VALUES ('%s', '%s', '%s', %s, %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8));
	}
	else if (statType == STAT_USE_GN ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_USE_GN (`time_stamp`, `areaid`, `uid`, `gnid`) VALUES ('%s', '%s', '%s', %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6));
	}
	else if (statType == STAT_LOGOUT ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_LOGOUT (`time_stamp`, `areaid`, `uid`, `oltime`, `acc`) VALUES ('%s', '%s', '%s', %s, '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7));
	}
	else if (statType == STAT_USER ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO SNAP_USER (`time_stamp`, `areaid`, `uid`, `nick`, `qd`, `lv`, `exp`, `viplv`, `vipscore`, `totaldep`, `totalrmb`, `gold`, `money`, `php`, `maxpower`, `state`, `stagelv`, `maxrank`, `menpai`) VALUES ('%s', '%s', '%s', '%s', '%s', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, '%s') ON DUPLICATE KEY UPDATE `time_stamp` = VALUES(`time_stamp`), `areaid` = VALUES(`areaid`), `uid` = VALUES(`uid`), `nick` = VALUES(`nick`), `qd` = VALUES(`qd`), `lv` = VALUES(`lv`), `exp` = VALUES(`exp`), `viplv` = VALUES(`viplv`), `vipscore` = VALUES(`vipscore`), `totaldep` = VALUES(`totaldep`), `totalrmb` = VALUES(`totalrmb`), `gold` = VALUES(`gold`), `money` = VALUES(`money`), `php` = VALUES(`php`), `maxpower` = VALUES(`maxpower`), `state` = VALUES(`state`), `stagelv` = VALUES(`stagelv`), `maxrank` = VALUES(`maxrank`), `menpai` = VALUES(`menpai`)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9), str(vec, 10), str(vec, 11), str(vec, 12), str(vec, 13), str(vec, 14), str(vec, 15), str(vec, 16), str(vec, 17), str(vec, 18), str(vec, 19), str(vec, 20), str(vec, 21));
	}
	else if (statType == STAT_CAST_YB ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_CAST_YB (`time_stamp`, `areaid`, `uid`, `where`, `num`, `real`, `confirm`, `depleft`, `realleft`, `totalleft`, `acc`, `ip`, `mmc`) VALUES ('%s', '%s', '%s', %s, %s, %s, %s, %s, %s, %s, '%s', '%s', '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9), str(vec, 10), str(vec, 11), str(vec, 12), str(vec, 13), str(vec, 14), str(vec, 15));
	}
	else if (statType == STAT_DEPOSIT ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_DEPOSIT (`time_stamp`, `areaid`, `uid`, `amount`, `paytype`, `isfirst`, `viplevel`, `vipscore`, `qd`) VALUES ('%s', '%s', '%s', %s, %s, %s, %s, %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9), str(vec, 10), str(vec, 11));
	}
	else if (statType == STAT_GET_GD ) 
	{
		return -1;
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_GET_GD (`time_stamp`, `areaid`, `uid`, `where`, `num`, `left`) VALUES ('%s', '%s', '%s', %s, %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8));
	}
	else if (statType == STAT_BAG ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO SNAP_BAG (`time_stamp`, `areaid`, `uid`, `kxl`, `lwl`, `wh`, `mpww`, `mpjz`) VALUES ('%s', '%s', '%s', %s, %s, %s, %s, %s) ON DUPLICATE KEY UPDATE `time_stamp` = VALUES(`time_stamp`), `areaid` = VALUES(`areaid`), `uid` = VALUES(`uid`), `kxl` = VALUES(`kxl`), `lwl` = VALUES(`lwl`), `wh` = VALUES(`wh`), `mpww` = VALUES(`mpww`), `mpjz` = VALUES(`mpjz`)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9), str(vec, 10));
	}
	else if (statType == STAT_GET_YB ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_GET_YB (`time_stamp`, `areaid`, `uid`, `where`, `num`, `real`, `confirm`, `depleft`, `realleft`, `totalleft`, `acc`, `ip`, `mmc`) VALUES ('%s', '%s', '%s', %s, %s, %s, %s, %s, %s, %s, '%s', '%s', '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9), str(vec, 10), str(vec, 11), str(vec, 12), str(vec, 13), str(vec, 14), str(vec, 15));
	}
	else if (statType == STAT_PASS_WL ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_PASS_WL (`time_stamp`, `areaid`, `uid`, `layer`) VALUES ('%s', '%s', '%s', %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6));
	}
	else if (statType == STAT_REGIST ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_REGIST (`time_stamp`, `areaid`, `uid`, `ip`, `mmc`, `acc`, `nick`, `lv`, `qd`) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9), str(vec, 10), str(vec, 11));
	}
	else if (statType == STAT_GET_XK ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_GET_XK (`time_stamp`, `areaid`, `uid`, `where`, `cardid`, `num`, `left`) VALUES ('%s', '%s', '%s', %s, %s, %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8), str(vec, 9));
	}
	else if (statType == STAT_USE_CDKEY ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_USE_CDKEY (`time_stamp`, `areaid`, `uid`, `cdkey`) VALUES ('%s', '%s', '%s', '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6));
	}
	else if (statType == STAT_GET_PHP ) 
	{
		return -1;
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_GET_PHP (`time_stamp`, `areaid`, `uid`, `where`, `num`, `left`) VALUES ('%s', '%s', '%s', %s, %s, %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8));
	}
	else if (statType == STAT_ACT_REWARD ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_ACT_REWARD (`time_stamp`, `areaid`, `uid`, `actid`) VALUES ('%s', '%s', '%s', %s)",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6));
	}
	else if (statType == STAT_LOG_PVE ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_ACT_REWARD (`time_stamp`, `areaid`, `uid`, `pveid`) VALUES ('%s', '%s', '%s', '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6));
	}
	else if (statType == STAT_LOG_BUILD ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_ACT_REWARD (`time_stamp`, `areaid`, `uid`, `type`, `level`) VALUES ('%s', '%s', '%s', '%s', '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7));
	}
	else if (statType == STAT_LOG_RES ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_ACT_REWARD (`time_stamp`, `areaid`, `uid`, `resid`, `add`, `num`) VALUES ('%s', '%s', '%s', '%s', '%s', '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7), str(vec, 8));
	}
	else if (statType == STAT_LOG_SHIP ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_ACT_REWARD (`time_stamp`, `areaid`, `uid`, `shipid`, `shiplevel`) VALUES ('%s', '%s', '%s', '%s', '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7));
	}
	else if (statType == STAT_LOG_BUY_ITEM ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_ACT_REWARD (`time_stamp`, `areaid`, `uid`, `itemid`, `itemnum`) VALUES ('%s', '%s', '%s', '%s', '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7));
	}
	else if (statType == STAT_LOG_USE_MONEY ) 
	{
		size = snprintf(buff, size, "INSERT IGNORE INTO LOG_ACT_REWARD (`time_stamp`, `areaid`, `uid`, `type`, `num`) VALUES ('%s', '%s', '%s', '%s', '%s')",
			getStamp(vec[0]), getAreaID(vec, 5), str(vec, 5), str(vec, 6), str(vec, 7));
	}
	return 0;
}

const char * StringHelper::getStamp(const std::string &logStamp)
{
	static char buff[128];
	size_t len = snprintf(buff, sizeof(buff), "%s-%s-%s %s %s", logStamp.substr(0, 4).c_str(), logStamp.substr(4, 2).c_str(), logStamp.substr(6, 2).c_str(), logStamp.substr(8, 8).c_str(), logStamp.substr(17).c_str());
	return std::string(buff, len).c_str();
}

const char * StringHelper::str(const StringVector &vec, int index)
{
	std::string retStr = "NULL";
	if( !vec.empty() && index < (int)vec.size() )
	{
		retStr = vec.at(index);
	}
	return retStr.c_str();
}

const char * StringHelper::getAreaID(const StringVector &vec, int index)
{
	static std::string retStr;
	retStr = "0";
	if( !vec.empty() && index < (int)vec.size() )
	{
		retStr = vec.at(index);
		static const size_t arealen = 5;
		if( retStr.size() < arealen )
		{
			return "0";
		}

		retStr = retStr.substr(retStr.size() - arealen);
	}
	return retStr.c_str();
}

