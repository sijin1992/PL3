#ifndef __LUA_CONFIG_WRAP_H__
#define __LUA_CONFIG_WRAP_H__

int get_config_data_by_id(const char *config_tab, int id, char ** data);
int get_config_data_by_real_id(const char *config_tab, int id, char ** data);

int cut_config_data(char *data, char ** fields, int field_num, const char *table_name);

int cut_sub_data(int *data, int len, char *str);

#endif // __LUA_CONFIG_WRAP_H__

