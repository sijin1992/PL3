#ifndef __CANG_QUAN_CONF_H__
#define __CANG_QUAN_CONF_H__
#include "lua_config_wrap.h"

#define CANG_QUAN_CONF_LEN 65

#define CONF_CANG_QUAN_QUAN_ID 0
#define CONF_CANG_QUAN_ACTIVITY_ID 1
#define CONF_CANG_QUAN_DEVOTE 2
#define CONF_CANG_QUAN_REWARD_LIST 3

class Cang_Quan_data{
private:
	char *buf;
	char *field[5];
	bool _is_valid;
public:
	int real_idx;
	int Quan_ID;
	int Activity_ID;
	int Devote;
	int Reward_List[2];
public:
	inline Cang_Quan_data();
	inline ~Cang_Quan_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 65) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(65);}
private:
	inline int fill_data();
};

Cang_Quan_data::Cang_Quan_data(){
	buf = NULL;
	_is_valid = false;
}

Cang_Quan_data::~Cang_Quan_data(){
	if(buf != NULL) free(buf);
}

bool Cang_Quan_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Cang_Quan_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 5, "Cang_Quan") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Cang_Quan_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Cang_Quan_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 5, "Cang_Quan") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Cang_Quan_data::fill_data(){
	Quan_ID = atoi(field[0]);
	Activity_ID = atoi(field[1]);
	Devote = atoi(field[2]);
	if(cut_sub_data(Reward_List, 2, field[3]) != 0) return -1;
	real_idx = atoi(field[4]);
	return 0;
}


#endif
