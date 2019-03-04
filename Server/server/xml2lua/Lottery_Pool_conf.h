#ifndef __LOTTERY_POOL_CONF_H__
#define __LOTTERY_POOL_CONF_H__
#include "lua_config_wrap.h"

#define LOTTERY_POOL_CONF_LEN 323

#define CONF_LOTTERY_POOL_BOX_ID 0
#define CONF_LOTTERY_POOL_BOX_SORT 1

class Lottery_Pool_data{
private:
	char *buf;
	char *field[3];
	bool _is_valid;
public:
	int real_idx;
	int BOX_ID;
	int BOX_SORT[132];
public:
	inline Lottery_Pool_data();
	inline ~Lottery_Pool_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 323) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(323);}
private:
	inline int fill_data();
};

Lottery_Pool_data::Lottery_Pool_data(){
	buf = NULL;
	_is_valid = false;
}

Lottery_Pool_data::~Lottery_Pool_data(){
	if(buf != NULL) free(buf);
}

bool Lottery_Pool_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Lottery_Pool_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 3, "Lottery_Pool") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Lottery_Pool_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Lottery_Pool_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 3, "Lottery_Pool") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Lottery_Pool_data::fill_data(){
	BOX_ID = atoi(field[0]);
	if(cut_sub_data(BOX_SORT, 132, field[1]) != 0) return -1;
	real_idx = atoi(field[2]);
	return 0;
}


#endif
