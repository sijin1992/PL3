

local TipsMessage = class("TipsMessage")

function TipsMessage:ctor()
    
end

function TipsMessage:getInstance()
    if self.instance == nil then
        self.instance = self:create()
    end
        
    return self.instance
end


function TipsMessage:tips(str,labelColor,bgPath)

	if self.renderer_ ~= nil then
		if self.renderer_:getParent() ~= nil then
			self.renderer_:removeFromParent()
		end
		self.renderer_:release()
		self.renderer_ = nil
	end

	local scene = display.getRunningScene()

	local center = cc.exports.VisibleRect:center()

	local back
    if bgPath then
        back = cc.Scale9Sprite:create(bgPath)
        back:getOriginalSize()
    else
        back = cc.Scale9Sprite:create("ChatLayer/cs.png")--cc.Scale9Sprite:create("ui_tips_message_back.png")
    end

	local ttfConfig = {}
    	ttfConfig.fontFilePath = s_default_font
    	ttfConfig.fontSize = 24
	local label = cc.Label:createWithTTF(ttfConfig,str,cc.VERTICAL_TEXT_ALIGNMENT_CENTER,500)
	label:setLineBreakWithoutSpace(true)
    if labelColor then
        label:setTextColor(labelColor)
    else
	    label:setTextColor(cc.c4b(255, 255, 255, 255))
	-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
    end

	local size = label:getContentSize()

	back:setContentSize(cc.size(size.width + 50, size.height+50))
	back:setPosition(center)

	scene:addChild(back, SceneZOrder.kTips)

	label:setPosition( back:getContentSize().width/2, back:getContentSize().height/2)
	back:addChild(label)

	local function actionOK(sender)
		self.renderer_:removeFromParent()
		self.renderer_:release()
		self.renderer_ = nil
	end

	local spawn = cc.Spawn:create(cc.MoveBy:create(1, cc.p(0,100)),cc.FadeOut:create(1))
	back:runAction(cc.Sequence:create(spawn,cc.CallFunc:create(actionOK)))

	self.renderer_ = back
	self.renderer_:retain()
end

return TipsMessage