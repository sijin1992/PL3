local tips = require("util.TipsMessage"):getInstance()
local player = require("app.Player"):getInstance()
local gl = require("util.GlobalLoading"):getInstance()
local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()
local animManager = require("app.AnimManager"):getInstance()
local ActivityScene = class("ActivityScene", cc.load("mvc").ViewBase)

ActivityScene.RESOURCE_FILENAME = "ActivityScene/ActivityLayer.csb"
ActivityScene.NEED_ADJUST_POSITION = true

ActivityScene.lagHelper = require("util.ExLagHelper"):getInstance()
ActivityScene.IS_SCENE_TRANSFER_EFFECT = false
local schedulerEntry = nil
local schedulerEntry1 = nil
ActivityScene.IS_SCENE_TRANSFER_EFFECT = false

local isConvertover = false
local ConvertScheduler = nil

local function getTime(str) -- 1999112100（年月日时）
	local nyear = tonumber(string.sub(str,1,4))
	local nmonth = tonumber(string.sub(str,5,6))
	local nday = tonumber(string.sub(str,7,8))
	local nhour = tonumber(string.sub(str,9,10))
	return os.time{year=nyear, month=nmonth, day=nday, hour=nhour,min=0,sec=0}
end

function ActivityScene:onCreate( data )
	if( self.IS_SCENE_TRANSFER_EFFECT == false ) then
		self.data_ = data
	else

	if data then
		self.data_ = data
	end
	if ((data and data.sfx) or true ) then
		if( data and data.sfx ) then
			data.sfx = false
		end
		local view = self:getApp():createView("CityScene/TransferScene",{from = "ActivityScene/ActivityScene" ,state = "enter"})
		self:addChild(view)
	end
	end
end

function ActivityScene:createActivityNode()

	self.svd_:clear()
	self.svd_:getScrollView():setTag(0)

	for i,v in ipairs(CONF.ACTIVITYGROUP.getIDList()) do

		local ag_conf = CONF.ACTIVITYGROUP.get(v)

		local has = false

		for ii,vv in ipairs(ag_conf.SUB_ID) do
			for iii,vvv in ipairs(self.small_list) do
				if vvv == vv then
					has = true
					break
				end
			end
		end

		if has then

			local add = true
			-- if v == CONF.EActivityGroup.kInvest then
			-- 	if player:getActivity(13001) then
			-- 		if player:getActivity(13001).invest_data.index >= CONF.INVESTGROUP.count() then
			-- 			add = false
			-- 		end
			-- 	end
			-- end
            if v == CONF.EActivityGroup.kChangeShip then
                local info = player:getActivity(15001)
                if info ~= nil and info.change_ship_data.getted_reward then
                    add = false
                end
            end

			if add then
				local node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/BigAv.csb")
				node:getChildByName("text"):setString(CONF:getStringValue(ag_conf.MAIN_NAME))
				node:getChildByName("text_choise"):setString(CONF:getStringValue(ag_conf.MAIN_NAME))
				node:getChildByName("text_choise"):setVisible(false)
				if ag_conf.MAIN_ICON == 0 then
					node:getChildByName("icon"):setVisible(false)
				else
					if ag_conf.MAIN_ICON == 1 then
					--Change By JinXin 20180620
						node:getChildByName("icon"):setTexture("ShopScene/ui/icon_hot2.png")
					elseif ag_conf.MAIN_ICON == 2 then
						node:getChildByName("icon"):setTexture("ShopScene/ui/icon_new2.png")
					elseif ag_conf.MAIN_ICON == 3 then
						node:getChildByName("icon"):setTexture("ShopScene/ui/icon_time2.png")
					end
				end

				node:setTag(v)
				node:setName("fff")

				local function func()
					self:resetActivityInfo(node:getTag())
					self.svd_:getScrollView():setTag(node:getTag())
				end

				local callback = {node = node:getChildByName("background"), func = func}
				self.svd_:addElement(node , {callback = callback})
			end

		end
	end

	if self.data_ and self.data_.group_id then
		self:resetActivityInfo(self.data_.group_id)
		self.svd_:getScrollView():setTag(self.data_.group_id)
	else
		if self.svd_:getScrollView():getChildByName("fff") then
			self:resetActivityInfo(self.svd_:getScrollView():getChildByName("fff"):getTag())
			self.svd_:getScrollView():setTag(self.svd_:getScrollView():getChildByName("fff"):getTag())
		else
			tips:tips("no activity")
		end
	end
			
end

function ActivityScene:resetActivityInfo( index, flag )

	if schedulerEntry1 ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerEntry1)
	 	schedulerEntry1 = nil
	end	
	if self.svd_:getScrollView():getTag() == index and (flag == nil or flag == false) then
		return
	end

	if index > CONF.ACTIVITYGROUP.count() then
		tips:tips(CONF:getStringValue("coming soon"))
		return
	end

	for i,v in ipairs(self.svd_:getScrollView():getChildren()) do

		print("heheh",v:getTag(),index)
		v:getChildByName('text_choise'):setVisible(false)
		v:getChildByName("text"):setVisible(true)
		if v:getTag() == index then
			v:getChildByName('text_choise'):setVisible(true)
			v:getChildByName('text'):setVisible(false)
			v:getChildByName("background"):setOpacity(255)
		else
			v:getChildByName("background"):setOpacity(255*0)
		end
	end

	if index == CONF.EActivityGroup.kMonthSign then 
		self:createMonthNode()
	elseif index == CONF.EActivityGroup.kChangeShip then
		self:createChangeShip()
	elseif index == CONF.EActivityGroup.kInvest then
		self:createInvestNode()
    elseif index == CONF.EActivityGroup.kConvert then
		self:createConvertNode()
	else
		self:createBigAvNode(index)
	end

end


function ActivityScene:createBigAvNode( index )

	local rn = self:getResourceNode()

	-- if rn:getChildByName("node"):getChildByName("big_node") then
	-- 	rn:getChildByName("node"):getChildByName("big_node"):removeFromParent()
	-- end

	-- if rn:getChildByName("node"):getChildByName("month_node") then
	-- 	rn:getChildByName("node"):getChildByName("month_node"):removeFromParent()
	-- end

	for i,v in ipairs(rn:getChildByName("node"):getChildren()) do
		-- if v:getName() ~= "month_node" then
			v:removeFromParent()
		-- end
	end

	if index ~= CONF.EActivityGroup.kSevenDays  then
		local big_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/BigAvNode.csb")

		local id_list = {}
		for i,v in ipairs(CONF:getActivityConf(index).getIDList()) do
			for i2,v2 in ipairs(self.small_list) do
				if v == v2 then
					table.insert(id_list, v2)
					break
				end
			end
		end

		local function sort( a,b )
			return a < b
		end

		table.sort(id_list, sort)


		big_node:getChildByName("list"):setScrollBarEnabled(false)
		local svd = require("util.ScrollViewDelegate"):create(big_node:getChildByName("list"),cc.size(0,0), cc.size(97,50))

		for i,v in ipairs(id_list) do

			local conf = CONF:getActivityConf(index).get(v)

			local list_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SmallAv.csb")

			list_node:getChildByName("text"):setString(CONF:getStringValue(conf.NAME))

			local function func( ... )

				if #id_list == 1 then
					return
				end

				playEffectSound("sound/system/tab.mp3")

				self:createSmallAvNode(index, v)
				svd:getScrollView():setTag(v)
			end

			list_node:setTag(v)

			local callback = {node = list_node:getChildByName("background"), func = func}

			svd:addElement(list_node, {callback = callback})

		end

		if #id_list == 1 then
			for i,v in ipairs(svd:getScrollView():getChildren()) do
				v:setVisible(false)
			end
		end

		big_node:setName("big_node")
		rn:getChildByName("node"):addChild(big_node)

		self:createSmallAvNode(index, id_list[1])
		svd:getScrollView():setTag(id_list[1])
	
	elseif index == CONF.EActivityGroup.kSevenDays then

		if player:getActivity(4001) == nil then
			return
		end

		local big_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/BigAvNode.csb")

		local id = CONF:getActivityConf(index).getIDList()[1]

		big_node:getChildByName("list"):setScrollBarEnabled(false)
		local svd = require("util.ScrollViewDelegate"):create(big_node:getChildByName("list"),cc.size(0,0), cc.size(100,50))

		local regist_time = player:getRegistTime()

		local time = player:getServerTime() - regist_time

		local day_now = 0
		if time < 0 then
			day_now = 7
		else

			day_now = math.ceil(time / 86400)
		end

		if day_now > 7 then
			day_now = 7
		end

		local dayy = {}

		for i=1,7 do
			local list_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SmallAv.csb")

			list_node:getChildByName("text"):setString(CONF:getStringValue(i.."_day"))

			if i > day_now then
				list_node:getChildByName("suo"):setVisible(true)
			end

			local function func( ... )

				if list_node:getChildByName("suo"):isVisible() then
				    return
				end

				playEffectSound("sound/system/tab.mp3")

				svd:getScrollView():setTag(i)
				self:createSmallAvNode(index, 4001)
				
			end

			list_node:setTag(i)

			local callback = {node = list_node:getChildByName("background"), func = func}

			local type = 1
			if i == day_now then
				type = 2
			end

			local tt = {item = list_node, index = i, callback = callback ,type = type}
			table.insert(dayy, tt)
		end

		local function sort( a,b )

			local day_now = math.ceil((player:getServerTime() - player:getRegistTime())/86400)

			if a.index == day_now or b.index == day_now then
				return a.type > b.type
			else
				if a.index < day_now then
					if b.index < day_now then
						return a.index < b.index
					else
						return b.index < a.index
					end
				else
					if b.index < day_now then
						return a.index > b.index
					else
						return b.index > a.index
					end
				end
			end

		end

		table.sort(dayy, sort)

		for i,v in ipairs(dayy) do
			svd:addElement(v.item, {callback = v.callback})
		end

		big_node:setName("big_node")
		rn:getChildByName("node"):addChild(big_node)

		big_node:setTag(4001)
		svd:getScrollView():setTag(day_now)
		self:createSmallAvNode(index, 4001)

	end
end

function ActivityScene:isGetReward(taskId, info)
	if info then
		for _,id in ipairs(info.seven_days_data.getted_reward_list) do
			if id == taskId then
				return true
			end
		end
	end
	return false
end

function ActivityScene:createSmallAvNode( index, id, flag)


	local big_node = self:getResourceNode():getChildByName("node"):getChildByName("big_node")

	if big_node:getChildByName("list"):getTag() == id and (flag == nil or flag == false) then
		return
	end

	if flag == nil or flag == false then
		self.svd_Y = nil
	end

	local bj_num = 0
	if index ~= CONF.EActivityGroup.kSevenDays then
		bj_num = id 
	elseif index == CONF.EActivityGroup.kSevenDays  then
		bj_num = big_node:getChildByName("list"):getTag()
	end

	for i,v in ipairs(big_node:getChildByName("list"):getChildren()) do
		if v:getTag() == bj_num then
			v:getChildByName("background"):setOpacity(255)
			v:getChildByName("text"):setTextColor(cc.c4b(220,246,255,255))
			-- v:getChildByName("text"):enableShadow(cc.c4b(220,246,255,255), cc.size(0.5,0.5))
		else
			v:getChildByName("background"):setOpacity(255*0)
			v:getChildByName("text"):setTextColor(cc.c4b(209,209,209,255))
			-- v:getChildByName("text"):enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
		end
	end

	if big_node and big_node:getChildByName("small_node") then
		big_node:getChildByName("small_node"):removeFromParent()
	end

	local conf = CONF:getActivityConf(index).get(id)

	local small_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SmallAvNode_0.csb")
	small_node:getChildByName("av_ins"):setVisible(true)
	if index ==  CONF.EActivityGroup.kSevenDays or index ==  CONF.EActivityGroup.kChange then
		small_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SmallAvNode_1.csb")
	elseif index == CONF.EActivityGroup.kRecharge or index ==  CONF.EActivityGroup.kConsume then
		small_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SmallAvNode.csb")
		if index == CONF.EActivityGroup.kRecharge then
			small_node:getChildByName("huodon_bottom_1"):setTexture("ActivityScene/ui/recharge_di.png")
		else
			small_node:getChildByName("huodon_bottom_1"):setTexture("ActivityScene/ui/recharge_di2.png")
		end
		small_node:getChildByName("av_ins"):setVisible(false)
	end
	-- small_node:getChildByName("av_name"):setString(CONF:getStringValue(conf.NAME))
	small_node:getChildByName("av_name"):setString("")
	small_node:getChildByName("av_ins"):setString(CONF:getStringValue(conf.MEMO))
	-- 

	-- if index == 5 then
	-- 	local label = cc.Label:createWithTTF(CONF:getStringValue("accumulate_online"), "fonts/cuyabra.ttf", 20)
	-- 	label:setAnchorPoint(cc.p(1,0.5))
	-- 	label:setPosition(cc.p(small_node:getChildByName("av_days"):getPositionX() - small_node:getChildByName("av_days"):getContentSize().width - 50, small_node:getChildByName("av_days"):getPositionY()))
	-- 	label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
	-- 	small_node:addChild(label)

	-- end

	local info = player:getActivity(id)

	local av_conf = CONF.ACTIVITY.get(id)
	small_node:getChildByName("av_days_text"):setString(CONF:getStringValue("activity_time"))

	if av_conf.START_TIME ~= 0 and av_conf.START_TIME ~= 1 then

		local end_time = getTime(av_conf.END_TIME)
		local time = end_time - player:getServerTime()

		small_node:getChildByName("av_days"):setString(formatTime(time))
	elseif av_conf.START_TIME == 1 then

		local regist_time = player:getRegistTime()

		local diff_time = 0--regist_time%86400
		local end_time = regist_time + av_conf.END_TIME*86400 - diff_time

		local time = end_time - player:getServerTime()

		small_node:getChildByName("av_days"):setString(formatTime(time))
	else
		small_node:getChildByName("av_days_text"):setVisible(false)
		small_node:getChildByName("av_days"):setVisible(false)
	end

	small_node:getChildByName("av_days_text"):setPositionX(small_node:getChildByName("av_days"):getPositionX() - small_node:getChildByName("av_days"):getContentSize().width)

	small_node:setName("small_node")
	big_node:addChild(small_node)

	small_node:getChildByName("list"):setScrollBarEnabled(false)
	local svd = require("util.ScrollViewDelegate"):create(small_node:getChildByName("list"),cc.size(0,10), cc.size(787.60,100.0))

	if index <= 3 then
		local items = {}

		for i,v in ipairs(conf.GROUP) do

			local group_conf = CONF:getActivityItemConf(index).get(v)

			local sm_list_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SmallAvListItem.csb")

			local x,y = sm_list_node:getChildByName("item_pos"):getPosition()

			if index == CONF.EActivityGroup.kChange then

				local function getLimitNum( id )

					if info == nil then
						return 0 
					end

					for ii,vv in ipairs(info.change_data.limit_list) do
						if vv.key == id then
							return vv.value 
						end
					end

					return 0
				end

				sm_list_node:getChildByName("has_num"):setString(getLimitNum(v))
				sm_list_node:getChildByName("need_num"):setString("/"..group_conf.LIMIT)

				sm_list_node:getChildByName("has_num"):setPositionX(sm_list_node:getChildByName("need_num"):getPositionX() - sm_list_node:getChildByName("need_num"):getContentSize().width)

				local get = 1
				if getLimitNum(v) == group_conf.LIMIT then
					get = 2

					sm_list_node:getChildByName("button"):setEnabled(false)
					sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("YIDUIHUAN"))

					sm_list_node:getChildByName("button"):setVisible(false)
					sm_list_node:getChildByName("icon"):setVisible(true)
					-- sm_list_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
					sm_list_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("YIDUIHUAN"))

					sm_list_node:getChildByName("has_num"):setVisible(false)
					sm_list_node:getChildByName("need_num"):setVisible(false)
				else
					sm_list_node:getChildByName("button"):setEnabled(true)
					sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("DUIHUAN"))
				end

				sm_list_node:getChildByName("button"):addClickEventListener(function ( ... )

					local enough = true

					for i,v in ipairs(group_conf.COST_ITEM) do
						if player:getItemNumByID(v) < group_conf.COST_NUM[i] then
							enough = false
							break
						end
					end

					if enough then
						self.svd_Y = svd:getScrollView():getInnerContainer():getPositionY()

						local function func( ... )

							local strData = Tools.encode("ActivityChangeReq", {
								activity_id = id,
								change_item_id = v,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_CHANGE_REQ"),strData)

							gl:retainLoading()
						end

						if checkRewardBeMax(CONF.CHANGEITEM.get(v).GET_ITEM, CONF.CHANGEITEM.get(v).GET_NUM) then
							func()
						else
							local messageBox = require("util.MessageBox"):getInstance()

							messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
						end

					else
						tips:tips(CONF:getStringValue("Material_not_enought"))
					end
				end)

				local num = 1
				local diff = 100

				for i2,v2 in ipairs(group_conf.COST_ITEM) do
					local itemNode = require("app.ExResInterface"):getInstance():FastLoad("Common/ItemNode.csb")
					itemNode:setScale(0.8)
					local item_conf = CONF.ITEM.get(v2)

					itemNode:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..item_conf.QUALITY..".png")
					itemNode:getChildByName("icon"):loadTexture("ItemIcon/"..item_conf.ICON_ID..".png")

					local label1 = cc.Label:createWithTTF(formatRes(player:getItemNumByID(v2)), "fonts/cuyabra.ttf", 16)

					if player:getItemNumByID(v2)<group_conf.COST_NUM[i2] then
						label1:setTextColor(cc.c4b(255, 145, 136, 255))
						-- label1:enableShadow(cc.c4b(255, 145, 136, 255),cc.size(0.5,0.5))
					else 
						label1:setTextColor(cc.c4b(33, 255, 70, 255))
						-- label1:enableShadow(cc.c4b(33, 255, 70, 255),cc.size(0.5,0.5))
					end

					local label2 = cc.Label:createWithTTF("/"..formatRes(group_conf.COST_NUM[i2]), "fonts/cuyabra.ttf", 18)
					label2:setTextColor(cc.c4b(209, 209, 209, 255))
					-- label2:enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))

					local cw = label1:getContentSize().width + label2:getContentSize().width

					local posX,posY = itemNode:getChildByName("text"):getPosition()
					posX = posX - cw/2

					label1:setPosition(cc.p(posX + label1:getContentSize().width/2 , posY-2))
					posX = posX + label1:getContentSize().width
					label2:setPosition(cc.p(posX + label2:getContentSize().width/2 , posY-2))

					label1:setName("text_1")
					label2:setName("text_2")
					itemNode:addChild(label2)
					itemNode:addChild(label1)

					itemNode:getChildByName("icon"):addClickEventListener(function ( ... )
						addItemInfoTips(item_conf)
					end)

					itemNode:getChildByName("text"):setVisible(false)

					itemNode:setPosition(cc.p(x + (num -1)*diff ,y-3))

					sm_list_node:addChild(itemNode)

					num = num + 1
				end

				-- =
				local dengNode = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/dengNode.csb")
				dengNode:setPosition(cc.p(x + (num -1)*diff + 37,-48))
				sm_list_node:addChild(dengNode)

				num = num + 1

				for i2,v2 in ipairs(group_conf.GET_ITEM) do
					local itemNode = require("app.ExResInterface"):getInstance():FastLoad("Common/ItemNode.csb")
					itemNode:setScale(0.8)
					local item_conf = CONF.ITEM.get(v2)

					itemNode:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..item_conf.QUALITY..".png")
					itemNode:getChildByName("icon"):loadTexture("ItemIcon/"..item_conf.ICON_ID..".png")

					itemNode:getChildByName("text"):setString(group_conf.GET_NUM[i2])

					itemNode:getChildByName("icon"):addClickEventListener(function ( ... )
						addItemInfoTips(item_conf)
					end)

					itemNode:getChildByName("text"):setVisible(true)

					itemNode:setPosition(cc.p(x + (num -1)*diff ,y-3))

					sm_list_node:addChild(itemNode)

					num = num + 1
				end

				local tt = {item = sm_list_node, get = 2, index = i, can = 2}

				table.insert(items, tt)

			elseif index == CONF.EActivityGroup.kRecharge then

				local function getRewardNum( id )

					if info == nil then
						return false
					end

					for ii,vv in ipairs(info.recharge_data.getted_id_list) do
						if vv == id then
							return true
						end
					end

					return false
				end

				if info then
					sm_list_node:getChildByName("has_num"):setString(info.recharge_data.recharge_money)
				else
					sm_list_node:getChildByName("has_num"):setString(0)
				end

				sm_list_node:getChildByName("need_num"):setString("/"..group_conf.COST)
				if small_node:getChildByName('Text_1') then
					small_node:getChildByName('Text_1'):setString(CONF:getStringValue('top up recharge')..':'..player:getRechargeTotal())
				end
				local can = 1
				local get = 1

				if tonumber(sm_list_node:getChildByName("has_num"):getString()) < group_conf.COST then

					sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(255, 145, 136, 255))
					-- sm_list_node:getChildByName("has_num"):enableShadow(cc.c4b(255, 145, 136, 255),cc.size(0.5,0.5))

					sm_list_node:getChildByName("button"):setEnabled(false)
					sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))
					sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
					-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
				else
					if getRewardNum(v) then
						get = 2

						sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(209, 209, 209, 255))
						-- sm_list_node:getChildByName("has_num"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))

						sm_list_node:getChildByName("button"):setEnabled(false)
						sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
						sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
						-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))

						sm_list_node:getChildByName("button"):setVisible(false)
						sm_list_node:getChildByName("icon"):setVisible(true)
						-- sm_list_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
						sm_list_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("has_get"))

						sm_list_node:getChildByName("has_num"):setVisible(false)
						sm_list_node:getChildByName("need_num"):setVisible(false)
					else

						can = 2

						sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(33, 255, 70, 255))
						-- sm_list_node:getChildByName("has_num"):enableShadow(cc.c4b(33, 255, 70, 255),cc.size(0.5,0.5))

						sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))
					end
				end

				sm_list_node:getChildByName("has_num"):setPositionX(sm_list_node:getChildByName("need_num"):getPositionX() - sm_list_node:getChildByName("need_num"):getContentSize().width)

				sm_list_node:getChildByName("button"):addClickEventListener(function ( ... )

						

					local function func( ... )

						local strData = Tools.encode("ActivityRechargeReq", {
							activity_id = id,
							id = v,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_RECHARGE_REQ"),strData)

						gl:retainLoading()
					end

					if checkRewardBeMax(CONF.RECHARGEITEM.get(v).ITEM, CONF.RECHARGEITEM.get(v).NUM) then
						func()
					else
						local messageBox = require("util.MessageBox"):getInstance()

						messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
					end
					
				end)

				for i2,v2 in ipairs(group_conf.ITEM) do
					local itemNode = require("util.ItemNode"):create():init(v2, group_conf.NUM[i2])
					itemNode:setPosition(cc.p(x + (i2 -1)*80, y-3))

					sm_list_node:addChild(itemNode)
				end

				local tt = {item = sm_list_node, can = can , get=  get, index = i}
				table.insert(items, tt)

			elseif index == CONF.EActivityGroup.kConsume then
				local function getRewardNum( id )

					if info == nil then
						return false
					end

					for ii,vv in ipairs(info.consume_data.getted_id_list) do
						if vv == id then
							return true
						end
					end

					return false
				end

				if info then
					sm_list_node:getChildByName("has_num"):setString(info.consume_data.consume)
				else
					sm_list_node:getChildByName("has_num"):setString(0)
				end
				if small_node:getChildByName('Text_1') then
					small_node:getChildByName('Text_1'):setString(CONF:getStringValue('at consume')..':'..player:getConsumeTotal())
				end
				sm_list_node:getChildByName("need_num"):setString("/"..group_conf.CONSUME)

				local can = 1
				local get = 1

				if tonumber(sm_list_node:getChildByName("has_num"):getString()) < group_conf.CONSUME then

					sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(255, 145, 136, 255))
					-- sm_list_node:getChildByName("has_num"):enableShadow(cc.c4b(255, 145, 136, 255),cc.size(0.5,0.5))

					sm_list_node:getChildByName("button"):setEnabled(false)
					sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))
					sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
					-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
				else
					if getRewardNum(v) then
						get = 2

						sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(209, 209, 209, 255))
						sm_list_node:getChildByName("has_num"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
 
						sm_list_node:getChildByName("button"):setEnabled(false)
						sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("YIDUIHUAN"))
						sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
						-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))

						sm_list_node:getChildByName("button"):setVisible(false)
						sm_list_node:getChildByName("icon"):setVisible(true)
						-- sm_list_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
						sm_list_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("has_get"))

						sm_list_node:getChildByName("has_num"):setVisible(false)
						sm_list_node:getChildByName("need_num"):setVisible(false)
					else

						can = 2

						sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(33, 255, 70, 255))
						-- sm_list_node:getChildByName("has_num"):enableShadow(cc.c4b(33, 255, 70, 255),cc.size(0.5,0.5))

						sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))
					end
				end

				sm_list_node:getChildByName("has_num"):setPositionX(sm_list_node:getChildByName("need_num"):getPositionX() - sm_list_node:getChildByName("need_num"):getContentSize().width)

				sm_list_node:getChildByName("button"):addClickEventListener(function ( ... )

					local function func( ... )

						local strData = Tools.encode("ActivityConsumeReq", {
							activity_id = id,
							id = v,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_CONSUME_REQ"),strData)

						gl:retainLoading()
					end

					if checkRewardBeMax(CONF.CONSUMEITEM.get(v).ITEM, CONF.CONSUMEITEM.get(v).NUM) then
						func()
					else
						local messageBox = require("util.MessageBox"):getInstance()

						messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
					end
					
				end)

				for i2,v2 in ipairs(group_conf.ITEM) do
					local itemNode = require("util.ItemNode"):create():init(v2, group_conf.NUM[i2])
					itemNode:setPosition(cc.p(x + (i2 -1)*80, y-3))

					sm_list_node:addChild(itemNode)
				end

				local tt = {item = sm_list_node, can = can , get=  get, index = i}
				table.insert(items, tt)
			end

		end

		local function sort( a,b )
			if a.get ~= b.get then
				return a.get < b.get 
			else
				if a.can ~= b.can then
					return a.can > b.can 
				else
					return a.index < b.index
				end
			end
		end

		table.sort(items, sort)

		for i,v in ipairs(items) do
			svd:addElement(v.item)
		end

		if self.svd_Y then
			svd:getScrollView():getInnerContainer():setPositionY(self.svd_Y)
		end

	elseif index ==  CONF.EActivityGroup.kSevenDays then

		local day = big_node:getChildByName("list"):getTag()

		local items = {}
		for i,task_id in ipairs(CONF:getActivityConf(index).get(id)["DAY"..day]) do
			local taskConf = CONF:getActivityItemConf(index).get(task_id)

			local sm_list_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SmallAvListItem.csb")
			sm_list_node:getChildByName("text"):setString(CONF:getStringValue(taskConf.MEMO))
			sm_list_node:getChildByName("text"):setVisible(true)

			local get_reward = self:isGetReward(task_id, info)
			local achieved, cur, need = player:IsActivityAchieved(taskConf, info)
			--print("what ", taskConf.ID, achieved, cur, need, get_reward)
			
			sm_list_node:getChildByName("has_num"):setString(cur)
			sm_list_node:getChildByName("need_num"):setString("/"..need)

			sm_list_node:getChildByName("has_num"):setPositionX(sm_list_node:getChildByName("need_num"):getPositionX() - sm_list_node:getChildByName("need_num"):getContentSize().width)

			if get_reward then
				
				sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
				-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
				sm_list_node:getChildByName("button"):setEnabled(false)

				sm_list_node:getChildByName("button"):setVisible(false)
				sm_list_node:getChildByName("icon"):setVisible(true)
				-- sm_list_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
				sm_list_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("has_get"))

				sm_list_node:getChildByName("has_num"):setVisible(false)
					sm_list_node:getChildByName("need_num"):setVisible(false)
			else
				if achieved == false then
					--sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(255, 145, 136, 255))

					--sm_list_node:getChildByName("button"):setEnabled(false)
					--sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
					local conf = CONF.SEVENDAYSTASK.get(task_id)
					if conf and conf.TURN_TYPE then
						sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("go"))					
						sm_list_node:getChildByName("button"):setEnabled(true)
						sm_list_node:getChildByName("button"):addClickEventListener(function ()
							playEffectSound("sound/system/click.mp3")							
							goScene(conf.TURN_TYPE, conf.TURN_ID)
						end)
					else
						sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))
						sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(255, 145, 136, 255))
						sm_list_node:getChildByName("button"):setEnabled(false)
						sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
					end
				else
					sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))
					sm_list_node:getChildByName("button"):setEnabled(true)
					sm_list_node:getChildByName("button"):addClickEventListener(function ()
						self.touch_node = sm_list_node

						local function func( ... )

							local strData = Tools.encode("ActivitySevenDaysReq", {
								activity_id = id,
								task_id = task_id,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_SEVEN_DAYS_REQ"),strData)

							gl:retainLoading()
						end

						if checkRewardBeMax(CONF.SEVENDAYSTASK.get(task_id).ITEM_ID, CONF.SEVENDAYSTASK.get(task_id).ITEM_NUM) then
							func()
						else
							local messageBox = require("util.MessageBox"):getInstance()

							messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
						end
					end)
				end
			end

			--[[sm_list_node:getChildByName("button"):addClickEventListener(function ()
				self.touch_node = sm_list_node

				local function func( ... )

					local strData = Tools.encode("ActivitySevenDaysReq", {
						activity_id = id,
						task_id = task_id,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_SEVEN_DAYS_REQ"),strData)

					gl:retainLoading()
				end

				if checkRewardBeMax(CONF.SEVENDAYSTASK.get(task_id).ITEM_ID, CONF.SEVENDAYSTASK.get(task_id).ITEM_NUM) then
					func()
				else
					local messageBox = require("util.MessageBox"):getInstance()

					messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
				end
			end)]]

			local x,y = sm_list_node:getChildByName("item_pos"):getPosition()
			y = y - 20
			for i2,v2 in ipairs(taskConf.ITEM_ID) do
				local itemNode = require("util.ItemNode"):create():init(v2, taskConf.ITEM_NUM[i2])
				itemNode:setScale(0.8)
				itemNode:setPosition(cc.p(x + (i2 -1)*80, y))
				sm_list_node:addChild(itemNode)
			end

			local tt = {item = sm_list_node, get = (get_reward and 2 or 1), can = (achieved and 2 or 1), index = i}
			table.insert(items, tt)

		end

		local function sort( a,b )
			if a.get ~= b.get then
				return a.get < b.get 
			else
				if a.can ~= b.can then
					return a.can > b.can 
				else
					return a.index < b.index
				end
			end
		end

		table.sort(items, sort)

		for i,v in ipairs(items) do
			svd:addElement(v.item)
		end

	elseif index ==  CONF.EActivityGroup.kOnline then

		local function isGet( index )
			if player:getActivity(5001) == nil then
				return false
			end

			local get = false
			for i,v in ipairs(player:getActivity(5001).online_data.get_indexs) do
				if v == index then
					get = true
					break
				end
			end

			return get
		end

		local function isCan( type, time )
			
			local flag = false
			if type == 1 then

				flag = math.floor(player:getUserInfo().timestamp.today_online_time) >= time
			else

				local hh = player:getServerDate().hour

				if hh >= time[1] and hh <= time[2] then
					flag = true
				end
			end

			return flag

		end

		local items = {}
		for i,v in ipairs(conf.GROUP) do
			local taskConf = CONF:getActivityItemConf(index).get(v) 
			local sm_list_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SmallAvListItem.csb")

			-- if taskConf.TYPE == 1 then
			-- 	local min_time = taskConf.TIME/60
			-- 	-- sm_list_node:getChildByName("text"):setString(CONF:getStringValue(taskConf.TEXT[1])..min_time..CONF:getStringValue(taskConf.TEXT[2]))
			-- 	sm_list_node:getChildByName("text"):setString(taskConf.TIME)
			-- else
			-- 	sm_list_node:getChildByName("text"):setString(taskConf.TIME[1].."-"..taskConf.TIME[2])
			-- end
			-- sm_list_node:getChildByName("text"):setVisible(true)

			local strs = self:getPinStringNeedColor(CONF:getStringValue(taskConf.TEXT), taskConf.PARAM, taskConf.COLOR)

			local richText = createRichTextNeedChangeColor(strs)
			richText:setAnchorPoint(cc.p(0,1))
			richText:setPosition(cc.p(sm_list_node:getChildByName("text"):getPosition()))
			sm_list_node:addChild(richText)

			sm_list_node:getChildByName("has_num"):setVisible(false)
			sm_list_node:getChildByName("need_num"):setVisible(false)

			sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))

			sm_list_node:getChildByName("button"):addClickEventListener(function ()
				self.touch_node = sm_list_node

				local function func( ... )

					local strData = Tools.encode("ActivityOnlineReq", {
						activity_id = id,
						index = i,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_ONLINE_REQ"),strData)

					gl:retainLoading()
				end

				if checkRewardBeMax(CONF.ONLINEGROUP.get(i).ITEM, CONF.ONLINEGROUP.get(i).NUM) then
					func()
				else
					local messageBox = require("util.MessageBox"):getInstance()

					messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
				end
			end)

			if isGet(i) then
				
				sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
				-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
				sm_list_node:getChildByName("button"):setEnabled(false)

				sm_list_node:getChildByName("button"):setVisible(false)
				sm_list_node:getChildByName("icon"):setVisible(true)
				-- sm_list_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
				sm_list_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("has_get"))

				sm_list_node:getChildByName("has_num"):setVisible(false)
					sm_list_node:getChildByName("need_num"):setVisible(false)
			else
				
				sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))

				if isCan(taskConf.TYPE,taskConf.TIME) == false then
					sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(255, 145, 136, 255))
					-- sm_list_node:getChildByName("has_num"):enableShadow(cc.c4b(255, 145, 136, 255),cc.size(0.5,0.5))

					sm_list_node:getChildByName("button"):setEnabled(false)
					sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
					-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
				end
			end

			local x,y = sm_list_node:getChildByName("item_pos"):getPosition()
			y = y - 20
			for i2,v2 in ipairs(taskConf.ITEM) do
				local itemNode = require("util.ItemNode"):create():init(v2, taskConf.NUM[i2])
				itemNode:setScale(0.8)
				itemNode:setPosition(cc.p(x + (i2 -1)*80, y))
				sm_list_node:addChild(itemNode)
			end

			local can = 1
			if taskConf.TYPE == 1 then
				if isCan(taskConf.TYPE,taskConf.TIME) then
					can = 2
				end
			else
				if isCan(taskConf.TYPE,taskConf.TIME) then
					can = 3
				end
			end

			local tt = {item = sm_list_node, get = (isGet(i) and 2 or 1), can = can, index = i}
			table.insert(items, tt)

		end

		local function sort( a,b )

			if a.get ~= b.get then
				return a.get < b.get 
			else
				if a.can ~= b.can then
					return a.can > b.can 
				else
					return a.index < b.index
				end
			end
		end

		table.sort(items, sort)

		for i,v in ipairs(items) do
			svd:addElement(v.item)
		end

	elseif index == CONF.EActivityGroup.kPower then
		local function isGet( index )
			if player:getActivity(10001) == nil then
				return false
			end

			local get = false
			for i,v in ipairs(player:getActivity(10001).power_data.get_indexs) do
				if v == index then
					get = true
					break
				end
			end

			return get
		end

		local function isCan( power )
			
			local flag = false
			if player:getPower() >=  power then
				flag = true
			end

			return flag

		end

		local items = {}
		for i,v in ipairs(conf.GROUP) do
			local taskConf = CONF:getActivityItemConf(index).get(v) 
			local sm_list_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SmallAvListItem.csb")

			local strs = self:getPinStringNeedColor(CONF:getStringValue(taskConf.TEXT), taskConf.PARAM, taskConf.COLOR)

			local richText = createRichTextNeedChangeColor(strs)
			richText:setAnchorPoint(cc.p(0,1))
			richText:setPosition(cc.p(sm_list_node:getChildByName("text"):getPosition()))
			sm_list_node:addChild(richText)

			
			-- sm_list_node:getChildByName("text"):setVisible(true)

			sm_list_node:getChildByName("has_num"):setVisible(false)
			sm_list_node:getChildByName("need_num"):setVisible(false)

			sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))

			sm_list_node:getChildByName("button"):addClickEventListener(function ()
				self.touch_node = sm_list_node

				local function func( ... )
					
					local strData = Tools.encode("ActivityPowerReq", {
						activity_id = id,
						index = i,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_POWER_REQ"),strData)

					gl:retainLoading()
				end

				if checkRewardBeMax(CONF.POWERGROUP.get(i).ITEM, CONF.POWERGROUP.get(i).NUM) then
					func()
				else
					local messageBox = require("util.MessageBox"):getInstance()

					messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
				end
			end)

			if isGet(i) then
				
				sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
				-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
				sm_list_node:getChildByName("button"):setEnabled(false)

				sm_list_node:getChildByName("button"):setVisible(false)
				sm_list_node:getChildByName("icon"):setVisible(true)
				-- sm_list_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
				sm_list_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("has_get"))


			else
				
				sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))

				if isCan(taskConf.POWER) == false then
					sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(255, 145, 136, 255))
					-- sm_list_node:getChildByName("has_num"):enableShadow(cc.c4b(255, 145, 136, 255),cc.size(0.5,0.5))

					sm_list_node:getChildByName("button"):setEnabled(false)
					sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
					-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
				end
			end

			local x,y = sm_list_node:getChildByName("item_pos"):getPosition()
			y = y - 20
			for i2,v2 in ipairs(taskConf.ITEM) do
				local itemNode = require("util.ItemNode"):create():init(v2, taskConf.NUM[i2])
				itemNode:setScale(0.8)
				itemNode:setPosition(cc.p(x + (i2 -1)*80, y))
				sm_list_node:addChild(itemNode)
			end


			local tt = {item = sm_list_node, get = (isGet(i) and 2 or 1), can = (isCan(taskConf.POWER) and 2 or 1), index = i}
			table.insert(items, tt)

		end

		local function sort( a,b )

			if a.get ~= b.get then
				return a.get < b.get 
			else
				if a.can ~= b.can then
					return a.can > b.can 
				else
					return a.index < b.index
				end
			end
		end

		table.sort(items, sort)

		for i,v in ipairs(items) do
			svd:addElement(v.item)
		end

	elseif index == CONF.EActivityGroup.kGrowthFund then

		small_node:getChildByName("av_ins"):setString("")

		local text_size = small_node:getChildByName("av_ins"):getContentSize()

		local strs = self:getPinStringNeedColor(CONF:getStringValue(conf.MEMO), conf.PARAM, conf.COLOR)
		local richText = createRichTextNeedChangeColor(strs)
		richText:setAnchorPoint(cc.p(0,1))
		richText:setContentSize(cc.size(text_size.width,text_size.height))
		richText:ignoreContentAdaptWithSize(false) 
		richText:setPosition(cc.p(small_node:getChildByName("av_ins"):getPosition()))
		small_node:addChild(richText)

		small_node:getChildByName("button"):setVisible(true)

		if player:getActivity(12001) and player:getActivity(12001).growth_fund_data.purchased then
			small_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("yi_buy"))
			small_node:getChildByName("button"):setEnabled(false)

			small_node:getChildByName("button"):setVisible(false)
			small_node:getChildByName("get_node"):setVisible(true)
			small_node:getChildByName("get_node"):getChildByName("text"):setString(CONF:getStringValue("yi_buy"))
		else
			small_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Buy"))

			small_node:getChildByName("button"):addClickEventListener(function ( ... )

				if player:getMoney() < conf.PRICE then
				-- tips:tips(CONF:getStringValue("no enought credit"))

					local function func()
						local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

						rechargeNode:init(self, {index = 1})
						self:addChild(rechargeNode)
					end

					local messageBox = require("util.MessageBox"):getInstance()
					messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
					return
				end

				local function buy_fund( ... )
					self.fund_type = 1

					local function func( ... )
						
						local strData = Tools.encode("ActivityGrowthFundReq", {
							activity_id = id,
							type = 1,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_GROWTH_FUND_REQ"),strData)

						gl:retainLoading()
					end

					-- if checkRewardBeMax(CONF.FUNDGROUP.get(i).ITEM, CONF.FUNDGROUP.get(i).NUM) then
						func()
					-- else
						-- local messageBox = require("util.MessageBox"):getInstance()

						-- messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
					-- end

				end
				-- playEffectSound("sound/system/click.mp3")
				-- messageBox:reset(CONF:getStringValue("building_level_text_confirm"), buy_fund)

				local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("building_level_text_confirm"), conf.PRICE, buy_fund)

				self:addChild(node)
				tipsAction(node)
				
			end)
		end

		local function isGet( index )
			if player:getActivity(12001) == nil then
				return false
			end

			local get = false
			for i,v in ipairs(player:getActivity(12001).growth_fund_data.get_indexs) do
				if v == index then
					get = true
					break
				end
			end

			return get
		end

		local function isCan( level )

			if player:getActivity(12001) == nil then
				return false
			end
			
			local flag = false

			if player:getActivity(12001).growth_fund_data.purchased then
				if player:getBuildingInfo(1).level >=  level then
					flag = true
				end
			end

			return flag

		end

		local items = {}
		for i,v in ipairs(conf.GROUP) do
			local taskConf = CONF:getActivityItemConf(index).get(v) 
			local sm_list_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SmallAvListItem.csb")

			local strs = self:getPinStringNeedColor(CONF:getStringValue(taskConf.TEXT), taskConf.PARAM, taskConf.COLOR)

			-- local strs = ""
			local richText = createRichTextNeedChangeColor(strs)
			richText:setAnchorPoint(cc.p(0,1))
			richText:setPosition(cc.p(sm_list_node:getChildByName("text"):getPosition()))
			sm_list_node:addChild(richText)

			
			-- sm_list_node:getChildByName("text"):setVisible(true)

			sm_list_node:getChildByName("has_num"):setVisible(false)
			sm_list_node:getChildByName("need_num"):setVisible(false)

			sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))

			sm_list_node:getChildByName("button"):addClickEventListener(function ()
				self.touch_node = sm_list_node
				self.fund_type = 2
	
				local function func( ... )
						
					local strData = Tools.encode("ActivityGrowthFundReq", {
						activity_id = id,
						type = 2,
						index = i,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_GROWTH_FUND_REQ"),strData)

					-- gl:retainLoading()
				end

				if checkRewardBeMax(CONF.FUNDGROUP.get(i).ITEM, CONF.FUNDGROUP.get(i).NUM) then
					func()
				else
					local messageBox = require("util.MessageBox"):getInstance()

					messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
				end

				gl:retainLoading()
			end)

			if isGet(i) then
				
				sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
				-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
				sm_list_node:getChildByName("button"):setEnabled(false)

				sm_list_node:getChildByName("button"):setVisible(false)
				sm_list_node:getChildByName("icon"):setVisible(true)
				-- sm_list_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
				sm_list_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("has_get"))

				sm_list_node:getChildByName("has_num"):setVisible(false)
					sm_list_node:getChildByName("need_num"):setVisible(false)
			else
				
				sm_list_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))

				if isCan(taskConf.LEVEL) == false then
					sm_list_node:getChildByName("has_num"):setTextColor(cc.c4b(255, 145, 136, 255))
					-- sm_list_node:getChildByName("has_num"):enableShadow(cc.c4b(255, 145, 136, 255),cc.size(0.5,0.5))

					sm_list_node:getChildByName("button"):setEnabled(false)
					sm_list_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
					-- sm_list_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
				end
			end

			local x,y = sm_list_node:getChildByName("item_pos"):getPosition()
			y = y - 20
			for i2,v2 in ipairs(taskConf.ITEM) do
				local itemNode = require("util.ItemNode"):create():init(v2, formatRes(taskConf.NUM[i2]))
				itemNode:setScale(0.8)
				itemNode:setPosition(cc.p(x + (i2 -1)*80, y))
				sm_list_node:addChild(itemNode)
			end


			local tt = {item = sm_list_node, get = (isGet(i) and 2 or 1), can = (isCan(taskConf.LEVEL) and 2 or 1), index = i}
			table.insert(items, tt)

		end

		local function sort( a,b )

			if a.get ~= b.get then
				return a.get < b.get 
			else
				if a.can ~= b.can then
					return a.can > b.can 
				else
					return a.index < b.index
				end
			end
		end

		table.sort(items, sort)

		for i,v in ipairs(items) do
			svd:addElement(v.item)
		end

	end

end

function ActivityScene:createMonthNode(flag)

	local rn = self:getResourceNode()

	-- local big_node = rn:getChildByName("node"):getChildByName("big_node")

	-- if big_node then
	-- 	big_node:removeFromParent()
	-- end

	for i,v in ipairs(rn:getChildByName("node"):getChildren()) do
		if v:getName() ~= "month_node" then
			v:removeFromParent()
		end
	end

	if rn:getChildByName("month_node") and (flag == nil or flag == false) then
		return
	end

	if flag and rn:getChildByName("node"):getChildByName("month_node") then
		rn:getChildByName("node"):getChildByName("month_node"):removeFromParent()
	end

	if flag == nil or flag == false then
		self.svd_Y = nil
	end

	local id = 14001

	local conf = CONF.ACTIVITYMONTHSIGN.get(id)
	local info = player:getActivity(id)
	local av_conf = CONF.ACTIVITY.get(id)

	local player_vip = player:getUserInfo().vip_level

	local buqian_num = 0

	if info then
		buqian_num = info.month_sign_data.resign_times 
	end
	local can_buqian_num = CONF.VIP.get(player:getVipLevel()).RESIGN - buqian_num

	local month_node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/MonthNode.csb")
	month_node:setName("month_node")
	rn:getChildByName("node"):addChild(month_node)

	month_node:getChildByName("cur_active"):setString(CONF:getStringValue("monthsign_text"))
	month_node:getChildByName("cur_s_active"):setString(CONF:getStringValue("residue_signin"))

	month_node:getChildByName("day_1"):setString(CONF:getStringValue("Sunday"))
	month_node:getChildByName("day_2"):setString(CONF:getStringValue("Monday"))
	month_node:getChildByName("day_3"):setString(CONF:getStringValue("Tuesday"))
	month_node:getChildByName("day_4"):setString(CONF:getStringValue("Wednesday"))
	month_node:getChildByName("day_5"):setString(CONF:getStringValue("Thursday"))
	month_node:getChildByName("day_6"):setString(CONF:getStringValue("Friday"))
	month_node:getChildByName("day_7"):setString(CONF:getStringValue("Saturday"))

	local function getBoxNum( index )
		if index <= 3 then
			return index
		elseif index == 4 then
			return 3

		elseif index == 5 then
			return 4
		end
	end

	local function getSignNum( ... )
		if info == nil then
			return 0
		else
			local num = 0
			for i,v in ipairs(info.month_sign_data.get_nums) do
				if v > 0 then
					num = num + 1
				end
			end

			return num
		end
	end

	month_node:getChildByName("cur_active_num"):setString(getSignNum())
	month_node:getChildByName("cur_active_num"):setPositionX(month_node:getChildByName("cur_active"):getPositionX() + month_node:getChildByName("cur_active"):getContentSize().width)

	month_node:getChildByName("cur_s_active_num"):setString(can_buqian_num)
	month_node:getChildByName("cur_s_active"):setPositionX(month_node:getChildByName("cur_s_active_num"):getPositionX() - month_node:getChildByName("cur_s_active_num"):getContentSize().width)

	local function checkBuQian( index )
		if info == nil then
			if index == 1 then
				return true
			else
				return false
			end
		else
			local num = 0
			for i,v in ipairs(info.month_sign_data.get_nums) do
				if v == 0 then
					num = i 
					break
				end
			end

			if num < index then
				return false
			else
				return true
			end
		end
	end

	for i=1,5 do
		local box = month_node:getChildByName("actives"):getChildByName("active_"..i)
		box:getChildByName("btn"):loadTextures("TaskScene/ui/active_"..getBoxNum(i)..".png", "TaskScene/ui/active_select_"..getBoxNum(i)..".png","TaskScene/ui/active_gray_"..getBoxNum(i)..".png")
		box:getChildByName("num"):setString(conf["SIGN"..i])

		local get = false

		if info then
			for i2,v2 in ipairs(info.month_sign_data.get_rewards) do
				if i == i2 then
					get = v2
					break
				end
			end
		end

		if getSignNum() < conf["SIGN"..i] then --不能领

			animManager:runAnimOnceByCSB(box,"TaskScene/ActiveIcon.csb" ,"unopen")

		elseif getSignNum() >= conf["SIGN"..i] and get == false then --可以领取

			animManager:runAnimByCSB(box, "TaskScene/ActiveIcon.csb" , "get")

		else--已经领取
			animManager:runAnimOnceByCSB(box, "TaskScene/ActiveIcon.csb" , "getted")
			box:getChildByName("btn"):setEnabled(false)
		end

		local ttt = 0

		box:getChildByName("btn"):addClickEventListener(function ( ... )

			self.reward_ = {}
			-- self.reward_ = {{id = conf["ITEM"..i], num = conf["NUM"..i]}}

			for i2,v2 in ipairs(conf["ITEM"..i]) do
				local tt = {id = v2, num = conf["NUM"..i][i2]}
				table.insert(self.reward_, tt)
			end

			local func 

			if info == nil then
				func = function ( ... )
					
				end

			else

				local has = false
				for i2,v2 in ipairs(info.month_sign_data.get_rewards) do
					if i == v2 then
						has = true
						break
					end
				end

				if has then
					func = function ( ... )
						
					end
				else
					if getSignNum() >= conf["SIGN"..i] then

						ttt = 1

						func = function ( ... )
							local strData = Tools.encode("ActivityMonthSignReq", {
								activity_id = id,
								type = 2,
								index = i,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_MONTH_SIGN_REQ"),strData)

							gl:retainLoading()
						end
					else
						func = function ( ... )
							-- body
						end
					end
				end

			end

			local node = require("util.RewardNode"):createNodeWithList(self.reward_, 1, func)	
			tipsAction(node)
			node:setPosition(cc.exports.VisibleRect:center())
			node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))

			if ttt == 1 then
				node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("Get"))
			end

			node:setName("reward_node")
			self:addChild(node)
			
		end)
	end

	month_node:getChildByName("active_progress"):setPercent(getSignNum() / conf.SIGN5 * 100)
	
	month_node:getChildByName("list"):setScrollBarEnabled(false)
	local svd = require("util.ScrollViewDelegate"):create(month_node:getChildByName("list"),cc.size(5,10), cc.size(95,105))


	local function createItem( index, item_id, item_num, vip )
		local item = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/MonthItem.csb")

		local item_conf = CONF.ITEM.get(item_id)

		item:getChildByName("icon_di"):setTexture("RankLayer/ui/ui_avatar_"..item_conf.QUALITY..".png")
		item:getChildByName("icon"):loadTexture("ItemIcon/"..item_conf.ICON_ID..".png")
		item:getChildByName("num"):setString(item_num)
		item:setTag(index)

		item:getChildByName("buqian"):setString(CONF:getStringValue("repair_signin"))

		if vip > 0 then
			item:getChildByName("vip_di"):setVisible(true)
			item:getChildByName("vip_num"):setVisible(true)
			item:getChildByName("vvip_num"):setVisible(true)

			item:getChildByName("vip_num"):setString("V"..vip)
		end

		if info == nil then

			if index < player:getServerDate().day then
				item:getChildByName("black"):setVisible(true)
				item:getChildByName("buqian_di"):setVisible(true)
				item:getChildByName("buqian"):setVisible(true)
			elseif index == player:getServerDate().day then
				item:getChildByName("select"):setVisible(true)

				item:getChildByName("texiao"):setVisible(true)

				animManager:runAnimByCSB(item:getChildByName("texiao"), "ActivityScene/sfx/qiandao/qiandao.csb", "1")

				item:getChildByName("text"):setVisible(true)
				item:getChildByName("text"):setString(CONF:getStringValue("click_get"))
			else

			end

		else

			if index < player:getServerDate().day then
				item:getChildByName("black"):setVisible(true)

				if info.month_sign_data.get_nums[index] == 0 then
					item:getChildByName("buqian_di"):setVisible(true)
					item:getChildByName("buqian"):setVisible(true)
				elseif info.month_sign_data.get_nums[index] == 1 then

					if vip > 0 then
						if player_vip < vip then
							item:getChildByName("ok"):setVisible(true)
						else
							item:getChildByName("buqian_di"):setVisible(true)
							item:getChildByName("buqian"):setVisible(true)
						end
					else
						item:getChildByName("ok"):setVisible(true)
					end
				else
					item:getChildByName("ok"):setVisible(true)
				end
			elseif index == player:getServerDate().day then
				item:getChildByName("select"):setVisible(true)
				item:getChildByName("texiao"):setVisible(true)

				animManager:runAnimByCSB(item:getChildByName("texiao"), "ActivityScene/sfx/qiandao/qiandao.csb", "1")

				if info.month_sign_data.get_nums[index] == 0 then
					item:getChildByName("text"):setVisible(true)
					item:getChildByName("text"):setString(CONF:getStringValue("click_get"))
				elseif info.month_sign_data.get_nums[index] == 1 then

					if vip > 0 then
						if player_vip < vip then
							item:getChildByName("black"):setVisible(true)
							item:getChildByName("ok"):setVisible(true)
							item:getChildByName("select"):setVisible(false)
							item:getChildByName("texiao"):setVisible(false)
						else
							-- item:getChildByName("buqian_di"):setVisible(true)
							-- item:getChildByName("buqian"):setVisible(true)
							item:getChildByName("text"):setVisible(true)
							item:getChildByName("text"):setString(CONF:getStringValue("continue_get"))
						end
					else
						item:getChildByName("black"):setVisible(true)
						item:getChildByName("ok"):setVisible(true)
						item:getChildByName("select"):setVisible(false)
						item:getChildByName("texiao"):setVisible(false)
					end
				else
					item:getChildByName("black"):setVisible(true)
					item:getChildByName("ok"):setVisible(true)
					item:getChildByName("select"):setVisible(false)
					item:getChildByName("texiao"):setVisible(false)
				end
			else

			end

		end

		return item

	end

	local function createNullItem( ... )
		local item = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/MonthItem.csb")

		item:getChildByName("back"):setVisible(false)
		item:getChildByName("icon_di"):setVisible(false)
		item:getChildByName("icon"):setVisible(false)
		item:getChildByName("num"):setVisible(false)

		item:getChildByName("black"):setVisible(false)
		item:getChildByName("Image_1"):setVisible(false)
		item:getChildByName("Image_2"):setVisible(false)
		item:getChildByName("select"):setVisible(false)
		return item
	end

	local day_data = player:getServerDate()
--    local day_data = os.date("*t",os.time())
--	local diff_day = day_data.day - 1
--	local diff_w = diff_day%7
--	local wday = (day_data.wday - diff_w) %7

    local firstweek_days = 0 -- 求出每个月第一周有几天
    if day_data.day - day_data.wday < 0 then
        firstweek_days = 7 - day_data.wday + 1
    elseif day_data.day - day_data.wday == 0 then
        firstweek_days = 7
    else
        firstweek_days = (day_data.day - day_data.wday)%7
    end

    local null_num = 7 - firstweek_days -- 第一行空几天
	if null_num > 1 then
		for i=1,null_num do
			local item = createNullItem()
			svd:addElement(item)
		end
	end
    -- 算出每月天数
    local monthday = {31,28,31,30,31,30,31,31,30,31,30,31}
    if day_data.year % 4 == 0 and day_data.year % 100 ~= 0 then
        monthday[2] = 29
    end

	for i,v in ipairs(conf.GROUP) do
        if i > monthday[day_data.month] then
            break
        end
		local cc_conf = CONF.MONTHSIGNGROUP.get(v)

		local item = createItem(i,cc_conf.ITEM,cc_conf.NUM,cc_conf.VIP)
		local func = function ( ... )

			self.reward_ = {}
			self.reward_ = {{id = cc_conf.ITEM, num = cc_conf.NUM}}

			if info == nil then
				if i == day_data.day then 
					local strData = Tools.encode("ActivityMonthSignReq", {
						activity_id = id,
						type = 1,
						index = i,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_MONTH_SIGN_REQ"),strData)

					gl:retainLoading()

				elseif i < day_data.day then

					if checkBuQian(i) == false then
						tips:tips(CONF:getStringValue("mend_signin"))
						return
					end


					if can_buqian_num > 0 then
						local strData = Tools.encode("ActivityMonthSignReq", {
							activity_id = id,
							type = 1,
							index = i,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_MONTH_SIGN_REQ"),strData)

						gl:retainLoading()
					else
						tips:tips(CONF:getStringValue("times_not_enought"))
					end
				else
					local info_node = require("util.ItemInfoNode"):createItemInfoNode(cc_conf.ITEM, CONF.ITEM.get(cc_conf.ITEM).TYPE)
					info_node:setPosition(cc.exports.VisibleRect:center())
					info_node:setName("info_node")
					self:addChild(info_node, SceneZOrder.kItemInfo)
				end
			else

				if i < day_data.day then

					if player_vip >= cc_conf.VIP and cc_conf.VIP > 0 then
						if info.month_sign_data.get_nums[i] == 0 or info.month_sign_data.get_nums[i] == 1 then

							if checkBuQian(i) == false then
								tips:tips(CONF:getStringValue("mend_signin"))
								return
							end

							if can_buqian_num > 0 then
								local strData = Tools.encode("ActivityMonthSignReq", {
									activity_id = id,
									type = 1,
									index = i,
								})
								GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_MONTH_SIGN_REQ"),strData)

								gl:retainLoading()
							else
								tips:tips(CONF:getStringValue("times_not_enought"))
							end

						end
					else

						if info.month_sign_data.get_nums[i] == 0 then

							if checkBuQian(i) == false then
								tips:tips(CONF:getStringValue("mend_signin"))
								return
							end

							if can_buqian_num > 0 then
								local strData = Tools.encode("ActivityMonthSignReq", {
									activity_id = id,
									type = 1,
									index = i,
								})
								GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_MONTH_SIGN_REQ"),strData)

								gl:retainLoading()
							else
								tips:tips(CONF:getStringValue("times_not_enought"))
							end

						end

					end

				elseif i == day_data.day then

					if player_vip >= cc_conf.VIP and cc_conf.VIP > 0 then
						if info.month_sign_data.get_nums[i] == 0 or info.month_sign_data.get_nums[i] == 1 then
							local strData = Tools.encode("ActivityMonthSignReq", {
								activity_id = id,
								type = 1,
								index = i,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_MONTH_SIGN_REQ"),strData)

							gl:retainLoading()
							
						end
					else
						if info.month_sign_data.get_nums[i] == 0 then
							local strData = Tools.encode("ActivityMonthSignReq", {
								activity_id = id,
								type = 1,
								index = i,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_MONTH_SIGN_REQ"),strData)

							gl:retainLoading()
							
						end
					end
				else
					local info_node = require("util.ItemInfoNode"):createItemInfoNode(cc_conf.ITEM, CONF.ITEM.get(cc_conf.ITEM).TYPE)
					info_node:setPosition(cc.exports.VisibleRect:center())
					info_node:setName("info_node")
					self:addChild(info_node, SceneZOrder.kItemInfo)
				end
			end
		end

		local callback = {node = item:getChildByName("back"), func = func}

		svd:addElement(item, {callback = callback})
	end
end

function ActivityScene:createChangeShip( flag )
	local rn = self:getResourceNode()

	-- local big_node = rn:getChildByName("node"):getChildByName("big_node")

	-- if big_node then
	-- 	big_node:removeFromParent()
	-- end

	for i,v in ipairs(rn:getChildByName("node"):getChildren()) do
		if v:getName() ~= "change_ship_node" then
			v:removeFromParent()
		end
	end

	if rn:getChildByName("change_ship_node") and (flag == nil or flag == false) then
		return
	end

	if flag and rn:getChildByName("node"):getChildByName("change_ship_node") then
		rn:getChildByName("node"):getChildByName("change_ship_node"):removeFromParent()
	end

	if flag == nil or flag == false then
		self.svd_Y = nil
	end

	local id = 15001

	local conf = CONF.ACTIVITYCHANGESHIP.get(id)
	local info = player:getActivity(id)
	local av_conf = CONF.ACTIVITY.get(id)

	local setInNode = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SetInNode.csb")
	setInNode:setName("change_ship_node")
	rn:getChildByName("node"):addChild(setInNode)

	setInNode:getChildByName("av_days_text"):setString(CONF:getStringValue("activity_time"))

	if av_conf.START_TIME ~= 0 and av_conf.START_TIME ~= 1 then

		local end_time = getTime(av_conf.END_TIME)
		local time = end_time - player:getServerTime()

		setInNode:getChildByName("av_days"):setString(formatTime(time))
	elseif av_conf.START_TIME == 1 then

		local regist_time = player:getRegistTime()

		local diff_time = 0--regist_time%86400
		local end_time = regist_time + av_conf.END_TIME*86400 - diff_time

		local time = end_time - player:getServerTime()

		setInNode:getChildByName("av_days"):setString(formatTime(time))
	else
		setInNode:getChildByName("av_days_text"):setVisible(false)
		setInNode:getChildByName("av_days"):setVisible(false)
	end

	setInNode:getChildByName("av_days_text"):setPositionX(setInNode:getChildByName("av_days"):getPositionX() - setInNode:getChildByName("av_days"):getContentSize().width)

	setInNode:getChildByName("av_ins"):setString(CONF:getStringValue("convert_text"))
	setInNode:getChildByName("ship_btn"):getChildByName("text"):setString(CONF:getStringValue("compound"))
	setInNode:getChildByName("ship_btn"):addClickEventListener(function ( ... )
		-- self:getApp():pushView("ShipDevelopScene/ShipDevelopScene")
		self:getApp():removeTopView()
	end)
	setInNode:getChildByName("ship_btn"):setVisible(false)

	setInNode:getChildByName("title_text"):setString(CONF:getStringValue("ACTI_11_text"))

	local strs = self:getPinStringNeedColorString(CONF:getStringValue("ACTI_11_text2"), conf.PARAM, conf.COLOR)

	local richText = createRichTextNeedChangeColor(strs)
	richText:setAnchorPoint(cc.p(1,0.5))
	richText:setPosition(cc.p(setInNode:getChildByName("get_ship_text"):getPosition()))
	setInNode:addChild(richText)

	setInNode:getChildByName("get_ship_text"):setVisible(false)

	local all_get = true
	for i,v in ipairs(conf.CHANGE_LIST) do
		local item = setInNode:getChildByName("item_"..i)
		local ship_conf = CONF.AIRSHIP.get(v)

		item:getChildByName("background"):loadTexture("RankLayer/ui/ui_avatar_"..ship_conf.QUALITY..".png")
		item:getChildByName("icon"):setTexture("ShipImage/"..ship_conf.DRIVER_ID..".png")

		if player:getShipByID(v) then
			item:getChildByName("gou"):setVisible(true)
		else
			item:getChildByName("background"):setOpacity(255*0.5)
			item:getChildByName("icon"):setOpacity(255*0.5)

			all_get = false
		end

		item:getChildByName("background"):addClickEventListener(function ( ... )
			local info_node = require("util.ItemInfoNode"):createShipInfoNode(v)
	        info_node:setPosition(cc.exports.VisibleRect:center())
	        local center = cc.exports.VisibleRect:center()
        	local bg = info_node:getChildByName("landi")
        	info_node:setPosition(cc.p(center.x - bg:getContentSize().width/2*bg:getScaleX(), center.y + bg:getContentSize().height/2*bg:getScaleY()))
	        info_node:setName("info_node")
	        self:addChild(info_node, SceneZOrder.kItemInfo)
		end)
	end

	local panel = setInNode:getChildByName("Panel")

	local get_ship_conf = CONF.AIRSHIP.get(conf.GET)
	panel:getChildByName("hero"):setTexture("RoleImage/"..get_ship_conf.DRIVER_ID..".png")
	panel:getChildByName("ship"):setTexture("ShipImage/"..get_ship_conf.DRIVER_ID..".png")

	setInNode:getChildByName("touch"):addClickEventListener(function ( ... )
		local info_node = require("util.ItemInfoNode"):createShipInfoNode(conf.GET)
        info_node:setPosition(cc.exports.VisibleRect:center())
        local center = cc.exports.VisibleRect:center()
    	local bg = info_node:getChildByName("landi")
    	info_node:setPosition(cc.p(center.x - bg:getContentSize().width/2*bg:getScaleX(), center.y + bg:getContentSize().height/2*bg:getScaleY()))
        info_node:setName("info_node")
        self:addChild(info_node, SceneZOrder.kItemInfo)
	end)

	setInNode:getChildByName("get_btn"):getChildByName("text"):setString(CONF:getStringValue("Get"))

	setInNode:getChildByName("get_btn"):addClickEventListener(function ( ... )
		local strData = Tools.encode("ActivityChangeShipReq", {
			activity_id = id,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_CHANGE_SHIP_REQ"),strData)

		gl:retainLoading()
	end)

	if info == nil then
		if all_get then

		else
			setInNode:getChildByName("get_btn"):setEnabled(false)
		end
	else
		if info.change_ship_data.getted_reward then
			setInNode:getChildByName("get_btn"):setVisible(false)
			setInNode:getChildByName("get_node"):setVisible(true)
			setInNode:getChildByName("get_node"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
		else
			if all_get then

			else
				setInNode:getChildByName("get_btn"):setEnabled(false)
			end
		end

	end

end

function ActivityScene:createInvestNode( flag )
	local rn = self:getResourceNode()

	-- local big_node = rn:getChildByName("node"):getChildByName("big_node")

	-- if big_node then
	-- 	big_node:removeFromParent()
	-- end

	for i,v in ipairs(rn:getChildByName("node"):getChildren()) do
		if v:getName() ~= "invest_node" then
			v:removeFromParent()
		end
	end

	if rn:getChildByName("invest_node") and (flag == nil or flag == false) then
		return
	end

	if flag and rn:getChildByName("node"):getChildByName("invest_node") then
		rn:getChildByName("node"):getChildByName("invest_node"):removeFromParent()
	end

	if flag == nil or flag == false then
		self.svd_Y = nil
	end

	local id = 13001

	local conf = CONF.ACTIVITYINVEST.get(id)
	local info = player:getActivity(id)
	local av_conf = CONF.ACTIVITY.get(id)

	local investNode = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/InvestNode.csb")
	investNode:setName("invest_node")
	rn:getChildByName("node"):addChild(investNode)

	local panel = investNode:getChildByName("Panel")

	local player_icon = math.floor(player:getPlayerIcon()/100)
	panel:getChildByName("hero"):setTexture("HeroImage/"..player_icon..".png")

	local invest_index = 1
	if info then
		invest_index = info.invest_data.index + 1
	end
	local function setObjVisible(v)
		investNode:getChildByName("invest_btn"):setVisible(v)
		-- investNode:getChildByName("invest_text"):setVisible(v)
		investNode:getChildByName("invest_num"):setVisible(v)
		investNode:getChildByName("money_text"):setVisible(v)
		investNode:getChildByName("money_num"):setVisible(v)
		investNode:getChildByName("money_icon"):setVisible(v)
		investNode:getChildByName("time_text"):setVisible(v)
		investNode:getChildByName("time_num"):setVisible(v)
	end
	
	if CONF.INVESTGROUP.check(invest_index) then
		local group_conf = CONF.INVESTGROUP.get(invest_index)
		investNode:getChildByName("invest_text"):setString(CONF:getStringValue("ACTI_8_text1"))
		investNode:getChildByName("money_text"):setString(CONF:getStringValue("ACTI_8_text3"))
		investNode:getChildByName("time_text"):setString(CONF:getStringValue("ACTI_8_text4"))
		investNode:getChildByName("ins_text"):setString(CONF:getStringValue("ACTI_8_text2"))
		investNode:getChildByName("invest_btn"):getChildByName("text"):setString(CONF:getStringValue("ACTI_8_text5"))

		investNode:getChildByName("invest_num"):setString(group_conf.EARNING[1].."%-"..group_conf.EARNING[#group_conf.EARNING].."%")
		investNode:getChildByName("money_num"):setString(group_conf.INVEST)
		investNode:getChildByName("money_icon"):setPositionX(investNode:getChildByName("money_num"):getPositionX() + investNode:getChildByName("money_num"):getContentSize().width + 20)

		local min = math.floor(group_conf.TIME/60)
		investNode:getChildByName("time_num"):setString(min..CONF:getStringValue("minutes"))
		setObjVisible(true)
	else
		setObjVisible(false)
		investNode:getChildByName("invest_text"):setString(CONF:getStringValue("invest_finish"))
	end
	investNode:getChildByName("av_days"):setString("")
	investNode:getChildByName("av_days_text"):setString("")


	local starTime = getTime(tostring(av_conf.START_TIME))
	local endTime = getTime(tostring(av_conf.END_TIME))
	if os.time() >= starTime and os.time() <= endTime then
		investNode:getChildByName("av_days"):setString(formatTime(endTime-os.time()))
		investNode:getChildByName("av_days_text"):setString(CONF:getStringValue("activity_time"))
	end
	
	investNode:getChildByName("av_days"):setPositionX(investNode:getChildByName("av_days_text"):getPositionX()+investNode:getChildByName("av_days_text"):getContentSize().width)
	local function timeUpdate()
		local function update()
			local info = player:getActivity(id)
			if info then

				local invest_index = info.invest_data.index + 1
				if not CONF.INVESTGROUP.check(invest_index) then return end
				local group_conf = CONF.INVESTGROUP.get(invest_index)
				if info.invest_data.start_time > 0 then
					local time = group_conf.TIME - (player:getServerTime() - info.invest_data.start_time)
					if time < 0 then time = 0 end
					if time > group_conf.TIME then time = group_conf.TIME end
					investNode:getChildByName("time_num"):setString(formatTime(time))
					if player:getServerTime() - info.invest_data.start_time >= group_conf.TIME then
						investNode:getChildByName("invest_btn"):getChildByName("text"):setString(CONF:getStringValue("ACTI_8_text6"))
					else
						investNode:getChildByName("invest_btn"):getChildByName("text"):setString(CONF:getStringValue("ACTI_8_text7"))
					end
					-- if schedulerEntry1 ~= nil and time <= 0 then
					--  	scheduler:unscheduleScriptEntry(schedulerEntry1)
					--  	schedulerEntry1 = nil
					-- end
				end
			end
		end
		update()
		local starTime = getTime(tostring(av_conf.START_TIME))
		local endTime = getTime(tostring(av_conf.END_TIME))
		if os.time() >= starTime and os.time() <= endTime then
			investNode:getChildByName("av_days"):setString(formatTime(endTime-os.time()))
			investNode:getChildByName("av_days_text"):setString(CONF:getStringValue("activity_time"))
		else
			investNode:getChildByName("av_days"):setString("")
			investNode:getChildByName("av_days_text"):setString("")
		end
		investNode:getChildByName("av_days"):setPositionX(investNode:getChildByName("av_days_text"):getPositionX()+investNode:getChildByName("av_days_text"):getContentSize().width)
	end
	timeUpdate()
	if schedulerEntry1 == nil then
	 	schedulerEntry1 = scheduler:scheduleScriptFunc(timeUpdate,1,false)
	end
	investNode:getChildByName("invest_btn"):addClickEventListener(function ( ... )
		local info = player:getActivity(id)
		local invest_index = 1
		if info then
			invest_index = info.invest_data.index + 1
		end
		if not CONF.INVESTGROUP.check(invest_index) then
			return
		end
		local group_conf = CONF.INVESTGROUP.get(invest_index)
		if not info then
			if player:getMoney() < group_conf.INVEST then

				local function func()
					local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

					rechargeNode:init(self, {index = 1})
					self:addChild(rechargeNode)
				end

				local messageBox = require("util.MessageBox"):getInstance()
				messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
				return
			end

			local strData = Tools.encode("ActivityInvestReq", {
				activity_id = id,
				type = 1,
				index = 1,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_INVEST_REQ"),strData)

			gl:retainLoading()
		else
			if info.invest_data.start_time > 0 then
				if player:getServerTime() - info.invest_data.start_time >= group_conf.TIME then
					local strData = Tools.encode("ActivityInvestReq", {
						activity_id = id,
						type = 3,
						index = info.invest_data.index,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_INVEST_REQ"),strData)

					gl:retainLoading()
				else
					local function func()
						local strData = Tools.encode("ActivityInvestReq", {
							activity_id = id,
							type = 2,
							index = info.invest_data.index,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_INVEST_REQ"),strData)

						gl:retainLoading()
					end
					local node = require("util.MakeSureLayer"):createNormal(func , CONF:getStringValue("revoke_invest"))
					local center = cc.exports.VisibleRect:center()
					rn:addChild(node)
				end
			else
				if player:getMoney() < group_conf.INVEST then

					local function func()
						local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

						rechargeNode:init(self, {index = 1})
						self:addChild(rechargeNode)
					end

					local messageBox = require("util.MessageBox"):getInstance()
					messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
					return
				end

				local strData = Tools.encode("ActivityInvestReq", {
					activity_id = id,
					type = 1,
					index = invest_index,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_INVEST_REQ"),strData)

				gl:retainLoading()
			end
		end
	end)
end

function ActivityScene:SearchIDForTime(id)
    local time = 0
    local info = player:getActivity(20001)
    local converttime_list = {}
    if info then
        converttime_list = info.change_item_data.item_list
    end
    for k,v in pairs(converttime_list) do
        if v.key == id then
            time = v.value
        end
    end
    return time
end

function ActivityScene:createConvertNode( flag )
    local rn = self:getResourceNode()

    for i,v in ipairs(rn:getChildByName("node"):getChildren()) do
		if v:getName() ~= "convert_node" then
			v:removeFromParent()
		end
	end

	if rn:getChildByName("convert_node") and (flag == nil or flag == false) then
		return
	end

	if flag and rn:getChildByName("node"):getChildByName("convert_node") then
		rn:getChildByName("node"):getChildByName("convert_node"):removeFromParent()
	end

	if flag == nil or flag == false then
		self.svd_Y = nil
	end

	local id = 20001
	local av_conf = CONF.ACTIVITY.get(id)
    local conf_list = {}
    for i=1,CONF.CHANGEITEM.len do
        if tonumber(CONF.CHANGEITEM[i].TYPE) == 2 then
            table.insert(conf_list,CONF.CHANGEITEM[i])
        end
    end
    local info = player:getActivity(id)
    local converttime_list = {}
    if info then
        converttime_list = info.change_item_data.item_list
    end

	local convertNode = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/ConvertBigNode.csb")
	convertNode:setName("convert_node")
	rn:getChildByName("node"):addChild(convertNode)

    --ui
    local convertlist = require("util.ScrollViewDelegate"):create(convertNode:getChildByName("list"),cc.size(10,10), cc.size(680,100))
    convertNode:getChildByName("list"):setScrollBarEnabled(false)
    for k,v in ipairs(conf_list) do
        local time_num = self:SearchIDForTime(v.ID)
        local node_conf = require("app.views.OperatingActivitieScene.PropConvertNode"):create():init({time = time_num ,conf = v ,isOperat = false})
        node_conf:getChildByName("bg"):getChildByName("bt"):addClickEventListener(function ( sender )
            if isConvertover then
                tips:tips(CONF:getStringValue("activity")..CONF:getStringValue("end"))
            else
                local strData = Tools.encode("ActivityExchangeItemReq", {
			    id = tonumber(v.ID)
		        })
		        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_EXCHANGE_ITEM_REQ"),strData)
            end
	    end)
        convertlist:addElement(node_conf)
    end
    --clock
    local starTime = getTime(tostring(CONF.ACTIVITY.get(id).START_TIME))
	local endTime = getTime(tostring(CONF.ACTIVITY.get(id).END_TIME))
    local function timer()
        local cNode = rn:getChildByName("node"):getChildByName("convert_node")
        if cNode == nil then
            return
        end
        if os.time() >= starTime and os.time() <= endTime then
            if isConvertover then
                isConvertover = false
            end
            cNode:getChildByName("time"):setString(formatTime(endTime-os.time()))
        else
            if not isConvertover then
                isConvertover = true
            end
            cNode:getChildByName("time"):setString(CONF:getStringValue("activity")..CONF:getStringValue("end"))
	    end
    end

    if ConvertScheduler == nil then
        ConvertScheduler = scheduler:scheduleScriptFunc(timer,0.033,false)
    end

end

function ActivityScene:resetList()
	local rn = self:getResourceNode()

	local big_node = rn:getChildByName("node"):getChildByName("big_node")

	if big_node then

		local id = big_node:getChildByName("list"):getTag()
		local index = CONF.ACTIVITY.get(id).TYPE
		self:createSmallAvNode(index, id, true)
	end
end

function ActivityScene:onEnterTransitionFinish()
	printInfo("ActivityScene:onEnterTransitionFinish")

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kActivity)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("hd_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end

	self.svd_Y = nil
	self.reward_ = nil
	self.add_online_time = 0
	self.ssss = 0

	local rn = self:getResourceNode()
	--rn:getChildByName("title"):setString(CONF:getStringValue("activity"))	Delete By JinXin 20180620

    	-- rn:getChildByName("title_bg"):setLocalZOrder(10)
    	-- rn:getChildByName("title"):setLocalZOrder(10)

	rn:getChildByName("close"):addClickEventListener(function ()
		playEffectSound("sound/system/return.mp3")
		-- self:getApp():removeTopView()

		-- EDIT BY WJJ 20180625
		-- self:getApp():removeViewByName("ActivityScene/ActivityScene")

		if( self.IS_SCENE_TRANSFER_EFFECT ) then
			self.lagHelper:BeginTransferEffect("city")
		else
            if self.data_ and self.data_["from"] == "ship" then
                self:getApp():removeTopView()
            else
			    self:getApp():popView()
            end
		end
	end)

	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(0,2), cc.size(299,69))

	local function update(dt)

		self:showRedPoint()

		local big_node = rn:getChildByName("node"):getChildByName("big_node")

		if big_node then
			local small_node = big_node:getChildByName("small_node")
			
			if small_node then
				local id = big_node:getChildByName("list"):getTag()

				local check = CONF.ACTIVITY.check(id)

				if check then

					if id ~= 5001 then
						local conf = CONF.ACTIVITY.get(id)

						if conf.START_TIME ~= 1 and conf.START_TIME ~= 0 then
							local end_time = getTime(conf.END_TIME)
							local time = end_time - player:getServerTime()

							small_node:getChildByName("av_days"):setString(formatTime(time))


						elseif conf.START_TIME == 1 then

							local regist_time = player:getRegistTime()

							local diff_time = 0--regist_time%86400
							local end_time = regist_time + conf.END_TIME*86400 - diff_time

							local time = end_time - player:getServerTime()

							small_node:getChildByName("av_days"):setString(formatTime(time))

						end 
					else

						local online_time = player:getUserInfo().timestamp.today_online_time + self.add_online_time
						local minute = math.floor(online_time/60)

						local max = 0
						for i,v in ipairs(CONF.ONLINEGROUP.getIDList()) do
							local conf = CONF.ONLINEGROUP.get(v)

							if type(conf.TIME) ~= "table" then
								if conf.TIME > max then
									max = conf.TIME
								end
							end
						end

						if minute >= max/60 then
							small_node:getChildByName("av_days"):setString(CONF:getStringValue("accomplish"))
						else
							-- small_node:getChildByName("av_days"):setString(minute..CONF:getStringValue("minutes"))
							small_node:getChildByName("av_days"):setString(formatTime(online_time))
						end

						small_node:getChildByName("av_days"):setVisible(true)
						small_node:getChildByName("av_days_text"):setVisible(true)
						small_node:getChildByName("av_days_text"):setString(CONF:getStringValue("today_online_time"))

						self.add_online_time = self.add_online_time + 1
					end

					small_node:getChildByName("av_days_text"):setPositionX(small_node:getChildByName("av_days"):getPositionX() - small_node:getChildByName("av_days"):getContentSize().width)

				else
					local id = big_node:getTag()

					local check = CONF.ACTIVITY.check(id)

					if check then
						local conf = CONF.ACTIVITY.get(id)

						if conf.START_TIME ~= 1 and conf.START_TIME ~= 0 then

							local end_time = getTime(conf.END_TIME)
							local time = end_time - player:getServerTime()

							small_node:getChildByName("av_days"):setString(formatTime(time))

						elseif conf.START_TIME == 1 then

							local regist_time = player:getRegistTime()

							local diff_time = 0--regist_time%86400
							local end_time = regist_time + conf.END_TIME*86400 - diff_time

							local time = end_time - player:getServerTime()

							small_node:getChildByName("av_days"):setString(formatTime(time))

						end

						small_node:getChildByName("av_days_text"):setPositionX(small_node:getChildByName("av_days"):getPositionX() - small_node:getChildByName("av_days"):getContentSize().width)

					end

				end

			end

		end


		local change_ship_node = rn:getChildByName("node"):getChildByName("change_ship_node")
		if change_ship_node then
			local id = 15001

			local check = CONF.ACTIVITY.check(id)

			if check then
				local conf = CONF.ACTIVITY.get(id)

				if conf.START_TIME ~= 1 and conf.START_TIME ~= 0 then

					local end_time = getTime(conf.END_TIME)
					local time = end_time - player:getServerTime()

					change_ship_node:getChildByName("av_days"):setString(formatTime(time))

				elseif conf.START_TIME == 1 then

					local regist_time = player:getRegistTime()

					local diff_time = 0--regist_time%86400
					local end_time = regist_time + conf.END_TIME*86400 - diff_time

					local time = end_time - player:getServerTime()

					change_ship_node:getChildByName("av_days"):setString(formatTime(time))

				end

				if conf.START_TIME == 0 then
					change_ship_node:getChildByName("av_days_text"):setVisible(false)
					change_ship_node:getChildByName("av_days"):setVisible(false)
				end

				change_ship_node:getChildByName("av_days_text"):setPositionX(change_ship_node:getChildByName("av_days"):getPositionX() - change_ship_node:getChildByName("av_days"):getContentSize().width)

			end

		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	animManager:runAnimOnceByCSB(rn, "ActivityScene/ActivityLayer.csb", "intro")
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_ACTIVITY_LIST_REQ")," ")
	-- gl:retainLoading()

	local function recvMsg( )
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_GET_ACTIVITY_LIST_RESP") then 
			-- gl:releaseLoading()

			local proto = Tools.decode("GetActivityListResp",strData)
			if proto.result ~= 0 then 
				print("GetActivityListResp error", proto.result)
			else 
				print("#id_list",#proto.id_list)
				for i,v in ipairs(proto.id_list) do
					print("ididid",i,v)
				end

				self.small_list = proto.id_list

				self:createActivityNode()
				self:showRedPoint()
				player:setPlayerActivityIDList(proto.id_list)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_CHANGE_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivityChangeResp",strData)
			if proto.result ~= 0 then 
				print("ActivityChangeResp error", proto.result)
			else 
				playEffectSound("sound/system/reward.mp3")	
				self:resetList()
				-- tips:tips(CONF:getStringValue("change_ok"))

				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("change_ok"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_RECHARGE_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivityRechargeResp",strData)

			if proto.result ~= 0 then 
				print("ActivityRechargeReq error", proto.result)
			else 
				playEffectSound("sound/system/reward.mp3")
				self:resetList()
				-- tips:tips(CONF:getStringValue("change_ok"))

				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("change_ok"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
				-- self:showReward(self.reward_)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_CONSUME_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivityConsumeResp",strData)

			print("ActivityConsumeResp", proto.result)
			if proto.result ~= 0 then 
				print("ActivityConsumeResp error", proto.result)
			else 
				playEffectSound("sound/system/reward.mp3")
				self:resetList()
				-- tips:tips(CONF:getStringValue("change_ok"))

				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("change_ok"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
				-- self:showReward(self.reward_)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_SEVEN_DAYS_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivitySevenDaysResp",strData)

			if proto.result ~= 0 then 
				print("ActivitySevenDaysResp error", proto.result)
			else 
				playEffectSound("sound/system/reward.mp3")
				self.touch_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				self.touch_node:getChildByName("button"):setEnabled(false)

				self.touch_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
				-- self.touch_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))

				self.touch_node:getChildByName("button"):setVisible(false)
				self.touch_node:getChildByName("icon"):setVisible(true)
				-- self.touch_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
				self.touch_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				
				self.touch_node:getChildByName("has_num"):setVisible(false)
					self.touch_node:getChildByName("need_num"):setVisible(false)
				-- tips:tips(CONF:getStringValue("change_ok"))


				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("change_ok"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
				-- self:showReward(self.reward_)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_ONLINE_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivityOnlineResp",strData)

			if proto.result ~= 0 then 
				print("ActivityOnlineResp error", proto.result)
			else 
				playEffectSound("sound/system/reward.mp3")	
				self.touch_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				self.touch_node:getChildByName("button"):setEnabled(false)

				self.touch_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
				-- self.touch_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))

				self.touch_node:getChildByName("button"):setVisible(false)
				self.touch_node:getChildByName("icon"):setVisible(true)
				-- self.touch_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
				self.touch_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				
				self.touch_node:getChildByName("has_num"):setVisible(false)
					self.touch_node:getChildByName("need_num"):setVisible(false)

				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
				-- self:showReward(self.reward_)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_POWER_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivityPowerResp",strData)

			if proto.result ~= 0 then 
				print("ActivityPowerResp error", proto.result)
			else 
				playEffectSound("sound/system/reward.mp3")
				self.touch_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				self.touch_node:getChildByName("button"):setEnabled(false)

				self.touch_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
				-- self.touch_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))

				self.touch_node:getChildByName("button"):setVisible(false)
				self.touch_node:getChildByName("icon"):setVisible(true)
				-- self.touch_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
				self.touch_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				
				self.touch_node:getChildByName("has_num"):setVisible(false)
					self.touch_node:getChildByName("need_num"):setVisible(false)

				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
				-- self:showReward(self.reward_)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_GROWTH_FUND_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivityGrowthFundResp",strData)

			if proto.result ~= 0 then 
				print("ActivityGrowthFundResp error", proto.result)
			else 

				if self.fund_type == 2 then
					playEffectSound("sound/system/reward.mp3")
					self.touch_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
					self.touch_node:getChildByName("button"):setEnabled(false)

					self.touch_node:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209, 209, 209, 255))
					-- self.touch_node:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))

					self.touch_node:getChildByName("button"):setVisible(false)
					self.touch_node:getChildByName("icon"):setVisible(true)
					-- self.touch_node:getChildByName("icon"):setTexture("Common/newUI/icon_claimed_"..server_platform..".png")
					self.touch_node:getChildByName("icon"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
					
					self.touch_node:getChildByName("has_num"):setVisible(false)
					self.touch_node:getChildByName("need_num"):setVisible(false)

					local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
					node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(node)

					-- self:showReward(self.reward_)
				else
					self:resetActivityInfo(CONF.EActivityGroup.kGrowthFund,true)
				end
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_MONTH_SIGN_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivityMonthSignResp",strData)

			if proto.result ~= 0 then 
				print("ActivityMonthSignResp error", proto.result)
			else 

				self:createMonthNode(true)

				self:showReward(self.reward_)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_CHANGE_SHIP_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivityChangeShipResp",strData)

			if proto.result ~= 0 then 
				print("ActivityChangeShipResp error", proto.result)
			else 

				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				self:createChangeShip(true)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_UPDATE_TIMESTAMP_RESP") then

			local proto = Tools.decode("UpdateTimeStampResp",strData)

			if proto.result == 0 then
				self.add_online_time = 0
        	end

        elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_INVEST_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivityInvestResp",strData)
			print("ActivityInvestResp")
			print(proto.result)
			if proto.result ~= 0 then 
				print("ActivityInvestResp error", proto.result)
			else

				-- local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				-- node:setPosition(cc.exports.VisibleRect:center())
				-- self:addChild(node)

				-- self:createChangeShip(true)
				if proto.earning and proto.earning ~= 0 then
					local info = player:getActivity(13001)
					local invest_index = 1
					if info then
						invest_index = info.invest_data.index
					end
					local group_conf = CONF.INVESTGROUP.get(invest_index)
					local node = require("util.RewardNode"):createGettedNodeWithList({{id = 7001, num = group_conf.INVEST*(1+proto.earning*0.01)}}, func, self)
					tipsAction(node)
					node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(node)
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
				end

				self.data_ = {}
				self.data_.group_id = CONF.EActivityGroup.kInvest

				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_ACTIVITY_LIST_REQ")," ")
				self:showRedPoint()
			end
        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_EXCHANGE_ITEM_RESP") then
			local proto = Tools.decode("ActivityExchangeItemResp",strData)
			if proto.result == 0 then
                tips:tips(CONF:getStringValue("change_ok"))
                local timelist
            	for k,v in ipairs(proto.user_sync.activity_list) do
		            if 20001 == v.id then
			            timelist = v.change_item_data.item_list
		            end
	            end
                if timelist ~= nil and Tools:isEmpty(timelist) == false then
                    self:createConvertNode(true)
				    cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
                end
			end

		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	if Tools.isEmpty(player:getPlayerActivityIDList()) == false then
		self.small_list = player:getPlayerActivityIDList()
		self:createActivityNode()
		self:showRedPoint()
	end
end

function ActivityScene:showReward( item_list )
	if item_list == nil then
		return
	end

	local node = require("util.RewardNode"):createGettedNodeWithList(item_list, nil, self)
	tipsAction(node)
	node:setPosition(cc.exports.VisibleRect:center())
	self:addChild(node)


end

function ActivityScene:getAvRed( id_list )

	local function getLimitNum( info,id )

		if info == nil then
			return 0 
		end

		for ii,vv in ipairs(info.change_data.limit_list) do
			if vv.key == id then
				return vv.value 
			end
		end

		return 0
	end

	local function getIsRecharge( info, id )
		if info == nil then
			return false
		end

		for i,v in ipairs(info.recharge_data.getted_id_list) do
			if v == id then
				return true
			end
		end

		return false
	end

	local function getIsConsume( info, id )
		if info == nil then
			return false
		end

		for i,v in ipairs(info.consume_data.getted_id_list) do
			if v == id then
				return true
			end
		end

		return false
	end

	local function getSevenDay( info, id, planet_user)
		if info == nil then
			return false
		end

		local info = info.seven_days_data

		for i,v in ipairs(info.getted_reward_list) do
			if v == id then
				return false
			end
		end

		local conf = CONF.SEVENDAYSTASK.get(id)

		if conf.TARGET_1 == 9 then
			if info.sign_in_days >= conf.VALUES[1] then
				return true
			end
		elseif conf.TARGET_1 == 1 then
			for i,v in ipairs(info.level_info) do
				if v.level_id == conf.VALUES[1] then
					if v.level_star >= conf.VALUES[2] then
						return true
					end
				end
			end
		elseif conf.TARGET_1 == 2 then
			if conf.TARGET_2 == 1 then
				if info.building_levelup_count >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 2 then
				if info.building_levelup_count + info.home_levelup_count >= conf.VALUES[1] then
					return true
				end
			end
		elseif conf.TARGET_1 == 3 then
			if info.home_levelup_count >= conf.VALUES[1] then
				return true
			end
		elseif conf.TARGET_1 == 4 then
			if player:getLevel() >= conf.VALUES[1] then
				return true
			end
		elseif conf.TARGET_1 == 5 then
			if conf.TARGET_2 == 1 then
				if info.ship_levelup_count >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 6 then
				if info.equip_strength_count >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 7 then
				if info.ship_break_count >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 3 then
				local ship_num = 0
				for ii,vv in ipairs(player:getShipList()) do
					if vv.quality == conf.VALUES[1] then
						ship_num = ship_num + 1
					end
				end

				if ship_num >= conf.VALUES[2] then
					return true
				end
			end
		elseif conf.TARGET_1 == 6 then
			if conf.TARGET_2 == 1 then
				if info.already_challenge_times >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 2 then
				if info.win_challenge_times >= conf.VALUES[1] then
					return true
				end
			end
		elseif conf.TARGET_1 == 7 then
			if info.contribute_times >= conf.VALUES[1] then
				return true
			end
		elseif conf.TARGET_1 == 8 then
			if conf.TARGET_2 == 1 then
				if info.recharge_money >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 2 then
				if info.consume_money >= conf.VALUES[1] then
					return true
				end
			end
		elseif conf.TARGET_1 == 10 then
			if conf.TARGET_2 == 1 then
				if info.lottery_count >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 2 then
				if info.money_lottery_count >= conf.VALUES[1] then
					return true
				end
			end
		elseif conf.TARGET_1 == 12 then
			for i,v in ipairs(info.trial_level_list) do
				if v.level_id == conf.VALUES[1] then
					if v.star >= conf.VALUES[2] then
						return true
					end
				end
			end
		elseif conf.TARGET_1 == 13 then
			if not planet_user or not planet_user.seven_days_data then
				return false
			end
			if conf.TARGET_2 == 10 then
				return planet_user.seven_days_data.attack_monster_times >= conf.VALUES[1]
			elseif conf.TARGET_2 == 11 then
				return planet_user.seven_days_data.base_attack_times >= conf.VALUES[1]
			elseif conf.TARGET_2 == 12 then
				return planet_user.seven_days_data.colloct_level_times_list_day >= conf.VALUES[1]
			elseif conf.TARGET_2 == 13 then
				return planet_user.seven_days_data.ruins_level_times_list_day >= conf.VALUES[1]
			elseif conf.TARGET_2 == 14 then
				return planet_user.seven_days_data.fishing_level_times_list_day >= conf.VALUES[1]
			elseif conf.TARGET_2 == 15 then
				return planet_user.seven_days_data.boss_level_times_list_day >= conf.VALUES[1]
			end
		elseif conf.TARGET_1 == 14 then
			if info.technology_levelup_count >= conf.VALUES[1] then
				return true
			end
		elseif conf.TARGET_1 == 15 then
			if info.weapon_levelup_count >= conf.VALUES[1] then
				return true
			end
		end

		return false
		
	end

	local function getOnline( info, index )
		if info == nil then
			return false
		end

		for i,v in ipairs(info.online_data.get_indexs) do
			if v == index then
				return true
			end
		end

		return false
	end

	local function getIsPower( info, index )
		if info == nil then
			return false
		end

		for i,v in ipairs(info.power_data.get_indexs) do
			if v == index then
				return true
			end
		end

		return false
	end

	local function getIsSetIn( info )

		if info == nil then
			return false
		end

		return info.change_ship_data.getted_reward
	end

	local function getInvest(info)
		if info == nil then
			return false
		end
		local invest_index = info.invest_data.index + 1
		if not CONF.INVESTGROUP.check(invest_index) then
			return false
		end
		local group_conf = CONF.INVESTGROUP.get(invest_index)
		if info.invest_data.start_time > 0 then
			local time = group_conf.TIME - (player:getServerTime() - info.invest_data.start_time)
			if time <= 0 then
				return true
			end
		end
		return false
	end

	local function getSignInToday(info)
		if not info or not info.month_sign_data or not info.month_sign_data.get_nums then
			return true
		end
		if info.month_sign_data.get_nums[player:getServerDate().day] == 0 then
			return true
		end
		return false
	end

	local index_list = {}

	for i,v in ipairs(id_list) do

		if CONF.ACTIVITY.check(v) then
			local av_type = CONF.ACTIVITY.get(v).TYPE

			local av_info = player:getActivity(v)

			if av_type == 1 then
				for i2,v2 in ipairs(CONF.ACTIVITYCHANGE.get(v).GROUP) do
					local conf = CONF.CHANGEITEM.get(v2)

					local limit_num = getLimitNum(av_info, v2)

					if limit_num < conf.LIMIT then
						local can = true
						for ii,vv in ipairs(conf.COST_ITEM) do
							if player:getItemNumByID(vv) < conf.COST_NUM[ii] then
								can = false
								break
							end
						end

						if can then
							-- return true
							table.insert(index_list, av_type)
						end
					end
				
				end
			elseif av_type == 2 then
				for i2,v2 in ipairs(CONF.ACTIVITYRECHARGE.get(v).GROUP) do
					local conf = CONF.RECHARGEITEM.get(v2)

					if av_info ~= nil then
						if av_info.recharge_data.recharge_money >= conf.COST then
							if not getIsRecharge(av_info, v2) then
								-- return true
								table.insert(index_list, av_type)
							end
						end
					end
				end
			elseif av_type == 3 then
				for i2,v2 in ipairs(CONF.ACTIVITYCONSUME.get(v).GROUP) do
					local conf = CONF.CONSUMEITEM.get(v2)

					if av_info ~= nil then
						if av_info.consume_data.consume >= conf.CONSUME then
							if not getIsConsume(av_info, v2) then
								-- return true
								table.insert(index_list, av_type)
							end
						end
					end
				end
			elseif av_type == 4 then
				local regist_time = player:getRegistTime()


				local time = player:getServerTime() - regist_time

				local day_now = 0
				if time < 0 then
					day_now = 7
				else

					day_now = math.ceil(time / 86400)
				end

				if day_now > 7 then
					day_now = 7
				end

				for j=1,day_now do
					for i2,v2 in ipairs(CONF.ACTIVITYSEVENDAYS.get(v)["DAY"..j]) do

						if getSevenDay(av_info, v2 ,player:getPlayerPlanetUser()) then
							-- return true
							table.insert(index_list, av_type)
						end

					end
				end
				
			elseif av_type == 5 then
				for i2,v2 in ipairs(CONF.ACTIVITYONLINE.get(v).GROUP) do
					local conf = CONF.ONLINEGROUP.get(v2)

					-- if av_info ~= nil then
						if conf.TYPE == 1 then
							if player:getUserInfo().timestamp.today_online_time >= conf.TIME then
								if not getOnline(av_info, v2) then
									-- return true
									table.insert(index_list, av_type)
								end
							end
						else

							local hh = player:getServerDate().hour

							if hh >= conf.TIME[1] and hh <= conf.TIME[2] then
								if not getOnline(av_info, v2) then
									-- return true
									table.insert(index_list, av_type)
								end
							end
						end
					-- end
				end
			elseif av_type == 10 then
				for i2,v2 in ipairs(CONF.ACTIVITYPOWER.get(v).GROUP) do
					local conf = CONF.POWERGROUP.get(v2)

					-- if av_info ~= nil then
						if player:getPower() >= conf.POWER then
							if not getIsPower(av_info, v2) then
								-- return true
								table.insert(index_list, 6)
							end
						end
						
					-- end
				end

			elseif av_type == 15 then
				local all_get = true
				for i,v in ipairs(CONF.ACTIVITYCHANGESHIP.get(v).CHANGE_LIST) do
					if player:getShipByID(v) == nil then
						all_get = false
						break
					end
				end

				if all_get then
					if not getIsSetIn(av_info) then

						table.insert(index_list, 10)
					end
				end
			elseif av_type == 13 then
				if getInvest(av_info) then
					table.insert(index_list, 8)
				end
			elseif av_type == 14 then
				if getSignInToday(av_info) then
					table.insert(index_list, 9)
				end
			end
		end
	end

	-- return false
	return index_list
end

function ActivityScene:showRedPoint( ... )
	if self.small_list == nil then
		return
	end

	local index_list = self:getAvRed(self.small_list)

	for i,v in ipairs(self.svd_:getScrollView():getChildren()) do
		v:getChildByName("point"):setVisible(false)
	end

	for i,v in ipairs(index_list) do
		if self.svd_:getScrollView():getChildByTag(v) then
			self.svd_:getScrollView():getChildByTag(v):getChildByName("point"):setVisible(true)
		end
	end


end

function ActivityScene:getPinString( str, param_list )
	
	local strs = Split(str,"|")

	local string = ""
	for i,v in ipairs(strs) do
		string = string..v

		if i <= #param_list then
			string = string..param_list[i]
		end
	end

	return string

end

function ActivityScene:getPinStringNeedColor(str, param_list, color_list)
	local strs = Split(str,"|")

	local string = ""
	for i,v in ipairs(strs) do
		string = string.."#ffffff02"..v

		if i <= #param_list then
			string = string..color_list[i].."02"..param_list[i]
		end
	end

	return string

end

function ActivityScene:getPinStringNeedColorString(str, param_list, color_list)
	local strs = Split(str,"|")

	local string = ""
	for i,v in ipairs(strs) do
		string = string.."#ffffff02"..v

		if i <= #param_list then
			string = string..color_list[i].."02"..CONF:getStringValue(param_list[i])
		end
	end

	return string

end

function ActivityScene:onExitTransitionStart()
	printInfo("ActivityScene:onExitTransitionStart")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	-- eventDispatcher:removeEventListener(self.resListener_)
	-- eventDispatcher:removeEventListener(self.moneyListener_)

	if schedulerEntry ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerEntry)
	end
	if schedulerEntry1 ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerEntry1)
	 	schedulerEntry1 = nil
	end

    if ConvertScheduler ~= nil then
        scheduler:unscheduleScriptEntry(ConvertScheduler)
	 	ConvertScheduler = nil
    end
end

return ActivityScene