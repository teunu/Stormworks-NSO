local lib = {}

lib.version = "0.1.0"

local AntiZGlitch = 0.0001

local function FindCircle(x1, y1, x2, y2, x3, y3)
	local x12 = x1 - x2
	local x13 = x1 - x3
	local y12 = y1 - y2
	local y13 = y1 - y3
	local y31 = y3 - y1
	local y21 = y2 - y1
	local x31 = x3 - x1
	local x21 = x2 - x1

	local sx13 = x1^2 - x3^2
	local sy13 = y1^2 - y3^2
	local sx21 = x2^2 - x1^2
	local sy21 = y2^2 - y1^2

	local f = ((sx13) * (x12) + (sy13) * (x12) + (sx21) * (x13) + (sy21) * (x13)) / (2 * ((y31) * (x12) - (y21) * (x13)))
	local g = ((sx13) * (y12) + (sy13) * (y12) + (sx21) * (y13) + (sy21) * (y13)) / (2 * ((x31) * (y12) - (x21) * (y13)))

	local c = -x1^2 - y1^2 - 2 * g * x1 - 2 * f * y1
	--- Center x coordinate
	local x = -g
	--- Center y coordinate
	local y = -f
	local sqr_of_r = x * x + y * y - c

	-- r is the radius
	local r = math.sqrt(sqr_of_r)
	return r, x, y
end

local function TunnelToCircle(HalfWidth, Height, YOffset)
	local x1 = -HalfWidth
	local y1 = YOffset

	local x2 = HalfWidth
	local y2 = YOffset

	local x3 = 0
	local y3 = Height + YOffset

	return FindCircle(x1, y1, x2, y2, x3, y3)
end

local function CircleToTruncatedPolygon(x, y, r, HalfWidth, NumberOfVerteces)

	local StrangeAngle = math.asin((HalfWidth) / r)
	local StartAngle = math.pi - StrangeAngle
	local TotalAngle = 2 * (math.pi - StrangeAngle)

	local BetweenAngle = TotalAngle / NumberOfVerteces

	local Points = {}

	for i = 0, NumberOfVerteces do

		local ThisAngle =  - BetweenAngle * i + StartAngle
		table.insert(Points, {
			x = math.sin(ThisAngle) * r + x,
			y = math.cos(ThisAngle) * r + y
		})

	end

	return Points
end


function lib.Tunnel(Settings, ISet)

	Settings = Settings or {}

	local Colour		= Settings.Colour		      or Color255(54, 64, 7, 255)
	local WallColour	= Settings.WallColour	      or Colour
	local HalfWidth		= (Settings.Width	    	  or 6) * 0.5
	local Height		= Settings.Height 		      or 8
	local YOffset		= Settings.YOffset 		      or -0.65
	local Shape			= string.upper(Settings.Shape or "box") -- Might also be: "circle", "rounded"
	local ShapeParam	= Settings.ShapeParam    	  or 4

	local extrusion	= Extrusion()
	local set = LoopSet()
	extrusion.LoopSets:Add(set)
	set.ReverseTriangles = true

	local loop = Loop()
	set.Loops:Add(loop)

	if ISet then -- Apply only when a value is provided, so we don't set it to nothing.
		loop.InterpolationSettings = ISet
	end

	local v	= VertexRecord()
	v.color	= Colour

	local NumIndeces = 0

	v.position	= Vector3(-HalfWidth, YOffset - AntiZGlitch, 0)
	loop.Vertices:Add(v)
	v.position	= Vector3(HalfWidth, YOffset, 0)
	loop.Vertices:Add(v)

	set.PhysFromVisual = false
	set.PhysLineIndices:Add(0)
	set.PhysLineIndices:Add(1)

	v.color		= WallColour

	if Shape == "BOX" then

		NumIndeces = 8

		v.position	= Vector3(HalfWidth, YOffset, 0)
		loop.Vertices:Add(v)
		v.position	= Vector3(HalfWidth, YOffset + Height, 0)
		loop.Vertices:Add(v)

		v.position	= Vector3(HalfWidth, YOffset + Height, 0)
		loop.Vertices:Add(v)
		v.position	= Vector3(-HalfWidth, YOffset + Height, 0)
		loop.Vertices:Add(v)

		v.position	= Vector3(-HalfWidth, YOffset + Height, 0)
		loop.Vertices:Add(v)
		v.position	= Vector3(-HalfWidth, YOffset - AntiZGlitch, 0)
		loop.Vertices:Add(v)

	elseif Shape == "CIRCLE" then

		local ShapeVerteces = ShapeParam - 1
		NumIndeces = (ShapeVerteces + 1) * 2 
		local r, x, y = TunnelToCircle(HalfWidth, Height, YOffset)
		local Points = CircleToTruncatedPolygon(x, y, r, HalfWidth, ShapeVerteces)

		local FirstPoint = true
		for i = 1, #Points do
			local P = Points[i]

			if FirstPoint == false then
				v.position = Vector3(P.x, P.y, 0)
				loop.Vertices:Add(v)
			end

			v.position = Vector3(P.x, P.y, 0)
			loop.Vertices:Add(v)

			FirstPoint = false
		end

	elseif Shape == "ROUNDED" then

		NumIndeces = 12

		v.position	= Vector3(HalfWidth, YOffset, 0)
		loop.Vertices:Add(v)
		v.position	= Vector3(HalfWidth, YOffset + Height - ShapeParam, 0)
		loop.Vertices:Add(v)

		v.position	= Vector3(HalfWidth, YOffset + Height - ShapeParam, 0)
		loop.Vertices:Add(v)
		v.position	= Vector3(HalfWidth - ShapeParam, YOffset + Height, 0)
		loop.Vertices:Add(v)

		v.position	= Vector3(HalfWidth - ShapeParam, YOffset + Height, 0)
		loop.Vertices:Add(v)
		v.position	= Vector3(-HalfWidth + ShapeParam, YOffset + Height, 0)
		loop.Vertices:Add(v)

		v.position	= Vector3(-HalfWidth + ShapeParam, YOffset + Height, 0)
		loop.Vertices:Add(v)
		v.position	= Vector3(-HalfWidth, YOffset + Height - ShapeParam, 0)
		loop.Vertices:Add(v)

		v.position	= Vector3(-HalfWidth, YOffset + Height - ShapeParam, 0)
		loop.Vertices:Add(v)
		v.position	= Vector3(-HalfWidth, YOffset, 0)
		loop.Vertices:Add(v)
	end

	for i = 0, NumIndeces - 1 do
		set.LineIndices:Add(i)
	end

	set:ComputeNormals()

	return extrusion
end

local mt =
{
	__call = function(self, ...) return lib.Tunnel(...) end,
}
setmetatable(lib, mt)

return lib