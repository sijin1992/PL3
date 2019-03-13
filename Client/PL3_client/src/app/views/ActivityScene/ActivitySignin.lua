-- 7天签到活动
local player = require("app.Player"):getInstance()
local ActivitySignin = class("ActivitySignin", cc.load("mvc").ViewBase)
-- ui文件
ActivitySignin.RESOURCE_FILENAME = "ActivityScene/ActivitySignin.csb"
ActivitySignin.NEED_ADJUST_POSITION = true

ActivitySignin.btn = {
	close = 1,
	receive = 2
}

ActivitySignin.text = {
	"1_day",
	"2_day",
	"3_day",
	"4_day",
	"5_day",
	"6_day",
	"7_day",
}

function ActivitySignin:onEnterTransitionFinish()

	self:getResourceNode():getChildByName("Text_1"):setString(CONF:getStringValue("signIn"))

	local function recvMsg( )
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_SIGN_IN_RESP") then 
			local proto = Tools.decode("ActivitySignInResp", strData)
			local daynum = 1
			if player:getActivity(8001) ~= nil then 
				daynum = player:getActivity(8001).sign_in_data.cur_day
			end
		
			if proto.result ~= 0 then
				print("CMD_ACTIVITY_SIGN_IN_RESP result", proto.result)
			else
				self:setDaysSelectImg(daynum)

				local signInConf = CONF.ACTIVITYSIGNIN.get(daynum-1)
				local items = {
					{id = signInConf.GET, num = signInConf.GET_NUM},
				}
	
	
				local node = require("util.RewardNode"):createGettedNodeWithList(items)
				tipsAction(node)
				node:setPosition(cc.exports.VisibleRect:center())
				self:getParent():addChild(node)
			end
		end
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	local res = self:getResourceNode()
	res:getChildByName("green_bg"):setSwallowTouches(true)
	res:getChildByName("green_bg"):addClickEventListener(function ( sender )
		
	end)
	-- set ui
	self:setUI(res)
	self:setUIData()
end

function ActivitySignin:setUI( res )

	local function btnFunc( sender, eventtype )
		if eventtype == ccui.TouchEventType.ended then 
			self:setBtnFunc(sender:getTag())
		end
	end

	local closeBtn = res:getChildByName("closeBtn")
	closeBtn:setTag(ActivitySignin.btn.close)
	closeBtn:addTouchEventListener(btnFunc)
	self.closeBtn = closeBtn

	local receiveBtn = res:getChildByName("receiveBtn")
	receiveBtn:setTag(ActivitySignin.btn.receive)
	receiveBtn:addTouchEventListener(btnFunc)
	self.receiveBtn = receiveBtn

	local cancleBtn = res:getChildByName("Button_16")
	cancleBtn:setTag(ActivitySignin.btn.close)
	cancleBtn:addTouchEventListener(btnFunc)

	self.sevenDays = {}
	self.selectBtnId = 1
	for i = 1, 7 do
		self.sevenDays[i] = {}
		self.sevenDays[i].bg = res:getChildByName("Node_1"):getChildByName("FileNode_" .. i)
		self.sevenDays[i].btn = self.sevenDays[i].bg:getChildByName("Button_1")
		self.sevenDays[i].itemIcon = self.sevenDays[i].bg:getChildByName("Image_7")
		self.sevenDays[i].itemNum = self.sevenDays[i].bg:getChildByName("num")
		self.sevenDays[i].selectImg = self.sevenDays[i].bg:getChildByName("Image_12_0")
		-- self.sevenDays[i].selectBtnImg = self.sevenDays[i].bg:getChildByName("Image_12")
		self.sevenDays[i].day_text = self.sevenDays[i].bg:getChildByName("day_text")
		self.sevenDays[i].day_text:setString(CONF:getStringValue(ActivitySignin.text[i]))
		-- self.sevenDays[i].gray = self.sevenDays[i].bg:getChildByName("gray_bg")
		-- self.sevenDays[i].gray:setVisible(false)
		-- self.sevenDays[i].btnBggray = self.sevenDays[i].bg:getChildByName("btnGray")
		-- self.sevenDays[i].btnBggray:setVisible(false)
		self.sevenDays[i].suo = self.sevenDays[i].bg:getChildByName("suo")

		local gray2 = mc.EffectGreyScale:create()
		self.sevenDays[i].iconbgGray = mc.EffectSprite:create(string.format("res/ItemIcon/" .. CONF.ITEM.get(CONF.ACTIVITYSIGNIN.get(i).GET).ICON_ID .. ".png"))
		self.sevenDays[i].iconbgGray:setPosition(cc.p(self.sevenDays[i].itemIcon:getPosition()))
		self.sevenDays[i].iconbgGray:setEffect(gray2)
		self.sevenDays[i].iconbgGray:setVisible(false)
		self.sevenDays[i].bg:addChild(self.sevenDays[i].iconbgGray, 99, 1000)
	end
end

function ActivitySignin:setUIData()

	local conf = CONF.ACTIVITYSIGNIN
	local function btn_CallBack( sender, eventtype )
		if eventtype == ccui.TouchEventType.ended then 
			self.selectBtnId = sender:getTag()
			self:setDaysSelectImg(sender:getTag())
		end
	end

	local isget = false
	local daynum = 1
	if player:getActivity(8001) ~= nil then 
		isget = player:getActivity(8001).sign_in_data.getted_today
		daynum = player:getActivity(8001).sign_in_data.cur_day
	end
	local iconbg = nil
	local btnGray = nil
	local iconsp = nil
	for i = 1, 7 do
		self.sevenDays[i].itemIcon:loadTexture("res/ItemIcon/" .. CONF.ITEM.get(conf.get(i).GET).ICON_ID .. ".png")
		self.sevenDays[i].itemNum:setString(conf.get(i).GET_NUM)
		self.sevenDays[i].btn:setTag(i)
		self.sevenDays[i].btn:addTouchEventListener(btn_CallBack)

		if i < daynum then 
			-- self.sevenDays[i].gray:setVisible(true)
			self.sevenDays[i].iconbgGray:setVisible(true)
			self.sevenDays[i].itemIcon:setVisible(false)
			-- self.sevenDays[i].btnBggray:setVisible(true)
			-- self.sevenDays[i].selectBtnImg:setVisible(false)
			self.sevenDays[i].btn:setTouchEnabled(false)
		end
	end


	-- set select
	self:setDaysSelectImg(daynum)
end

function ActivitySignin:setDaysSelectImg(selectId)
	local isget = false
	local daynum = 1

	if player:getActivity(8001) ~= nil then
		isget = player:getActivity(8001).sign_in_data.getted_today or false
		daynum = player:getActivity(8001).sign_in_data.cur_day or 1
	end


	for i = 1, 7 do

		if not isget and i == selectId then 
			self.sevenDays[selectId].bg:setOpacity(255)
			self.sevenDays[i].bg:setScale(1)
			-- self.sevenDays[selectId].selectBtnImg:setOpacity(255)
		elseif i == selectId then 
			self.sevenDays[selectId].bg:setOpacity(255)
			self.sevenDays[i].bg:setScale(1)
			-- self.sevenDays[selectId].selectBtnImg:setOpacity(255)
		else 
			self.sevenDays[i].bg:setOpacity(255*0.6)
			self.sevenDays[i].bg:setScale(0.95)
			-- self.sevenDays[i].selectBtnImg:setOpacity(122)
		end

		if i < daynum and isget then 
			-- self.sevenDays[i].gray:setVisible(true)
			self.sevenDays[i].iconbgGray:setVisible(true)
			self.sevenDays[i].itemIcon:setVisible(false)
			-- self.sevenDays[i].btnBggray:setVisible(true)
			-- self.sevenDays[i].selectBtnImg:setVisible(false)
			self.sevenDays[i].btn:setEnabled(false)
		end

		if i == daynum and not isget then 
			self.sevenDays[selectId].selectImg:setVisible(true)
			-- self.sevenDays[selectId].selectBtnImg:setOpacity(255)
			self.sevenDays[i].btn:setEnabled(true)
		end

		

		if daynum == 1 and not isget then 
			-- self.sevenDays[i].gray:setVisible(false)
			self.sevenDays[i].iconbgGray:setVisible(false)
			self.sevenDays[i].itemIcon:setVisible(true)
			-- self.sevenDays[i].btnBggray:setVisible(false)
			-- self.sevenDays[i].selectBtnImg:setVisible(true)
			self.sevenDays[i].btn:setEnabled(true)
		end

		if i > daynum then
			self.sevenDays[i].btn:setTouchEnabled(false)
			self.sevenDays[i].suo:setVisible(true)
		end

	end

	if daynum == 7 and isget then 
		-- self.sevenDays[7].gray:setVisible(true)
		self.sevenDays[7].iconbgGray:setVisible(true)
		self.sevenDays[7].itemIcon:setVisible(false)
		-- self.sevenDays[7].btnBggray:setVisible(true)
		-- self.sevenDays[7].selectBtnImg:setVisible(false)
		self.sevenDays[7].btn:setEnabled(false)
	end

	if selectId < daynum then 
		self.receiveBtn:setBright(false)
		self.receiveBtn:setTouchEnabled(false)
		self.receiveBtn:getChildByName("Text_26"):setString(CONF:getStringValue("Get"))
	elseif selectId == daynum and not isget then 
		self.receiveBtn:setBright(true)
		self.receiveBtn:setTouchEnabled(true)
		self.receiveBtn:getChildByName("Text_26"):setString(CONF:getStringValue("Get"))
	elseif selectId == daynum and isget then 
		self.receiveBtn:setBright(false)
		self.receiveBtn:setTouchEnabled(false)
		self.receiveBtn:getChildByName("Text_26"):setString(CONF:getStringValue("has_get"))
	else 
		self.receiveBtn:setBright(false)
		self.receiveBtn:setTouchEnabled(false)
		self.receiveBtn:getChildByName("Text_26"):setString(CONF:getStringValue("Get"))
	end
end


function ActivitySignin:setBtnFunc( tag )
	if tag == ActivitySignin.btn.close then 
		self:removeFromParent()
		playEffectSound("sound/system/return.mp3")
	elseif tag == ActivitySignin.btn.receive then 
		self:setReceiveBtn_CallBack()
		playEffectSound("sound/system/click.mp3")
	end
end

-- set gamedata
function ActivitySignin:setReceiveBtn_CallBack( )
	local receiveData = Tools.encode("ActivitySignInReq", {
				activity_id = 8001,
			})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_SIGN_IN_REQ"), receiveData)
end

function ActivitySignin:onExitTransitionStart()
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end

return ActivitySignin