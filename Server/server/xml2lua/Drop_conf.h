#ifndef __DROP_CONF_H__
#define __DROP_CONF_H__
#include "lua_config_wrap.h"

#define DROP_CONF_LEN 1161

#define CONF_DROP_DROP_BOX_ID 0
#define CONF_DROP_DROP_ITEM 1
#define CONF_DROP_DROP_PROBABILITY 2
#define CONF_DROP_NUM 3

class Drop_data{
private:
	char *buf;
	char *field[5];
	bool _is_valid;
public:
	int real_idx;
	int DROP_BOX_ID;
	int DROP_ITEM;
	int DROP_PROBABILITY[30];
	int Num;
public:
	inline Drop_data();
	inline ~Drop_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 1161) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(1161);}
private:
	inline int fill_data();
};

Drop_data::Drop_data(){
	buf = NULL;
	_is_valid = false;
}

Drop_data::~Drop_data(){
	if(buf != NULL) free(buf);
}

bool Drop_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Drop_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 5, "Drop") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Drop_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Drop_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 5, "Drop") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Drop_data::fill_data(){
	DROP_BOX_ID = atoi(field[0]);
	DROP_ITEM = atoi(field[1]);
	if(cut_sub_data(DROP_PROBABILITY, 30, field[2]) != 0) return -1;
	Num = atoi(field[3]);
	real_idx = atoi(field[4]);
	return 0;
}


#endif
