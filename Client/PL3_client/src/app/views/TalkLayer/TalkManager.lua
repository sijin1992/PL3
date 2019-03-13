
local app = require("app.MyApp"):getInstance()

local player = require("app.Player"):getInstance()

local TalkManager = class("TalkManager")

TalkManager.talk_type = false 
TalkManager.msg_type = false
TalkManager.show_talk = g_show_talk

function TalkManager:ctor()
	local function recvMsg()
		--printInfo("Player:recvMsg")

		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GUIDE_STEP_RESP") then

			local proto = Tools.decode("GuideStepResp",strData)
			print("GuideStepResp", proto.result)
			if proto.result == 0 then

	            if self.talk_type then
					app:removeTopView()
				end

	            cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("talk_over")
			end
		end
	
	end

	self.recvListener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

	eventDispatcher:addEventListenerWithFixedPriority(self.recvListener_, FixedPriority.kNormal)

end

function TalkManager:addGuideStep(key)
	print("TalkManager:addGuideStep", key)
	local strData = Tools.encode("GuideStepReq", {
        type = 2,
        talk_key = key,
    })
    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GUIDE_STEP_REQ"),strData)
end

function TalkManager:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end  
		
	return self.instance  
end

function TalkManager:checkInterface( id )


end

function TalkManager:getTalkID( key )
	if CONF.TALK.check(key) then
		return CONF.TALK.get(key).ID 
	end

	return nil
end

function TalkManager:getPlayerTalkID( )

	print("player key", player:getTalkKey())

	if CONF.TALK.check(player:getTalkKey()) then
		return CONF.TALK.get(player:getTalkKey()).ID 
	end

	return nil
end

function TalkManager:addTalkLayer( index, copy_id ) -- 1战斗,2关卡,3区域,4任务


	if self.show_talk == false then

		if index == 1 then

			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("talk_over")
		end

		return
	end 
	local talk_id = self:getPlayerTalkID()
	if talk_id == nil then
		talk_id = 0
	end
	if CONF.TALK.check(talk_id+1) then
		local conf = CONF.TALK.get(talk_id + 1)
		local mode = conf.MODE 
		print("addTalkLayer",conf.ID,conf.KEY,mode, index)
		if mode == index*2 or mode == index*2-1 then

			if index == 3 then
				if mode == index*2 then
					local qu_num = math.floor(tonumber(string.sub(conf.KEY, 6))/1000)
					if qu_num < 5 then
						if player:getMaxArea() ~= qu_num + 1 then	
							return
						end
					else
						if player:getMaxArea() ~= qu_num then
							return
						end
					end
				else
					local qu_num = math.floor(tonumber(string.sub(conf.KEY, 6))/1000)
					if player:getMaxArea() < qu_num then
						return
					end
				end
			elseif index == 2 then

				local copy_num = 0
				for i,v in ipairs(CONF.CHECKPOINT.getIDList()) do
					if CONF.CHECKPOINT.get(v).TALK_ID then
						for i2,v2 in ipairs(CONF.CHECKPOINT.get(v).TALK_ID) do
							if v2 == conf.KEY then
								copy_num = v
								break
							end
						end
					end
				end

				if copy_id < CONF.CHECKPOINT.get(copy_num).AREA_ID then
					return
				end

				if mode == index*2 then
					if player:getCopyStar(copy_num) == 0 then
						return
					end
				else

					if CONF.CHECKPOINT.get(copy_num).PRE_COPYID ~= 0 then
						if player:getCopyStar(CONF.CHECKPOINT.get(copy_num).PRE_COPYID) == 0 then
							return
						end
					end
				end

			elseif index == 1 then

				local copy_num = 0
				for i,v in ipairs(CONF.CHECKPOINT.getIDList()) do
					if CONF.CHECKPOINT.get(v).TALK_ID then
						for i2,v2 in ipairs(CONF.CHECKPOINT.get(v).TALK_ID) do
							if v2 == conf.KEY then
								copy_num = v
								break
							end
						end
					end
				end

				if copy_num > copy_id then
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("talk_over")
					return
				end

				if g_Player_Battle_Talk == 0 then

					if mode ~= 1 then 
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("talk_over")
						return
					end

				elseif g_Player_Battle_Talk == 1 then

					if mode ~= 2 then
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("talk_over")
						return
					end

				end
			end

			self:createTalkLayer(conf.KEY)
		else
			if index == 1 then
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("talk_over")
			end
		end
	end
end

function TalkManager:createTalkLayer( id )

	if self.show_talk == false then
		return
	end
	print("TalkManager:createTalkLayer", id)
	
	if player:isInited() then
		player:setTalkKey(id)
	end

	if self.talk_type then
		app:removeTopView()
	end

	app:addView2Top("TalkLayer/TalkLayer", {talk_id = id})
end


function TalkManager:setTalkType( flag )
	self.talk_type = flag
end

function TalkManager:getTalkType()
	return self.talk_type
end

function TalkManager:getMsgType()
	return self.msg_type
end

function TalkManager:setMsgType( flag )
	self.msg_type = flag
end

function TalkManager:setShowTalk( flag )
	self.show_talk = flag
end

function TalkManager:getShowTalk()
	return self.show_talk
end

return TalkManager