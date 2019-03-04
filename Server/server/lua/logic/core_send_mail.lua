local core_user = require "core_user_funcs"
local core_task = require "core_task"
local util = require "util.c"

local function send_mail(user_info, mail_list, tmail)
	local mail = clonetab(tmail)
    local guid = user_info.next_mail_guid
    user_info.next_mail_guid = guid + 1
    if mail.stamp == 0 then mail.stamp = os.time() end
    mail.guid = guid
    if mail.type == 10 then mail.expiry_stamp = 0
    else
        local validity = mail.expiry_stamp
        if validity < 1000 then
            mail.expiry_stamp = mail.stamp + 86400 * validity
        end
    end
    table.insert(mail_list, mail)
end

local function limit_mail_count(main_data, item_list, mail_list)
    local num = #mail_list
    local t = false
    while num > 100 do
        t = true
        local idx = 1
        local reward_item_list = mail_list[1].item_list
        if reward_item_list then
            for k,v in ipairs(reward_item_list) do
                core_user.get_item(v.id, v.num, main_data, 301, nil, item_list, nil, nil)
            end
        end
        table.remove(mail_list, 1)
        num = num - 1
    end
    if t then
        core_task.check_chengjiu_title(nil, main_data)
        core_task.check_chengjiu_shengwang(nil, main_data)
        core_task.check_chengjiu_total_gold(nil, main_data)
        core_task.check_chengjiu_max_gold(nil, main_data)
        core_task.check_newtask_by_event(main_data, 7)
    end
end

local function send_pvp_reward_mail(rank, time_list, main_data, item_list, mail_list)
    assert(rank <= 10000)
    local reward_item_list = {}
    for k,v in ipairs(PVP_Reward_conf.index) do
        local conf = PVP_Reward_conf[v]
        if rank <= conf.ID then
            table.insert(reward_item_list, {id = 191040210, num = conf.POPULARITY})
            table.insert(reward_item_list, {id = 191010056 ,num = conf.MEDAL})
            local k = 1
            while conf.ITEM[k] do
                table.insert(reward_item_list, {id = conf.ITEM[k], num = conf.ITEM[k + 1]})
                k = k + 2
            end
            break
        end
    end
    local text = string.format(lang.pvp_reward, rank)
    for k = #time_list, 1, -1 do
        local mail = {
            type = 10,
            from = lang.baixiaosheng,
            subject = lang.pvp_reward_subject,
            message = text,
            item_list = reward_item_list,
            stamp = time_list[k],
            guid = 0,
            expiry_stamp = 0,}
        send_mail(main_data, mail_list, mail)
    end
    --count_mail(main_data, item_list, mail_list)
end

local function send_pvp_rank_reward_mail(old_rank, new_rank, main_data, mail_list)
    local rank_end = old_rank
    local rank_first = new_rank
    local conf_index = PVP_Rank_conf.index
    local limit = conf_index[#conf_index]
    if rank_end > limit then rank_end = limit + 1 end
    if new_rank >= rank_end then return end
    local i_list = {}
    for k,v in ipairs(conf_index) do
        if rank_first >= rank_end then break end
        if rank_first <= v then
            local lim = v + 1
            if rank_end <= v then lim = rank_end end
            local r = lim - rank_first
            local reward = PVP_Rank_conf[v].REWARD
            local k1 = 1
            while(reward[k1]) do
                local id = reward[k1]
                local num = reward[k1 + 1]
                local done = false
                for k2,v2 in ipairs(i_list) do
                    if v2.id == id then
                        v2.num = v2.num + num * r
                        done = true
                        break
                    end
                end
                if not done then
                    table.insert(i_list, {id = id, num = num * r})
                end
                k1 = k1 + 2
            end
            rank_first = v + 1
        end
    end
    
    local text = string.format(lang.pvp_rank_reward, new_rank, old_rank - new_rank)
    local mail = {
        type = 10,
        from = lang.baixiaosheng,
        subject = lang.pvp_rank_reward_subject,
        message = text,
        item_list = i_list,
        stamp = os.time(),
        guid = 0,
        expiry_stamp = 0,}
    send_mail(main_data, mail_list, mail)

    --count_mail(main_data, item_list, mail_list)
end

local function send_cjsz_mail(main_data, idx, mail_list, cangjian_data)
    local cang_rank = global_huodong.get_cur_cang_rank(cangjian_data)
    assert(cang_rank)
    local conf_idx = 0
    if idx >= 1 and idx <= 50 then conf_idx = idx
    else conf_idx = 51 end
    local conf = cang_rank[conf_idx]
    if not conf then return nil end
    local e_item_list = {}
    local k = 1
    while conf.Reward[k] do
        table.insert(e_item_list, {id = conf.Reward[k], num = conf.Reward[k + 1]})
        k = k + 2
    end
    
    local text = nil
    if conf_idx == 51 then
        text = lang.cjsz_mail51
    else
        text = string.format(lang.cjsz_mail50, conf_idx)
    end
    local mail = {
        type = 10,
        from = lang.youlongsheng,
        subject = lang.cjsz_subject,
        message = text,
        item_list = e_item_list,
        stamp = os.time(),
        guid = 0,
        expiry_stamp = 0,}
    send_mail(main_data, mail_list, mail)

    --count_mail(main_data, item_list, mail_list)
end

local function send_ext_mail(main_data, mail_list)
    local mail = {
        type = 10,
        from = lang.gl_yunying,
        subject = lang.ext_mail_subject,
        message = lang.ext_mail_msg,
        item_list = {{id= 191010099, num = 200}},
        stamp = os.time(),
        guid = 0,
        expiry_stamp = 0,}
    send_mail(main_data, mail_list, mail)
end

local function send_haojiao_mail(main_data, mail_list)
    local item_id = 191010022
    local item_num = 5
    
    local mail = {
        type = 10,
        from = lang.gl_yunying,
        subject = lang.haojiao20150401_subject,
        message = lang.haojiao20150401_msg,
        item_list = {{id = item_id, num = item_num}},
        stamp = os.time(),
        guid = 0,
        expiry_stamp = 0,}
    send_mail(main_data, mail_list, mail)
end

local function send_huodong_mail_daily(main_data, mail_list, dayid)
    if dayid >= 16605 and dayid <= 16607 then
        local day = dayid - 16586
        local sb = string.format(lang.sb_dayid, 6, day)
        --local item_list = {}
        --if dayid == 16605 then
        local item_list = {{id = 191010003, num = 200}, {id = 191020213, num = 2}, {id = 191010001, num = 1000000},{id = 190050006, num = 5}}
        --elseif dayid == 16606 then
        --    item_list = {{id = 191010003, num = 200}, {id = 191020214, num = 1}, {id = 191010001, num = 50000}}
        --elseif dayid == 16607 then
        --    item_list = {{id = 191010003, num = 200}, {id = 191020214, num = 1}, {id = 191010001, num = 50000}}
        --end
        
        local mail = {
            type = 10,
            from = lang.gl_yunying,
            subject = sb,
            message = lang.msg_dayid,
            item_list = item_list,
            stamp = os.time(),
            guid = 0,
            expiry_stamp = 0,}
        send_mail(main_data, mail_list, mail)
    end

	--台湾
	if server_platform == 1 then

		--9月19~9月25
		--一共7天
		do
			local startDay = get_dayid('2015-09-19')
			if dayid >= startDay and dayid <= get_dayid('2015-09-25') then
                local date = os.date("*t")
                local sb = string.format(lang.sb_dayid, date.month, date.day)
				local reward_list = {} --奖励列表
				local item_list = {{id = 191020214, num = 6}, {id = 191020213, num = 6}, {id = 190050007, num = 20}, {id = 190050009, num = 20}}
				assert(item_list, 'item_list is null, dayid:' .. dayid)
				local mail = {
					type = 10,
					from = lang.gl_yunying,
					subject = sb,
					message = lang.msg_dayid,
					item_list = item_list,
					stamp = os.time(),
					guid = 0,
					expiry_stamp = 0,}

				send_mail(main_data, mail_list, mail)
			end
		end

		--9月26号~9月29
		do 
			local startDay = get_dayid('2015-09-26')
			if dayid >= startDay and dayid <= get_dayid('2015-09-29')then
				local date = os.date("*t")
				local sb = string.format(lang.sb_dayid, date.month, date.day)
				--当前奖励
				local item_list = {{id = 193010004, num = 200}, {id = 193010005, num = 200}, 
                    {id = 191010001, num = 2000000}, {id = 190050006, num = 30}, {id = 190050017, num = 30}}
				assert(item_list, 'item_list is null, dayid:' .. dayid)
				local mail = {
					type = 10,
					from = lang.gl_yunying,
					subject = sb,
					message = lang.msg_dayid,
					item_list = item_list,
					stamp = os.time(),
					guid = 0,
					expiry_stamp = 0,}

				send_mail(main_data, mail_list, mail)
			end
		end

        --9月30号~10月2号
        do 
            local startDay = get_dayid('2015-09-30')
            if dayid >= startDay and dayid <= get_dayid('2015-10-02')then
                local date = os.date("*t")
                local sb = string.format(lang.sb_dayid, date.month, date.day)
                --当前奖励
                local item_list = {{id = 194804000, num = 1}, {id = 190050006, num = 30}, {id = 190050017, num = 30}}
                assert(item_list, 'item_list is null, dayid:' .. dayid)
                local mail = {
                    type = 10,
                    from = lang.gl_yunying,
                    subject = sb,
                    message = lang.msg_dayid,
                    item_list = item_list,
                    stamp = os.time(),
                    guid = 0,
                    expiry_stamp = 0,}

                send_mail(main_data, mail_list, mail)
            end
        end

        --10月3号~10月8号
        do 
            local startDay = get_dayid('2015-10-03')
            if dayid >= startDay and dayid <= get_dayid('2015-10-08')then
                local date = os.date("*t")
                local sb = string.format(lang.sb_dayid, date.month, date.day)
                --当前奖励
                local item_list = {{id = 191020213, num = 6}, {id = 194020202, num = 8}, {id = 190050011, num = 20}, {id = 190050038, num = 20}}
                assert(item_list, 'item_list is null, dayid:' .. dayid)
                local mail = {
                    type = 10,
                    from = lang.gl_yunying,
                    subject = sb,
                    message = lang.msg_dayid,
                    item_list = item_list,
                    stamp = os.time(),
                    guid = 0,
                    expiry_stamp = 0,}

                send_mail(main_data, mail_list, mail)
            end
        end

        --10月9号~10月13号
        do 
            local startDay = get_dayid('2015-10-09')
            if dayid >= startDay and dayid <= get_dayid('2015-10-13')then
                local date = os.date("*t")
                local sb = string.format(lang.sb_dayid, date.month, date.day)
                --当前奖励
                local item_list = {{id = 191020214, num = 6}, {id = 191020213, num = 6}, {id = 190050007, num = 20}, {id = 190050006, num = 20}}
                assert(item_list, 'item_list is null, dayid:' .. dayid)
                local mail = {
                    type = 10,
                    from = lang.gl_yunying,
                    subject = sb,
                    message = lang.msg_dayid,
                    item_list = item_list,
                    stamp = os.time(),
                    guid = 0,
                    expiry_stamp = 0,}

                send_mail(main_data, mail_list, mail)
            end
        end

        --10月14号~10月16号
        do 
            local startDay = get_dayid('2015-10-14')
            if dayid >= startDay and dayid <= get_dayid('2015-10-16')then
                local date = os.date("*t")
                local sb = string.format(lang.sb_dayid, date.month, date.day)
                --当前奖励
                local item_list = {{id = 191020214, num = 6}, {id = 191020213, num = 6}, {id = 190050011, num = 20}, {id = 190050038, num = 20}}
                assert(item_list, 'item_list is null, dayid:' .. dayid)
                local mail = {
                    type = 10,
                    from = lang.gl_yunying,
                    subject = sb,
                    message = lang.msg_dayid,
                    item_list = item_list,
                    stamp = os.time(),
                    guid = 0,
                    expiry_stamp = 0,}

                send_mail(main_data, mail_list, mail)
            end
        end

	end

end

local core_send_mail = {
    send_pvp_reward_mail = send_pvp_reward_mail,
    send_pvp_rank_reward_mail = send_pvp_rank_reward_mail,
    limit_mail_count = limit_mail_count,
    send_cjsz_mail = send_cjsz_mail,
    send_mail = send_mail,
    send_ext_mail = send_ext_mail,
    send_haojiao_mail = send_haojiao_mail,
    send_huodong_mail_daily = send_huodong_mail_daily
}

return core_send_mail
