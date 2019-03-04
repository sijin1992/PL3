local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local PlayerInfoNode = class("PlayerInfoNode")


function PlayerInfoNode:create(info)
	local rn = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/PlayerInfoNode.csb")
	self.battleList = {0,0,0,0,0}
	--攻击次数 防御次数 胜率
	self.battleList[1] = info.attack_count or 0
	self.battleList[2] = info.defence_count or 0
	self.battleList[3] = info.win_count or 0
	local vip = info.vip_level or 0
	local nickname = info.nickname or 'nickname'
	rn:getChildByName("name_vipLv"):setString(nickname.."     VIP "..vip)
    rn:getChildByName("FileNode_2"):setVisible(false)
    rn:getChildByName("head_di"):setVisible(true)
    rn:getChildByName("icon"):setVisible(true)
    rn:getChildByName("lv"):setVisible(true)
    rn:getChildByName("icon"):loadTexture("HeroImage/".. info.icon_id .. ".png")
    rn:getChildByName("lv"):setString("LV." .. info.level)
	rn:getChildByName("power"):setString(info.power)
	local groupName = info.group_nickname == "" and CONF:getStringValue("notInLeague") or info.group_nickname
	rn:getChildByName("group"):setString(CONF:getStringValue("covenant")..": "..groupName)
	rn:getChildByName("Text_17"):setString(CONF:getStringValue("BattleList"))
	local labels2 = {"winRate","attackTime" ,"defenseTime" ,"winTime","battleTime"} 
	for i=1,5 do
		rn:getChildByName('zhandou_text'..i):setString(CONF:getStringValue(labels2[i]))
	end
	self.battleList[5] = self.battleList[1] + self.battleList[2]
	if self.battleList[5] ==0 then
		self.battleList[4] = 0
	else 
		self.battleList[4] = math.floor(self.battleList[3] / self.battleList[5]*100 )
	end

	rn:getChildByName('zhandou_num1'):setString(self.battleList[4] .. "%")
	rn:getChildByName('zhandou_num2'):setString(self.battleList[1])
	rn:getChildByName('zhandou_num3'):setString(self.battleList[2])
	rn:getChildByName('zhandou_num4'):setString(self.battleList[3])
	rn:getChildByName('zhandou_num5'):setString(self.battleList[5])
	rn:getChildByName("bg"):addClickEventListener(function()
		rn:removeFromParent()
		end)
	return rn
end

function PlayerInfoNode:onExitTransitionStart()
	printInfo("PlayerInfoNode:onExitTransitionStart()")
end

return PlayerInfoNode