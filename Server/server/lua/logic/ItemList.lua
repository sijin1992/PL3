local ItemList = {}

function ItemList:addItem(item_id, item_num)
	local item_list = self:getItemList()
	CoreItem.addItemList(item_id, item_num, item_list)
end

function ItemList:getItemBuff()
	local pb = require "protobuf"
	return pb.encode("ItemList", self.m_item_list)
end

function ItemList:getItemList()
	return rawget(self.m_item_list, "item_list")
end

function ItemList:new(item_buff)
	local item_list
	if item_buff then
		local pb = require "protobuf"
		item_list = pb.decode("ItemList", item_buff)
	else
		item_list = {}
	end
	if not rawget(item_list, "item_list") then
		item_list.item_list = {}
	end
	self.m_item_list = item_list
end

return ItemList
