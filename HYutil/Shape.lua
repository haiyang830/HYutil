package.path = "L:\\HYutil\\HYutil\\?.lua;".."I:\\HYutil\\HYutil\\?.lua;"..package.path
local HYutil = require("HY")
local Path = require("Path")
---------------------------------------------
-- SHAPE ------------------------------------
---------------------------------------------
local Shape = {
	tag={createShape=false, toTable=false, closed=false, pathNew=false, lengthAll=false, stepAll=false}
}

Shape = HYutil:new(Shape)

function Shape:createShape() --> table ShapeObj
	--重置 method tag
	for tag_name in pairs(self.tag) do
		self.tag[tag_name] = false
	end
	--清除cache
	for cache_name in pairs(self.cache) do
		self.cache[cache_name] = nil
	end

	if type(self[1]) == "string" then
		self:toTable()
	else
		assert(type(self[1]) == "table", "shape object error!")
	end

	self.tag.createShape = true

	return self
end

--图形转为表数据（多条path）
-- exp: "m 0 0 l 1 1 2 2 b 3 3 4 4 5 5 m 0 0 1 1" --> { { {{0,0},{1,1}}, {{1,1},{2,2}}, {{2,2},{3,3},{4,4},{5,5}} }, { {{0,0},{1,1}} } }
function Shape:toTable(re_path, re_p) --> table ShapeObj

	if not self.shape_conf then
		self.shape_conf = self[1] --保存shape字符串
	end
	assert(type(self.shape_conf) == "string", "shape string error! (not string)")
	assert(#self.shape_conf >= 11, "shape string error! (points must >= 2)")

	for k, _ in ipairs(self) do --初始化对象
		self[k] = nil
	end

	re_path = re_path or "m ([%-%d%.lb ]+)"
	re_p = re_p or "[%-%d%.lb]+"
	--按m分开图形代码
	for path_str in string.gmatch(self.shape_conf, re_path) do
		local path = {}
		local p_split = {}
		--分割图形代码内point
		for p_str in string.gmatch(path_str, re_p) do
			p_split[#p_split+1] = tonumber(p_str) or p_str
		end

		local limit_num = 50000 --防止错误的绘图代码导致死循环，此为循环上限（可能会对复杂绘图代码造成问题）
		local err_message = "shape string error or too long, check the shape string or limit_num"

		local split_key = 0
		repeat
			if p_split[split_key+3] == "b" then
				repeat
					local p = {}
					for i=1, 4 do
						split_key = split_key + 2
						if p_split[split_key-1] == "b" then
							split_key = split_key + 1
						end
						local point = {}
						point[1] = p_split[split_key-1]
						point[2] = p_split[split_key]
						p[i] = point
					end
					split_key = split_key - 2
					path[#path+1] = p

					limit_num = limit_num - 1
					assert(limit_num > 0, err_message)

				until p_split[split_key+3] == "l" or split_key + 2 == #p_split
			elseif p_split[split_key+3] == "l" then
				repeat
					local p = {}
					for i=1, 2 do
						split_key = split_key + 2
						if p_split[split_key-1] == "l" then
							split_key = split_key + 1
						end
						local point = {}
						point[1] = p_split[split_key-1]
						point[2] = p_split[split_key]
						p[i] = point
					end
					split_key = split_key - 2
					path[#path+1] = p

					limit_num = limit_num - 1
					assert(limit_num > 0, err_message)

				until p_split[split_key+3] == "b" or split_key + 2 == #p_split
			end

			limit_num = limit_num - 1
			assert(limit_num > 0, err_message)

		until split_key + 2 == #p_split

		--去除距离为0的线（距离为0的线会导致pointAtStep出现无法正确到达下个step路径的问题）
		local path_chk = {}
		for _, p in ipairs(path) do
			if #p == 2 then
				if p[1][1] ~= p[2][1] or p[1][2] ~= p[2][2] then --ax ~= bx or ay ~= by
					path_chk[#path_chk+1] = p
				end
			elseif #p == 4 then
				if p[1][1] ~= p[4][1] or p[1][2] ~= p[4][2] then --ax ~= dx or ay ~= dy
					path_chk[#path_chk+1] = p
				end
			end
		end

		self[#self+1] = path_chk
	end

	self.tag.createShape = true
	self.tag.toTable = true

	return self
end

--开放图形转为闭合图形 （对已闭合的图形无效）
function Shape:closed() --> table ShapeObj

	if not self.tag.createShape then self:createShape() end

	for _, path in ipairs(self) do
		local p_end = path[#path]
		local p_start = path[1]
		--判断是否为开放路径
		if p_end[#p_end][1] ~= p_start[1][1] and p_end[#p_end][2] ~= p_start[1][2] then
			local p_closed = {
				p_end[#p_end],
				p_start[1]
			}
			path[#path+1] = p_closed
		end
	end

	self.tag.closed = true

	return self
end

--所有分割路径继承Class path
function Shape:pathNew() --> table ShapeObj

	if not self.tag.createShape then self:createShape() end

	for _, path in ipairs(self) do
		path = Path:new(path)
	end

	self.tag.pathNew = true --标记为 已运行

	return self
end

--计算路径总长
function Shape:lengthAll() --> table ShapeObj

	if not self.tag.pathNew then self:pathNew() end

	--储存单个path内的路径长度（包含总长）
	local LEN = {}
	setmetatable(LEN, {__mode="k"})
	LEN.sum = 0

	for _, path in ipairs(self) do --计算单个图形内路径的所有长度
		path:lengthAll()
		LEN[path] = path.len.sum
		LEN.sum = LEN.sum + LEN[path]
	end
	self.len = LEN

	self.tag.lengthAll = true --标记为 已运行

	return self
end

--计算每个图形的总step
function Shape:stepAll() --> table ShapeObj

	if not self.step then self.step = {sum=1} end
	assert(type(self.step.sum) == "number", "number 'step.sum' not found!")

	if not self.tag.lengthAll then self:lengthAll() end --计算图形所有路径长度

	local STEP = {}
	setmetatable(STEP, {__mode="k"})
	STEP.sum = self.step.sum

	for _, path in ipairs(self) do

		local step_single = path.len.sum / self.len.sum * STEP.sum
		STEP[path] = step_single --单个图形对象所需要的step数

		path.step = { sum=STEP[path] }
		path:stepAll() --根据单个图形的step数（step.sum的值）  计算每条路径的step数

	end

	self.step = STEP

	self.tag.stepAll = true

	return self
end

--返回指定step处对应 路径, 曲线, x, y
function Shape:pointAtStep(step) --> table PathObj, table BezierObj/LineObj, number x, number y

	if not self.tag.stepAll then self:stepAll() end

	if step > self.step.sum then
		step = self.step.sum
	elseif step < 0 then
		step = 0
	end

	if not self.cache.pointAtStep then
		self.cache.pointAtStep = {
				step_prev = -math.huge,
				step_sum_prev = self.step[self[1]],
				key_prev = 1
		}
	end

	local step_prev = self.cache.pointAtStep.step_prev --上一次的step
	local step_sum = self.cache.pointAtStep.step_sum_prev --上一次的step_sum
	local key = self.cache.pointAtStep.key_prev --上一次path表的key

	if step > step_prev then --当前step大于上一次step 则从上一次的key为起点 正向遍历shape表
		for i=key, #self do
			local path = self[i]

			if i ~= key then
				step_sum = step_sum + self.step[path]
			end

			--if step_sum >= step then
			if math.fCompar(step_sum, ">=", step) then
				local step_diff = step_sum - self.step[path]
				self.cache.pointAtStep.step_prev = step
				self.cache.pointAtStep.step_sum_prev = step_sum
				self.cache.pointAtStep.key_prev = i
				return path, path:pointAtStep(step - step_diff)
			end
		end
	elseif step < step_prev then --当前step小于上一次step 则从上一次的key为起点 反向遍历shape表
		for i=key, 1, -1 do
			local path = self[i]

			step_sum = step_sum - self.step[path]

			--if step_sum <= step then
			if math.fCompar(step_sum, "<=", step) then
				local step_diff = step_sum
				self.cache.pointAtStep.step_prev = step
				self.cache.pointAtStep.step_sum_prev = step_sum + self.step[path]
				self.cache.pointAtStep.key_prev = i
				return path, path:pointAtStep(step - step_diff)
			end
		end
	elseif step == step_prev then --当前step等于上一次step 直接返回
		local path = self[key]
		local step_diff = step_sum - self.step[path]
		return  path, path:pointAtStep(step - step_diff)
	end
	--no tag func
end

--返回指定step处的点坐标 路径循环模式
function Shape:pointAtStepModeLoop(step) --> number x, number y

	if not self.tag.stepAll then self:stepAll() end

	local x, y

	if step >= 0 and step <= self.step.sum then
		_, _, x, y = self:pointAtStep(step)
	elseif step < 0 then
		step = math.abs(step)
		local shape = self:_tblClone()
		shape:changeDirection("reverse", "reverse", "reverse")
		_, _, x, y = shape:pointAtStep(step)
	elseif step > self.step.sum then
		_, _, x, y = self:pointAtStep(step - self.step.sum)
	end
	--no tag func
	return x, y
end

--返回指定step处点坐标 路径延伸模式
function Shape:pointAtStepModeExtend(step) --> number x, number y

	if not self.tag.stepAll then self:stepAll() end

	local x, y

	if step >= 0 and step <= self.step.sum then
		_, _, x, y = self:pointAtStep(step)
	elseif step < 0 then
		step = math.abs(step)
		local _, _, x_t0, y_t0 = self:pointAtStep(0)
		_, _, x, y = self:pointAtStep(step)
		x, y = x_t0 * 2 - x, y_t0 * 2 - y
	elseif step > self.step.sum then
		local _, _, x_t1, y_t1 = self:pointAtStep(self.step.sum)
		local shape = self:_tblClone()
		shape:changeDirection("reverse", "reverse", "reverse")
		_, _, x, y = shape:pointAtStep(step - self.step.sum)
		x, y = x_t1 * 2 - x, y_t1 * 2 - y
	end
	--no tag func
	return x, y
end

--图形路径方向变更 "reverse" 则翻转 图形 或 路径 或 单条路径控制点
function Shape:changeDirection(shape_mode, path_mode, p_mode) --> table ShapeObj

	if not self.tag.createShape then self:createShape() end

	self._tblSort(self, shape_mode, 1, true) --图形顺序
	for _, path in ipairs(self) do
		self._tblSort(path, path_mode, 1, true) --路径方向
		for _, p in ipairs(path) do
			self._tblSort(p, p_mode, 1, true) --单条路径方向
		end
	end
	--no tag func
	return self
end

--图形方向 顺/逆时针 判断   计算所有路径返回表，key为路径对象 （相对于笛卡尔坐标系，true为顺时针，屏幕坐标系则相反，共线返回0）
function Shape:direction() --> table all_PathObj_direction

	if not self.tag.pathNew then self:pathNew() end

	local shape_direction = {}
	for key, path in ipairs(self) do
		shape_direction[path] = path:direction()
	end
	--no tag func
	return shape_direction --> {[PathObj1]=bool, [PathObj2]=bool, ...}
end

--图形方向 顺/逆时针 判断   shape中存在多条路径，只计算第一条路径 并返回布尔值
function Shape:directionFirst() --> bool frist_PathObj_direction

	if not self.tag.pathNew then self:pathNew() end
	--no tag func
	return self[1]:direction()
end

--将图形在每个step处的坐标点 连成多边形或折线并返回新对象  side边数 mode计算模式（基于边数量计算step数 side值要求：side=>3  mode为"t0"时从step0为起点开始计算图形）
function Shape:stepToPolygonModeSide(side, mode) --> table new_ShapeObj

	assert(side >= 3, "side must >= 3 !")

	if not self.tag.stepAll then self:stepAll() end

	local pt = {} --保存点集
	local offset
	if mode == "t0" then offset = 1 else offset = 0 end

	side = math.floor(math.abs(side)) - offset
	for i=1-offset, side do
		local step = self.step.sum / side * i
		local path, _, x_num, y_num = self:pointAtStep(step)

		pt[path] = pt[path] or {}
		pt[path].x = pt[path].x or {}
		pt[path].y = pt[path].y or {}

		local maxn = #pt[path].x
		pt[path].x[maxn+1] = x_num
		pt[path].y[maxn+1] = y_num
	end

	local new_shape = {}
	for _, path in ipairs(self) do
		if pt[path] then
			local new_path = {}
			local maxn = #pt[path].x
			for i=1, maxn-1 do
				local new_p = {}
				new_p[1] = {
					pt[path].x[i],
					pt[path].y[i]
				}
				new_p[2] = {
					pt[path].x[i+1],
					pt[path].y[i+1]
				}
				new_path[#new_path+1] = new_p
			end
			new_shape[#new_shape+1] = new_path
		end
	end
	new_shape = Shape:new(new_shape)
	--no tag func
	return new_shape
end

--将图形在每个step处的坐标点 连成多边形或折线并返回新对象   len分割长度 （基于分割长度计算step数 len值要求：len_sum/3>len>0  mode为"t0"时从step0为起点开始计算图形）
function Shape:stepToPolygonModeLen(len, mode) --> table new_ShapeObj

	assert(len >= 0.5, "length must >= 0.5 !") --阈值 最小分割长度低于0.5像素已无意义

	if not self.tag.lengthAll then self:lengthAll() end

	assert(len <= self.len.sum / 3, "length is too large!")
	local side = self.len.sum / len

	return self:stepToPolygonModeSide(side, mode)
end

--返回Shape t0-t1 的点集链表 （shape链表内包含path子链表）  len分割长度 长度越小点集越多 （mode为"all"，则对line路径和bezier路径都执行计算; mode为"no_bezier"，则都不执行计算，可以看作是将path内所有bezier路径转为了line路径并输出点集； 默认只对bezier路径执行点集计算）
function Shape:pointCollection(len, mode) --> table pt

	if not self.tag.stepAll then self:stepAll() end

	local pt = {}
	pt.path_start = self[1]
	pt.path_end = self[#self]

	for key, path in ipairs(self) do
		pt[path] = path:pointCollection(len, mode)
		pt[path].path_next = self[key+1] or pt.path_start
		pt[path].path_prev = self[key-1] or pt.path_end
	end
	--no tag func
	return pt --> {path_start=pathObj1, path_end=pathObjXXX,		pathObj1={path_next=pathObj2, path_prev=pathObjXXX, p_start=pObj1, p_end=pObjXXX, pObj1={p_next=pObj2, p_prev=pObjXXX, x={[0]=t0_num, [1]=num, ... },y={...}},	pObj2={p_next=pObj3, p_prev=pObj2, x={},y={}},	...	},	pathObj2={...},	...	}
end

--使Shape中的路径折线化返回新对象  len分割长度 长度越长bezier折线拟合程度越低 （mode为"all"，则对line路径和bezier路径都执行计算; mode为"no_bezier"，则都不执行计算，可以看作是将path内所有bezier路径转为了line路径并； 默认只折线化bezier路径）
function Shape:flatten(len, mode) --> table new_ShapeObj

	if not self.tag.stepAll then self:stepAll() end

	local new_shape = {}
	for key, path in ipairs(self) do
		new_shape[key] = path:flatten(len, mode)
	end
	new_shape = Shape:new(new_shape)
	--no tag func
	return new_shape
end

--图形边界框 返回 x_min, y_min, x_max, y_max
function Shape:bounding() --> number x_min, number y_min, number x_max, number y_max

	if not self.tag.stepAll then self:stepAll() end

	local pt = {x={}, y={}}
	for _, path in ipairs(self) do
		local ax, ay, bx, by = path:bounding()
		pt.x[#pt.x+1] = ax
		pt.y[#pt.y+1] = ay
		pt.x[#pt.x+1] = bx
		pt.y[#pt.y+1] = by
	end

	local x_min, y_min = math.min(table.unpack(pt.x)), math.min(table.unpack(pt.y))
	local x_max, y_max = math.max(table.unpack(pt.x)), math.max(table.unpack(pt.y))
	--no tag func
	return x_min, y_min, x_max, y_max
end

--[[
--图形求凸包 返回新对象（待写）
function Shape:ConvexHull() --> table new_ShapeObj
	--no tag func
	return new_shape
end
]]

--图形对象转为图形字符串  mode为"no_closed"时  如执行过closed开放图形闭合，则删除闭合路径并输出开放图形
function Shape:objFormat(mode) --> str shape

	if not self.tag.createShape and type(self[1]) == "string" then
		return self[1]
	end

	local str = {}

	for _, path in ipairs(self) do
		for k, p in ipairs(path) do
			if k == 1 then
				str[#str+1] = "m "
							..p[1][1].." " --ax
							..p[1][2].." " --ay
			end
			if #p == 2 then
				str[#str+1] = "l "
							..p[2][1].." " --bx
							..p[2][2].." " --by
			elseif #p == 4 then
				str[#str+1] = "b "
							..p[2][1].." " --bx
							..p[2][2].." " --by
							..p[3][1].." " --cx
							..p[3][2].." " --cy
							..p[4][1].." " --dx
							..p[4][2].." " --dy
			end
		end

		if mode == "no_closed" and  self.tag.closed then
			str[#str] = nil
		end

	end
	--no tag func
	return table.concat(str)
end



return Shape
