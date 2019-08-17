package.path = "L:\\HYutil\\HYutil\\?.lua;".."I:\\HYutil\\HYutil\\?.lua;"..package.path
local HYutil = require("HY")
local Motion = require("Motion")
---------------------------------------------
-- MOTION MULTI -----------------------------
---------------------------------------------
--[[
创建MotionMulti对象

M_conf = {
	MotionObj1,
	MotionObj2,
	...
	--offset = {x=number, y=number}  --坐标偏移值（可选）
}

计算复合运动轨迹
MotionMulti:new(M_conf)
M_conf:createMotionTrack(10)
]]
local MotionMulti = {
	tag={collectConf=false, createMotionAll=false, }
}

MotionMulti = HYutil:new(MotionMulti)

--收集配置
function MotionMulti:collectConf()

	if type(self.Mmulti_conf) ~= "table" then
		self.Mmulti_conf = {}
		for k, v in ipairs(self) do
			if type(v) == "table" then
				self.Mmulti_conf[k] = v --保存所有Motion对象
			end
		end
	end
	self.Mmulti_conf.offset = self.Mmulti_conf.offset or self.offset
	if self.Mmulti_conf.offset then assert(type(self.Mmulti_conf.offset.x) == "number" and type(self.Mmulti_conf.offset.y) == "number", "table offset error!") end

	--初始化
	for k, _ in pairs(self) do
		if k ~= "Mmulti_conf" and k ~= "tag" and k ~= "cache" then
			self[k] = nil
		end
	end

	self.tag.collectConf = true

	return self
end

--计算所有运动对象
function MotionMulti:createMotionAll(frame)

	if not self.tag.collectConf then self:collectConf() end

	local Mmulti = self.Mmulti_conf
	for _, new_motion in ipairs(Mmulti) do
		new_motion = Motion:new(new_motion)
		new_motion:createMotionTrack(frame)
	end

	self.tag.createMotionAll = true

	return self
end

--计算复合运动轨迹
function MotionMulti:createMotionTrack(frame)

	if self.tag.createMotionTrack then return self end
	assert(frame >= 1, "frame number error!(frame must >= 1)")
	if not self.tag.createMotionAll then self:createMotionAll(frame) end

	local pt = {x={}, y={}}
	local Mmulti = self.Mmulti_conf
	local offset = self.Mmulti_conf.offset or {x=0, y=0}
	for k, motion in ipairs(Mmulti) do
		for i=1, frame do
			pt.x[i] = motion.x[i] + (pt.x[i] or 0) + offset.x
			pt.y[i] = motion.y[i] + (pt.y[i] or 0) + offset.y
		end
	end

	self.x, self.y = pt.x, pt.y

	self.tag.createMotionTrack = true

	return self
end



return MotionMulti
