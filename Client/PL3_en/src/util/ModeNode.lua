local ModeNode = class("ModeNode")

ModeNode._node = nil

function ModeNode:set(node, str, flag)
	self._node = node

	self._node:getChildByName("panel"):getChildByName("text"):setString(str)
	self._node:getChildByName("panel"):getChildByName("icon"):setVisible(flag)
end

function ModeNode:ctor(node)
	self.node = node
    
end

function ModeNode:createNode(str, flag, func)

	local modeNode = require("app.ExResInterface"):getInstance():FastLoad("Common/ModeNode.csb")

	local panel_ = modeNode:getChildByName("panel")
	local text_ = panel_:getChildByName("text")
	local icon_ = panel_:getChildByName("icon")

	text_:setString(str)
	icon_:setVisible(flag)

	return modeNode
end

function ModeNode:setIconVisible(flag)
	self.node:getChildByName("panel"):getChildByName("icon"):setVisible(flag)
end

function ModeNode:setPanelColor(color)
	self.node:getChildByName("panel"):setBackGroundColor(color)
    self.node:getChildByName("panel"):setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

function ModeNode:getSize()
	return self.node:getChildByName("panel"):getContentSize()
end

return ModeNode