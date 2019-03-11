
local SlaveNode = class("SlaveNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

SlaveNode.RESOURCE_FILENAME = "ChatLayer/world_list.csb"

function SlaveNode:onEnterTransitionFinish()

end

function SlaveNode:init(scene,data)

    self.scene_ = scene

    local rn = self:getResourceNode()

    rn:getChildByName("list"):setSwallowTouches(false)
    rn:getChildByName("list"):setScrollBarEnabled(false)
    self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(10,10), cc.size(850,66))

    local strData = Tools.encode("GetChatLogReq", {

        chat_id = 0,
        minor = {3},
    })
    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)

    gl:retainLoading()

    local function recvMsg()
        print("SlaveNode:recvMsg")
        local cmd,strData = GameHandler.handler_c.recvProtobuf()

        if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("GetChatLogResp",strData)
            if proto.result < 0 then
                print("error :",proto.result)
            else

                self.list_ = proto.log_list

                self:resetList()

            end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_RESP") then
            gl:releaseLoading()
            
            local proto = Tools.decode("CmdGetOtherUserInfoResp",strData)
            if proto.result ~= 0 then
                printInfo("proto error")  
            else

                -- local node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/chatNode.csb")

                -- -- node:getChildByName("head"):setTexture("RoleIcon/"..proto.info.icon_id..".png")
                -- node:getChildByName("name"):setString(proto.info.nickname)
                -- node:getChildByName("lv_num"):setString(proto.info.level)
                -- node:getChildByName("lv_num_0"):setString(proto.info.level)
                -- node:getChildByName("fight_num_0"):setString(proto.info.power)
                -- node:getChildByName("close"):getChildByName("text"):setString(CONF:getStringValue("closed"))
                -- node:getChildByName("close"):addClickEventListener(function ( ... )
                --     node:removeFromParent()
                -- end)

                -- node:setName("chatNode")
                -- node:setPosition(cc.p(749,211))
                -- self.scene_:addChild(node)

                local node = app:createView("ChatLayer/ChatNode2", {data = proto})
                node:setName("chatNode")
                node:setPosition(cc.p(self.scene_:getResourceNode():getChildByName("chat_node_pos"):getPosition()))
                self.scene_:addChild(node)
            end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("SlaveSyncDataResp",strData)
            --print("SlaveSyncDataResp",proto.result)

            if proto.result ~= "OK" then
                print("error :",proto.result)
            else

                if proto.slave_data_list[1] and proto.slave_data_list[1].state == 2 then
                    self:craeteSlaveNode(proto.slave_data_list[1], proto.info_list[1])
                else
                    tips:tips(CONF:getStringValue("show_end"))
                end
            end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SHOW_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("SlaveShowResp",strData)
            print("SlaveShowResp",proto.result)

            if proto.result == "NO_MASTER" then
                tips:tips(CONF:getStringValue("show_end"))

                elf.scene_:getChildByName("visit_node"):removeFromParent()
            elseif proto.result ~= "OK" then
                print("error :",proto.result)
            else
                self.scene_:getChildByName("visit_node"):getChildByName("weiguan_button"):setEnabled(false)

                local conf = CONF.ITEM.get(proto.get_item_list[1].key)

                local node = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/visit_win.csb")

                node:getChildByName("text_1"):setString(CONF:getStringValue("show_gain"))

                node:getChildByName("back"):addClickEventListener(function ( ... )
                    node:removeFromParent()
                end)

                node:getChildByName("confirm"):setString(CONF:getStringValue("yes"))

                node:getChildByName("confirm_button"):addClickEventListener(function ( ... )
                    node:removeFromParent()
                end)

                node:getChildByName("icon"):loadTexture("ItemIcon/"..conf.ICON_ID..".png")
                node:getChildByName("currency"):setString(proto.get_item_list[1].value)

                self.scene_:addChild(node)

                tipsAction(node)

            end 

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("BlackListResp",strData)
            if proto.result ~= 0 then
                print("error :",proto.result)
            else
                
                tips:tips(CONF:getStringValue("add black ok"))

                player:addBlack(self.black_name)
            end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("TalkListResp",strData)

            if proto.result == 1 then
                self.scene_:resetNode("chat", {user_name = self.talk_name})
            elseif proto.result ~= 0 then
                print("error :",proto.result)
            else
                
                self.scene_:resetNode("chat", {user_name = self.talk_name})
            end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_APPLY_FRIEND_RESP") then
            gl:releaseLoading()

            local proto = Tools.decode("ApplyFriendResp",strData)

            if proto.result == "FAIL" then
                print("error :",proto.result)
            else

                if proto.result == "SENDED" then
                    tips:tips(CONF:getStringValue("appling friend now"))

                    -- self.svd_:getScrollView():getChildByName("item_"..self.add_index):getChildByName("botton"):setVisible(false)
                elseif proto.result == "OTHER_BLACK" then
                    tips:tips(CONF:getStringValue("you in this player blacklist"))
                elseif proto.result == "MY_BLACK" then
                    tips:tips(CONF:getStringValue("this player in you blacklist"))
                else
                    tips:tips(CONF:getStringValue("apply friend mail is send"))
                end
            end

        end

    end

    self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

    self.msgListener_ = cc.EventListenerCustom:create("slaveMsg", function (event)

        -- local chat = event.chat[4]..CONF:getStringValue("visit_text_1")..event.chat[3]..CONF:getStringValue("visit_text_2")
        -- local table_ = {stamp = player:getServerTime(), nickname = event.chat[3], master_nickname = event.chat[4], user_name = event.chat[2], chat = chat}

        -- table.insert(self.list_, table_)

        -- self:resetList()

        local strData = Tools.encode("GetChatLogReq", {

            chat_id = 0,
            minor = {3},
        })
        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)
    end)
    eventDispatcher:addEventListenerWithFixedPriority(self.msgListener_, FixedPriority.kNormal)


end

function SlaveNode:changeChat( str )

    local richText = ccui.RichText:create()

    local fontName = s_default_font

    local fontSize = 20

    if not string.find(str,"#") then
        local label = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, str, fontName, fontSize, 2 ) 
        richText:pushBackElement(label) 

        local label2 = ccui.RichElementText:create( 2, cc.c3b(255, 244, 121), 255, CONF:getStringValue("visit_button"), fontName, fontSize, 6 ) 
        richText:pushBackElement(label2) 

        return richText

    else
        if string.sub(str, 1,1) ~= "#" then
            local label = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, str, fontName, fontSize, 2 ) 
            richText:pushBackElement(label) 

            local label2 = ccui.RichElementText:create( 2, cc.c3b(255, 244, 121), 255, CONF:getStringValue("visit_button"), fontName, fontSize, 6 ) 
            richText:pushBackElement(label2) 

            return richText
        end

    end

    
    local strs = {}

    print("changeChat")

    while true do
        if not string.find(str,"#") then
        
            table.insert(strs,str)
            break
        end

        local pos1 = string.find(str,"#")

        local sr = string.sub(str, 1, pos1-1)

        if sr ~= "" then
            table.insert(strs, sr)
        end

        local ssr = string.sub(str,pos1,pos1+8)
        table.insert(strs, ssr)

        str = string.sub(str, pos1+9)
    end

    local labels = {}

    for i=1,#strs/2 do
        local v1 = strs[i*2-1]
        local v2 = strs[i*2]

        local sttr = string.sub(v1,2)

        local s1 = string.sub(sttr,1,2)
        local s2 = string.sub(sttr,3,4)
        local s3 = string.sub(sttr,5,6)
        local s4 = string.sub(sttr,7,8)

        local color1 = tonumber(s1, 16)
        local color2 = tonumber(s2, 16)
        local color3 = tonumber(s3, 16)
        local flags = tonumber(s4)

        local label = ccui.RichElementText:create( i, cc.c3b(color1, color2, color3), 255, v2, fontName, fontSize, flags ) 

        table.insert(labels,label)
    end

    for i,v in ipairs(labels) do
        richText:pushBackElement(v) 
    end

    local label2 = ccui.RichElementText:create( #labels+1, cc.c3b(255, 244, 121), 255, CONF:getStringValue("visit_button"), fontName, fontSize, 6 ) 
    richText:pushBackElement(label2) 

    return richText

end

function SlaveNode:craeteSlaveNode( data,info,isAction )    
    local node = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/visit.csb")
    node:setName("visit_node")

    node:getChildByName("slave_portrait"):loadTexture("HeroImage/"..info.icon_id..".png")
    node:getChildByName("zhuren"):setString(CONF:getStringValue("host")..":")
    node:getChildByName("name"):setString(info.master_nickname)
    node:getChildByName("shizhong_slave"):setString(CONF:getStringValue("show_salve")..":")
    node:getChildByName("slave_name"):setString(info.nickname)
    node:getChildByName("weiguan_character"):setString(CONF:getStringValue("visit_quantity")..":")
    node:getChildByName("weiguan_quantity"):setString(#data.watch_list)
    node:getChildByName("weiguan_limit"):setString("/"..CONF.PARAM.get("slave_watch_num").PARAM)

    node:getChildByName("end_time"):setString(formatTime(CONF.PARAM.get("slave_show_time").PARAM - (player:getServerTime() - data.show_start_time))..CONF:getStringValue("show_end"))

    local function setPos( name1,name2 )
        node:getChildByName(name1):setPositionX(node:getChildByName(name2):getPositionX() + node:getChildByName(name2):getContentSize().width)
    end

    setPos("name", "zhuren")
    setPos("slave_name", "shizhong_slave")
    setPos("weiguan_quantity", "weiguan_character")
    setPos("weiguan_limit", "weiguan_quantity")


    node:getChildByName("back"):addClickEventListener(function ( ... )
        node:removeFromParent()
    end)

    local has = false
    for i,v in ipairs(data.watch_list) do
        if v == player:getName() then
            has = true
            break
        end
    end

    if has then
        node:getChildByName("weiguan_button"):setEnabled(false)
    end

    node:getChildByName("weiguan"):setString(CONF:getStringValue("weiguan"))
    node:getChildByName("weiguan_button"):addClickEventListener(function ( ... )

        if info.master == player:getName() then
            self.scene_:getApp():pushToRootView("SlaveScene/SlaveScene")
            return
        end

        if info.user_name == player:getName() then
            self.scene_:getApp():pushToRootView("SlaveScene/SlaveScene")
            return
        end

        local strData = Tools.encode("SlaveShowReq", {    
            type = 2,
            slave_name =  data.user_name,
        })
        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SHOW_REQ"),strData)
        gl:retainLoading()
    end)

    self.scene_:addChild(node)

    tipsAction(node)
end

function SlaveNode:resetList()
    local rn = self:getResourceNode()

    if table.getn(self.list_) <= 5 then
        rn:getChildByName("list"):setBounceEnabled(false)
    else
        rn:getChildByName("list"):setBounceEnabled(true)
    end

    self.svd_:clear()

    local function createListItem( info )
        local item = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/Slave_list_item.csb")

        local string_1 = item:getChildByName("string_1")
        local string_2 = item:getChildByName("string_2")
        local string_3 = item:getChildByName("string_3")
        local string_4 = item:getChildByName("string_4")
        local btn = item:getChildByName("button")

        string_1:removeFromParent()
        string_2:removeFromParent()

        string_3:setString(CONF:getStringValue("system"))
        string_4:setString(self.scene_:formatTime(info.stamp%86400))

        string_4:setFontSize(16)

        string_3:setPositionX(0)
        string_4:setPositionX(string_3:getContentSize().width + 2)

        -- local label = cc.Label:createWithTTF(info.chat, "fonts/cuyabra.ttf", 16)
        -- label:setAnchorPoint(cc.p(0,1))
        -- -- label:setContentSize(node:getChildByName("text"):getContentSize())
        -- label:setPosition(cc.p(0, -13))
        -- label:setLineBreakWithoutSpace(true)
        -- label:setMaxLineWidth(666)
        -- label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        -- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))

        -- if info.nickname == player:getNickName() then
        --     string_4:setPositionX(830 - string_4:getContentSize().width)
        --     string_3:setPositionX(string_4:getPositionX() - 2 - string_3:getContentSize().width)

        --     label:setAnchorPoint(cc.p(1,1))
        --     label:setPosition(cc.p(830, -13))
 
        --     label:setTextColor(cc.c4b(124, 208, 138, 255))
        --     label:enableShadow(cc.c4b(124, 208, 138, 255),cc.size(0.5,0.5))
        -- end

        -- item:addChild(label)

        btn:setPosition(cc.p(string_3:getPosition()))
        btn:setContentSize(cc.size(string_3:getContentSize().width, string_3:getContentSize().height + 3))

        -- btn:addClickEventListener(function ( ... )

        --     if rn:getChildByName("click_node") then
        --         if rn:getChildByName("click_node"):getTag() == node:getTag() then
        --             rn:getChildByName("click_node"):removeFromParent()
        --             return
        --         else
        --             rn:getChildByName("click_node"):removeFromParent()
        --         end
        --     end

        --     if player:getName() ~= info.user_name then
        --         local click_node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/click_notFriend.csb")

        --         click_node:getChildByName("see"):getChildByName("text"):setString(CONF:getStringValue("info"))
        --         click_node:getChildByName("see"):addClickEventListener(function ( ... )
        --             if self.scene_:getChildByName("chatNode") then
        --                 self.scene_:getChildByName("chatNode"):removeFromParent()
        --             end

        --             local strData = Tools.encode("CmdGetOtherUserInfoReq", {
        --                 user_name = info.user_name,
        --             })
        --             GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_REQ"),strData)

        --             gl:retainLoading()

        --             click_node:removeFromParent()
        --         end)

        --         click_node:getChildByName("friend"):getChildByName("text"):setString(CONF:getStringValue("addFriend"))
        --         click_node:getChildByName("friend"):addClickEventListener(function ( ... )
        --             local strData = Tools.encode("ApplyFriendReq", {
        --                 recver = info.user_name,
        --             })
        --             GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_APPLY_FRIEND_REQ"),strData)

        --             gl:retainLoading()

        --             click_node:removeFromParent()
        --         end)

        --         click_node:getChildByName("chat"):getChildByName("text"):setString(CONF:getStringValue("privateChat"))
        --         click_node:getChildByName("chat"):addClickEventListener(function ( ... )
        --             self.talk_name = info.user_name

        --             local strData = Tools.encode("TalkListReq", {
        --                 type = 1,
        --                 user_name = info.user_name,
        --             })
        --             GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_REQ"),strData)

        --             gl:retainLoading()

        --             click_node:removeFromParent()
        --         end)

        --         click_node:getChildByName("mail"):getChildByName("text"):setString(CONF:getStringValue("mail"))
        --         click_node:getChildByName("mail"):addClickEventListener(function ( ... )
        --             printInfo("mail")

        --             local sendLayer = require("app.views.MailScene.SendMail"):create()
        --             self:getParent():addChild(sendLayer)
        --             sendLayer:init(info.nickname,info.user_name)

        --             click_node:removeFromParent()
        --         end)

        --         click_node:getChildByName("black"):getChildByName("text"):setString(CONF:getStringValue("black"))
        --         click_node:getChildByName("black"):addClickEventListener(function ( ... )

        --             if player:getFriendsNum(2) == CONF.PLAYERLEVEL.get(player:getLevel()).BLACK_NUM then
        --                 tips:tips(CONF:getStringValue("blackListIsFull"))
        --                 return
        --             end
                    
        --             self.black_name = info.user_name

        --             local strData = Tools.encode("BlackListReq", {
        --                 type = 1,
        --                 user_name = info.user_name,
        --             })
        --             GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_REQ"),strData)

        --             gl:retainLoading()

        --             click_node:removeFromParent()
        --         end)

        --             click_node:getChildByName("group"):getChildByName("text"):setString(CONF:getStringValue("group_yaoqing"))
        --         click_node:getChildByName("group"):addClickEventListener(function ( ... )
        --             local strData = Tools.encode("GroupInviteReq", {
        --                 recver = info.user_name,
        --             })
        --             GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_INVITE_REQ"),strData)

        --             gl:retainLoading()

        --             click_node:removeFromParent()
        --         end)

        --         if player:isFriend(info.user_name) then
        --             click_node:getChildByName("group"):setPosition(cc.p(click_node:getChildByName("black"):getPosition()))
        --             click_node:getChildByName("black"):setPosition(cc.p(click_node:getChildByName("mail"):getPosition()))
        --             click_node:getChildByName("mail"):setPosition(cc.p(click_node:getChildByName("chat"):getPosition()))
        --             click_node:getChildByName("chat"):setPosition(cc.p(click_node:getChildByName("friend"):getPosition()))

        --             click_node:getChildByName("friend"):removeFromParent()

        --             click_node:getChildByName("bg"):setContentSize(cc.size(click_node:getChildByName("bg"):getContentSize().width, click_node:getChildByName("bg"):getContentSize().height - 50))
        --         end

        --         if player:isGroup() then
        --             if player:getGroupData().job == 3 then

        --                 click_node:getChildByName("group"):removeFromParent()
        --                 click_node:getChildByName("bg"):setContentSize(cc.size(click_node:getChildByName("bg"):getContentSize().width, click_node:getChildByName("bg"):getContentSize().height - 50))
        --             end
        --         else
        --             click_node:getChildByName("group"):removeFromParent()
        --             click_node:getChildByName("bg"):setContentSize(cc.size(click_node:getChildByName("bg"):getContentSize().width, click_node:getChildByName("bg"):getContentSize().height - 50))

        --         end
                

        --         click_node:setPosition(cc.p(string_3:convertToWorldSpace(cc.p(0,0)).x + string_3:getContentSize().width/2 -self:getPositionX(), string_3:convertToWorldSpace(cc.p(0,0)).y - self:getPositionY()))
        --         click_node:setName("click_node")
        --         click_node:setTag(item:getTag())
        --         rn:addChild(click_node)
        --     end
        -- end)

        -- local text_1 = item:getChildByName("text_1")
        -- local text_2 = item:getChildByName("text_2")

        -- local function setPos( text1,text2 )
        --     text2:setPositionX(text1:getPositionX() + text1:getContentSize().width)
        -- end

        -- text_1:setString(info.chat)
        -- text_2:setString(CONF:getStringValue("visit_button"))

        -- text_2:addClickEventListener(function ( ... )
        --     local strData = Tools.encode("SlaveSyncDataReq", {
        --         type = 0,
        --         user_name_list = {info.user_name}
        --     })
        --     GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)

        --     gl:retainLoading()
        -- end)

        -- setPos(text_1,text_2)

        local richText = self:changeChat(info.chat)
        richText:setAnchorPoint(cc.p(0,1))
        richText:setPosition(cc.p(item:getChildByName("text_1"):getPosition()))

        richText:setTouchEnabled(true)
        richText:addClickEventListener(function ( ... )
            local strData = Tools.encode("SlaveSyncDataReq", {
                type = 0,
                user_name_list = {info.user_name}
            })
            GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)

            gl:retainLoading()
        end)

        item:addChild(richText)

        item:getChildByName("text_1"):removeFromParent()

        local size = string_3:getContentSize().height + 22

        return item,size
    end

    for i,v in ipairs(self.list_) do

        local item,size = createListItem(v)

        item:setTag(i)
        item:setName("chat_item_"..i)

        self.svd_:addElement(item, {size = cc.size(850, size)})

    end

    self.svd_:getScrollView():getInnerContainer():setPositionY(0)
end

function SlaveNode:onExitTransitionStart()

    printInfo("SlaveNode:onExitTransitionStart()")

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListener(self.recvlistener_)
    eventDispatcher:removeEventListener(self.msgListener_)

end

return SlaveNode