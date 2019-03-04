#ifndef __ACHIEVEMENT_CONF_H__
#define __ACHIEVEMENT_CONF_H__
#include "lua_config_wrap.h"

#define ACHIEVEMENT_CONF_LEN 235

#define CONF_ACHIEVEMENT_ACH_NUM 0
#define CONF_ACHIEVEMENT_ACH_NAME 1
#define CONF_ACHIEVEMENT_ACH_TYPE 2
#define CONF_ACHIEVEMENT_ACH_DSR 3
#define CONF_ACHIEVEMENT_PARA_TYPE 4
#define CONF_ACHIEVEMENT_PARA 5
#define CONF_ACHIEVEMENT_REWARD 6
#define CONF_ACHIEVEMENT_ICON 7
#define CONF_ACHIEVEMENT_PER_ACH 8
#define CONF_ACHIEVEMENT_PROCESS_DSC 9

class Achievement_data{
private:
	char *buf;
	char *field[11];
	bool _is_valid;
public:
	int real_idx;
	int Ach_Num;
	int Ach_Name;
	int Ach_Type;
	int Ach_Dsr;
	int Para_Type;
	int Para[2];
	int Reward[2];
	int Icon;
	int Per_Ach;
	int Process_Dsc;
public:
	inline Achievement_data();
	inline ~Achievement_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 235) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(235);}
private:
	inline int fill_data();
};

Achievement_data::Achievement_data(){
	buf = NULL;
	_is_valid = false;
}

Achievement_data::~Achievement_data(){
	if(buf != NULL) free(buf);
}

bool Achievement_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Achievement_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 11, "Achievement") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Achievement_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Achievement_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 11, "Achievement") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Achievement_data::fill_data(){
	Ach_Num = atoi(field[0]);
	Ach_Name = atoi(field[1]);
	Ach_Type = atoi(field[2]);
	Ach_Dsr = atoi(field[3]);
	Para_Type = atoi(field[4]);
	if(cut_sub_data(Para, 2, field[5]) != 0) return -1;
	if(cut_sub_data(Reward, 2, field[6]) != 0) return -1;
	Icon = atoi(field[7]);
	Per_Ach = atoi(field[8]);
	Process_Dsc = atoi(field[9]);
	real_idx = atoi(field[10]);
	return 0;
}


#endif
