
local TechnologyNode = class("TechnologyNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

TechnologyNode.RESOURCE_FILENAME = "StarLeagueScene/league_tech.csb"

local triangle_pos = {right = {x = 27, y = 26.5}, bottom = {x = 24, y = 25.5}}

local schedulerEntry = nil

function TechnologyNode:onEnterTransitionFinish()

end

function TechnologyNode:init(scene,data)

	self.scene_ = scene
    self.group_list = data.group 
    self.info_list = data.user_info

    self.select_tech = nil

    for i,v in ipairs(self.group_list.tech_list) do
        print(i,v.tech_id)
    end

	local rn = self:getResourceNode()
    rn:getChildByName("Text_2_0_0"):setString(CONF:getStringValue("player'sContribution"))
    rn:getChildByName("Text_2_0"):setString(CONF:getStringValue("totalContribution"))
    rn:getChildByName("Text_2"):setString(CONF:getStringValue("technologyNum"))

    -----

    local panel_info = rn:getChildByName("panel_info")
    panel_info:getChildByName("btn_upgrade"):getChildByName("text"):setString(CONF:getStringValue("upgrade"))
    -- local back = cc.Sprite:create("Common/ui/chat_bottom.png")
    -- -- self.progress = cc.Scale9Sprite:create("Common/ui/ui_progress_light_big.png")
    -- self.progress = ccui.ImageView:create("Common/ui/ui_progress_light_big.png")
    -- self.progress:setCapInsets(cc.rect(0,0,8,8))
    -- self.progress:setAnchorPoint(cc.p(0.02,0.5))
    -- self.progress:setScale9Enabled(true)

    -- back:setAnchorPoint(cc.p(0.0,0.5))
    -- back:setScale(276/back:getContentSize().width, 18/back:getContentSize().height)

    -- local clippingNode = cc.ClippingNode:create()
    -- clippingNode:setStencil(back)
    -- clippingNode:setInverted(false)
    -- clippingNode:setAlphaThreshold(0.5)
    -- clippingNode:addChild(self.progress)
    -- clippingNode:setAnchorPoint(cc.p(0.5,0.5))

    local bs = cc.size(320, 20)
    -- local cap = cc.rect(6,6,7,19)
    self.progress = require("util.ClippingScaleProgressDelegate"):create("TaskScene/ui/active_progress.png", 320, { bg_size = bs, lightLength = 0})

    panel_info:addChild(self.progress:getClippingNode())
    self.progress:getClippingNode():setPosition(cc.p(panel_info:getChildByName("upgrade_tech_progress_back"):getPosition()))

    panel_info:getChildByName("exp_text"):setLocalZOrder(2)
    panel_info:getChildByName("exp_now_num"):setLocalZOrder(2)
    panel_info:getChildByName("exp_max_num"):setLocalZOrder(2)

    local function cdFull( ... )
        if player:getMoney() < player:getSpeedUpNeedMoney(player:getGroupData().contribute_end_cd - player:getServerTime()) then
            -- tips:tips(CONF:getStringValue("no enought credit"))
            local function func()
                local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

                rechargeNode:init(self, {index = 1})
                self:addChild(rechargeNode)
            end

            local messageBox = require("util.MessageBox"):getInstance()
            messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
        end

        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_CONTRIBUTE_CD_REQ"),"nil")

        gl:retainLoading()
    end

    panel_info:getChildByName("btn_normal"):addClickEventListener(function ( ... )

        local money_num = player:getSpeedUpNeedMoney(player:getGroupData().contribute_end_cd - player:getServerTime())

        if player:getGroupData().contribute_end_cd - player:getServerTime() > 0 then
            if player:getGroupData().contribute_end_cd - player:getServerTime() > 7200 then
                local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("UseMoneyToClearCD"), money_num, cdFull)

                self:addChild(node)
                tipsAction(node)
                return
            else

                if player:getGroupData().contribute_locker then
                    local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("UseMoneyToClearCD"), money_num, cdFull)

                    self:addChild(node)
                    tipsAction(node)
                    return
                end
                
            end
                        
        end

        if panel_info:getChildByName("btn_normal"):getChildByName("num"):getTextColor().b == 0 then
            local conf = CONF.GROUP_TECH.get(self.tech_id_)
            local itemId = conf.ITEM[player:getGroupTechItemIndex(self.tech_id_, 1)]
            local jumpTab = {}
            local cfg_item = CONF.ITEM.get(itemId)
            if cfg_item and cfg_item.JUMP then
                table.insert(jumpTab,cfg_item.JUMP)
            end
            if Tools.isEmpty(jumpTab) == false and not self:getChildByName("JumpChoseLayer") then
                jumpTab.scene = "TechnologyNode"
                local center = cc.exports.VisibleRect:center()
                local layer = app:createView("ShipsScene/JumpChoseLayer",jumpTab)
                tipsAction(layer, cc.p(center.x , center.y+90 ))
                layer:setName("JumpChoseLayer")
                self:addChild(layer)
            end  
            tips:tips(CONF:getStringValue("Material_not_enought"))
            return
        end

        self.contribute_type = 1
        local strData = Tools.encode("GroupContributeReq", {
            type = 1,
            tech_id = self.tech_id_,
        })
        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_CONTRIBUTE_REQ"),strData)

        -- gl:retainLoading()
    end)

    panel_info:getChildByName("btn_baoji"):addClickEventListener(function ( ... )

        local money_num = player:getSpeedUpNeedMoney(player:getGroupData().contribute_end_cd - player:getServerTime())

        if player:getGroupData().contribute_end_cd - player:getServerTime() > 0 then
            if player:getGroupData().contribute_end_cd - player:getServerTime() > 7200 then
                local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("UseMoneyToClearCD"), money_num, cdFull)

                self:addChild(node)
                tipsAction(node)
                return
            else

                if player:getGroupData().contribute_locker then
                   local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("UseMoneyToClearCD"), money_num, cdFull)

                    self:addChild(node)
                    tipsAction(node)
                    return
                end
                
            end
                        
        end

        if panel_info:getChildByName("btn_baoji"):getChildByName("num"):getTextColor().b == 0 then
            local conf = CONF.GROUP_TECH.get(self.tech_id_)
            local itemId = conf.ITEM[player:getGroupTechItemIndex(self.tech_id_, 2)]
            local jumpTab = {}
            local cfg_item = CONF.ITEM.get(itemId)
            if cfg_item and cfg_item.JUMP then
                table.insert(jumpTab,cfg_item.JUMP)
            end
            if Tools.isEmpty(jumpTab) == false and not self:getChildByName("JumpChoseLayer") then
                jumpTab.scene = "TechnologyNode"
                local center = cc.exports.VisibleRect:center()
                local layer = app:createView("ShipsScene/JumpChoseLayer",jumpTab)
                tipsAction(layer, cc.p(center.x , center.y+90))
                layer:setName("JumpChoseLayer")
                self:addChild(layer)
            end  
            tips:tips(CONF:getStringValue("Material_not_enought"))
            return
        end

        self.contribute_type = 2
        local strData = Tools.encode("GroupContributeReq", {
            type = 2,
            tech_id = self.tech_id_,
        })
        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_CONTRIBUTE_REQ"),strData)

        -- gl:retainLoading()
    end)

    panel_info:getChildByName("btn_upgrade"):addClickEventListener(function ( ... )
        if player:getGroupData().job == 1 or player:getGroupData().job == 2 then

            local flag = false
            for i,v in ipairs(self.group_list.tech_list) do
                if v.begin_upgrade_time > 0 then
                    flag = true
                    break
                end
            end

            if flag then
                tips:tips(CONF:getStringValue("has tech upgrade"))
            else

                local strData = Tools.encode("GroupTechLevelupReq", {
                    tech_id = self.tech_id_,
                })
                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_TECH_LEVELUP_REQ"),strData)

                gl:retainLoading()
            end
        else
            tips:tips(CONF:getStringValue("Permission denied"))
        end
    end)

    panel_info:setVisible(false)

    rn:getChildByName("list"):setScrollBarEnabled(false)
    rn:getChildByName("list"):setSwallowTouches(false)
    self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(2,2), cc.size(954,73))

    self:resetInfo()
    self:resetList()

    local function update(dt)

        self:updateTech()

        if self.tech_id_ then
            local conf = CONF.GROUP_TECH.get(self.tech_id_)

            local tech_info = {}
            local upgrade_tech_id = 0
            for i,v in ipairs(self.group_list.tech_list) do
                if v.tech_id == self.tech_id_ then
                    tech_info = v
                    break
                end
            end
            if tech_info.status == 2 then
                panel_info:getChildByName("time"):setString(formatTime(conf.CD - (player:getServerTime() - tech_info.begin_upgrade_time)))
            else
                -- printInfo(player:getGroupData().contribute_end_cd)
                -- printInfo(player:getServerTime())
                if player:getGroupData().contribute_end_cd - player:getServerTime() < 0 then
                    panel_info:getChildByName("time"):setString("00:00:00")
                else
                    panel_info:getChildByName("time"):setString(formatTime(player:getGroupData().contribute_end_cd - player:getServerTime()))
                end

                if player:getGroupData().contribute_locker then
                    panel_info:getChildByName("time"):setTextColor(cc.c4b(255, 0, 0, 255))
                    -- panel_info:getChildByName("time"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
                else
                    panel_info:getChildByName("time"):setTextColor(cc.c4b(255, 255, 255, 255))
                    -- panel_info:getChildByName("time"):enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
                end
            end
        end

    end

    schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)
    
    local function recvMsg()
        print("TechnologyNode:recvMsg")
        local cmd,strData = GameHandler.handler_c.recvProtobuf()

        if cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_CONTRIBUTE_RESP") then

            if self.contribute_type == 0 then
                gl:releaseLoading()
            end

            local proto = Tools.decode("GroupContributeResp",strData)
            if proto.result ~= 0 then
                print("error :",proto.result)
            else
                
                -- self.group_list = proto.user_sync.group_main

                self:resetPanelInfo()

                if self.contribute_type ~= 0 then
                    flurryLogEvent("group_contribute_tech", {tech_id = self.tech_id_, contribute_str = self.contribute_str}, 2)
                end
                
            end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_TECH_LEVELUP_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("GroupTechLevelupResp",strData)

            if proto.result ~= 0 then
                print("error :",proto.result)
            else
                -- self.group_list = proto.user_sync.group_main

                -- self:resetPanelInfo()

                flurryLogEvent("group_tech_level_up", {tech_id = self.tech_id_}, 2)
                
            end

        -- elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_GET_TECH_RESP") then
        --     gl:releaseLoading()

        --     local proto = Tools.decode("GroupGetTechResp",strData)

        --     if proto.result ~= 0 then
        --         print("error :",proto.result)
        --     else

        --         self.group_list = proto.user_sync.group_main
        --     end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_CONTRIBUTE_CD_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("GroupContributeCDResp",strData)

            if proto.result ~= 0 then
                print("error :",proto.result)
            else
                tips:tips(CONF:getStringValue("ResetCDSucess"))
                self:resetPanelInfo()
            end

        end

    end
    
    self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function TechnologyNode:updateTech( ... )

    for i,v in ipairs(self.svd_:getScrollView():getChildren()) do
        for i=1,v:getChildByName("button"):getChildByName("icon"):getTag() do
            local tech = v:getChildByName("tech_"..i)

            local conf = CONF.GROUP_TECH.get(tech:getTag())

            local tech_info = {}
            for i2,v2 in ipairs(self.group_list.tech_list) do
                if v2.tech_id == tech:getTag() then
                    tech_info = v2

                end
            end

            -- print(tech_info.tech_id, tech_info.status)
            if tech_info.status == 2 then

                tech:getChildByName("back"):setVisible(true)
                tech:getChildByName("time"):setVisible(true)

                tech:getChildByName("time"):setString(formatTime(conf.CD - (player:getServerTime() - tech_info.begin_upgrade_time)))

                if conf.CD - (player:getServerTime() - tech_info.begin_upgrade_time) <= 0 then

                    if self.tech_id_ == tech:getTag() then

                        self.contribute_type = 0
                        local strData = Tools.encode("GroupContributeReq", {
                            type = 0,
                            tech_id = tech:getTag(),
                        })
                        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_CONTRIBUTE_REQ"),strData)

                        gl:retainLoading()

                        tech:getChildByName("ban"):getChildByName("lv_num"):setString(tech:getTag()%100)
                    else

                        tech:getChildByName("back"):setVisible(false)
                        tech:getChildByName("time"):setVisible(false)

                        tech:getChildByName("ban"):getChildByName("lv_num"):setString(tech:getTag()%100)
                    end
                end

            else
                tech:getChildByName("back"):setVisible(false)
                tech:getChildByName("time"):setVisible(false)
            end

            local c_conf = CONF.GROUP_TECH.check(tech:getTag()+1) 

            local chang = 95

            if tech_info.tech_id then

                if c_conf then

                    tech:getChildByName("kuang_white"):setVisible(true)
                    tech:getChildByName("kuang_yellow"):setVisible(false)

                    if tech_info.exp <= conf.EXP/4 then

                        tech:getChildByName("line_1"):setVisible(true)
                        for i=2,4 do
                            tech:getChildByName("line_"..i):setVisible(false)
                        end

                        tech:getChildByName("line_1"):setContentSize(cc.size(5, tech_info.exp/(conf.EXP/4)*chang))

                    elseif tech_info.exp > conf.EXP/4 and tech_info.exp <= conf.EXP/2 then

                        tech:getChildByName("line_1"):setVisible(true)
                        tech:getChildByName("line_2"):setVisible(true)
                        for i=3,4 do
                            tech:getChildByName("line_"..i):setVisible(false)
                        end

                        tech:getChildByName("line_1"):setContentSize(cc.size(5, chang))
                        tech:getChildByName("line_2"):setContentSize(cc.size(5, (tech_info.exp-conf.EXP/4)/(conf.EXP/4)*chang))

                    elseif tech_info.exp > conf.EXP/2 and tech_info.exp <= conf.EXP*0.75 then
                        tech:getChildByName("line_1"):setContentSize(cc.size(5, chang))
                        tech:getChildByName("line_2"):setContentSize(cc.size(5, chang))
                        tech:getChildByName("line_3"):setContentSize(cc.size(5, (tech_info.exp-conf.EXP/2)/(conf.EXP/4)*chang))

                        for i=1,3 do
                            tech:getChildByName("line_"..i):setVisible(true)
                        end
                        tech:getChildByName("line_4"):setVisible(false)

                    elseif tech_info.exp > conf.EXP*0.75 and tech_info.exp <= conf.EXP then

                        for i=1,4 do
                            tech:getChildByName("line_"..i):setVisible(true)
                        end

                        tech:getChildByName("line_1"):setContentSize(cc.size(5, chang))
                        tech:getChildByName("line_2"):setContentSize(cc.size(5, chang))
                        tech:getChildByName("line_3"):setContentSize(cc.size(5, chang))
                        tech:getChildByName("line_4"):setContentSize(cc.size(5, (tech_info.exp-conf.EXP*0.75)/(conf.EXP/4)*chang))

                    end

                else
                    tech:getChildByName("kuang_white"):setVisible(false)
                    tech:getChildByName("kuang_yellow"):setVisible(true)

                    for i=1,4 do
                        tech:getChildByName("line_"..i):setVisible(false)
                    end

                end
            end

        end
    end
end

function TechnologyNode:resetList( ... )
    
    self.svd_:clear()

    local function createListItem( type, tech_list )
        local item = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_tech_list_item.csb")

        item:getChildByName("text"):setString(CONF:getStringValue("Group_Tech_Type_"..type))

        if type == 1 then
            item:getChildByName("bg"):loadTexture("Common/newUI/bz_yq_light.png")
        end

        local button = item:getChildByName("button")
        local function clickBtn( ... )
            if button:getTag() == 400 then

                item:getChildByName("bg"):loadTexture("Common/newUI/bz_yq_light.png")
                item:getChildByName("bu"):setVisible(true)

                for i=1,button:getChildByName("icon"):getTag() do
                    item:getChildByName("tech_"..i):setVisible(true)
                end

                self.svd_:resetConfig(type, {size = cc.size(item:getChildByName("bg"):getContentSize().width, 60 + item:getTag())})
                self.svd_:resetAllElementPosition()

                button:setTag(401)
            elseif button:getTag() == 401 then

                item:getChildByName("bg"):loadTexture("Common/newUI/bz_yq.png")
                item:getChildByName("bu"):setVisible(false)

                for i=1,button:getChildByName("icon"):getTag() do
                    item:getChildByName("tech_"..i):setVisible(false)
                end

                self.svd_:resetConfig(type, {size = cc.size(item:getChildByName("bg"):getContentSize().width, 60)})
                self.svd_:resetAllElementPosition()

                button:setTag(400)
            end
        end

        button:addClickEventListener(clickBtn)
        item:getChildByName("bg"):addClickEventListener(clickBtn)

        for i,v in ipairs(tech_list) do
            local node = self:createTechItem(v)

            local x = i%5
            if x == 0 then
                x = 5
            end

            local y = math.ceil(i/5)
            node:setPosition(cc.p(50+110*(x-1), -105-100*(y-1)))
            node:setVisible(false)
            node:setName("tech_"..i)
            item:addChild(node)
        end

        local tag_num = math.ceil(table.getn(tech_list)/5)*100

        if math.ceil(table.getn(tech_list)/5)*100 < item:getChildByName("bu"):getContentSize().height then
            tag_num = item:getChildByName("bu"):getContentSize().height
        end

        item:setTag(tag_num)
        item:setName("item_"..type)
        button:getChildByName("icon"):setTag(table.getn(tech_list))

        local size = cc.size(item:getChildByName("bg"):getContentSize().width, 60)

        if type == 1 then
            size= cc.size(item:getChildByName("bg"):getContentSize().width, 60 + item:getTag())

            item:getChildByName("bu"):setVisible(true)

            button:getChildByName("icon"):setRotation(90)
            button:getChildByName("icon"):setPosition(cc.p(triangle_pos.bottom))

            for i=1,button:getChildByName("icon"):getTag() do
                item:getChildByName("tech_"..i):setVisible(true)
            end

            button:setTag(401)
        end


        return item,size

    end

    local function createNextListItem( type, tech_list,level )
        local item = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_tech_list_item.csb")

        item:getChildByName("text"):setString(CONF:getStringValue("Group_Tech_Type_"..type))

        if type == 1 then
            item:getChildByName("bg"):loadTexture("Common/newUI/bz_yq_light.png")
        end

        local show_level = 0
        for i,v in ipairs(CONF.GROUP.getIDList()) do
            for i2,v2 in ipairs(CONF.GROUP.get(v).OPEN_TECH_ID) do
                if CONF.GROUP_TECH.get(v2).TYPE == type then
                    show_level = i
                    break
                end
            end
        end
        if CONF.GROUP.check(level+1) then
            show_level = level + 1
        end
        item:getChildByName("show_text"):setString(CONF:getStringValue("covenant")..show_level..CONF:getStringValue("level_ji")..CONF:getStringValue("open"))

        local button = item:getChildByName("button")
        local function clickBtn( ... )

            tips:tips(CONF:getStringValue("covenant")..show_level..CONF:getStringValue("level_ji")..CONF:getStringValue("open"))
        end

        button:addClickEventListener(clickBtn)
        item:getChildByName("bg"):addClickEventListener(clickBtn)

        for i,v in ipairs(tech_list) do
            local node = self:createTechItem(v)

            local x = i%5
            if x == 0 then
                x = 5
            end

            local y = math.ceil(i/5)
            node:setPosition(cc.p(50+110*(x-1), -105-100*(y-1)))
            node:setVisible(false)
            node:setName("tech_"..i)
            item:addChild(node)
        end

        item:setTag(math.ceil(table.getn(tech_list)/5)*100)
        item:setName("item_"..type)
        button:getChildByName("icon"):setTag(table.getn(tech_list))

        local size = cc.size(item:getChildByName("bg"):getContentSize().width, 60)

        if type == 1 then
            size= cc.size(item:getChildByName("bg"):getContentSize().width, 60 + item:getTag())

            button:getChildByName("icon"):setRotation(90)
            button:getChildByName("icon"):setPosition(cc.p(triangle_pos.bottom))

            for i=1,button:getChildByName("icon"):getTag() do
                item:getChildByName("tech_"..i):setVisible(true)
            end

            button:setTag(401)
        end


        return item,size
    end

    local level = self.group_list.level

    local tech_list = {}
    local type_list = {}

    for i=1,level do
        local conf = CONF.GROUP.get(i)
        for i,v in ipairs(conf.OPEN_TECH_ID) do
            table.insert(tech_list, v)
        end
    end

    for i,v in ipairs(tech_list) do
        local conf = CONF.GROUP_TECH.get(v)
        if type_list[1] then
            local has = false
            for i2,v2 in ipairs(type_list) do
                if conf.TYPE == v2 then
                    has = true
                end
            end

            if not has then
                type_list[table.getn(type_list)+1] = conf.TYPE
            end
        else
            type_list[1] = conf.TYPE
        end
    end

    for i,v in ipairs(type_list) do

        local tech = {}

        for ii,vv in ipairs(tech_list) do

            local conf = CONF.GROUP_TECH.get(vv)

            if conf.TYPE == v then
                table.insert(tech, vv)
            end
        end

        local item,size = createListItem(v, tech)

        self.svd_:addElement(item, {size = size})
    end


    local has_type = 0
    local get_type = 0
    for i,v in ipairs(type_list) do
        -- if v > get_type then
        --     get_type = v
        -- end
        get_type = math.max(get_type,v)
    end

    for i,v in ipairs(CONF.GROUP_TECH.getIDList()) do
        if CONF.GROUP_TECH.get(v).TYPE > get_type then
            has_type = get_type + 1
            break
        end
    end
    if has_type ~= 0 then
        local item,size = createNextListItem(has_type, {},level)
        self.svd_:addElement(item, {size = size})
    end

    self:updateTech()

end

function TechnologyNode:getIsExit( ... )
    return false
end

function TechnologyNode:resetInfo( ... )
    local rn = self:getResourceNode()

    local te_num = 0
    for i,v in ipairs(self.group_list.tech_list) do
        if v.city_buff_count == nil or v.city_buff_count == 0 then
            if v.status == 3 then
                te_num = te_num + 1
            end
        end
    end

    rn:getChildByName("technology_num"):setString(te_num)
    rn:getChildByName("contributes_num"):setString(self.group_list.contribute)
    rn:getChildByName("my_contributes_num"):setString(player:getGroupData().contribute)

--    rn:getChildByName("technology_num"):setPositionX(rn:getChildByName("Text_2"):getPositionX() + rn:getChildByName("Text_2"):getContentSize().width + 5)
--    rn:getChildByName("Text_2_0"):setPositionX(rn:getChildByName("technology_num"):getPositionX() + rn:getChildByName("technology_num"):getContentSize().width + 26)

--    rn:getChildByName("contributes_num"):setPositionX(rn:getChildByName("Text_2_0"):getPositionX() + rn:getChildByName("Text_2_0"):getContentSize().width + 5)
--    rn:getChildByName("contribution_1"):setPositionX(rn:getChildByName("contributes_num"):getPositionX() + rn:getChildByName("contributes_num"):getContentSize().width + rn:getChildByName("contribution_1"):getContentSize().width/2 + 4)

--    rn:getChildByName("Text_2_0_0"):setPositionX(rn:getChildByName("contribution_1"):getPositionX() + rn:getChildByName("contribution_1"):getContentSize().width + 10)
--    rn:getChildByName("my_contributes_num"):setPositionX(rn:getChildByName("Text_2_0_0"):getPositionX() + rn:getChildByName("Text_2_0_0"):getContentSize().width + 5)
--    rn:getChildByName("contribution_2"):setPositionX(rn:getChildByName("my_contributes_num"):getPositionX() + rn:getChildByName("my_contributes_num"):getContentSize().width + rn:getChildByName("contribution_2"):getContentSize().width/2 + 2)
end

function TechnologyNode:createTechItem( id )

    local function addListener( node, func)

        local sv = self.svd_:getScrollView()
        local isTouchMe = false

        local function onTouchBegan(touch, event)

            local target = event:getCurrentTarget()
            
            local locationInNode = sv:convertToNodeSpace(touch:getLocation())

            local sv_s = sv:getContentSize()
            local sv_rect = cc.rect(0, 0, sv_s.width, sv_s.height)

            if cc.rectContainsPoint(sv_rect, locationInNode) then

                local ln = target:convertToNodeSpace(touch:getLocation())

                local s = target:getContentSize()
                local rect = cc.rect(0, 0, s.width, s.height)
                
                if cc.rectContainsPoint(rect, ln) then
                    isTouchMe = true
                    return true
                end

            end

            return false
        end

        local function onTouchMoved(touch, event)

            local delta = touch:getDelta()
            if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
                isTouchMe = false
            end
        end

        local function onTouchEnded(touch, event)
            if isTouchMe == true then
                    
                func(node)
            end
        end

        local listener = cc.EventListenerTouchOneByOne:create()
        listener:setSwallowTouches(false)
        listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
        listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
        listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
        local eventDispatcher = sv:getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
    end

    local node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_tech_item.csb")

    local conf = CONF.GROUP_TECH.get(id)

    node:getChildByName("icon"):loadTexture("StarLeagueScene/LeagueTechIcon/"..conf.ICON..".png")

    local tech_id = 0
    local status = 1
    for i,v in ipairs(self.group_list.tech_list) do
        if v.city_buff_count == nil or v.city_buff_count == 0 then
            if math.floor(v.tech_id/100) == math.floor(id/100) then

                if tech_id < v.tech_id then
                    tech_id = v.tech_id
                    status = v.status

                    if v.status == 3 then
                        tech_id = v.tech_id + 1
                        status = 1
                    end
                end
            end 
        end
    end

    if tech_id == 0 then
        node:setTag(id)
    else
        node:setTag(tech_id)
    end

    if tech_id == 0 then
        node:getChildByName("ban"):getChildByName("lv_num"):setString(math.floor(0))
    else
        node:getChildByName("ban"):getChildByName("lv_num"):setString(math.floor((node:getTag()-1)%100))
    end

    -- node:getChildByName("icon"):setTexture("")

    local function bg_func( ... )
        if self.select_tech then

            if self.select_tech:getName() == node:getName() then
                return
            else
                self.select_tech:getChildByName("select_light"):setVisible(false)
            end
        else
            -- self:getResourceNode():getChildByName("panel_info"):setVisible(true)
        end

        for i,v in ipairs(self.group_list.tech_list) do
            if node:getTag() == v.tech_id then
                if v.status == 3 then
                    node:setTag(node:getTag() + 1)
        
                end
            end
        end

        node:getChildByName("select_light"):setVisible(true)
        self.select_tech = node
        self.tech_id_ = node:getTag()

        print("tech_iddddddd",  node:getTag())

        self.contribute_type = 0
        local strData = Tools.encode("GroupContributeReq", {
            type = 0,
            tech_id = node:getTag(),
        })
        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_CONTRIBUTE_REQ"),strData)

        gl:retainLoading()
    end

    addListener(node:getChildByName("bg"),bg_func )

    -- node:getChildByName("bg"):addClickEventListener(function ( ... )

    --     if self.select_tech then

    --         if self.select_tech:getName() == node:getName() then
    --             return
    --         else
    --             self.select_tech:getChildByName("select_light"):setVisible(false)
    --         end
    --     else
    --         -- self:getResourceNode():getChildByName("panel_info"):setVisible(true)
    --     end

    --     for i,v in ipairs(self.group_list.tech_list) do
    --         if node:getTag() == v.tech_id then
    --             if v.status == 3 then
    --                 node:setTag(node:getTag() + 1)
        
    --             end
    --         end
    --     end

    --     node:getChildByName("select_light"):setVisible(true)
    --     self.select_tech = node
    --     self.tech_id_ = node:getTag()

    --     print("tech_iddddddd",  node:getTag())

    --     self.contribute_type = 0
    --     local strData = Tools.encode("GroupContributeReq", {
    --         type = 0,
    --         tech_id = node:getTag(),
    --     })
    --     GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_CONTRIBUTE_REQ"),strData)

    --     gl:retainLoading()

    -- end)


    return node
end

function TechnologyNode:resetPanelInfo()
    local conf = CONF.GROUP_TECH.get(self.tech_id_)
    local rn = self:getResourceNode()

    local tech_info 
    for i,v in ipairs(self.group_list.tech_list) do
        print(i, v.tech_id)
        if v.tech_id == self.tech_id_ then
            tech_info = v
            break
        end
    end

    if tech_info == nil then
        return
    end

    local check_conf = CONF.GROUP_TECH.check(self.tech_id_ + 1)

    local isMax = false
    if check_conf == nil then
        isMax = true
    end

    local panel_info = rn:getChildByName("panel_info")

    if not panel_info:isVisible() then
        panel_info:setVisible(true)
    end

    panel_info:getChildByName("upgrade_tech_icon"):loadTexture("StarLeagueScene/LeagueTechIcon/"..conf.ICON..".png")
    panel_info:getChildByName("upgrade_tech_name"):setString(CONF:getStringValue(conf.NAME))
    panel_info:getChildByName("upgrade_tech_description"):setString(CONF:getStringValue(conf.MEMO))

    if player:getServerTime() >= player:getGroupData().contribute_end_cd then
        panel_info:getChildByName("time"):setVisible(false)
        panel_info:getChildByName("time_bg"):setVisible(false)
    else
        panel_info:getChildByName("time"):setVisible(true)
        panel_info:getChildByName("time_bg"):setVisible(true)
    end

    if player:getGroupData().contribute_locker then
        panel_info:getChildByName("time"):setTextColor(cc.c4b(255, 0, 0, 255))
        -- panel_info:getChildByName("time"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
    else
        panel_info:getChildByName("time"):setTextColor(cc.c4b(255, 255, 255, 255))
        -- panel_info:getChildByName("time"):enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
    end

    if isMax then

        ---shuxing
        local str = ""
        if conf.TECHNOLOGY_ATTR_PERCENT ~= 0 then
            str = conf.TECHNOLOGY_ATTR_PERCENT.."%"
        end

        if conf.TECHNOLOGY_ATTR_VALUE ~= 0 then
            str = str.."+"..conf.TECHNOLOGY_ATTR_VALUE
        end

        panel_info:getChildByName("upgrade_tech_now_num"):setString(str)
        panel_info:getChildByName("max"):setVisible(true)
        panel_info:getChildByName("upgrade_tech_evolution"):setVisible(false)
        panel_info:getChildByName("upgrade_tech_max_num"):setVisible(false)

        --exp progress

        panel_info:getChildByName("exp_text"):setVisible(false)
        panel_info:getChildByName("exp_now_num"):setVisible(false)
        panel_info:getChildByName("exp_max_num"):setVisible(false)

        self:setExpProgress(1)

        panel_info:getChildByName("btn_normal"):setVisible(false)
        panel_info:getChildByName("ui_EXP_26_0"):setVisible(false)
        panel_info:getChildByName("normal_exp_num"):setVisible(false)
        panel_info:getChildByName("contribution_personal_28"):setVisible(false)
        panel_info:getChildByName("normal_gongxian_num"):setVisible(false)

        panel_info:getChildByName("btn_baoji"):setVisible(false)
        panel_info:getChildByName("ui_EXP_26_0_0"):setVisible(false)
        panel_info:getChildByName("baoji_exp_num"):setVisible(false)
        panel_info:getChildByName("contribution_personal_28_0"):setVisible(false)
        panel_info:getChildByName("baoji_gongxian_num"):setVisible(false)

        panel_info:getChildByName("max"):setVisible(true)
        panel_info:getChildByName("upgrade_tech_evolution"):setVisible(false)
        panel_info:getChildByName("upgrade_tech_max_num"):setVisible(false)

        panel_info:getChildByName("btn_upgrade"):setVisible(true)
        panel_info:getChildByName("btn_upgrade"):getChildByName("text"):setString("MAX")
        panel_info:getChildByName("btn_upgrade"):setEnabled(false)

        --time

        if player:getGroupData().contribute_end_cd - player:getServerTime() < 0 then
            panel_info:getChildByName("time"):setString("00:00:00")
        else
            panel_info:getChildByName("time"):setString(formatTime(player:getGroupData().contribute_end_cd - player:getServerTime()))
        end

    else

        --exp
        panel_info:getChildByName("exp_text"):setVisible(true)
        panel_info:getChildByName("exp_now_num"):setVisible(true)
        panel_info:getChildByName("exp_max_num"):setVisible(true)

        panel_info:getChildByName("exp_now_num"):setString(tech_info.exp)
        panel_info:getChildByName("exp_max_num"):setString("/"..conf.EXP)

        --shuxing

        local next_conf = CONF.GROUP_TECH.get(self.tech_id_+1)

        local str = ""
        if conf.TECHNOLOGY_ATTR_PERCENT ~= 0 then
            str = conf.TECHNOLOGY_ATTR_PERCENT.."%"
        end

        if conf.TECHNOLOGY_ATTR_VALUE ~= 0 then
            str = str.."+"..conf.TECHNOLOGY_ATTR_VALUE
        end

        panel_info:getChildByName("upgrade_tech_now_num"):setString(str)

        local n_str = ""
        if next_conf.TECHNOLOGY_ATTR_PERCENT ~= 0 then
            n_str = next_conf.TECHNOLOGY_ATTR_PERCENT.."%"
        end

        if next_conf.TECHNOLOGY_ATTR_VALUE ~= 0 then
            n_str = n_str.."+"..next_conf.TECHNOLOGY_ATTR_VALUE
        end
        panel_info:getChildByName("upgrade_tech_max_num"):setString(n_str)

        panel_info:getChildByName("max"):setVisible(false)
        panel_info:getChildByName("upgrade_tech_evolution"):setVisible(true)
        panel_info:getChildByName("upgrade_tech_max_num"):setVisible(true)

        --1ji
        if math.floor(self.tech_id_%100) == 1 then
            panel_info:getChildByName("upgrade_tech_now_num"):setString(0)
            panel_info:getChildByName("upgrade_tech_max_num"):setString(str)
        end

        if tech_info.status == 2 then   --升级中

            panel_info:getChildByName("time"):setVisible(true)
            panel_info:getChildByName("time_bg"):setVisible(true)

            panel_info:getChildByName("btn_normal"):setVisible(false)
            panel_info:getChildByName("ui_EXP_26_0"):setVisible(false)
            panel_info:getChildByName("normal_exp_num"):setVisible(false)
            panel_info:getChildByName("contribution_personal_28"):setVisible(false)
            panel_info:getChildByName("normal_gongxian_num"):setVisible(false)

            panel_info:getChildByName("btn_baoji"):setVisible(false)
            panel_info:getChildByName("ui_EXP_26_0_0"):setVisible(false)
            panel_info:getChildByName("baoji_exp_num"):setVisible(false)
            panel_info:getChildByName("contribution_personal_28_0"):setVisible(false)
            panel_info:getChildByName("baoji_gongxian_num"):setVisible(false)

            panel_info:getChildByName("btn_upgrade"):setVisible(true)
            panel_info:getChildByName("btn_upgrade"):getChildByName("text"):setString(CONF:getStringValue("upgrade_now"))

            panel_info:getChildByName("btn_upgrade"):setEnabled(false)

            panel_info:getChildByName("exp_now_num"):setString(conf.EXP)

            panel_info:getChildByName("time"):setString(formatTime(conf.CD - (player:getServerTime() - tech_info.begin_upgrade_time)))
            panel_info:getChildByName("time"):setTextColor(cc.c4b(255,255,255,255))
            -- panel_info:getChildByName("time"):enableShadow(cc.c4b(255,255,255,255), cc.size(0.5,0.5))

            self:setExpProgress(1)
     
        else

            if tech_info.exp >= conf.EXP and tech_info.status == 1 then

                panel_info:getChildByName("btn_normal"):setVisible(false)
                panel_info:getChildByName("ui_EXP_26_0"):setVisible(false)
                panel_info:getChildByName("normal_exp_num"):setVisible(false)
                panel_info:getChildByName("contribution_personal_28"):setVisible(false)
                panel_info:getChildByName("normal_gongxian_num"):setVisible(false)

                panel_info:getChildByName("btn_baoji"):setVisible(false)
                panel_info:getChildByName("ui_EXP_26_0_0"):setVisible(false)
                panel_info:getChildByName("baoji_exp_num"):setVisible(false)
                panel_info:getChildByName("contribution_personal_28_0"):setVisible(false)
                panel_info:getChildByName("baoji_gongxian_num"):setVisible(false)

                panel_info:getChildByName("btn_upgrade"):setVisible(true)
                panel_info:getChildByName("btn_upgrade"):getChildByName("text"):setString(CONF:getStringValue("upgrade"))

                panel_info:getChildByName("btn_upgrade"):setEnabled(true)

                local update_tech_info = nil
                for i,v in ipairs(self.group_list) do
                    if v.status == 2 then
                        update_tech_info = v
                        break
                    end
                end

                if update_tech_info == nil then
                    if player:getGroupData().contribute_end_cd - player:getServerTime() < 0 then
                        panel_info:getChildByName("time"):setString("00:00:00")
                    else
                        panel_info:getChildByName("time"):setString(formatTime(player:getGroupData().contribute_end_cd - player:getServerTime()))
                    end
                else
                    local c_conf = CONF.GROUP_TECH.get(update_tech_info.tech_id)
                    panel_info:getChildByName("time"):setString(formatTime(c_conf.CD - (player:getServerTime() - update_tech_info.begin_upgrade_time)))

                end

                self:setExpProgress(1)

            else

                panel_info:getChildByName("btn_normal"):setVisible(true)
                panel_info:getChildByName("ui_EXP_26_0"):setVisible(true)
                panel_info:getChildByName("normal_exp_num"):setVisible(true)
                panel_info:getChildByName("contribution_personal_28"):setVisible(true)
                panel_info:getChildByName("normal_gongxian_num"):setVisible(true)

                panel_info:getChildByName("btn_baoji"):setVisible(true)
                panel_info:getChildByName("ui_EXP_26_0_0"):setVisible(true)
                panel_info:getChildByName("baoji_exp_num"):setVisible(true)
                panel_info:getChildByName("contribution_personal_28_0"):setVisible(true)
                panel_info:getChildByName("baoji_gongxian_num"):setVisible(true)

                panel_info:getChildByName("btn_upgrade"):setVisible(false)
                panel_info:getChildByName("btn_upgrade"):setEnabled(true)

                -------------

                self:setExpProgress(tech_info.exp/conf.EXP) 
                
                ---
                panel_info:getChildByName("normal_exp_num"):setString("+"..conf.GOT_EXP)
                panel_info:getChildByName("normal_gongxian_num"):setString("+"..conf.GOT_CONTRIBUTE)

                -----------normalItem
                print("suoyin",player:getGroupTechItemIndex(self.tech_id_, 1))
                local item_name = conf.ITEM[player:getGroupTechItemIndex(self.tech_id_, 1)]
                local item_num = conf.NUM[player:getGroupTechItemIndex(self.tech_id_, 1)]

                print("item_name",self.tech_id_,item_name)
                self.contribute_str = string.format("%d-%d",item_name,item_num)

                panel_info:getChildByName("btn_normal"):getChildByName("icon"):setTexture("ItemIcon/"..CONF.ITEM.get(item_name).ICON_ID..".png")
                panel_info:getChildByName("btn_normal"):getChildByName("num"):setString(item_num)

                local is_enought = true
                if item_name == 3001 then
                    if player:getResByIndex(CONF.ERes.kRes1) < item_num then

                        is_enought = false
                    end
                elseif item_name == 4001 then
                    if player:getResByIndex(CONF.ERes.kRes2) < item_num then
                        is_enought = false
                    end
                elseif item_name == 5001 then
                    if player:getResByIndex(CONF.ERes.kRes3) < item_num then
                        is_enought = false
                    end
                elseif item_name == 6001 then
                    if player:getResByIndex(CONF.ERes.kRes4) < item_num then
                        is_enought = false
                    end
                else
                    if player:getItemNumByID(item_name) < item_num then
                        is_enought = false
                    end
                end

                if is_enought then
                    panel_info:getChildByName("btn_normal"):getChildByName("num"):setTextColor(cc.c4b(255, 255, 255, 255))
                    -- panel_info:getChildByName("btn_normal"):getChildByName("num"):enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
                else
                    panel_info:getChildByName("btn_normal"):getChildByName("num"):setTextColor(cc.c4b(255, 0, 0, 255))
                    -- panel_info:getChildByName("btn_normal"):getChildByName("num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
                end


                if player:getGroupTechItemIndex(self.tech_id_, 2) == nil or player:getGroupTechItemIndex(self.tech_id_, 2) == 0 then

                    panel_info:getChildByName("btn_baoji"):getChildByName("icon"):setVisible(false)
                    panel_info:getChildByName("btn_baoji"):getChildByName("num"):setVisible(false)
                    panel_info:getChildByName("btn_baoji"):getChildByName("wenhao"):setVisible(true)

                    panel_info:getChildByName("ui_EXP_26_0_0"):setVisible(false)
                    panel_info:getChildByName("contribution_personal_28_0"):setVisible(false)
                    panel_info:getChildByName("baoji_exp_num"):setVisible(false)
                    panel_info:getChildByName("baoji_gongxian_num"):setVisible(false) 

                    panel_info:getChildByName("btn_baoji"):setEnabled(false)

                else

                    panel_info:getChildByName("btn_baoji"):getChildByName("icon"):setVisible(true)
                    panel_info:getChildByName("btn_baoji"):getChildByName("num"):setVisible(true)
                    panel_info:getChildByName("btn_baoji"):getChildByName("wenhao"):setVisible(false)

                    panel_info:getChildByName("ui_EXP_26_0_0"):setVisible(true)
                    panel_info:getChildByName("contribution_personal_28_0"):setVisible(true)
                    panel_info:getChildByName("baoji_exp_num"):setVisible(true)
                    panel_info:getChildByName("baoji_gongxian_num"):setVisible(true)

                    panel_info:getChildByName("btn_baoji"):setEnabled(true)

                    -----------baojiItem
                    local item_name = conf.ITEM[player:getGroupTechItemIndex(self.tech_id_, 2)]
                    local item_num = conf.NUM[player:getGroupTechItemIndex(self.tech_id_, 2)]

                    panel_info:getChildByName("btn_baoji"):getChildByName("icon"):setTexture("ItemIcon/"..CONF.ITEM.get(item_name).ICON_ID..".png")
                    panel_info:getChildByName("btn_baoji"):getChildByName("num"):setString(item_num)

                    local is_enought = true
                    if item_name == 3001 then
                        if player:getResByIndex(CONF.ERes.kRes1) < item_num then
                            panel_info:getChildByName("btn_baoji"):getChildByName("num"):setTextColor(cc.c4b(255, 0, 0, 255))
                            -- panel_info:getChildByName("btn_baoji"):getChildByName("num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))

                            is_enought = false
                        end
                    elseif item_name == 4001 then
                        if player:getResByIndex(CONF.ERes.kRes2) < item_num then
                            is_enought = false
                        end
                    elseif item_name == 5001 then
                        if player:getResByIndex(CONF.ERes.kRes3) < item_num then
                            is_enought = false
                        end
                    elseif item_name == 6001 then
                        if player:getResByIndex(CONF.ERes.kRes4) < item_num then
                            is_enought = false
                        end
                    else
                        if player:getItemNumByID(item_name) < item_num then
                            is_enought = false
                        end
                    end

                    if is_enought then
                        panel_info:getChildByName("btn_baoji"):getChildByName("num"):setTextColor(cc.c4b(255, 255, 255, 255))
                        -- panel_info:getChildByName("btn_baoji"):getChildByName("num"):enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
                    else
                        panel_info:getChildByName("btn_baoji"):getChildByName("num"):setTextColor(cc.c4b(255, 0, 0, 255))
                        -- panel_info:getChildByName("btn_baoji"):getChildByName("num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
                    end

                    panel_info:getChildByName("baoji_exp_num"):setString("+"..conf.GOT_EXP*2)
                    panel_info:getChildByName("baoji_gongxian_num"):setString("+"..conf.GOT_CONTRIBUTE*2)

                end

                if player:getGroupData().contribute_end_cd - player:getServerTime() < 0 then
                    panel_info:getChildByName("time"):setString("00:00:00")
                else
                    panel_info:getChildByName("time"):setString(formatTime(player:getGroupData().contribute_end_cd - player:getServerTime()))
                end

            end
        end

    end
    
end

function TechnologyNode:setExpProgress( num )
    -- self.progress:setContentSize(cc.size(num*303, self.progress:getContentSize().height))
    self.progress:setPercentage(100*num)
end

function TechnologyNode:updateUI( group_list, info_list, join_list )
    self.group_list = group_list
    self.info_list = info_list

    self:resetInfo()
    self:updateTech()

    if self.tech_id_ then
        self:resetPanelInfo()
    end
end

function TechnologyNode:onExitTransitionStart()
    printInfo("TechnologyNode:onExitTransitionStart()")

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListener(self.recvlistener_)

    if schedulerEntry ~= nil then
      scheduler:unscheduleScriptEntry(schedulerEntry)
    end

end

return TechnologyNode