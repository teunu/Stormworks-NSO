local lib = {}

lib.version = "0.1.0"

local AntiZGlitch = 0.0001

function lib.Embankment(Settings, ISet)

	Settings = Settings or {}

	local Colour		= Settings.Colour		or Color255(54, 64, 7, 255)
	local TopColour		= Settings.TopColour	or Colour
	local TopWidth		= (Settings.TopWidth	or 6)	* 0.5
	local BottomWidth	= (Settings.BottomWidth	or 20)	* 0.5
	local Height		= Settings.Height 		or 3
	local YOffset		= Settings.YOffset 		or -0.65
	local closedBottom  = Settings.ClosedBottom or false

	local extrusion	= Extrusion()
	local set = LoopSet()
	extrusion.LoopSets:Add(set)
	set.ReverseTriangles = true

	local loop = Loop()
	set.Loops:Add(loop)

	if ISet then -- Apply only when a value is provided, so we don't set it to nothing.
		loop.InterpolationSettings = ISet
	end

	set.LineIndices:Add(0)
	set.LineIndices:Add(1)
	set.LineIndices:Add(2)
	set.LineIndices:Add(3)
	set.LineIndices:Add(4)
	set.LineIndices:Add(5)

	local v	= VertexRecord()
	v.color		= Colour

	v.position	= Vector3(-BottomWidth, -Height + YOffset, 0)
	loop.Vertices:Add(v)

	v.position	= Vector3(-TopWidth, YOffset - AntiZGlitch, 0)
	loop.Vertices:Add(v)

	v.color		= TopColour

	v.position	= Vector3(-TopWidth, YOffset - AntiZGlitch, 0)
	loop.Vertices:Add(v)

	v.position	= Vector3(TopWidth, YOffset, 0)
	loop.Vertices:Add(v)

	v.color		= Colour
	
	v.position	= Vector3(TopWidth, YOffset, 0)
	loop.Vertices:Add(v)

	v.position	= Vector3(BottomWidth, -Height + YOffset, 0)
	loop.Vertices:Add(v)

	if closedBottom then
		v.position	= Vector3(BottomWidth, -Height + YOffset, 0)
		loop.Vertices:Add(v)

		v.position	= Vector3(-BottomWidth, -Height + YOffset, 0)
		loop.Vertices:Add(v)

		set.LineIndices:Add(6)
		set.LineIndices:Add(7)
	end

	set:ComputeNormals()

	return extrusion
end

local mt =
{
	__call = function(self, ...) return lib.Embankment(...) end,
}
setmetatable(lib, mt)

return lib