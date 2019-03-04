#ifndef __CANG_RANK_CONF_H__
#define __CANG_RANK_CONF_H__
#include "lua_config_wrap.h"

#define CANG_RANK_CONF_LEN 714

#define CONF_CANG_RANK_INDEX 0
#define CONF_CANG_RANK_ACTIVITY_ID 1
#define CONF_CANG_RANK_RANK 2
#define CONF_CANG_RANK_REWARD 3

class Cang_Rank_data{
private:
	char *buf;
	char *field[5];
	bool _is_valid;
public:
	int real_idx;
	int Index;
	int Activity_ID;
	int Rank;
	int Reward[4];
public:
	inline Cang_Rank_data();
	inline ~Cang_Rank_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 714) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(714);}
private:
	inline int fill_data();
};

Cang_Rank_data::Cang_Rank_data(){
	buf = NULL;
	_is_valid = false;
}

Cang_Rank_data::~Cang_Rank_data(){
	if(buf != NULL) free(buf);
}

bool Cang_Rank_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Cang_Rank_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 5, "Cang_Rank") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Cang_Rank_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Cang_Rank_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 5, "Cang_Rank") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Cang_Rank_data::fill_data(){
	Index = atoi(field[0]);
	Activity_ID = atoi(field[1]);
	Rank = atoi(field[2]);
	if(cut_sub_data(Reward, 4, field[3]) != 0) return -1;
	real_idx = atoi(field[4]);
	return 0;
}


#endif
