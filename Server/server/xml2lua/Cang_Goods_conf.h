#ifndef __CANG_GOODS_CONF_H__
#define __CANG_GOODS_CONF_H__
#include "lua_config_wrap.h"

#define CANG_GOODS_CONF_LEN 1360

#define CONF_CANG_GOODS_GOODS_ID 0
#define CONF_CANG_GOODS_ACTIVITY_ID 1
#define CONF_CANG_GOODS_COIN_ITEM 2
#define CONF_CANG_GOODS_GOOD_ITEM 3
#define CONF_CANG_GOODS_ADD_DEVOTE 4
#define CONF_CANG_GOODS_WEIGHT 5

class Cang_Goods_data{
private:
	char *buf;
	char *field[7];
	bool _is_valid;
public:
	int real_idx;
	int Goods_ID;
	int Activity_ID;
	int Coin_Item[2];
	int Good_Item[2];
	int Add_Devote;
	int Weight;
public:
	inline Cang_Goods_data();
	inline ~Cang_Goods_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 1360) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(1360);}
private:
	inline int fill_data();
};

Cang_Goods_data::Cang_Goods_data(){
	buf = NULL;
	_is_valid = false;
}

Cang_Goods_data::~Cang_Goods_data(){
	if(buf != NULL) free(buf);
}

bool Cang_Goods_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Cang_Goods_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 7, "Cang_Goods") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Cang_Goods_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Cang_Goods_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 7, "Cang_Goods") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Cang_Goods_data::fill_data(){
	Goods_ID = atoi(field[0]);
	Activity_ID = atoi(field[1]);
	if(cut_sub_data(Coin_Item, 2, field[2]) != 0) return -1;
	if(cut_sub_data(Good_Item, 2, field[3]) != 0) return -1;
	Add_Devote = atoi(field[4]);
	Weight = atoi(field[5]);
	real_idx = atoi(field[6]);
	return 0;
}


#endif
