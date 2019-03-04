datablock={}
datablock["main_data"] = 1
datablock["knight_bag"] = 2
datablock["item_package"] = 4
datablock["mail_list"] = 8
datablock["create"] = 512   -- 门派创建时，因为会存在
datablock["lock"] = 1024
datablock["save"] = 2048
datablock["try"] = 4096     --在帮派中，这个标志允许取不到数据，但逻辑继续往下走而不是报错。用于门派查询和创建
datablock["groupid"] = 8192 --如果为true，则后一个参数为groupid。否则为user_name,从userinfo中获取groupid

datablock["group_main"] = 16384

refid = {}
refid["tili"] = 191040211 --体力ID
refid["real_yb"] = 191010099 --真元宝ID
refid["fake_yb"] = 191010003 --假元宝ID
