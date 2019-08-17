package.path = "L:\\HYutil\\HYutil\\?.lua;".."I:\\HYutil\\HYutil\\?.lua;"..package.path
local HYutil = require("HY")
local Shape = require("Shape")
local VC = require("VC")
---------------------------------------------
-- MOTION -----------------------------------
---------------------------------------------
local Motion = {
	tag={collectConf=false, createShape=false, createVelocityCurve=false, createPoint=false},
}

Motion = HYutil:new(Motion)

--[[
创建Motion对象

motion_test = {
	shape = {"m 0 0 l 100 100"}, --用于计算Shape对象  运动轨迹将会是图形的边缘 （你可以用 {"图形字符串"}，也可以用Shape的表数据格式 { { { {0,0}, {100,100} } } } 详见Shape.lua）

	vc = {0.25, 0.25, 0.75, 0.75},  --缓动曲线控制点 bx, by, cx, cy （其中 ax, ay 与 dx, dy 会被自动设为0, 0 与 1, 1）（你也可以用多组曲线或直线去构造一个缓动曲线 详见VC.lua）

	--point_create = "loop", --可选配置项 点生成模式 路径循环（默认为 路径延伸 模式）
	--path_type = "closed",  --可选配置项 闭合开放路径（默认不闭合）
	--shape_direction = "reverse", --可选配置项 图形顺序翻转
	--path_direction = "reverse", --可选配置项 路径方向翻转
	--p_direction = "reverse", --可选配置项 单条路径方向翻转
}

计算运动轨迹
Motion:new(motion_conf):createMotionTrack(10)
]]
function Motion:collectConf() --> table MotionObj

	--收集配置
	if type(self.motion_conf) ~= "table" then
		self.motion_conf = {}
	end
	self.motion_conf.shape = self.motion_conf.shape or self.shape
	assert(type(self.motion_conf.shape) == "table", "table shape not found!")
	self.motion_conf.vc = self.motion_conf.vc or self.vc
	assert(type(self.motion_conf.vc) == "table", "table vc not found!")

	self.motion_conf.point_create = self.motion_conf.point_create or self.point_create
	self.motion_conf.path_type = self.motion_conf.path_type or self.path_type
	self.motion_conf.shape_direction = self.motion_conf.shape_direction or self.shape_direction
	self.motion_conf.path_direction = self.motion_conf.path_direction or self.path_direction
	self.motion_conf.p_direction = self.motion_conf.p_direction or self.p_direction

	--初始化
	for k, _ in pairs(self) do
		if k ~= "motion_conf" and k ~= "tag" and k ~= "cache" then
			self[k] = nil
		end
	end

	self.tag.collectConf = true

	return self
end


--继承Shape
function Motion:createShape() --> table MotionObj

	if not self.tag.collectConf then self:collectConf() end

	local new_shape = self.motion_conf.shape
	new_shape = Shape:new(new_shape)

	if self.motion_conf.path_type == "closed" then
		new_shape:closed() --闭合开放路径
	end

	if self.motion_conf.shape_direction or self.motion_conf.path_direction or self.motion_conf.p_direction then
		self.motion_conf.shape:changeDirection(self.motion_conf.shape_direction, self.motion_conf.path_direction, self.motion_conf.p_direction) --设定图形路径方向
	end

	self.tag.createShape = true

	return self
end

--计算缓动对照表
function Motion:createVelocityCurve(frame) --> table MotionObj

	if not self.tag.collectConf then self:collectConf() end

	local new_vc = self.motion_conf.vc
	new_vc = VC:new(new_vc)
	new_vc:createVelocityCurve(frame)

	self.tag.createVelocityCurve = true

	return self
end

--根据缓动表 计算shape所有路径（路径循环模式）
function Motion:createPointModeLoop(frame) --> table MotionObj

	if not self.tag.createShape then self:createShape() end
	if not self.tag.createVelocityCurve then self:createVelocityCurve(frame) end

	local vc, shape = self.motion_conf.vc, self.motion_conf.shape

	local pt = {x={}, y={}} --保存路径坐标
	for i=1, frame do
		local step = vc[i]
		pt.x[i], pt.y[i] = shape:pointAtStepModeLoop(step)
	end

	self.x, self.y = pt.x, pt.y

	self.tag.createPoint = true

	return self
end

--根据缓动表 计算所有路径（路径延伸模式）
function Motion:createPointModeExtend(frame) --> table MotionObj

	if not self.tag.createShape then self:createShape() end
	if not self.tag.createVelocityCurve then self:createVelocityCurve(frame) end

	local vc, shape = self.motion_conf.vc, self.motion_conf.shape

	local pt = {x={}, y={}} --保存路径坐标
	for i=1, frame do
		local step = vc[i]
		pt.x[i], pt.y[i] = shape:pointAtStepModeExtend(step)
	end

	self.x, self.y = pt.x, pt.y

	self.tag.createPoint = true

	return self
end

--创建运动轨迹
function Motion:createMotionTrack(frame) --> table MotionObj

	if self.tag.createPoint then return self end
	assert(frame >= 1, "frame number error!(frame must >= 1)")
	if not self.tag.collectConf then self:collectConf() end

	if self.motion_conf.point_create == "loop" then
		self:createPointModeLoop(frame)
	else
		self:createPointModeExtend(frame)
	end
	--no tag func
	return self --> {x={...}, y={...}, motion_conf={...}}
end




return Motion
