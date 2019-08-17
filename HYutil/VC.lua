package.path = "L:\\HYutil\\HYutil\\?.lua;".."I:\\HYutil\\HYutil\\?.lua;"..package.path
local HYutil = require("HY")
local Bezier = require("Bezier")
local Path = require("Path")
---------------------------------------------
-- VELOCITY CURVE ---------------------------
---------------------------------------------
local VC = {
	tag={collectConf=false, createVC=false}
}

VC = HYutil:new(VC)

--配置收集
function VC:collectConf()

	if type(self.vc_conf) ~= "table" then
		self.vc_conf = {}
		for k, v in ipairs(self) do
			self.vc_conf[k] = v --保存缓动曲线配置
		end
	end

	--初始化
	for k, _ in pairs(self) do
		if k ~= "vc_conf" and k ~= "tag" and k ~= "cache" then
			self[k] = nil
		end
	end

	self.tag.collectConf = true

	return self
end

--单缓动曲线
--self -> {bx, by, cx, cy}
function VC:createVCModeSingle(step) --> table VCObj

	if not self.tag.collectConf then self:collectConf() end

	--补全控制点 ax, ay, dx, dy
	self.vc_conf[3], self.vc_conf[4], self.vc_conf[5], self.vc_conf[6] = self.vc_conf[1], self.vc_conf[2], self.vc_conf[3], self.vc_conf[4]
	self.vc_conf[1], self.vc_conf[2], self.vc_conf[7], self.vc_conf[8] = 0, 0, 1, 1

	assert(#self.vc_conf == 8, "velocityCurve points error!")
	assert(self.vc_conf[3] >= 0 and self.vc_conf[3] <= 1, "velocityCurve points error! (X point must >=0 and <=1)")
	assert(self.vc_conf[5] >= 0 and self.vc_conf[5] <= 1, "velocityCurve points error! (X point must >=0 and <=1)")

	--将配置数据转换为Bezier对象数据结构
	local new_bezier = {}
	for i=1, 4 do
		new_bezier[i] =
		{
			self.vc_conf[i*2-1],
			self.vc_conf[i*2]
		}
	end

	new_bezier = Bezier:new(new_bezier)
	new_bezier.step = math.floor(step)
	--计算缓动对照表
	for i=1, new_bezier.step do
		_, self[i] = new_bezier:pEven(i)
	end

	self.tag.createVC = true

	return self
end

--多缓动曲线
--			曲线1						直线2			曲线/直线n
--self -> { {ax,ay,bx,by,cx,cy,dx,dy},	{ax,ay,bx,by},	...}
--头曲线 ax,ay须为0,0  尾曲线 dx,dy（或直线末端点的bx,by）须为1,1
--各曲线之间要保证连续性，即 曲线n的ax,ay 须等于 曲线n-1的dx,dy（或直线末端点的bx,by）
function VC:createVCModeMulti(step) --> table VCObj

	if not self.tag.collectConf then self:collectConf() end
	--conf check
	for key, curve in ipairs(self.vc_conf) do

		assert(#curve == 4 or #curve == 8, "velocityCurve points error (at curve "..key..") (curve must be bezier or line)") --防止控制点不足或多出

		if key == 1 then
			assert(curve[1] == 0 and curve[2] == 0, "velocityCurve points error (at curve 1)! (start point must 0,0)") --首控制点需为0,0
		elseif key == #self.vc_conf then
			assert(curve[#curve-1] == 1 and curve[#curve] == 1, "velocityCurve points error (at curve "..key..")! (end point must 1,1)") --尾控制点需为1,1
		end

		for i=1, #curve, 2 do
			assert(curve[i] >= 0 and curve[i] <= 1, "velocityCurve points error (at curve "..key..", point"..i..")! (X point must >=0 and <=1)") --控制点x坐标限制
		end

		if key ~= 1 then --检查曲线连续性
			local ax, ay = curve[1], curve[2]
			local curve_prev = self.vc_conf[key-1]
			local dx_prev, dy_prev = curve_prev[#curve_prev-1], curve_prev[#curve_prev]
			assert(ax == dx_prev and ay == dy_prev, "velocityCurve points error (at curve "..key..")! (start point must = prev end point)")
		end
	end

	--将配置数据转换为Path对象数据结构
	local new_path = {}
	for key, curve in ipairs(self.vc_conf) do
		local new_bezier = {}
		for i=1, #curve/2 do
			new_bezier[i] =
			{
				curve[i*2-1],
				curve[i*2]
			}
		end
		new_path[key] = new_bezier
	end

	--计算缓动对照表
	new_path = Path:new(new_path)
	new_path.step = {sum=math.floor(step)}

	for i=1, new_path.step.sum do
		_, _, self[i] = new_path:pointAtStep(i)
	end

	self.tag.createVC = true

	return self
end

function VC:createVelocityCurve(step) --> table VCObj

	if self.tag.createVC then return self end
	assert(step >= 1, "step number error!(step must >= 1)")
	if not self.tag.collectConf then self:collectConf() end

	if type(self.vc_conf[1]) == "table" then
		self:createVCModeMulti(step)
	else
		self:createVCModeSingle(step)
	end

	return self
end



return VC
