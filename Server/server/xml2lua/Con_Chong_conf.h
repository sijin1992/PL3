#ifndef __CON_CHONG_CONF_H__
#define __CON_CHONG_CONF_H__
#include "lua_config_wrap.h"

#define CON_CHONG_CONF_LEN 111

#define CONF_CON_CHONG_ID 0
#define CONF_CON_CHONG_ACTIVITY_ID 1
#define CONF_CON_CHONG_LIMIT 2
#define CONF_CON_CHONG_TARGETDSR 3
#define CONF_CON_CHONG_REWARD 4

class Con_Chong_data{
private:
	char *buf;
	char *field[6];
	bool _is_valid;
public:
	int real_idx;
	int ID;
	int ACTIVITY_ID;
	int LIMIT;
	int TARGETDSR;
	int REWARD[8];
public:
	inline Con_Chong_data();
	inline ~Con_Chong_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 111) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(111);}
private:
	inline int fill_data();
};

Con_Chong_data::Con_Chong_data(){
	buf = NULL;
	_is_valid = false;
}

Con_Chong_data::~Con_Chong_data(){
	if(buf != NULL) free(buf);
}

bool Con_Chong_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Con_Chong_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 6, "Con_Chong") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Con_Chong_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Con_Chong_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 6, "Con_Chong") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Con_Chong_data::fill_data(){
	ID = atoi(field[0]);
	ACTIVITY_ID = atoi(field[1]);
	LIMIT = atoi(field[2]);
	TARGETDSR = atoi(field[3]);
	if(cut_sub_data(REWARD, 8, field[4]) != 0) return -1;
	real_idx = atoi(field[5]);
	return 0;
}


#endif
