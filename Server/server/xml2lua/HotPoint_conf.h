#ifndef __HOTPOINT_CONF_H__
#define __HOTPOINT_CONF_H__
#include "lua_config_wrap.h"

#define HOTPOINT_CONF_LEN 20

#define CONF_HOTPOINT_INDEX 0
#define CONF_HOTPOINT_START_TIME 1
#define CONF_HOTPOINT_END_TIME 2
#define CONF_HOTPOINT_SHOW_HERO 3
#define CONF_HOTPOINT_HOT_POOL 4

class HotPoint_data{
private:
	char *buf;
	char *field[6];
	bool _is_valid;
public:
	int real_idx;
	int Index;
	int Start_Time;
	int End_Time;
	int Show_Hero;
	int Hot_Pool;
public:
	inline HotPoint_data();
	inline ~HotPoint_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 20) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(20);}
private:
	inline int fill_data();
};

HotPoint_data::HotPoint_data(){
	buf = NULL;
	_is_valid = false;
}

HotPoint_data::~HotPoint_data(){
	if(buf != NULL) free(buf);
}

bool HotPoint_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("HotPoint_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 6, "HotPoint") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool HotPoint_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("HotPoint_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 6, "HotPoint") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int HotPoint_data::fill_data(){
	Index = atoi(field[0]);
	Start_Time = atoi(field[1]);
	End_Time = atoi(field[2]);
	Show_Hero = atoi(field[3]);
	Hot_Pool = atoi(field[4]);
	real_idx = atoi(field[5]);
	return 0;
}


#endif
