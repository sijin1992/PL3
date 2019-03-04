#ifndef __ACTIVITY_LOGIN_CONF_H__
#define __ACTIVITY_LOGIN_CONF_H__
#include "lua_config_wrap.h"

#define ACTIVITY_LOGIN_CONF_LEN 75

#define CONF_ACTIVITY_LOGIN_ID 0
#define CONF_ACTIVITY_LOGIN_ACTIVITY_ID 1
#define CONF_ACTIVITY_LOGIN_DAY 2
#define CONF_ACTIVITY_LOGIN_TARGETDSR 3
#define CONF_ACTIVITY_LOGIN_REWARD 4

class Activity_Login_data{
private:
	char *buf;
	char *field[6];
	bool _is_valid;
public:
	int real_idx;
	int ID;
	int ACTIVITY_ID;
	int DAY;
	int TARGETDSR;
	int REWARD[10];
public:
	inline Activity_Login_data();
	inline ~Activity_Login_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 75) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(75);}
private:
	inline int fill_data();
};

Activity_Login_data::Activity_Login_data(){
	buf = NULL;
	_is_valid = false;
}

Activity_Login_data::~Activity_Login_data(){
	if(buf != NULL) free(buf);
}

bool Activity_Login_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Activity_Login_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 6, "Activity_Login") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Activity_Login_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Activity_Login_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 6, "Activity_Login") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Activity_Login_data::fill_data(){
	ID = atoi(field[0]);
	ACTIVITY_ID = atoi(field[1]);
	DAY = atoi(field[2]);
	TARGETDSR = atoi(field[3]);
	if(cut_sub_data(REWARD, 10, field[4]) != 0) return -1;
	real_idx = atoi(field[5]);
	return 0;
}


#endif
