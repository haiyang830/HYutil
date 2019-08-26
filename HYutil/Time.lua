local HYutil = require("HYutil.HY")
---------------------------------------------
-- TIME -------------------------------------
---------------------------------------------
--v1.0

local Time = {
	tag={collectConf=false, createFrames=false}
}

Time = HYutil:new(Time)

--收集配置
function Time:collectConf()

	if type(self.time_conf) ~= "table" then
		self.time_conf = {}
	end
	self.time_conf.s = self.time_conf.s or self.s
	assert(type(self.time_conf.s) == "number", "number s not found!")
	self.time_conf.e = self.time_conf.e or self.e
	assert(type(self.time_conf.e) == "number", "number e not found!")

	self.time_conf.f = self.time_conf.f or self.f
	if self.time_conf.f then assert(type(self.time_conf.f) == "number", "number f not found!") end

	--初始化
	for k, _ in pairs(self) do
		if k ~= "time_conf" and k ~= "tag" and k ~= "cache" then
			self[k] = nil
		end
	end

	self.tag.collectConf = true

	return self
end

--自动帧时间
function Time:createFramesModeAuto() --> table TimeObj

	if not self.tag.collectConf then self:collectConf() end

	assert(self.time_conf.e - self.time_conf.s >= 0, "time duration must >= 0 !")
	--aegisub api
	assert(aegisub, "aegisub api not found!")
	local frameMs, msFrame = aegisub.frame_from_ms, aegisub.ms_from_frame

	local fr_s = frameMs(self.time_conf.s) --起始时间帧
	local fr_e = frameMs(self.time_conf.e) --结束时间帧

	local t = {s={}, e={}}
	t.frame = fr_e - fr_s --总帧数

	for i=1, t.frame do
		t.s[i] = msFrame(fr_s + i - 1) 
		t.e[i] = msFrame(fr_s + i)
	end

	self.s, self.e, self.frame = t.s, t.e, t.frame

	self.tag.createFrames = true

	return self
end
--自定义帧时间
function Time:createFramesModeCustom() --> table TimeObj

	if not self.tag.collectConf then self:collectConf() end

	assert(self.time_conf.e - self.time_conf.s >= 0, "time duration must >= 0 !")
	assert(self.time_conf.f > 0, "precision error! (precision must >0)")

	local t = {s={}, e={}}
	local t_dur = self.time_conf.e - self.time_conf.s
	t.frame = math.floor(t_dur / self.time_conf.f)

	for i=1, t.frame do
		t.s[i] = (i - 1) * self.time_conf.f + self.time_conf.s
		t.e[i] = i * self.time_conf.f + self.time_conf.s
	end

	self.s, self.e, self.frame = t.s, t.e, t.frame

	self.tag.createFrames = true

	return self
end

--计算单位时间内的帧数量
function Time:createFrames() --> table TimeObj

	if self.tag.createFrames then return self end
	if not self.tag.collectConf then self:collectConf() end

	if self.time_conf.f then
		self:createFramesModeCustom() --自定义帧时间
	else
		self:createFramesModeAuto() --自动帧时间
	end

	return self
end



return Time
