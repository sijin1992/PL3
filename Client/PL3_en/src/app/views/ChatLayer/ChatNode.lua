
local ChatNode = class("ChatNode", cc.load("mvc").ViewBase)

local app = require("app.MyApp"):getInstance()

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

ChatNode.RESOURCE_FILENAME = "ChatLayer/chat_list.csb"

function ChatNode:onEnterTransitionFinish()

end


function ChatNode:init(scene,data)

    self.scene_ = scene
    self.data_ = data
    print(self.data_.user_name)

    self.select_index = -1

    local rn = self:getResourceNode()

    rn:getChildByName("text"):setString(CONF:getStringValue("no chater"))

    rn:getChildByName("chat_list"):setVisible(false)

    self.player_name = ""


    rn:getChildByName("player_list"):setScrollBarEnabled(false)
    -- rn:getChildByName("player_list"):setSwallowTouches(false)
    self.player_svd = require("util.ScrollViewDelegate"):create(rn:getChildByName("player_list"),cc.size(0,10), cc.size(299,69))

    rn:getChildByName("chat_list"):setScrollBarEnabled(false)
    rn:getChildByName("chat_list"):setSwallowTouches(false)
    self.chat_svd = require("util.ScrollViewDelegate"):create(rn:getChildByName("chat_list"),cc.size(10,15), cc.size(533,91.5))

    local strData = Tools.encode("GetFriendsInfoReq", {
        type = 3,
        index = 1,
        num = 999,
    })
    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

    local function recvMsg()
        print("ChatNode:recvMsg")
        local cmd,strData = GameHandler.handler_c.recvProtobuf()

        if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_RESP") then

            local proto = Tools.decode("GetFriendsInfoResp",strData)
            print("GetFriendsInfoResp")
            print(proto.result)
            
            if proto.result == 2 then
                self.player_list_ = {}

                self:resetPlayerList()

            elseif proto.result < 0 then
                print("error :",proto.result)
            else
                self.player_list_ = proto.list

                self:resetPlayerList()

            end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("GetChatLogResp",strData)

            if proto.result == 1 then
                self.chat_list_ = {}

                self:resetChatList()
            elseif proto.result < 0 then
                print("error :",proto.result)
            else

                self.chat_list_ = proto.log_list

                self:resetChatList()

            end
            
        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("TalkListResp",strData)
                
            if proto.result ~= 0 then
                print("error :",proto.result)
            else

                self:removeItem()

            end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("BlackListResp",strData)
            if proto.result ~= 0 then
                print("error :",proto.result)
            else
                
                tips:tips(CONF:getStringValue("add black ok"))
                player:addBlack(self.player_list_[self.close_index].user_name)

                local strData = Tools.encode("TalkListReq", {
                    type = 2,
                    user_name = self.player_list_[self.close_index].user_name,
                })
                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_REQ"),strData)

                gl:retainLoading()

            end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_RESP") then
            gl:releaseLoading()
            
            local proto = Tools.decode("CmdGetOtherUserInfoResp",strData)
            if proto.result ~= 0 then
                printInfo("proto error")  
            else
                local node = app:createView("ChatLayer/ChatNode2", {data = proto})
                node:setName("chatNode")
                node:setPosition(cc.p(self.scene_:getResourceNode():getChildByName("chat_node_pos"):getPosition()))
                self.scene_:addChild(node)
            end
        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_INVITE_RESP") then
            gl:releaseLoading()
            
            local proto = Tools.decode("GroupInviteResp",strData)
            if proto.result == "OK" then
                tips:tips(CONF:getStringValue("successful operation"))
            elseif proto.result == "FAIL" then
                print("proto error")
            elseif proto.result == "MY_BLACK" then
                tips:tips(CONF:getStringValue("this player in you blacklist"))
            elseif proto.result == "OTHER_BLACK" then
                tips:tips(CONF:getStringValue("you in this player blacklist"))
            elseif proto.result == "SENDED" then
                tips:tips(CONF:getStringValue("sended"))
            elseif proto.result == "HAS_GROUP" then
                tips:tips(CONF:getStringValue("has_garup"))
            elseif proto.result == "NO_OPEN" then
                tips:tips(CONF:getStringValue("not_open"))
            end

        end

    end

    self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

    self.chatListener_ = cc.EventListenerCustom:create("chatMsg", function (event)
        self:setChat(event)
    end)
    eventDispatcher:addEventListenerWithFixedPriority(self.chatListener_, FixedPriority.kNormal)
    
end

function ChatNode:setChat( event )
    if self.player_name == event.chat.sender.uid or self.player_name == event.chat.recver.uid then
        -- local strData = Tools.encode("GetChatLogReq", {

        --     chat_id = self.player_name..player:getName()
        -- })
        -- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)

        -- gl:retainLoading()

        local table_ = {stamp = player:getServerTime(), chat = event.chat.msg, nickname = event.chat.sender.nickname, user_name = event.chat.sender.uid, group_name = event.chat.sender.group_nickname}

        table.insert(self.chat_list_, table_)

        self:resetChatList()

    end
end

function ChatNode:resetPlayerList( ... )

    local rn = self:getResourceNode()

    self.player_svd:clear()
    
    if table.getn(self.player_list_) > 0 then
        rn:getChildByName("text"):setVisible(false)
        rn:getChildByName("player_list"):setVisible(true)
        rn:getChildByName("chat_list"):setVisible(true)

        self.scene_:setSend(true)   
    else
        rn:getChildByName("text"):setVisible(true)
        rn:getChildByName("player_list"):setVisible(false)
        rn:getChildByName("chat_list"):setVisible(false)

        self.scene_:setSend(false)
        return
    end

    if table.getn(self.player_list_) <= 5 then
        rn:getChildByName("player_list"):setBounceEnabled(false)
    else
        rn:getChildByName("player_list"):setBounceEnabled(true)
    end

    local function createListItem(info)
        local node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/chat_player_item.csb")

        node:getChildByName("icon"):setTexture("HeroImage/"..info.icon_id..".png")
        node:getChildByName("name"):setString(info.nickname)
        node:getChildByName("lv_num"):setString(info.level)

        node:getChildByName("close"):addClickEventListener(function ( ... )

            self.close_index = node:getTag()

            local strData = Tools.encode("TalkListReq", {
                type = 2,
                user_name = info.user_name,
            })
            GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_REQ"),strData)

            gl:retainLoading()
        end)

        return node
    end

    for i,v in ipairs(self.player_list_) do
        local item = createListItem(v)

        item:setTag(i)
        item:setName("player_item_"..i)

        local func = function( ... )

            self:selectItem(item, v.user_name)

        end

        local callback = {node = item:getChildByName("background"), func = func}

        self.player_svd:addElement(item, {callback = callback})

        if self.data_.user_name ~= "" then
            if v.user_name == self.data_.user_name then
                self:selectItem(item, v.user_name)

                self.data_.user_name = ""
            end

        else
            if self.select_index < 0 then
                if i == 1 then
                    self:selectItem(item, v.user_name)
                end
            else
                if i == self.select_index then
                    self:selectItem(item, v.user_name)
                end
            end
        end
    end

end
    
function ChatNode:removeItem(  )
    
    table.remove(self.player_list_, self.close_index)

    if self.select_index >= self.close_index then
        if self.select_index ~= 1 then
            self.select_index = self.select_index - 1 
        end
    end

    print(self.select_index)

    self:resetPlayerList()

end

function ChatNode:selectItem(item, name)
    printInfo("name "..name)

    if self:getResourceNode():getChildByName("click_node") then
        self:getResourceNode():getChildByName("click_node"):removeFromParent()
    end

    local preItem = self.player_svd:getScrollView():getChildByName("player_item_"..self.select_index)
    if preItem then
        -- preItem:setScale(1)
        preItem:setOpacity(255*0.6)
        preItem:setPositionX(preItem:getPositionX() - 8)
        preItem:getChildByName("background"):setVisible(false)
        -- preItem:getChildByName("head_di"):setTexture("ChatLayer/ui/player_bottom_normal.png")
        -- preItem:getChildByName("head_kuang"):setVisible(false)

    end

    -- item:setScale(1.05)
    item:setOpacity(255)
    item:setPositionX(item:getPositionX() + 8)
    item:getChildByName("background"):setVisible(true)


    -- item:getChildByName("head_di"):setTexture("ChatLayer/ui/player_bottom_light.png")
    -- item:getChildByName("head_kuang"):setVisible(true)

    self.chat_list_ = {}
    if self.player_name ~= name then
        local str = ""

        if tonumber(name) < tonumber(player:getName()) then
            str = name..player:getName()
        elseif tonumber(name) > tonumber(player:getName()) then
            str = player:getName()..name
        end

        local strData = Tools.encode("GetChatLogReq", {

            chat_id = str
        })
        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)

        gl:retainLoading()
    end

    self.select_index = item:getTag()
    self.player_name = name

    self.scene_:setUserName(self.player_name)

end

function ChatNode:resetChatList()
    local rn = self:getResourceNode()

    self.chat_svd:clear()

    -- if table.getn(self.player_list_) > 0 then
    --     rn:getChildByName("text"):setVisible(false)   
    -- else
    --     rn:getChildByName("text"):setVisible(true)
    --     return
    -- end

    if table.getn(self.chat_list_) <= 5 then
        rn:getChildByName("chat_list"):setBounceEnabled(false)
    else
        rn:getChildByName("chat_list"):setBounceEnabled(true)
    end

    local function createOtherListItem(info)
        local node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/chat_list_item.csb")

        local string_1 = node:getChildByName("string_1")
        local string_2 = node:getChildByName("string_2")
        local string_3 = node:getChildByName("string_3")

        if info.group_name == nil then
            info.group_name = ""
        end
        
        if info.group_name ~= "" then
            string_1:setString("["..info.group_name.."]")
        else
            string_1:setString(info.group_name)
        end
        string_2:setString(info.nickname)
        string_3:setString(info.stamp)

        string_3:setString(self.scene_:formatTime(info.stamp%86400))
        string_3:setFontSize(16)

        string_3:setTextColor(cc.c4b(255, 255, 255, 255))
        -- string_3:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))

        string_1:setPositionX(0)

        local diff =  2
        if info.group_name == "" then
            diff = 0
        end

        string_2:setPositionX(string_1:getContentSize().width + diff)
        string_3:setPositionX(string_2:getPositionX() + string_2:getContentSize().width + 2)

        local label = cc.Label:createWithTTF(info.chat, "fonts/cuyabra.ttf", 16)
        label:setAnchorPoint(cc.p(0,1))
        -- label:setContentSize(node:getChildByName("text"):getContentSize())
        label:setPosition(cc.p(0, -13))
        label:setLineBreakWithoutSpace(true)
        label:setMaxLineWidth(600)
        label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        -- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
        node:addChild(label)

        node:getChildByName("text"):removeFromParent()

        node:getChildByName("button"):setTouchEnabled(false)
        node:getChildByName("button"):setPosition(cc.p(string_1:getPosition()))
        node:getChildByName("button"):setContentSize(cc.size(string_2:getContentSize().width + 2 + string_1:getContentSize().width
            , string_2:getContentSize().height))
        node:getChildByName("button"):addClickEventListener(function ( ... )
            if rn:getChildByName("click_node") then
                if rn:getChildByName("click_node"):getTag() == node:getTag() then
                    rn:getChildByName("click_node"):removeFromParent()
                    return
                else
                    rn:getChildByName("click_node"):removeFromParent()
                end

            end

            local click_node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/click_notFriend.csb")

            click_node:getChildByName("see"):addClickEventListener(function ( ... )
                if self.scene_:getChildByName("chatNode") then
                    self.scene_:getChildByName("chatNode"):removeFromParent()
                end

                local strData = Tools.encode("CmdGetOtherUserInfoReq", {
                    user_name = info.user_name,
                })
                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_REQ"),strData)

                gl:retainLoading()

                click_node:removeFromParent()
            end)

            click_node:getChildByName("mail"):addClickEventListener(function ( ... )

                local sendLayer = require("app.views.MailScene.SendMail"):create()
                self:getParent():addChild(sendLayer)
                sendLayer:init(info.nickname,info.user_name)

                click_node:removeFromParent()
            end)

            click_node:getChildByName("black"):addClickEventListener(function ( ... )

                if player:getFriendsNum(2) == CONF.PLAYERLEVEL.get(player:getLevel()).BLACK_NUM then
                    tips:tips(CONF:getStringValue("blackListIsFull"))
                    return
                end

                self.close_index = click_node:getTag()

                local strData = Tools.encode("BlackListReq", {
                    type = 1,
                    user_name = info.user_name,
                })
                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_REQ"),strData)

                gl:retainLoading()

                click_node:removeFromParent()
            end)

            click_node:getChildByName("group"):getChildByName("text"):setString(CONF:getStringValue("group_yaoqing"))
            click_node:getChildByName("group"):addClickEventListener(function ( ... )
                local strData = Tools.encode("GroupInviteReq", {
                    recver = info.user_name,
                })
                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_INVITE_REQ"),strData)

                gl:retainLoading()

                click_node:removeFromParent()
            end)


            click_node:getChildByName("mail"):setPosition(cc.p(click_node:getChildByName("friend"):getPosition()))
            click_node:getChildByName("black"):setPosition(cc.p(click_node:getChildByName("chat"):getPosition()))

            click_node:getChildByName("friend"):removeFromParent()
            click_node:getChildByName("chat"):removeFromParent()

            click_node:getChildByName("bg"):setContentSize(cc.size(click_node:getChildByName("bg"):getContentSize().width, click_node:getChildByName("bg"):getContentSize().height-80))

            if player:isGroup() then
                if player:getGroupData().job == 3 then

                    click_node:getChildByName("group"):removeFromParent()
                    click_node:getChildByName("bg"):setContentSize(cc.size(click_node:getChildByName("bg"):getContentSize().width, click_node:getChildByName("bg"):getContentSize().height - 50))
                end
            else
                click_node:getChildByName("group"):removeFromParent()
                click_node:getChildByName("bg"):setContentSize(cc.size(click_node:getChildByName("bg"):getContentSize().width, click_node:getChildByName("bg"):getContentSize().height - 50))

            end


            click_node:setPosition(cc.p(string_3:convertToWorldSpace(cc.p(0,0)).x + string_3:getContentSize().width/2 -self:getPositionX(), string_3:convertToWorldSpace(cc.p(0,0)).y - self:getPositionY()))
            click_node:setName("click_node")
            click_node:setTag(node:getTag())
            rn:addChild(click_node)

        end)

        local size = string_2:getContentSize().height + label:getContentSize().height

        return node,size

    end

    local function createMyListItem(info)
        local node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/chat_list_item.csb")

        local string_1 = node:getChildByName("string_1")
        local string_2 = node:getChildByName("string_2")
        local string_3 = node:getChildByName("string_3")

        if info.group_name == nil then
            info.group_name = ""
        end
        if info.group_name ~= "" then
            string_2:setString("["..info.group_name.."]")
        else
            string_2:setString(info.group_name)
        end
        string_3:setString(info.nickname)
        -- string_1:setString(info.stamp) 
        string_1:setString(self.scene_:formatTime(info.stamp%86400))
        string_1:setFontSize(16)

        string_1:setTextColor(cc.c4b(255, 255, 255, 255))
        -- string_1:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))

        string_3:setPositionX(530 - string_3:getContentSize().width)
        string_2:setPositionX(string_3:getPositionX() - string_2:getContentSize().width - 2)
        string_1:setPositionX(string_2:getPositionX() - string_1:getContentSize().width - 2)

        local label = cc.Label:createWithTTF(info.chat, "fonts/cuyabra.ttf", 16)
        label:setAnchorPoint(cc.p(1,1))
        -- label:setContentSize(node:getChildByName("text"):getContentSize())
        label:setPosition(cc.p(530, -13))
        label:setLineBreakWithoutSpace(true)
        label:setMaxLineWidth(380)
        label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        label:setTextColor(cc.c4b(124, 208, 138, 255))
        -- label:enableShadow(cc.c4b(124, 208, 138, 255),cc.size(0.5,0.5))
        node:addChild(label)

        node:getChildByName("button"):setVisible(false)
        -- node:getChildByName("text"):setString(info.chat)
        -- node:getChildByName("text"):setPositionX()
        -- node:getChildByName("text"):setLineBreakWithoutSpace(true)
        -- node:getChildByName("text"):setMaxLineWidth(430)

        node:getChildByName("text"):removeFromParent()


        local size = string_1:getContentSize().height + label:getContentSize().height

        return node,size

    end

    for i,v in ipairs(self.chat_list_) do

        local item 
        local size
        if v.nickname ~= player:getNickName() then
            item,size = createOtherListItem(v)
        end

        if v.nickname == player:getNickName() then
            item,size = createMyListItem(v)
        end

        item:setTag(i)
        item:setName("chat_item_"..i)

        self.chat_svd:addElement(item, {size = cc.size(444,size)})

    end

    self.chat_svd:getScrollView():getInnerContainer():setPositionY(0)

end

function ChatNode:onExitTransitionStart()
    printInfo("ChatNode:onExitTransitionStart()")

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListener(self.recvlistener_)
    eventDispatcher:removeEventListener(self.chatListener_)

end

return ChatNode