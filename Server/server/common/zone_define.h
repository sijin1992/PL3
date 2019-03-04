#ifndef __COM_DEFINE_H__
#define __COM_DEFINE_H__

//中国地区
#define SERVER_ZONE_CH 0
//台湾地区
#define SERVER_ZONE_TW 1
//香港地区
#define SERVER_ZONE_HK 2

#ifndef GAME_SERVER_ZONE
	#define GAME_SERVER_ZONE SERVER_ZONE_CH
#endif

#define IS_SERVER_ZONE_TW (GAME_SERVER_ZONE == SERVER_ZONE_TW)

#endif