package.path = "L:\\HYutil\\?.lua;".."I:\\HYutil\\?.lua;"..package.path
---------------------------------------------
-- DEBUG ------------------------------------
---------------------------------------------
function PrintTable(tbl, level, filteDefault)
  local msg = ""
  filteDefault = filteDefault or true --默认过滤关键字（DeleteMe, _class_type）
  level = level or 1
  local indent_str = ""
  for i = 1, level do
    indent_str = indent_str.."  "
  end

  print(indent_str .. "{")
  for k,v in pairs(tbl) do
    if filteDefault then
      if k ~= "_class_type" and k ~= "DeleteMe" then
        local item_str = string.format("%s%s = %s", indent_str .. " ",tostring(k), tostring(v))
        print(item_str)
        if type(v) == "table" then
          PrintTable(v, level + 1)
        end
      end
    else
      local item_str = string.format("%s%s = %s", indent_str .. " ",tostring(k), tostring(v))
      print(item_str)
      if type(v) == "table" then
        PrintTable(v, level + 1)
      end
    end
  end
  print(indent_str .. "}")
end



--local HYutil = require("HYutil.HY")

--local Point = require("HYutil.Point")
--local Line = require("HYutil.Line")
--local Bezier = require("HYutil.Bezier")
local Path = require("HYutil.Path")
local Shape = require("HYutil.Shape")
--local VC = require("HYutil.VC")
--local Time = require("HYutil.Time")
--local Motion = require("HYutil.Motion")
local MotionMulti = require("HYutil.MotionMulti")
--local NL = require("HYutil.NL")
--local Colour = require("HYutil.Colour")
--local FX = require("HYutil.FX")

--[[
motion_conf = {

	--shape = {"m 0 0 l 100 100"},
	shape = {{ { {0,0},{100,100} } }},

	vc = {0, 0, 1, 1},  --缓动曲线控制点 p2 p3

	--point_create = "loop", --点生成模式 路径循环（默认为 路径延伸 模式）
	--path_type = "closed",  --闭合开放路径（默认不闭合）
	--shape_direction = "reverse", --图形顺序翻转
	--path_direction = "reverse", --路径方向翻转
	--p_direction = "reverse", --单条路径方向翻转

}
motion_conf = Motion:new(motion_conf)
PrintTable(motion_conf:createMotionTrack(10))
]]
--[[
mu = {
	{shape = {{ {{0,0},{0,1080} } }}, vc = {{0,0,0.29,0.06,0.48,0.25,0.5,1},{0.5,1,0.51,0.44,0.79,0.68,0.8,1},{0.8,1,0.81,0.77,0.93,0.87,0.95,1},{0.95,1,0.95,0.92,0.99,0.96,1,1}}},
	{shape = {{ {{0,0},{1000,0} } }}, vc = {0.17,0.67,0.83,0.67}}
}
PrintTable(MotionMulti:new(mu):createMotionTrack(100).x)
]]
--[[
NL_conf = {
	num_s = 0, --起始值（因缓动曲线 生成结果会超出或小于此值）
	num_e = 100, --结束值（因缓动曲线 生成结果会超出或小于此值）
	vc = {0, 0, 1, 1},  --缓动曲线
	--num_type = "hex" --转换为十六进制形式

}
NL_conf = NL:new(NL_conf)

PrintTable(NL_conf:createNLValues(10))
]]

--[[
vc1 = {{0,0,0.29,0.06,0.48,0.25,0.5,1},{0.5,1,0.51,0.44,0.79,0.68,0.8,1},{0.8,1,0.81,0.77,0.93,0.87,0.95,1},{0.95,1,0.95,0.92,0.99,0.96,1,1}}
vc1 = VC:new(vc1)
PrintTable(vc1:createVelocityCurve(100))
]]
--[[
--pth = {{{0,0},{0.29,0.06},{0.48,0.25},{0.5,1}},{{0.5,1},{0.51,0.44},{0.79,0.68},{0.8,1}},{{0.8,1},{0.81,0.77},{0.93,0.87},{0.95,1}},{{0.95,1},{0.95,0.92},{0.99,0.96},{1,1}}}
pth = {
	[1]={{0,0},{29,6},{48,25},{50,100}},
	[2]={{50,100},{51,44},{79,68},{80,100}},
	[3]={{80,100},{81,77},{93,87},{95,100}},
	[4]={{95,100},{95,92},{99,96},{100,100}}
}
pth = Path:new(pth)
--pth:stepAll()
--pth:lengthAll()
--pth:stepAll()
print(pth:pointAtStep(0.2))
--print(pth[4].step)
--PrintTable(pth)
]]


shp = {"m 100 0 l 200 0"}
shp = Shape:new(shp)
--print(shp:pointAtStep(0.05))
--PrintTable(shp)
print(shp:pointAtStepModeLoop(2))

--[[
test = FX:new()
--test:addMotionLine({0,0,100,100},{0,0,1,1})
test:addTime(0,1000,100)
--test:addNLTag("blur",0,10,{0,0,1,1})
test:addStaticTag("\\bord3")
test:addStaticTag("\\shad4")
--test:addNLTagForColourHSL("1c", {0,0,0}, {360,1,1})

--test:createFXInitial()
test:addTagsAfterFXInitial("\\test_tag",0.4,0.5)

test:createFXFinal()
PrintTable(test)
]]

--[[
local C = {H=0,S=0,L=0}

C = Colour:new(C)

--PrintTable(RGB:toHSV())

print(C:toStr("ass"))
]]
--[[
return {
	Point = Point,
	Line = Line,
	Bezier = Bezier,
	Path = Path,
	Shape = Shape,
	VC = VC,
	Time = Time,
	Motion = Motion,
	MotionMulti = MotionMulti,
	NL = NL,
	Colour =Colour,
	FX = FX
}
]]
