
local LotteryShowNode = class("LotteryShowNode", cc.load("mvc").ViewBase)

local app = require("app.MyApp"):getInstance()

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

LotteryShowNode.RESOURCE_FILENAME = "LotteryScene/showLotteryNode.csb"

LotteryShowNode.selectedBtn = 2

function LotteryShowNode:onEnterTransitionFinish()

end

function LotteryShowNode:createNode( id,spcail )
	local itemNode = require("util.ItemNode"):create():init(id)
	itemNode:getChildByName('Image_1'):setVisible(false)
	-- itemNode:getChildByName('Image_1'):loadTexture('LotteryScene/ui/must.png')



	return itemNode
end

function LotteryShowNode:resetList()
	local rn = self:getResourceNode()
	rn:getChildByName('btn_show1'):getChildByName('light'):setVisible(false)
	rn:getChildByName('btn_show2'):getChildByName('light'):setVisible(false)
	rn:getChildByName('btn_show'..self.selectedBtn):getChildByName('light'):setVisible(true)
	self.svd_:clear()
	local cfg_lottery = CONF.SHIP_LOTTERY.get(self.selectedBtn)
	local heap_items = {}
	local heap_item = {}
	for k,v in ipairs(cfg_lottery.HEAP_ITEM) do
		if not heap_item[v] then
			heap_item[v] = k
			table.insert(heap_items,v)
		end
	end
	table.sort(heap_items)
--	for k,v in ipairs(heap_items) do
--		local node = self:createNode(v,true)
--		self.svd_:addElement(node)
--	end
	local item = cfg_lottery.ITEM
	for k1,v1 in pairs(heap_item) do
		for i = #item ,1,-1 do
			if item[i] == tonumber(k1) then
				table.remove(item,i)
				item[i] = nil
			end
		end
	end
	local items1 = {}
	local items = {}
	for k,v in ipairs(item) do
		if not items1[v] then
			items1[v] = k
			table.insert(items,v)
		end
	end
	table.sort(items)

    local allitems = {}
    for k,v in ipairs(heap_items) do
        local iteminfo = CONF.ITEM.get(v)
        table.insert(allitems,{id = v,quality = iteminfo.QUALITY})
    end
    for k,v in ipairs(items) do
        local iteminfo = CONF.ITEM.get(v)
        table.insert(allitems,{id = v,quality = iteminfo.QUALITY})
    end
    local function sortitem(a,b)
        if a.quality ~= b.quality then
            return a.quality > b.quality
        else
            return a.id > b.id
        end
    end
    table.sort(allitems,sortitem)

	for k,v in ipairs(allitems) do
		local node = self:createNode(v.id,false)
		self.svd_:addElement(node)
	end
	
end


function LotteryShowNode:init(scene,data)

	self.scene_ = scene
	self.data_ = data

	local rn = self:getResourceNode()

	--rn:getChildByName('text'):setString(CONF:getStringValue('jackpot'))
	rn:getChildByName('btn_show1'):getChildByName('text'):setString(CONF:getStringValue('jackpot_gold'))
	rn:getChildByName('btn_show2'):getChildByName('text'):setString(CONF:getStringValue('jackpot_credit'))
	rn:getChildByName("back"):setSwallowTouches(true)
	rn:getChildByName("back"):addClickEventListener(function ( sender )
		-- playEffectSound("sound/system/return.mp3")
		-- self:removeFromParent()
	end)
	rn:getChildByName('btn_show1'):addClickEventListener(function()
		if self.selectedBtn ~= 1 then
			self.selectedBtn = 1
			self:resetList(self.selectedBtn)
		end
		end)
	rn:getChildByName('btn_show2'):addClickEventListener(function()
		if self.selectedBtn ~= 2 then
			self.selectedBtn = 2
			self:resetList(self.selectedBtn)
		end
		end)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(10,10), cc.size(100,100))
	self.svd_:getScrollView():setScrollBarEnabled(false)

	self:resetList(self.selectedBtn)

	rn:getChildByName("closeBtn"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/return.mp3")
		self:removeFromParent()
	end)

	tipsAction(self)


	-- 180724 wjj 
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_JiangChi(self)
end


function LotteryShowNode:onExitTransitionStart()
	printInfo("LotteryShowNode:onExitTransitionStart()")

end

return LotteryShowNode