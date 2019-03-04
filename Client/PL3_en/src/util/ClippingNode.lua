local ClippingNode = class("ClippingNode")

function ClippingNode:ctor(node)
	self.node = node
    
end

function ClippingNode:createNode(Stencil_texture, sprite_texture, config) -- {sprite_scale, stencil_scale, alpha,pos} 

	local sprite = cc.Sprite:create(sprite_texture)
    sprite:setName("sprite")

    if config.sprite_scale then
    	sprite:setScale(config.sprite_scale)
    end

    if config.pos then
    	sprite:setPosition(config.pos)
    end

    local stencil = cc.Sprite:create(Stencil_texture)
    if config.stencil_scale then
    	stencil:setScale(config.stencil_scale)
    end

    local clippingNode = cc.ClippingNode:create()
    clippingNode:setStencil(stencil)
    clippingNode:setInverted(false)

    if config.alpha then
    	clippingNode:setAlphaThreshold(config.alpha)
    else
    	clippingNode:setAlphaThreshold(0.5)
    end

    clippingNode:addChild(sprite)
    clippingNode:setName("clippingNode")

	return clippingNode
end



return ClippingNode