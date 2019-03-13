
local tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local WangZuoBuffDetail = class("WangZuoBuffDetail", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()
local app = require("app.MyApp"):getInstance()

WangZuoBuffDetail.RESOURCE_FILENAME = "PlanetScene/wangzuo/buffDetailLayer.csb"

WangZuoBuffDetail.RUN_TIMELINE = true

WangZuoBuffDetail.NEED_ADJUST_POSITION = true

WangZuoBuffDetail.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

function WangZuoBuffDetail:onCreate( data )
	self.data_ = data
end

function WangZuoBuffDetail:onEnter()

end

function WangZuoBuffDetail:onExit()
	
end

function WangZuoBuffDetail:onEnterTransitionFinish()
	printInfo("WangZuoBuffDetail:onEnterTransitionFinish()")
	local rn = self:getResourceNode()
	if not self.data_.id then
		return
	end
	local conf = CONF.TITLE_BUFF.get(self.data_.id)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName('list'),cc.size(0,40), cc.size(370,23))
	rn:getChildByName("list"):setScrollBarEnabled(false)
	rn:getChildByName("back"):addClickEventListener(function()
		self:getApp():removeTopView()
		end)
	rn:getChildByName("title"):setString(CONF:getStringValue(conf.MEMO_ID)..CONF:getStringValue("state"))
	rn:getChildByName("close"):addClickEventListener(function()
		self:getApp():removeTopView()
		end)
	rn:getChildByName("btn"):addClickEventListener(function()
		self:getApp():addView2Top("PlanetScene/WangZuo/WangZuoBuffAppoint",{id = self.data_.id})
		-- self:getApp():removeTopView()
		end)
	rn:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("appointing_a_player"))
	local node = rn:getChildByName("FileNode_2")
	node:getChildByName("shouhuo_ins"):setString(CONF:getStringValue(conf.MEMO_ID))
	node:getChildByName("work_type"):setString(CONF:getStringValue("wu_text"))
	node:getChildByName("head"):setTexture("PlanetScene/wangzuo/buffIcon/"..conf.ICON..".png")
	if conf.STR_DEBUFF == 1 then
		node:getChildByName("shouhuo_ins"):setTextColor(cc.c4b(243,57,57,255))
		node:getChildByName("back"):loadTextures("PlanetScene/wangzuo/ui/bg_red.png","PlanetScene/wangzuo/ui/bg_red_light.png")
		node:getChildByName("head_di"):setTexture("PlanetScene/wangzuo/ui/icon_red.png")
	end
	if self.data_.buffowner and Tools.isEmpty(self.data_.buffowner) == false then
		rn:getChildByName("btn"):setVisible(false)
		node:getChildByName("work_type"):setString(self.data_.buffowner.nickname)
		node:getChildByName("head"):setTexture("HeroImage/"..self.data_.buffowner.icon_id..".png")
	end
	for k,v in ipairs(conf.BUFF) do
		local buff_info = cc.CSLoader:createNode("PlanetScene/wangzuo/buffDetailNode.csb")
		local tech = CONF.TECHNOLOGY.get(v)
		if tech.TECHNOLOGY_ATTR_PERCENT ~= 0 then
			buff_info:getChildByName("buff"):setString(tech.TECHNOLOGY_ATTR_PERCENT.."%")
		end
		if tech.TECHNOLOGY_ATTR_VALUE ~= 0 then
			buff_info:getChildByName("buff"):setString(tech.TECHNOLOGY_ATTR_VALUE)
		end
		buff_info:getChildByName("buffName"):setString(CONF:getStringValue(tech.MEMO_ID))
        buff_info:getChildByName("buffName"):getVirtualRenderer():setLineBreakWithoutSpace(true)
        buff_info:getChildByName("buffName"):getVirtualRenderer():setMaxLineWidth(320)
        buff_info:getChildByName("buffName"):setContentSize(buff_info:getChildByName("buffName"):getVirtualRenderer():getContentSize())
		if conf.STR_DEBUFF == 1 then
			buff_info:getChildByName("buff"):setTextColor(cc.c4b(243,57,57,255))
			buff_info:getChildByName("buffName"):setTextColor(cc.c4b(243,57,57,255))
		else
			buff_info:getChildByName("buff"):setTextColor(cc.c4b(128,255,83,255))
			buff_info:getChildByName("buffName"):setTextColor(cc.c4b(128,255,83,255))
		end 
		self.svd_:addElement(buff_info)
	end
	local function recvMsg()
		print("WangZuoBuff:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PANET_WANGZUO_TITLE_RESP") then
        	local proto = Tools.decode("PLanetWangZuoTitleResp",strData)
			print("PLanetWangZuoTitleResp result",proto.result, proto.type)
			if proto.result == 0 then
				if  proto.type == 2 then
					for k,v in ipairs(proto.title_list.wangzuo_title_list) do
						if v.title == self.data_.id then
							for k1,v1 in ipairs(proto.user_list) do
								rn:getChildByName("btn"):setVisible(false)
								node:getChildByName("work_type"):setString(v1.nickname)
							end
						end
					end
				end
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	if player:getName() ~= self.data_.king then
		rn:getChildByName("btn"):setVisible(false)
	end
	if self.data_.state == 2 then
		rn:getChildByName("btn"):setVisible(false)
	end
end

function WangZuoBuffDetail:onExitTransitionStart()

	printInfo("WangZuoBuffDetail:onExitTransitionStart()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end

return WangZuoBuffDetail