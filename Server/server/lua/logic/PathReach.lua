
local PathReach = class("PathReach")

local State = {
	cell_state_none = 0,
	cell_state_balk = 1,
	cell_state_origin = 2,
	cell_state_target = 3,
	cell_state_close = 4,
	cell_state_open = 5,
	cell_state_path = 6,
	cell_state_check = 7,
	cell_state_next = 8,
}

function PathReach:createPoint(id, x, y)
	 
	local point = {
		id = id,
		X = x,
		Y = y,
		F = 0,
		G = 0,
		S = State.cell_state_none,
		parentPoint = nil,
	}
	return point
end

function PathReach:ctor()
	self.node_list = {}

	local nodes = CONF.PLANETWORLD.getIDList()
	for i,id in ipairs(nodes) do
		local conf = CONF.PLANETWORLD.get(id)
		local p = self:createPoint(conf.ID, conf.ROW, conf.COL)

		if self.node_list[conf.ROW] == nil then
			self.node_list[conf.ROW] = {}
		end

		self.node_list[conf.ROW][conf.COL] = p
	end
end

-- --获取列表中F值最小的点  
function PathReach:getMinPoint()
	local index = 1
	local min = self.open_list[index] 

	for i = 1, #self.open_list do  
		if self.open_list[i].F < min.F then  
			min = self.open_list[i]
			index = i
		end  
	end  
	return min, index
end 


-- --获取相邻的点  
function PathReach:getSurroundPoints(point)  
	local surroundPoints = {}
	for i = point.X - 1 ,point.X + 1 do  
		for j=point.Y - 1,point.Y + 1 do
			

			if self.node_list[i] ~= nil and self.node_list[i][j] ~= nil and self.node_list[i][j].id ~= point.id then  --排除超表  
				if math.abs(i-point.X)+math.abs(j-point.Y) == 1 then
					table.insert(surroundPoints, self.node_list[i][j])
				end
			end
		end
	end
	return surroundPoints   --返回point点的集合  
end


-- --计算F值
local function calF( endPoint, point )

	point.F = math.abs(endPoint.X - point.X) + math.abs(endPoint.Y - point.Y)
end
  

function PathReach:findPath( startPoint, endPoint)

	self.open_list = {}

	table.insert(self.open_list, startPoint)
	calF(endPoint, startPoint)

	startPoint.S = State.cell_state_origin

	while Tools.isEmpty(self.open_list) == false do
		--找出F的最小值 
		local curPoint, curIndex = self:getMinPoint()  


		--找出它相邻的点  
		local surroundPoints = self:getSurroundPoints(curPoint)
		if Tools.isEmpty(surroundPoints) == true then
			return nil
		end
		for _,nextPoint in ipairs(surroundPoints) do

			if nextPoint.id == endPoint.id then
				nextPoint.parentPoint = curPoint
				nextPoint.G = curPoint.G + 1
				nextPoint.F = 0
				return nextPoint
			end

			if nextPoint.S == State.cell_state_none 
			or (nextPoint.S == State.cell_state_close and curPoint.G + 1 < nextPoint.G)
			or (nextPoint.S == State.cell_state_open and curPoint.G + 1 < nextPoint.G) then

				nextPoint.parentPoint = curPoint
				nextPoint.G = curPoint.G + 1
				calF(endPoint, nextPoint)
				if nextPoint.S ~= State.cell_state_open then
					table.insert(self.open_list, nextPoint)
				end
				nextPoint.S = State.cell_state_open
			end
		end

		if curPoint.S ~= State.cell_state_origin then
			curPoint.S = State.cell_state_close
		end

		table.remove(self.open_list, curIndex)
	end

	return nil
end

function PathReach:clear()
	local nodes = CONF.PLANETWORLD.getIDList()
	for i,id in ipairs(nodes) do
		local conf = CONF.PLANETWORLD.get(id)
		local node = self.node_list[conf.ROW][conf.COL]
		node.F = 0
		node.G = 0
		node.S = State.cell_state_none
		node.parentPoint = nil
	end

	self.open_list = nil
end

function PathReach:getFindPathList(start_id, end_id)
	if start_id == end_id then
		return nil
	end

	local startConf = CONF.PLANETWORLD.get(start_id)
	local endConf = CONF.PLANETWORLD.get(end_id)

	local startPoint = self.node_list[startConf.ROW][startConf.COL]
	local endPoint = self.node_list[endConf.ROW][endConf.COL]

	if not startPoint or not endPoint then

		return nil
	end

	local p = self:findPath(startPoint, endPoint)
	if not p then
		return nil
	end
	local list = {p.id}

	while p.parentPoint do
		
		table.insert(list, 1, p.parentPoint.id)
		p = p.parentPoint
	end

	self:clear()

	return list
end

return PathReach