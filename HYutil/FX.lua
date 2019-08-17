package.path = "L:\\HYutil\\HYutil\\?.lua;".."I:\\HYutil\\HYutil\\?.lua;"..package.path
local HYutil = require("HY")
local math = require("Math")
local Time = require("Time")
local MotionMulti = require("MotionMulti")
local NL = require("NL")
local Colour = require("Colour")
---------------------------------------------
-- FX ---------------------------------------
---------------------------------------------
--[[
--配置阶段
fx = {

	time = Time_Obj
	multi_motion = MotionMulti_Obj
	nl_tags = {
		"\frz" = NL_Obj,
		"\fscy" = NL_Obj
	}
	nl_tags_colour = {
		"\1c" = {
			H = NL_Obj,
			S = NL_Obj,
			L = NL_Obj,
		}
		"\3c" = {...}
	}
	static_tags = {
		[1] = "\fs80",
		[2] = "\b1",
	}
}


--初始生成阶段
fx = {
	{												--frame 1
		time = {s=number, e=number},
		tags = {
			"\pos" = {x=100, y=100}, --> table
			"frz" = 100 --> number
			"\fscy" = 100
			"\1c" = &HFFFFFF&, --> string
			"\3c" = &HFFFFFF&,
			static = "\fs80\b1" （合成静态标签字符串）
		}
	},
	{time = {...}, tags = {...}}, 					--frame 2
	...												--frame n

	fx_conf = {...} --配置阶段的表会收集到这里
}

--最终生成阶段（tags内的值全部被合并为字符串）
fx = {
	{												--frame 1
		time = {s=number, e=number},
		tags = "{\pos(100,100)\frz100\fscy100\1c&HFFFFFF&\3c&HFFFFFF&\fs80\b1}" --> string
	},
	{time = {...}, tags = {...}}, 					--frame 2
	...												--frame n
}


]]

local FX = {
	tag = {collectConf=false, createTime=false, createMotionMulti=false, createNL=false, createNLColour=false, createStaticTags=false, createFXInitial=false, createFXFinal=false}
}

FX = HYutil:new(FX)


-- ADD Time ---------------------------------------------------------------------------

--添加时间对象 s 开始时间， e 结束时间， f 帧持续时间（可选 默认由aegisub计算）
function FX:addTime(s, e, f)

	assert(type(s) == "number" and type(e) == "number", "time start or end error!")
	if f then assert(type(f) == "number", "frame duration error! ") end

	local new_time = {
		s = s,
		e = e,
		f = f
	}

	self.time = Time:new(new_time)

	return self
end



-- ADD Motion -------------------------------------------------------------------------

--添加shape运动对象
function FX:addMotionShape(shape, vc, point_create, path_type, shape_direction, path_direction, p_direction)

	assert(shape, "motion path not found!")
	if vc then assert(type(vc) == "table", "velocity curve error!") end

	if type(shape) == "string" then shape = {shape} end
	vc = vc or {0.25,0.25,0.75,0.75} --默认为线性运动

	local new_motion = {
		shape = shape,
		vc = vc,
		point_create = point_create,
		path_type = path_type,
		shape_direction = shape_direction,
		path_direction = path_direction,
		p_direction = p_direction,
	}

	self.multi_motion = self.multi_motion or {}
	self.multi_motion[#self.multi_motion+1] = new_motion

	return self
end

--添加line运动对象
function FX:addMotionLine(line, vc, point_create, p_direction)

	assert(type(line) == "table", "motion path not found!")
	assert(#line == 4, "motion path point error!")

	local shape = { { { {line[1], line[2]}, {line[3], line[4]} } } }

	return self:addMotionShape(shape, vc, point_create, _, _, _, p_direction)
end

--添加运动对象坐标偏移值
function FX:addMotionOffset(x, y)

	assert(type(x) == "number" and type(y) == "number", "number x or y not found!")
	self.multi_motion = self.multi_motion or {}
	self.multi_motion.offset = {x = x, y = y}

	return self
end



-- ADD ASSTags ------------------------------------------------------------------------

--添加非线性 ass tag
function FX:addNLTag(tag_str, num_s, num_e, vc, num_type)

	assert(type(tag_str) == "string", "tag string not found!")
	assert(type(num_s) == "number" and type(num_e) == "number", "number start or end error!")

	if not tag_str:find("\\", 1) then tag_str = "\\"..tag_str end
	vc = vc or {0.25,0.25,0.75,0.75} --默认为线性运动

	local new_nl = {
		num_s = num_s,
		num_e = num_e,
		vc = vc,
		num_type = num_type
	}

	self.nl_tags = self.nl_tags or {}
	self.nl_tags[tag_str] = new_nl

	return self
end

--添加非线性 ass tag （仅用于colour HSL空间）
function FX:addNLTagForColourHSL(tag_str, HSL_s, HSL_e, vc_H, vc_S, vc_L)

	assert(type(tag_str) == "string", "tag string not found!")
	assert(type(HSL_s) == "table" and type(HSL_e) == "table", "table HSL_s or HSL_e not found!")
	--可以使用number key 构造HSL对象
	if (not HSL_s.H) or (not HSL_s.S) or (not HSL_s.L) then
		if #HSL_s == 3 then
			HSL_s.H, HSL_s.S, HSL_s.L = HSL_s[1], HSL_s[2], HSL_s[3]
			HSL_s[1], HSL_s[2], HSL_s[3] = nil, nil, nil
		end
	end
	if (not HSL_e.H) or (not HSL_e.S) or (not HSL_e.L) then
		if #HSL_e == 3 then
			HSL_e.H, HSL_e.S, HSL_e.L = HSL_e[1], HSL_e[2], HSL_e[3]
			HSL_e[1], HSL_e[2], HSL_e[3] = nil, nil, nil
		end
	end

	if not tag_str:find("\\", 1) then tag_str = "\\"..tag_str end
	local vc_def = {0.25,0.25,0.75,0.75} --默认为线性运动
	vc_H = vc_H or vc_def
	vc_S = vc_S or vc_def
	vc_L = vc_L or vc_def

	local new_nl_H = {
		num_s = HSL_s.H,
		num_e = HSL_e.H,
		vc = vc_H
	}

	local new_nl_S = {
		num_s = HSL_s.S,
		num_e = HSL_e.S,
		vc = vc_S
	}

	local new_nl_L = {
		num_s = HSL_s.L,
		num_e = HSL_e.L,
		vc = vc_L
	}

	self.nl_tags_colour = self.nl_tags_colour or {}
	self.nl_tags_colour[tag_str] = {H=new_nl_H, S=new_nl_S, L=new_nl_L}

	return self
end

--添加静态 ass tag
function FX:addStaticTag(tag_str)

	assert(type(tag_str) == "string", "string not found!")
	if not tag_str:find("\\", 1) then tag_str = "\\"..tag_str end

	self.static_tags = self.static_tags or {}
	self.static_tags[#self.static_tags+1] = tag_str

	return self
end



-- Create Conf ---------------------------------------------------------------------------

--收集配置
function FX:collectConf()

	if type(self.fx_conf) ~= "table" then
		self.fx_conf = {}
	end
	self.fx_conf.time = self.fx_conf.time or self.time
	assert(type(self.fx_conf.time) == "table", "table time not found!")
	self.fx_conf.multi_motion = self.fx_conf.multi_motion or self.multi_motion
	self.fx_conf.nl_tags = self.fx_conf.nl_tags or self.nl_tags
	self.fx_conf.nl_tags_colour = self.fx_conf.nl_tags_colour or self.nl_tags_colour
	self.fx_conf.static_tags = self.fx_conf.static_tags or self.static_tags

	--初始化
	for k, _ in pairs(self) do
		if k ~= "fx_conf" and k ~= "tag" and k ~= "cache" then
			self[k] = nil
		end
	end

	self.tag.collectConf = true

	return self
end

--生成帧时间
function FX:createTime()

	if not self.tag.collectConf then self:collectConf() end

	local new_time = self.fx_conf.time
	new_time = Time:new(new_time)
	new_time:createFrames()

	self.tag.createTime = true

	return self
end

--生成运动坐标
function FX:createMotionMulti()

	if not self.tag.createTime then self:createTime() end

	local frame = self.fx_conf.time.frame

	local new_Mmulti = self.fx_conf.multi_motion
	new_Mmulti = MotionMulti:new(new_Mmulti)
	new_Mmulti:createMotionTrack(frame)

	self.tag.createMotionMulti = true

	return self
end

--计算nl_tags
function FX:createNL()

	if not self.tag.createTime then self:createTime() end

	local frame = self.fx_conf.time.frame

	local nl_tags = self.fx_conf.nl_tags
	for _, new_nl in pairs(nl_tags) do
		new_nl = NL:new(new_nl)
		new_nl:createNLValues(frame)
	end

	self.tag.createNL = true

	return self
end


--计算nl_tags_colour
function FX:createNLColour()

	if not self.tag.createTime then self:createTime() end

	local frame = self.fx_conf.time.frame

	local nl_tags_colour = self.fx_conf.nl_tags_colour
	for _, new_nl_multi in pairs(nl_tags_colour) do
		new_nl_multi.H = NL:new(new_nl_multi.H)
		new_nl_multi.H:createNLValues(frame)

		new_nl_multi.S = NL:new(new_nl_multi.S)
		new_nl_multi.S:createNLValues(frame)

		new_nl_multi.L = NL:new(new_nl_multi.L)
		new_nl_multi.L:createNLValues(frame)
	end

	self.tag.createNLColour = true

	return self
end

--合成 static tags
function FX:createStaticTags()

	if not self.tag.collectConf then self:collectConf() end

	local static_tags = self.fx_conf.static_tags
	static_tags.all = table.concat(static_tags)

	self.tag.createStaticTags = true

	return self
end


-- Create FX ---------------------------------------------------------------------------


--生成FX 初始合成阶段
function FX:createFXInitial()

	if self.tag.createFXInitial then return self end
	if not self.tag.createTime then self:createTime() end
	if not self.tag.createMotionMulti and self.fx_conf.multi_motion then self:createMotionMulti() end
	if not self.tag.createNL and self.fx_conf.nl_tags then self:createNL() end
	if not self.tag.createNLColour and self.fx_conf.nl_tags_colour then self:createNLColour() end
	if not self.tag.createStaticTags and self.fx_conf.static_tags then self:createStaticTags() end

	local time = self.fx_conf.time
	local multi_motion = self.fx_conf.multi_motion
	local nl_tags = self.fx_conf.nl_tags
	local nl_tags_colour = self.fx_conf.nl_tags_colour
	local static_tags = self.fx_conf.static_tags or {}
	--计算所有配置
	for i=1, time.frame do
		local fx = {}
		fx.time = {
			s = time.s[i],
			e = time.e[i]
		}

		fx.tags = {}

		if multi_motion then
			--fx.tags["\\pos"] = string.format("(%.3f,%.3f)", multi_motion.x[i], multi_motion.y[i])
			fx.tags["\\pos"] = {x=multi_motion.x[i], y=multi_motion.y[i]}
		end

		if nl_tags then
			for tag_name, nl in pairs(nl_tags) do
				if type(nl[i]) == "string" then --16进制
					fx.tags[tag_name] = nl[i]
				else
					fx.tags[tag_name] = string.format("%.3f", nl[i])
				end
			end
		end

		if nl_tags_colour then
			for tag_name, nl_multi in pairs(nl_tags_colour) do
				local new_colour = {H=nl_multi.H[i], S=nl_multi.S[i], L=nl_multi.L[i]}
				new_colour = Colour:new(new_colour)
				fx.tags[tag_name] = new_colour:toStr("ass")
			end
		end

		if static_tags then
			fx.tags.static = static_tags.all
		end

		self[i] = fx
	end

	self.tag.createFXInitial = true

	return self
end

--初始合成阶段之后 手动批量添加指定 min% ~ max% 处的ass tag
function FX:addTagsAfterFXInitial(tag_str, per_min, per_max)

	assert(type(tag_str) == "string", "tag_str not found!")
	assert(type(per_min) == "number", "per_min not found!")
	assert(type(per_max) == "number", "per_max not found!")
	if not self.tag.createFXInitial then self:createFXInitial() end
	
	if not tag_str:find("\\", 1) then tag_str = "\\"..tag_str end
	per_min = math.clamp(per_min, 0, 1)
	per_max = math.clamp(per_max, 0, 1)
	
	local k_min, k_max = math.ceil(#self * per_min), math.ceil(#self * per_max)

	for i=k_min, k_max do
		if i ~= 0 then --避免0%时 key为0
			self[i].tags.static = (self[i].tags.static or "") .. tag_str
		end
	end

	return self
end


--生成FX 最终合成阶段
function FX:createFXFinal()

	if self.tag.createFXFinal then return self end
	if not self.tag.createFXInitial then self:createFXInitial() end

	for _, frame in ipairs(self) do
		local tags = {}
		tags[#tags+1] = "{"
		for name, val in pairs(frame.tags) do
			if name == "static" then
				tags[#tags+1] = val
			elseif name == "\\pos" then
				tags[#tags+1] = name .. string.format("(%.3f,%.3f)", val.x, val.y)
			else
				tags[#tags+1] = name .. val
			end
		end
		tags[#tags+1] = "}"
		frame.tags = table.concat(tags)
	end

	--清除无用表
	for k, _ in pairs(self) do
		if type(k) ~= "number" and k ~= "tag" then
			self[k] = nil
		end
	end

	self.tag.createFXFinal = true

	return self
end



return FX

