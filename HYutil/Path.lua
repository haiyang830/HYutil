package.path = "L:\\HYutil\\HYutil\\?.lua;".."I:\\HYutil\\HYutil\\?.lua;"..package.path
local HYutil = require("HY")
local Point = require("Point")
local Line = require("Line")
local Bezier = require("Bezier")
---------------------------------------------
-- PATH -------------------------------------
---------------------------------------------
local Path = {
	tag={pNew=false, lengthAll=false, stepAll=false}
}

Path = HYutil:new(Path)

--继承Class Bezier或Line
function Path:pNew() --> table PathObj
	--重置 method tag
	for tag_name in pairs(self.tag) do
		self.tag[tag_name] = false
	end
	--清除cache
	for cache_name in pairs(self.cache) do
		self.cache[cache_name] = nil
	end

	for _, p in ipairs(self) do
		if #p == 2 then
			p = Line:new(p) --继承Line
		elseif #p == 4 then
			p = Bezier:new(p) --继承Bezier
		end
	end

	self.tag.pNew = true
	self.tag.lengthAll = false
	self.tag.stepAll = false

	return self
end

--计算单个path内的路径长度
function Path:lengthAll() --> table PathObj

	if not self.tag.pNew then self:pNew() end

	--储存单个path内的路径长度（包含总长）
	local LEN = {}
	setmetatable(LEN, {__mode="k"})
	LEN.sum = 0

	for _, p in ipairs(self) do

		LEN[p] = p:length(1)
		LEN.sum = LEN.sum + LEN[p]

		p.len = LEN[p]

	end

	self.len = LEN --> {self[1]=length_num1,  self[2]=length_num2,  ...,  sum=length_num1+length_num2+ ... }

	self.tag.lengthAll = true

	return self
end

--计算每条路径长度与总长度占比 求实际step
function Path:stepAll() --> table PathObj

	if not self.step then self.step = {sum=1} end
	assert(type(self.step.sum) == "number", "number 'step.sum' not found!")

	if not self.tag.lengthAll then self:lengthAll() end --计算path总长

	local STEP = {}
	setmetatable(STEP, {__mode="k"})
	STEP.sum = self.step.sum

	for _, p in ipairs(self) do

		local step_single = self.len[p] / self.len.sum * STEP.sum
		STEP[p] = step_single

		p.step = STEP[p]

	end

	self.step = STEP --> {self[1]=step_num1,  self[2]=step_num2,  ...,  sum=step_num1+step_num2+ ... }

	self.tag.stepAll = true

	return self
end

--返回指定step处对应 曲线, x, y
function Path:pointAtStep(step) --> table BezierObj/LineObj, number x, number y

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
				k_prev = 1
		}
	end

	local step_prev = self.cache.pointAtStep.step_prev --上一次的step
	local step_sum = self.cache.pointAtStep.step_sum_prev --上一次的step_sum
	local k = self.cache.pointAtStep.k_prev --上一次path表的key

	if step > step_prev then --当前step大于上一次step 则从上一次的key为起点 正向遍历path表
		for i=k, #self do
			local p = self[i]

			if i ~= k then
				step_sum = step_sum + self.step[p]
			end

			--if step_sum >= step then
			if math.fCompar(step_sum, ">=", step) then
				local step_diff = step_sum - self.step[p]
				self.cache.pointAtStep.step_prev = step
				self.cache.pointAtStep.step_sum_prev = step_sum
				self.cache.pointAtStep.k_prev = i
				return p, p:pEven(step - step_diff)
			end
		end
	elseif step < step_prev then --当前step小于上一次step 则从上一次的key为起点 反向遍历path表
		for i=k, 1, -1 do
			local p = self[i]

			step_sum = step_sum - self.step[p]

			--if step_sum <= step then
			if math.fCompar(step_sum, "<=", step) then
				local step_diff = step_sum
				self.cache.pointAtStep.step_prev = step
				self.cache.pointAtStep.step_sum_prev = step_sum + self.step[p]
				self.cache.pointAtStep.k_prev = i
				return p, p:pEven(step - step_diff)
			end
		end
	elseif step == step_prev then --当前step等于上一次step 直接返回
		local p = self[k]
		local step_diff = step_sum - self.step[p]
		return  p, p:pEven(step - step_diff)
	end
	--no tag func
end

--返回path t0-t1 的点集链表	 len分割长度 长度越小点集越多（mode为"all"，则对line路径和bezier路径都执行计算; mode为"no_bezier"，则都不执行计算，可以看作是将path内所有bezier路径转为了line路径并输出点集； 默认只对bezier路径执行点集计算）
function Path:pointCollection(len, mode) --> table pt

	if not self.tag.stepAll then self:stepAll() end

	local pt = {}
	pt.p_start = self[1] --起始路径
	pt.p_end = self[#self] --结束路径

	if mode == "all" then
		for k, p in ipairs(self) do
			pt[p] = p:pointCollection(len)
			pt[p].p_next = self[k+1] or pt.p_start
			pt[p].p_prev = self[k-1] or pt.p_end
		end

	elseif mode == "no_bezier" then
		for k, p in ipairs(self) do
			pt[p] = p:T0andT1()
			pt[p].p_next = self[k+1] or pt.p_start
			pt[p].p_prev = self[k-1] or pt.p_end

		end

	else
		for k, p in ipairs(self) do
			if #p == 4 then
				pt[p] = p:pointCollection(len)
			elseif #p == 2 then
				pt[p] = p:T0andT1()
			end
			pt[p].p_next = self[k+1] or pt.p_start
			pt[p].p_prev = self[k-1] or pt.p_end
		end

	end
	--no tag func
	return pt --> {p_start=pObj1, p_end=pObjXXX, pObj1={p_next=pObj2, p_prev=pObjXXX, x={[0]=t0_num, [1]=num, ... },y={}},	pObj2={p_next=pObj3, p_prev=pObj2, x={},y={}},	...	}
end

--使Path中的bezier路径折线化返回新对象  len分割长度 长度越长bezier折线拟合程度越低 （mode为"all"，则对line路径和bezier路径都执行计算; mode为"no_bezier"，则都不执行计算，可以看作是将path内所有bezier路径转为了line路径； 默认只折线化bezier路径）
function Path:flatten(len, mode) --> table new_PathObj

	if not self.tag.stepAll then self:stepAll() end

	local pt = self:pointCollection(len, mode)

	local new_path = {}
	--遍历链表
	local the_next = pt.p_start
	repeat
		local maxn = #pt[the_next].x
		for i=0, maxn-1 do
			local p = {}
			p[1] = {pt[the_next].x[i], pt[the_next].y[i]}
			p[2] = {pt[the_next].x[i+1], pt[the_next].y[i+1]}
			new_path[#new_path+1] = p
		end
		the_next = pt[the_next].p_next --下一个对象
	until the_next == pt.p_start

	new_path = Path:new(new_path)
	--no tag func
	return new_path
end

--路径边界框
function Path:bounding() --> number x_min, number y_min, number x_max, number y_max

	if not self.tag.stepAll then self:stepAll() end

	local pt = {x={}, y={}}
	for _, p in ipairs(self) do
		local ax, ay, bx, by = p:bounding()
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

--路径方向 顺/逆时针 判断 （相对于笛卡尔坐标系，顺时针返回true，逆时针返回false ，屏幕坐标系则相反，共线返回0）
function Path:direction() --> bool direction

	local path = self:flatten(_, "no_bezier")
	local _, _, x_max = path:bounding() --找出多边形最大的x（必定为凸点)

	local cross --叉积
	for k, p in ipairs(path) do
		if p.a.x == x_max or p.b.x == x_max then
			local p_next
			if k == #path then --如最后一条line路径是凸点所在
				p_next = path[1]:_tblSort("reverse", 1) --取首条line路劲并翻转路径方向
			else
				p_next = path[k+1]
			end
			local ax, ay, bx, by, cx, cy = p.a.x, p.a.y, p.b.x, p.b.y, p_next.b.x, p_next.b.y
			ax, ay, bx, by = bx - ax, by - ay, cx - ax, cy - ay
			local new_line = Line:new({{ax, ay}, {bx, by}})
			cross = new_line:cross()
			break
		end
	end

	if cross < 0 then --顺时针
		return true
	elseif cross > 0 then --逆时针
		return false
	end
	--no tag func
	return cross
end



return Path
