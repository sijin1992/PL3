#ifndef __ACTIVITY_XIAO_CONF_H__
#define __ACTIVITY_XIAO_CONF_H__
#include "lua_config_wrap.h"

#define ACTIVITY_XIAO_CONF_LEN 81

#define CONF_ACTIVITY_XIAO_ID 0
#define CONF_ACTIVITY_XIAO_ACTIVITY_ID 1
#define CONF_ACTIVITY_XIAO_X_GOLD 2
#define CONF_ACTIVITY_XIAO_TARGETDSR 3
#define CONF_ACTIVITY_XIAO_REWARD 4

class Activity_Xiao_data{
private:
	char *buf;
	char *field[6];
	bool _is_valid;
public:
	int real_idx;
	int ID;
	int ACTIVITY_ID;
	int X_Gold;
	int TARGETDSR;
	int REWARD[8];
public:
	inline Activity_Xiao_data();
	inline ~Activity_Xiao_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 81) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(81);}
private:
	inline int fill_data();
};

Activity_Xiao_data::Activity_Xiao_data(){
	buf = NULL;
	_is_valid = false;
}

Activity_Xiao_data::~Activity_Xiao_data(){
	if(buf != NULL) free(buf);
}

bool Activity_Xiao_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Activity_Xiao_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 6, "Activity_Xiao") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Activity_Xiao_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Activity_Xiao_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 6, "Activity_Xiao") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Activity_Xiao_data::fill_data(){
	ID = atoi(field[0]);
	ACTIVITY_ID = atoi(field[1]);
	X_Gold = atoi(field[2]);
	TARGETDSR = atoi(field[3]);
	if(cut_sub_data(REWARD, 8, field[4]) != 0) return -1;
	real_idx = atoi(field[5]);
	return 0;
}


#endif
