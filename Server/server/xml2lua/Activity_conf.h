#ifndef __ACTIVITY_CONF_H__
#define __ACTIVITY_CONF_H__
#include "lua_config_wrap.h"

#define ACTIVITY_CONF_LEN 75

#define CONF_ACTIVITY_ACTIVITY_ID 0
#define CONF_ACTIVITY_ACTIVITY_START 1
#define CONF_ACTIVITY_LASTTIME 2
#define CONF_ACTIVITY_SHOW 3
#define CONF_ACTIVITY_GROUP 4
#define CONF_ACTIVITY_EFFECT 5
#define CONF_ACTIVITY_HIDE 6
#define CONF_ACTIVITY_HIDE1 7
#define CONF_ACTIVITY_HIDE2 8

class Activity_data{
private:
	char *buf;
	char *field[10];
	bool _is_valid;
public:
	int real_idx;
	int Activity_ID;
	int Activity_Start;
	int LastTime;
	int Show;
	int Group;
	char *Effect;
	int Hide;
	int Hide1;
	int Hide2;
public:
	inline Activity_data();
	inline ~Activity_data();
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

Activity_data::Activity_data(){
	buf = NULL;
	_is_valid = false;
}

Activity_data::~Activity_data(){
	if(buf != NULL) free(buf);
}

bool Activity_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Activity_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 10, "Activity") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Activity_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Activity_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 10, "Activity") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Activity_data::fill_data(){
	Activity_ID = atoi(field[0]);
	Activity_Start = atoi(field[1]);
	LastTime = atoi(field[2]);
	Show = atoi(field[3]);
	Group = atoi(field[4]);
	Effect = field[5];
	Hide = atoi(field[6]);
	Hide1 = atoi(field[7]);
	Hide2 = atoi(field[8]);
	real_idx = atoi(field[9]);
	return 0;
}


#endif
