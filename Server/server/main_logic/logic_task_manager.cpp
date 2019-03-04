#include "logic_task_manager.h"
#include "log/log.h"
#include "logic_lua.h"

using namespace std;

enum
{
	TM_UNKNOW_TASK = 0,
	TM_GET_DATA,
	TM_DO_LOGIC,
	TM_SET_DATA,
};

#define DATA_LOCK (1 << 10)
#define DATA_SAVE (1 << 11)
#define DATA_TRYDATA (1 << 12)
#define DATA_REAL_GROUPID (1 << 13)
#define DATA_CREATE (1 << 9)

const char* feature_func = "xxx_feature";
const char* do_logic_func = "xxx_do_logic";
#define ASSERT_STACK() if(lua_gettop(l) != 0) LOG(LOG_ERROR, "%s|lua cmd 0x%x: stack top is %u", m_name.str(), m_cmd, lua_gettop(l))

LogicTaskManager::LogicTaskManager()
{
	m_step = TM_UNKNOW_TASK;
	m_args_num = 0;
	m_received_num = 0;
	m_args = NULL;
	m_is_valid = false;
	m_act_resp = -1;
	m_ext_cmd1 = 0;
	m_ext_cmd2 = 0;
}

LogicTaskManager::~LogicTaskManager()
{
	if(m_args != NULL)
	{
		delete[] m_args;
	}
}

void LogicTaskManager::init(CUserDataBase *data_handle, LUA_handle *lua, USER_NAME &name,
	string *req, string *resp_fail, string *resp, int cmd)
{
	if(m_is_valid)
		return;
	m_step = TM_GET_DATA * 10;
	m_data_handle = data_handle;
	m_lua = lua;
	m_name = name;
	m_req = req;
	m_resp_fail = resp_fail;
	m_resp = resp;
	m_is_valid = true;
	m_cmd = cmd;
}

int LogicTaskManager::run()
{
	int ret;
	while((ret = do_next()) == TM_NEXT);
	return ret;
}

int LogicTaskManager::do_next()
{
	if(!m_is_valid)
		return TM_UNKNOW;
	if(m_step / 10 == TM_GET_DATA)
	{
		return prepare_data();
	}
	else if(m_step == TM_DO_LOGIC)
	{
		return do_logic();
	}
	else if(m_step / 10 == TM_SET_DATA)
	{
		return set_next_data();
	}
	return TM_DONE;
}

// 获取所有待输入的数据
// 每次获取一个数据块，比如
int LogicTaskManager::prepare_data()
{
	// 首先要获取此逻辑的特征,才能去获取数据
	if(m_step % 10 == 0)
		return get_feature_order();
	size_t sub_step = m_step % 10;
	if(sub_step > m_args_num)
	{
		if(sub_step == 1 && m_args_num == 0)
		{// 没有参数，直接执行逻辑
			m_step = TM_DO_LOGIC;
			return TM_NEXT;
		}
		else
		{
			LOG(LOG_ERROR, "%s|lua cmd 0x%x: step(%zu) > m_args_num(%zu)",m_name.str(), m_cmd, sub_step, m_args_num);
			return TM_UNKNOW;
		}
	}
	lua_State *l = m_lua->l;
	ASSERT_STACK();
	// 调用 xxx_feature() 获取数据
	lua_getglobal(l, feature_func);
	lua_pushinteger(l, m_cmd);
	lua_pushinteger(l, m_step % 10);
	lua_pushlstring(l, m_req->c_str(), m_req->size());
	const char *n = m_name.str();
	lua_pushlstring(l, n, strlen(n));
	// 2个返回参数
	if(lua_pcall(l, 4, 2, 0) == 0)//LUA_OK)
	{
		if(lua_type(l, -2) != LUA_TNUMBER || lua_type(l, -1) != LUA_TSTRING)
		{
			LOG(LOG_ERROR, "%s|lua cmd 0x%x step %zu",m_name.str(), m_cmd, sub_step);
			lua_pop(l, 2);
			return TM_UNKNOW;
		}
		int cur_flag = lua_tointeger(l, -2);
		if(cur_flag < 10000)
		{
			size_t name_len = 0;
			const char *t_name = lua_tolstring(l, -1, &name_len);
			size_t data_idx = sub_step - 1;
			m_args[data_idx].name.from_str(t_name);
			m_args[data_idx].data_flag = cur_flag;
			m_args[data_idx].data_type = TA_USER_DATA;
			m_args[data_idx].lock = (cur_flag & (DATA_LOCK | DATA_SAVE)) != 0;
			m_args[data_idx].save = (cur_flag & DATA_SAVE) != 0;
			lua_pop(l, 2);
			int ret;
			if(m_args[data_idx].lock)
			{
				ret = m_data_handle->lockget_user_data(m_args[data_idx].name, cur_flag);
			}
			else
			{
				ret = m_data_handle->get_user_data(m_args[data_idx].name, cur_flag);
			}
			if(gDebugFlag)
				LOG(LOG_DEBUG, "%s|lua cmd 0x%x data_idx %d, user", m_name.str(), m_cmd, static_cast<int>(data_idx));
			if(ret == m_data_handle->RET_DONE)
				return TM_UNKNOW;
			else if(ret == m_data_handle->RET_YIELD)
				return TM_YIELD;
			else
				return TM_UNKNOW;
		}
		else
		{
			size_t data_idx = sub_step - 1;
			size_t name_len = 0;
			const char *t_name = lua_tolstring(l, -1, &name_len);
			m_args[data_idx].data_flag = cur_flag;
			//m_args[data_idx].name.from_str(t_name);
			m_args[data_idx].data_type = TA_GROUP_DATA;
			m_args[data_idx].lock = (cur_flag & (DATA_LOCK | DATA_SAVE)) != 0;
			m_args[data_idx].save = (cur_flag & DATA_SAVE) != 0;
			m_args[data_idx].try_data = (cur_flag & (DATA_TRYDATA)) != 0;
			if((cur_flag & (DATA_CREATE)) != 0)
			{
				m_args[data_idx].create = true;
				m_args[data_idx].lock = true;
				m_args[data_idx].save = true;
			}
			else if((cur_flag & (DATA_REAL_GROUPID)) != 0)
			{
				m_args[data_idx].name.from_str(t_name);
			}
			else
			{
				int ok = false;
				for(size_t j = 0; j < data_idx; j++)
				{
					if(gDebugFlag)
						LOG(LOG_DEBUG, "%s, %s, %d, %d", m_args[j].name.str(), t_name, m_args[j].data_type,
							string(m_args[j].name.str()).compare(t_name));
					if(m_args[j].data_type == TA_USER_DATA && string(m_args[j].name.str()).compare(t_name) == 0)
					{
						UserInfo t;
						if(t.ParseFromString(*(m_args[j].data[0])))
						{
							if(t.has_group_data())
							{
								m_args[data_idx].name.from_str(t.group_data().groupid());
								ok = true;
							}
							else if(m_args[data_idx].try_data)
							{
								ok = true;
							}
							else
							{
							}
						}
						break;
					}
					else
					{
					}
				}
				if(!ok)
				{
					lua_pop(l, 2);
					LOG(LOG_ERROR, "not find user who in the group");
					return TM_UNKNOW;
				}
			}
			lua_pop(l, 2);
			int ret;

			CLogicLUA * logic_lua = (CLogicLUA *)(m_data_handle);

			int data_flag = 0;
			if(cur_flag & (1 << 14))
				data_flag = data_flag | 1;
			if(m_args[data_idx].create ||
				(m_args[data_idx].try_data && string(m_args[data_idx].name.str()).empty()))
			{
				if(++sub_step > m_args_num)
					m_step = TM_DO_LOGIC;
				else
					++m_step;
				if(gDebugFlag)
					LOG(LOG_DEBUG, "%s|not has group", t_name);
				return TM_NEXT;
			}
			ret = logic_lua->get_group(m_args[data_idx].name.str(), m_args[data_idx].lock);
			if(gDebugFlag)
				LOG(LOG_DEBUG, "%s|lua cmd 0x%x data_idx %d, group", m_name.str(), m_cmd, static_cast<int>(data_idx));

			if(ret == m_data_handle->RET_DONE)
				return TM_UNKNOW;
			else if(ret == m_data_handle->RET_YIELD)
				return TM_YIELD;
			else
				return TM_UNKNOW;
		}
	}
	else
	{
		LOG(LOG_ERROR, "%s|lua cmd 0x%x step %zu :%s",m_name.str(), m_cmd,
			sub_step, lua_tostring(l, -1));
		lua_pop(l, 1);
		return TM_UNKNOW;
	}
}

/*
	int LogicTaskManager::prepare_data()
	{
		// 首先要获取此逻辑的特征,才能去获取数据
		if(m_step % 10 == 0)
			return get_feature_order();
		size_t sub_step = m_step % 10;
		if(sub_step > m_args_num)
		{
			if(sub_step == 1 && m_args_num == 0)
			{// 没有参数，直接执行逻辑
				m_step = TM_DO_LOGIC;
				return TM_NEXT;
			}
			else
			{
				LOG(LOG_ERROR, "%s|%s: step(%zu) > m_args_num(%zu)",m_name.str(), m_lua->module.c_str(), sub_step, m_args_num);
				return TM_UNKNOW;
			}
		}
			int cur_flag = DATA_SAVE | DATA_BLOCK_FLAG_MAIN;
			size_t data_idx = sub_step - 1;
			m_args[data_idx].name = m_name;
			m_args[data_idx].data_flag = cur_flag;
			m_args[data_idx].data_type = TA_USER_DATA;
			m_args[data_idx].lock = (cur_flag & (DATA_LOCK | DATA_SAVE)) != 0;
			m_args[data_idx].save = (cur_flag & DATA_SAVE) != 0;
			int ret;
			if(m_args[data_idx].lock)
				ret = m_data_handle->lockget_user_data(m_args[data_idx].name, cur_flag);
			else
				ret = m_data_handle->get_user_data(m_args[data_idx].name, cur_flag);
			if(ret == m_data_handle->RET_DONE)
				return TM_UNKNOW;
			else if(ret == m_data_handle->RET_YIELD)
				return TM_YIELD;
			else
				return TM_UNKNOW;

	}
*/

int LogicTaskManager::set_next_data()
{
	size_t sub_step = m_step % 10;
	if(gDebugFlag)
		LOG(LOG_DEBUG, "step: %d", static_cast<int>(m_step));
	if (sub_step >= m_args_num)
	{
		m_act_resp = 0;	// 整个流程结束，发送成功的resp
		return TM_DONE;
	}
	if(!m_args[sub_step].lock)
	{
		++m_step;
		return set_next_data();
	}
	else if(m_args[sub_step].data_type == TA_GROUP_DATA && m_args[sub_step].data[0] == NULL)
	{//如果在创建公会时遇到问题，会走到这里
		++m_step;
		return set_next_data();
	}
	else
	{
		if(m_args[sub_step].data_type == TA_USER_DATA)
		{
			if((m_args[sub_step].data_flag & DATA_BLOCK_FLAG_MAIN) != 0)
			{
				m_args[sub_step].slot->set_data_from_string(DATA_BLOCK_FLAG_MAIN, *(m_args[sub_step].data[TA_MAIN_DATA]));
			}
			if((m_args[sub_step].data_flag & DATA_BLOCK_FLAG_SHIP) != 0)
			{
				m_args[sub_step].slot->set_data_from_string(DATA_BLOCK_FLAG_SHIP, *(m_args[sub_step].data[TA_SHIP_LIST]));
			}
			if((m_args[sub_step].data_flag & DATA_BLOCK_FLAG_ITEMS) != 0)
			{
				m_args[sub_step].slot->set_data_from_string(DATA_BLOCK_FLAG_ITEMS, *(m_args[sub_step].data[TA_PACKAGE_DATA]));
			}
			if((m_args[sub_step].data_flag & DATA_BLOCK_FLAG_MAIL) != 0)
			{
				m_args[sub_step].slot->set_data_from_string(DATA_BLOCK_FLAG_MAIL, *(m_args[sub_step].data[TA_MAIL_LIST]));
			}
			int ret;
			if(m_args[sub_step].save)
				ret = m_data_handle->unlockset_user_data(m_args[sub_step].name);
			else if(m_args[sub_step].lock)
				ret = m_data_handle->unlock_user_data(m_args[sub_step].name);
			else
				ret = TM_NEXT;
			if(ret == m_data_handle->RET_DONE)
				return TM_UNKNOW;
			else if(ret == m_data_handle->RET_YIELD)
				return TM_YIELD;
			else
				return TM_UNKNOW;
		}
		else
		{
			int ret;
			CLogicLUA * logic_lua = (CLogicLUA *)(m_data_handle);

			if(m_args[sub_step].create)
			{
				if(gDebugFlag)
					LOG(LOG_DEBUG, "create group %s", m_args[sub_step].name.str());
				ret = logic_lua->set_group(*(m_args[sub_step].data[0]), m_args[sub_step].name.str(), m_args[sub_step].create);
			}
			else if(m_args[sub_step].save)
				ret = logic_lua->set_group(*(m_args[sub_step].data[0]), m_args[sub_step].name.str(), m_args[sub_step].create);
			else if(m_args[sub_step].lock)
			{
				ret = logic_lua->unlock_group(true);
			}
			else
				return TM_NEXT;
			if(ret == m_data_handle->RET_DONE)
				return TM_UNKNOW;
			else if(ret == m_data_handle->RET_YIELD)
				return TM_YIELD;
			else
				return TM_UNKNOW;
		}
	}
}

#define CHECK_PUSH_DATA(block_flag, arg_enum) \
	if((m_args[i].data_flag & block_flag) != 0) \
	{\
		if(m_args[i].data[arg_enum] == NULL)\
		{\
			LOG(LOG_ERROR, "%s|%zu %s|get data err", m_name.str(), i, m_args[i].name.str());\
			return -1;\
		}\
		lua_pushlstring(l, m_args[i].data[arg_enum]->c_str(), m_args[i].data[arg_enum]->length());\
		++total_args_num;\
	}

#define CHECK_PUSH_MAIN_DATA() CHECK_PUSH_DATA(DATA_BLOCK_FLAG_MAIN, TA_MAIN_DATA)
#define CHECK_PUSH_SHIP_LIST() CHECK_PUSH_DATA(DATA_BLOCK_FLAG_SHIP, TA_SHIP_LIST)
#define CHECK_PUSH_ITEM_PACKAGE() CHECK_PUSH_DATA(DATA_BLOCK_FLAG_ITEMS, TA_PACKAGE_DATA)
#define CHECK_PUSH_MAIL_LIST() CHECK_PUSH_DATA(DATA_BLOCK_FLAG_MAIL, TA_MAIL_LIST)





#define CHECK_GET_LUA_DATA(block_flag, arg_enum, pbclass) \
	if((m_args[i].data_flag & block_flag) != 0) \
	{\
		if(m_args[i].data[arg_enum] == NULL)\
		{\
			LOG(LOG_ERROR, "%s|%zu %s|get lua data err", m_name.str(), i, m_args[i].name.str());\
			lua_pop(l, total_args_num + 4);\
			return -1;\
		}\
		if(lua_isstring(l, stack_id))\
		{\
			s = lua_tolstring(l, stack_id, &ll);\
			m_args[i].data[arg_enum]->assign(s, ll);\
			pbclass pb;\
			if(!pb.ParseFromString(*(m_args[i].data[arg_enum])))\
			{\
				LOG(LOG_ERROR, "%s|%zu %s|%d|lua cmd 0x%x parse data %d err", m_name.str(), i, m_args[i].name.str(),\
					arg_enum, m_cmd, -(stack_id));\
				lua_pop(l, total_args_num + 4);\
				return -1;\
			}\
		}\
		else\
		{\
			LOG(LOG_ERROR, "%s|%zu %s|lua cmd 0x%x return data %d err", m_name.str(), i, m_args[i].name.str(),\
				m_cmd, -(stack_id));\
			lua_pop(l, total_args_num + 4);\
			return -1;\
		}\
		++stack_id;\
	}

#define CHECK_GET_MAIN_DATA() CHECK_GET_LUA_DATA(DATA_BLOCK_FLAG_MAIN, TA_MAIN_DATA, UserInfo)
#define CHECK_GET_SHIP_LIST() CHECK_GET_LUA_DATA(DATA_BLOCK_FLAG_SHIP, TA_SHIP_LIST, ShipList)
#define CHECK_GET_ITEM_PACKAGE() CHECK_GET_LUA_DATA(DATA_BLOCK_FLAG_ITEMS, TA_PACKAGE_DATA, ItemList)
#define CHECK_GET_MAIL_LIST() CHECK_GET_LUA_DATA(DATA_BLOCK_FLAG_MAIL, TA_MAIL_LIST, MailList)




// 获取逻辑待用数据的基本信息:
// 主要是有几个待用数据，以及如果处理失败，返回的消息
int LogicTaskManager::get_feature_order()
{
	lua_State *l = m_lua->l;
	ASSERT_STACK();
	// 调用 xxx_feature() 获取数据
	string sUserName(m_name.str());
	lua_getglobal(l, feature_func);//m_lua->feature_function.c_str());
	lua_pushinteger(l, m_cmd);
	lua_pushinteger(l, 0);
	// 错误返回的resp可能需要req的数据，所以把它传进去
	// 在这里生成了fail resp后，真实的逻辑调用中就可以忽略任何异常，错了没关系，不需要保护现场生成fail resp了
	lua_pushlstring(l, m_req->c_str(), m_req->size());
	lua_pushlstring(l, sUserName.c_str(), sUserName.length());
	// 2个返回参数:数据块数量/失败消息-1
	if(lua_pcall(l, 4, 2, 0) == 0/*LUA_OK*/)
	{
		if(lua_type(l, -2) != LUA_TNUMBER || lua_type(l, -1) != LUA_TSTRING)
		{
			LOG(LOG_ERROR, "%s|lua cmd 0x%x step 0", sUserName.c_str(), m_cmd);
			lua_pop(l, 2);
			return TM_UNKNOW;
		}
		size_t ll = 0;
		const char *resp = lua_tolstring(l, -1, &ll);
		m_resp_fail->assign(resp, ll);
		m_args_num = lua_tointeger(l, -2);
		//printf("get_feature_order,name,%s,feature_func,%s,cmd,0x%x,arg_num,%d\n", sUserName.c_str(), feature_func, m_cmd, m_args_num);
		if(m_args != NULL)
		{
			LOG(LOG_ERROR, "%s|get args err", sUserName.c_str());
			lua_pop(l, 2);
			return TM_UNKNOW;
		}
		if(m_args_num > 0)
		{
			m_args = new TaskArgs[m_args_num];
			++m_step;
		}
		else
		{
			m_step = TM_DO_LOGIC;
		}
		lua_pop(l, 2);
		m_act_resp = 1;	// 已经活的fail resp了，失败了就可以发了
		return TM_NEXT;
	}
	else
	{
		LOG(LOG_ERROR, "%s|lua cmd 0x%x step 0 :%s", sUserName.c_str(), m_cmd, lua_tostring(l, -1));
		lua_pop(l, 1);
		return TM_UNKNOW;
	}
}
/*
int LogicTaskManager::get_feature_order()
{
	//lua_State *l = m_lua->l;
	//ASSERT_STACK();

		int arg_num = 1;
		PVE_RESP resp;
		resp.set_result(PVE_RESP::FAIL);
		char buffer[128];
		resp.SerializeToArray(buffer, 128);
		m_resp_fail->assign(buffer, resp.GetCachedSize());
		m_args_num = arg_num;
		if(m_args != NULL)
		{
			LOG(LOG_ERROR, "%s|get args err", m_name.str());
			return TM_UNKNOW;
		}
		if(m_args_num > 0)
		{
			m_args = new TaskArgs[m_args_num];
			++m_step;
		}
		else
		{
			m_step = TM_DO_LOGIC;
		}
		m_act_resp = 1; // 已经活的fail resp了，失败了就可以发了
		return TM_NEXT;
}
*/

int LogicTaskManager::do_logic()
{
	lua_State *l = m_lua->l;
	ASSERT_STACK();
	int total_args_num = 0;
	// 调用函数xxx_logic

	lua_getglobal(l, "__G__TRACKBACK__");


	lua_getglobal(l, do_logic_func);
	lua_pushinteger(l, m_cmd);
	lua_pushlstring(l, m_req->c_str(), m_req->size());
	const char *n = m_name.str();
	lua_pushlstring(l, n, strlen(n));
	total_args_num = 1;
	for(size_t i = 0; i < m_args_num; ++i)
	{
		if(m_args[i].data_type == TA_USER_DATA)
		{
			CHECK_PUSH_MAIN_DATA();
			CHECK_PUSH_SHIP_LIST();
			CHECK_PUSH_ITEM_PACKAGE();
			CHECK_PUSH_MAIL_LIST();
		}
		else
		{
			// 公会等信息
			{
				if(m_args[i].data[0] == NULL)
					lua_pushnil(l);
				else
					lua_pushlstring(l, m_args[i].data[0]->c_str(), m_args[i].data[0]->length());
				++total_args_num;
			}
		}
	}
	// 实际调用
	// 第一项，输入时是req，输出时是resp
	// 输出最后两项如果不是nil，则应该是特别的消息，额外发给客户端的
	if(lua_pcall(l, total_args_num + 2, total_args_num + 4, 1) != 0)//LUA_OK)
	{
		LOG(LOG_ERROR, "%s|lua cmd 0x%x call error %s",m_name.str(), m_cmd, lua_tostring(l, -1));
		lua_pop(l, 1);
		lua_pop(l, 1);
		return TM_UNKNOW;
	}

	// 逻辑调用成功
	int stack_id = -(total_args_num + 4);
	size_t ll = 0;
	const char *s;
	if(!lua_isstring(l, stack_id))
	{
		LOG(LOG_ERROR, "%s|lua cmd 0x%x return resp err", m_name.str(), m_cmd);
		lua_pop(l, total_args_num + 4);
		return TM_UNKNOW;
	}
	s = lua_tolstring(l, stack_id, &ll);
	m_resp->assign(s, ll);
	++stack_id;
	for(size_t i = 0; i < m_args_num; ++i)
	{
		if(m_args[i].data_type == TA_USER_DATA)
		{
			CHECK_GET_MAIN_DATA();
			CHECK_GET_SHIP_LIST();
			CHECK_GET_ITEM_PACKAGE();
			CHECK_GET_MAIL_LIST();
		}
		else
		{
			// 公会等信息
			{
				if(m_args[i].create)
				{
					if(m_args[i].data[0] == NULL)
					{
						if(lua_isstring(l, stack_id))
						{
							if((m_args[i].data[0] = new(std::nothrow) string) == NULL)
							{
								LOG(LOG_ERROR, "%s|new group err", m_name.str());
								lua_pop(l, total_args_num + 4);
								return TM_UNKNOW;
							}
							s = lua_tolstring(l, stack_id, &ll);
							m_args[i].data[0]->assign(s, ll);
							GroupMainData pb;
							if(!pb.ParseFromString(*(m_args[i].data[0])))
							{
								LOG(LOG_ERROR, "%s|%zu %s|lua cmd 0x%x parse group data %d err", m_name.str(), i, m_args[i].name.str(), m_cmd, -(stack_id));
								lua_pop(l, total_args_num + 4);
								return -1;
							}
							m_args[i].name.from_str(pb.groupid());
						}
						else
						{
							//LOG(LOG_ERROR, "%s|%zu %s|lua cmd 0x%x create group get data from stack err", m_name.str(), i, m_args[i].name.str(), m_cmd);
							//不要做特殊处理，创建失败也要返回正确的code
							//lua_pop(l, total_args_num + 4);
							//return TM_UNKNOW;
						}
					}
					else
					{
						LOG(LOG_ERROR, "%s|%zu %s|lua cmd 0x%x create group but data is not NULL", m_name.str(), i, m_args[i].name.str(),
							m_cmd);
						lua_pop(l, total_args_num + 4);
						return TM_UNKNOW;
					}
				}
				else if(lua_isstring(l, stack_id))
				{
					s = lua_tolstring(l, stack_id, &ll);
					m_args[i].data[0]->assign(s, ll);
					GroupMainData pb;
					if(!pb.ParseFromString(*(m_args[i].data[0])))
					{
						LOG(LOG_ERROR, "%s|%zu %s|lua cmd 0x%x parse group data %d err", m_name.str(), i, m_args[i].name.str(),
							m_cmd, -(stack_id));
						lua_pop(l, total_args_num + 4);
						return -1;
					}
				}
				else
				{
					LOG(LOG_ERROR, "%s|%zu %s|lua cmd 0x%x return group data %d err", m_name.str(), i, m_args[i].name.str(),
						m_cmd, -(stack_id));
					lua_pop(l, total_args_num + 4);
					return -1;
				}
				++stack_id;
			}
		}
	}
	if(lua_isnumber(l, stack_id) && lua_isstring(l, stack_id + 1))
	{
		m_ext_cmd1 = lua_tointeger(l, stack_id);
		s = lua_tolstring(l, stack_id + 1, &ll);
		m_ext_resp1.assign(s, ll);
	}
	if(lua_isnumber(l, stack_id + 2) && lua_isstring(l, stack_id + 3))
	{
		m_ext_cmd2 = lua_tointeger(l, stack_id+2);
		s = lua_tolstring(l, stack_id + 3, &ll);
		m_ext_resp2.assign(s, ll);
	}
	lua_pop(l, total_args_num + 4);
	m_step = TM_SET_DATA * 10;


	if( m_cmd == CMD_UPDATE_TIMESTAMP_REQ )
	{
		UserInfo userInfo;
		if(!userInfo.ParseFromString(*(m_args[0].data[TA_MAIN_DATA])))
		{
			LOG(LOG_ERROR, "ParseFromString userInfo failed");
			return -1;
		}
		//PARSE_USER_INFO(userInfo);
		//SNAP_USER(m_name.str());
	}

	lua_pop(l, 1);//删除error func

	return TM_NEXT;
}
/*
int LogicTaskManager::do_logic()
{
		return TM_UNKNOW;
}
*/
/*
#include <sys/time.h>
int LogicTaskManager::do_logic()
{
	timeval t1;
	gettimeofday(&t1, NULL);

for(int m = 0; m < 10000; m++)
{
	lua_State *l = m_lua->l;
	int total_args_num = 0;
	// 调用函数xxx_logic
	lua_getglobal(l, m_lua->do_logic_function.c_str());
	lua_pushlstring(l, m_req->c_str(), m_req->size());
	total_args_num = 1;
	for(size_t i = 0; i < m_args_num; ++i)
	{
		if(m_args[i].data_type == TA_USER_DATA)
		{
			CHECK_PUSH_MAIN_DATA();
			CHECK_PUSH_KNIGHT_BAG();
			//包裹等信息
		}
		else
		{
			// 公会等信息
		}
	}
	// 实际调用
	// 参数数量是一致的。第一项，输入时是req，输出时是resp
	if(lua_pcall(l, total_args_num, total_args_num, 0) != 0)//LUA_OK)
	{
		LOG(LOG_ERROR, "%s:%s call error %s", m_lua->file.c_str(),
			m_lua->do_logic_function.c_str(), lua_tostring(l, -1));
		lua_pop(l, 1);
		return TM_UNKNOW;
	}
	// 逻辑调用成功
	int stack_id = -(total_args_num);
	size_t ll = 0;
	const char *s;
	if(!lua_isstring(l, stack_id))
	{
		LOG(LOG_ERROR, "%s:%s return resp err", m_lua->file.c_str(),
			m_lua->do_logic_function.c_str());
		return TM_UNKNOW;
	}
	s = lua_tolstring(l, stack_id, &ll);
	m_resp->assign(s, ll);

	lua_pop(l, total_args_num);

}
	m_step = TM_SET_DATA * 10;
	timeval t2;
	gettimeofday(&t2, NULL);
	int t = t2.tv_sec - t1.tv_sec;
	int st = t2.tv_usec - t1.tv_usec;
	if(st < 0)
	{
		st += 1000000;
		t--;
	}
	LOG(LOG_DEBUG, "use time %d:%d",t,st);

	return TM_NEXT;
}
*/

int LogicTaskManager::on_get_data(CDataControlSlot *data_slot)
{
	if(data_slot == NULL || data_slot->theSet.result() != DataBlockSet::OK)
	{
		if(data_slot == NULL)
			LOG(LOG_ERROR, "%s|get data err NULL", m_name.str());
		else
			LOG(LOG_ERROR, "%s|get data err %d", m_name.str(), data_slot->theSet.result());
		return TM_UNKNOW;
	}
	if(m_is_valid != true || m_step / 10 != TM_GET_DATA)
	{
		LOG(LOG_ERROR, "%s|unknow err", m_name.str());
		return TM_UNKNOW;
	}
	size_t sub_step = m_step % 10;
	if(sub_step > m_args_num)
	{
		LOG(LOG_ERROR, "%s|sub_step = %zu, m_args_num = %zu", m_name.str(), sub_step, m_args_num);
		return TM_UNKNOW;
	}

	if(fill_data_to(&m_args[sub_step - 1], data_slot) != 0)
		return -1;
	if(++sub_step > m_args_num)
		m_step = TM_DO_LOGIC;
	else
		++m_step;
	return TM_NEXT;
}

int LogicTaskManager::on_set_data(CDataControlSlot * data_slot)
{
	if(data_slot == NULL || data_slot->theSet.result() != DataBlockSet::OK)
	{
		if(data_slot == NULL)
			LOG(LOG_ERROR, "%s|set data err NULL", m_name.str());
		else
			LOG(LOG_ERROR, "%s|set data err %d", m_name.str(), data_slot->theSet.result());
		++m_step;
		return TM_UNKNOW;
	}
	size_t sub_step = m_step % 10;
	if (sub_step >= m_args_num)
		return TM_UNKNOW;
	if(m_args[sub_step].lock)
	{
		m_args[sub_step].lock = false;
	}
	else
	{
		LOG(LOG_ERROR, "%s|task manager:set data err", m_name.str());
	}
	++m_step;
	return TM_NEXT;
}

int LogicTaskManager::get_sub_data(string **buf, int flag, CDataControlSlot *data_slot)
{
	if(*buf != NULL)
	{
		return -1;
	}
	if((*buf = new(std::nothrow) string) == NULL)
	{

		return -1;
	}
	if(data_slot->get_data_to_string(flag, **buf) != 0)
	{
		return -1;
	}
	return 0;
}

int LogicTaskManager::fill_data_to(TaskArgs *arg, CDataControlSlot *data_slot)
{
	if(arg->data_type == TA_USER_DATA)
	{
		if((arg->data_flag & DATA_BLOCK_FLAG_MAIN) != 0)
		{
			if(get_sub_data(&arg->data[TA_MAIN_DATA], DATA_BLOCK_FLAG_MAIN, data_slot) != 0)
			{
				LOG(LOG_ERROR, "%s|get data err", m_name.str());
				return -1;
			}
		}
		if((arg->data_flag & DATA_BLOCK_FLAG_SHIP) != 0)
		{
			if(get_sub_data(&arg->data[TA_SHIP_LIST], DATA_BLOCK_FLAG_SHIP, data_slot) != 0)
			{
				LOG(LOG_ERROR, "%s|get data err", m_name.str());
				return -1;
			}
		}
		if((arg->data_flag & DATA_BLOCK_FLAG_ITEMS) != 0)
		{
			if(get_sub_data(&arg->data[TA_PACKAGE_DATA], DATA_BLOCK_FLAG_ITEMS, data_slot) != 0)
			{
				LOG(LOG_ERROR, "%s|get data err", m_name.str());
				return -1;
			}
		}
		if((arg->data_flag & DATA_BLOCK_FLAG_MAIL) != 0)
		{
			if(get_sub_data(&arg->data[TA_MAIL_LIST], DATA_BLOCK_FLAG_MAIL, data_slot) != 0)
			{
				LOG(LOG_ERROR, "%s|get data err", m_name.str());
				return -1;
			}
		}
	}
	arg->slot = data_slot;
	// ...其他
	return 0;
}

// lock的数据需要解除lock
void LogicTaskManager::clear()
{
	if(m_step != TM_UNKNOW_TASK && m_step != TM_GET_DATA * 10)//这两个状态下，数据还没有获得，不需要清理
	{
		size_t i = 0;
		if(m_step == TM_DO_LOGIC)
			m_step = TM_SET_DATA * 10;
		if(m_step / 10 == TM_SET_DATA)
			i = m_step % 10;
		for(; i < m_args_num; ++i)
		{
			if(m_args[i].data_type == TA_USER_DATA && m_args[i].lock)
			{
				m_data_handle->unlock_user_data(m_args[i].name, false, true);
			}
		}
	}
}

int LogicTaskManager::on_get_group_data(GroupMainData *group_data)
{
	if(m_is_valid != true || m_step / 10 != TM_GET_DATA)
	{
		LOG(LOG_ERROR, "%s|unknow err", m_name.str());
		return TM_UNKNOW;
	}
	size_t sub_step = m_step % 10;
	if(sub_step > m_args_num)
	{
		LOG(LOG_ERROR, "%s|sub_step = %zu, m_args_num = %zu", m_name.str(), sub_step, m_args_num);
		return TM_UNKNOW;
	}
	if(gDebugFlag)
		LOG(LOG_DEBUG, "get group %s", m_args[sub_step - 1].name.str());
	if(group_data == NULL)
	{
		if(!m_args[sub_step - 1].try_data)
		{
			LOG(LOG_ERROR, "%s|get group data err NULL", m_name.str());
			return TM_UNKNOW;
		}
	}
	else
	{
		if(m_args[sub_step - 1].data[0] != NULL)
		{
			LOG(LOG_ERROR, "%s|get group err", m_name.str());
			return TM_UNKNOW;
		}
		if((m_args[sub_step - 1].data[0] = new(std::nothrow) string) == NULL)
		{
			LOG(LOG_ERROR, "%s|get group err", m_name.str());
			return TM_UNKNOW;
		}
		group_data->SerializeToString(m_args[sub_step - 1].data[0]);
	}
	if(++sub_step > m_args_num)
		m_step = TM_DO_LOGIC;
	else
		++m_step;
	return TM_NEXT;
}

int LogicTaskManager::on_set_group_data()
{
	size_t sub_step = m_step % 10;
	if(sub_step > m_args_num)
	{
		LOG(LOG_ERROR, "%s|sub_step = %zu, m_args_num = %zu", m_name.str(), sub_step, m_args_num);
		return TM_UNKNOW;
	}
	if(m_args[sub_step].lock)
	{
		m_args[sub_step].lock = false;
	}
	else
	{
		LOG(LOG_ERROR, "%s|task manager:set data err", m_name.str());
	}
	++m_step;
	return TM_NEXT;
}

int LogicTaskManager::call_lf(const char* function)
{
	lua_State *l = m_lua->l;
	ASSERT_STACK();
	// 调用 xxx_feature() 获取数据
	lua_getglobal(l, function);
	if(lua_pcall(l, 0, 0, 0) != 0)//LUA_OK)
	{
		LOG(LOG_ERROR, "%s|lua cmd 0x%x call %s err",m_name.str(), m_cmd,
			function);
		return -1;
	}
	return 0;
}


