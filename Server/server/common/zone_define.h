#ifndef __COM_DEFINE_H__
#define __COM_DEFINE_H__

//�й�����
#define SERVER_ZONE_CH 0
//̨�����
#define SERVER_ZONE_TW 1
//��۵���
#define SERVER_ZONE_HK 2

#ifndef GAME_SERVER_ZONE
	#define GAME_SERVER_ZONE SERVER_ZONE_CH
#endif

#define IS_SERVER_ZONE_TW (GAME_SERVER_ZONE == SERVER_ZONE_TW)

#endif