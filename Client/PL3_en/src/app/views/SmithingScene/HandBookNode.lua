
local HandBookNode = class("HandBookNode", cc.load("mvc").ViewBase)
local player = require("app.Player"):getInstance()
local num = 3

function HandBookNode:createNode(data)
    local rnnode = require("app.ExResInterface"):getInstance():FastLoad("SmithingScene/HandBookNode.csb")
    if self.node_list then
        self.node_list = nil
    end
    self.node_ = rnnode
    self.data_ = data
    self:Init()
    self:ShowUILeft()
    self.node_:getChildByName("up"):addClickEventListener(function()
            self.forgelevel = self.forgelevel - 7
            if self.forgelevel <= 0 then
                self.forgelevel = 1
            end
			self:SetLeftListInfo(self.forgelevel)
            self:ShowUILeft()
			end)
    self.node_:getChildByName("down"):addClickEventListener(function()
            self.forgelevel = self.forgelevel + 7
            if self.forgelevel >= #self.infolist then
                self.forgelevel = #self.infolist
            end
			self:SetLeftListInfo(self.forgelevel)
            self:ShowUILeft()
			end)
    return self.node_
end

function HandBookNode:Init()
    self.infolist = CONF.BUILDING_16
    local buildinginfo = player:getBuildingInfo(16)
    self.forgelevel = buildinginfo.level
    self:SetLeftListInfo(self.forgelevel)
end

function HandBookNode:SetLeftListInfo(level)
    self.showlist = {}
    local min , max
    self.mode = 1
    if level - num > 0 and level + num < #self.infolist then -- 4~42
        min , max = level - num , level + num
        self.mode = 4
    elseif level - num <= 0 then -- 1~3
        min , max = 1,7
    elseif level + num >= #self.infolist then -- 43~45
        min , max = 39,45
    end

    for i = min , max do
        local conf = self.infolist.get(i)
        table.insert(self.showlist , conf)
    end
    self:changeMode()
end

function HandBookNode:ShowUILeft()
    for k,v in ipairs(self.showlist) do
        local mode_node = self.node_:getChildByName("leftBg"):getChildByName("mode_"..k)
        local strlist = Split(CONF:getStringValue("Unlock"),"#")
        strlist[1] = v.ID
        local str = strlist[1]..strlist[2]
		mode_node:getChildByName("text"):setString(str)
		mode_node:getChildByName("text_0"):setString(str)
		mode_node:getChildByName("selected"):addClickEventListener(function()
			if self.mode == k then return end
			self.mode = k
		    self:changeMode()
			end)
		mode_node:getChildByName("normal"):addClickEventListener(function()
			if self.mode == k then return end
			self.mode = k
		    self:changeMode()
			end)
    end
end

function HandBookNode:changeMode()
	playEffectSound("sound/system/tab.mp3")
	local children = self.node_:getChildByName("leftBg"):getChildren()
    local function setBarHighLight(bar, flag)
		if flag == true then
			bar:getChildByName("selected"):setVisible(true)
			bar:getChildByName("normal"):setVisible(false)
		else
			bar:getChildByName("selected"):setVisible(false)
			bar:getChildByName("normal"):setVisible(true)
		end
	end
	local function func(v)
		local bar_name = v:getName()
		if bar_name == string.format("mode_%d", self.mode) then
			setBarHighLight(v, true)
		else
			setBarHighLight(v, false)
		end
	end
	for i,v in ipairs(children) do
		func(v)
	end
	for i=1,7 do
		local mode_node = self.node_:getChildByName("leftBg"):getChildByName("mode_"..i)
		mode_node:getChildByName("text"):setVisible(true)
		mode_node:getChildByName("text_0"):setVisible(false)
		if self.mode == i then
			mode_node:getChildByName("text"):setVisible(false)
			mode_node:getChildByName("text_0"):setVisible(true)
		end
	end
    self:ShowUIRight()
end

function HandBookNode:ShowUIRight()
    local showinfo = self.showlist[self.mode]
    if self.node_list == nil then
        self.node_list = require("util.ScrollViewDelegate"):create(self.node_:getChildByName("list"),cc.size(5,5), cc.size(700,126))
        self.node_:getChildByName("list"):setScrollBarEnabled(false)
    else
        self.node_list:clear()
    end
    for k,v in ipairs(showinfo.DEBLOCKING_EQUIP) do
        local rightnode = require("app.ExResInterface"):getInstance():FastLoad("SmithingScene/BookItemNode.csb")
        local bg = rightnode:getChildByName("bg")
        local equip = CONF.EQUIP.get(v)
        bg:getChildByName("equip"):getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..equip.QUALITY..".png")
		bg:getChildByName("equip"):getChildByName("icon"):setVisible(true)
		bg:getChildByName("equip"):getChildByName("icon"):loadTexture("ItemIcon/"..equip.RES_ID..".png")
		bg:getChildByName("equip"):getChildByName("shadow"):setVisible(false)
		bg:getChildByName("equip"):getChildByName("num"):setVisible(false)
		bg:getChildByName("equip"):getChildByName("level_num"):setVisible(true)
		bg:getChildByName("equip"):getChildByName("level_num"):setString("Lv.".. equip.LEVEL)
		bg:getChildByName("equip"):getChildByName("shadow_0"):setVisible(false)
		bg:getChildByName("name"):setString(CONF:getStringValue(equip.NAME_ID))
        local attr = equip.ATTR
        for k2,v2 in ipairs(equip.KEY) do
            bg:getChildByName("attr"..k2):setVisible(true)
            bg:getChildByName("attr"..k2):setString(CONF:getStringValue("Attr_"..v2)..":"..attr[k2])
        end
        self.node_list:addElement(rightnode)
    end
end

return HandBookNode