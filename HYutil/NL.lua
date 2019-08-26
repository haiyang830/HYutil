local HYutil = require("HYutil.HY")
local VC = require("HYutil.VC")
---------------------------------------------
-- NONLINEAR --------------------------------
---------------------------------------------
--v1.0

local NL = {
	tag={collectConf=false, createVelocityCurve=false, createNLValues=false},
}

NL = HYutil:new(NL)

--[[
简单非线性数值计算

创建NL对象
nl_conf = {
	num_s = number --起始值（因缓动曲线 生成结果会超出或小于此值）
	num_e = number --结束值（因缓动曲线 生成结果会超出或小于此值）
	vc = table  --缓动曲线
	--num_type = "hex" --转换为十六进制形式（可选）
}

计算非线性数值
NL:new(nl_conf):createNLValues(10)
]]
function NL:collectConf()

	--收集配置
	if type(self.nl_conf) ~= "table" then
		self.nl_conf = {}
	end
	self.nl_conf.num_s = self.nl_conf.num_s or self.num_s
	assert(type(self.nl_conf.num_s) == "number", "number num_s not found!")
	self.nl_conf.num_e = self.nl_conf.num_e or self.num_e
	assert(type(self.nl_conf.num_e) == "number", "number num_e not found!")
	self.nl_conf.vc = self.nl_conf.vc or self.vc
	assert(type(self.nl_conf.vc) == "table", "table vc not found!")

	self.nl_conf.num_type = self.nl_conf.num_type or self.num_type

	--初始化
	for k, _ in pairs(self) do
		if k ~= "nl_conf" and k ~= "tag" and k ~= "cache" then
			self[k] = nil
		end
	end

	self.tag.collectConf = true

	return self
end

function NL:createVelocityCurve(frame)

	if not self.tag.collectConf then self:collectConf() end

	local new_vc = self.nl_conf.vc
	new_vc = VC:new(new_vc)
	new_vc:createVelocityCurve(frame)

	self.tag.createVelocityCurve = true

	return self
end

function NL:toHex()
	for k, num in ipairs(self) do
		self[k] = string.format('%X', num)
	end
	return self
end

function NL:createNLValues(frame)

	if self.tag.createNLValues then return self end
	assert(frame >= 1, "frame number error!(frame must >= 1)")
	if not self.tag.createVelocityCurve then self:createVelocityCurve(frame) end

	local num_s, num_e, num_diff = self.nl_conf.num_s, self.nl_conf.num_e, self.nl_conf.num_e - self.nl_conf.num_s
	local vc = self.nl_conf.vc

	for i=1, frame do
		local step = vc[i]
		self[i] = num_s + num_diff * step
	end

	if self.nl_conf.num_type == "hex" then self:toHex() end

	self.tag.createNLValues = true

	return self
end



return NL
