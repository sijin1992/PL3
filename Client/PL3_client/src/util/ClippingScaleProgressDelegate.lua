local ClippingScaleProgressDelegate = class("ClippingScaleProgressDelegate")

function ClippingScaleProgressDelegate:ctor(texture, maxLength, config)--{capinsets, bg_size, bg_texture, lightLength，progress_size}
	self.maxLength_ = maxLength

	if config.bg_texture then
		self.back= cc.Sprite:create(config.bg_texture)
	else
		self.back= cc.Sprite:create("Common/ui/chat_bottom.png")
	end

	self.renderer_ = ccui.ImageView:create(texture)

	if config.progress_size then
		self.renderer_:setContentSize(config.progress_size)
	end

    self.renderer_:setScale9Enabled(true)

    if config.capinsets then
    	self.renderer_:setCapInsets(config.capinsets)
    end

    self.renderer_:setAnchorPoint(cc.p(0, 0.5))
    
    self.renderer_:setPositionX(-config.bg_size.width - config.lightLength)

    self.back:setAnchorPoint(cc.p(1,0.5))
    -- back:setScale(config.bg_size.width/back:getContentSize().width, config.bg_size.height/back:getContentSize().height)
    self.back:setScale(maxLength/self.back:getContentSize().width, self.renderer_:getContentSize().height/self.back:getContentSize().height)

    self.clippingNode_ = cc.ClippingNode:create()
    self.clippingNode_:setStencil(self.back)
    self.clippingNode_:setInverted(false)
    self.clippingNode_:setAlphaThreshold(0.5)
    self.clippingNode_:addChild(self.renderer_)
    self.clippingNode_:setAnchorPoint(cc.p(1,0.5))

end

function ClippingScaleProgressDelegate:getClippingNode( ... )
	return self.clippingNode_
end

function ClippingScaleProgressDelegate:getRenderer( ... )
	return self.renderer_
end

function ClippingScaleProgressDelegate:setRendererSize( size )
	self.renderer_:setContentSize(size)

	self.back:setScale(self.maxLength_ /self.back:getContentSize().width, self.renderer_:getContentSize().height/self.back:getContentSize().height)
end

function ClippingScaleProgressDelegate:setPercentage( percentage )

	local cs = self.renderer_:getContentSize()

	self.renderer_:setContentSize(cc.size(self.maxLength_* (percentage / 100),self.renderer_:getContentSize().height))
end

return ClippingScaleProgressDelegate