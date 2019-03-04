#ifndef __GBOSS_CONF_H__
#define __GBOSS_CONF_H__
#include "lua_config_wrap.h"

#define GBOSS_CONF_LEN 10

#define CONF_GBOSS_INDEX 0
#define CONF_GBOSS_NAME 1
#define CONF_GBOSS_STAGE_ID 2
#define CONF_GBOSS_KILL_REWARD 3
#define CONF_GBOSS_BOSS_LIFE 4

class GBoss_data{
private:
	char *buf;
	char *field[6];
	bool _is_valid;
public:
	int real_idx;
	int Index;
	int Name;
	int Stage_ID;
	int Kill_Reward[2];
	int Boss_Life;
public:
	inline GBoss_data();
	inline ~GBoss_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 10) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(10);}
private:
	inline int fill_data();
};

GBoss_data::GBoss_data(){
	buf = NULL;
	_is_valid = false;
}

GBoss_data::~GBoss_data(){
	if(buf != NULL) free(buf);
}

bool GBoss_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("GBoss_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 6, "GBoss") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool GBoss_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("GBoss_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 6, "GBoss") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int GBoss_data::fill_data(){
	Index = atoi(field[0]);
	Name = atoi(field[1]);
	Stage_ID = atoi(field[2]);
	if(cut_sub_data(Kill_Reward, 2, field[3]) != 0) return -1;
	Boss_Life = atoi(field[4]);
	real_idx = atoi(field[5]);
	return 0;
}


#endif
