#ifndef __CANG_SHOP_CONF_H__
#define __CANG_SHOP_CONF_H__
#include "lua_config_wrap.h"

#define CANG_SHOP_CONF_LEN 72

#define CONF_CANG_SHOP_CSHOP_ID 0
#define CONF_CANG_SHOP_ACTIVITY_ID 1
#define CONF_CANG_SHOP_CSHOP_ITEM 2
#define CONF_CANG_SHOP_DEVOTE 3

class Cang_Shop_data{
private:
	char *buf;
	char *field[5];
	bool _is_valid;
public:
	int real_idx;
	int CShop_ID;
	int Activity_ID;
	int CShop_Item;
	int Devote;
public:
	inline Cang_Shop_data();
	inline ~Cang_Shop_data();
	inline bool is_valid() {return _is_valid;}
	inline bool get_data_by_idx(int idx);
	inline bool get_data_by_real_idx(int idx);
	inline bool get_first() {return get_data_by_real_idx(1);}
	inline bool get_next(){
		if(_is_valid) if(++real_idx > 72) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_prev(){
		if(_is_valid) if(--real_idx < 1) _is_valid = false;
		return (_is_valid && get_data_by_real_idx(real_idx));
	}
	inline bool get_end() {return get_data_by_real_idx(72);}
private:
	inline int fill_data();
};

Cang_Shop_data::Cang_Shop_data(){
	buf = NULL;
	_is_valid = false;
}

Cang_Shop_data::~Cang_Shop_data(){
	if(buf != NULL) free(buf);
}

bool Cang_Shop_data::get_data_by_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_id("Cang_Shop_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 5, "Cang_Shop") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

bool Cang_Shop_data::get_data_by_real_idx(int idx){
	_is_valid = false;
	if(buf != NULL) {free(buf); buf = NULL;}
	if(get_config_data_by_real_id("Cang_Shop_conf", idx, &buf) != 0) return false;
	if(cut_config_data(buf, field, 5, "Cang_Shop") != 0) return false;
	if(fill_data() != 0) return false;
	_is_valid = true;
	return true;
}

int Cang_Shop_data::fill_data(){
	CShop_ID = atoi(field[0]);
	Activity_ID = atoi(field[1]);
	CShop_Item = atoi(field[2]);
	Devote = atoi(field[3]);
	real_idx = atoi(field[4]);
	return 0;
}


#endif
