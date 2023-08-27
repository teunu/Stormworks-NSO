local Colours = require('Lib.Colours')

local lib = {}

lib.version = "0.1.0"

local AntiZGlitch = 0.0001

lib.Presets =
{
	Gravel =
	{
		Colour			= Colours.Gravel,
		TopWidth		= 3.5 * 0.5,
		BottomWidth		= 6   * 0.5,
		Height			= 0.69,
		CenterGroove	= -0.08,
		YOffset			= -0.22
	},

	-- CONCRETE NEEDS TO LIVE SOMEWHERE ELSE CAUSE ITS NOT ROUND!!


	Concrete =
	{
		Colour			= Colours.Concrete,
		TopWidth		= 4	  * 0.5,
		BottomWidth		= 4.8 * 0.5,
		Height			= 0.69,
		CenterGroove	= -0.02,
		YOffset			= -0.22
	}
}

function lib.Railbed(Settings, ISet)

	local Colour		= Settings.Colour
	local TopWidth		= Settings.TopWidth
	local BottomWidth	= Settings.BottomWidth
	local Height		= Settings.Height
	local CenterGroove	= Settings.CenterGroove
	local YOffset		= Settings.YOffset

	local extrusion	= Extrusion()
	local set	= LoopSet()
	extrusion.LoopSets:Add(set)
	set.ReverseTriangles = true

	local loop	= Loop()
	set.Loops:Add(loop)

	if ISet then -- Apply only when a value is provided, so we don't set it to nothing.
		loop.InterpolationSettings = ISet
	end

	local v	= VertexRecord()
	v.color	= Colour

	v.position = Vector3(-BottomWidth, -Height, 0)
	loop.Vertices:Add(v)

	v.position = Vector3(-TopWidth, YOffset - AntiZGlitch, 0)
	loop.Vertices:Add(v)

	v.position = Vector3(-TopWidth, YOffset - AntiZGlitch, 0)
	loop.Vertices:Add(v)

	v.position = Vector3(0, YOffset + CenterGroove, 0)
	loop.Vertices:Add(v)

	v.position = Vector3(0, YOffset + CenterGroove, 0)
	loop.Vertices:Add(v)

	v.position = Vector3(TopWidth, YOffset, 0)
	loop.Vertices:Add(v)

	v.position = Vector3(TopWidth, YOffset, 0)
	loop.Vertices:Add(v)

	v.position = Vector3(BottomWidth, -Height, 0)
	loop.Vertices:Add(v)

	-- Indices link vertices together with lines.
	set.LineIndices:Add(0)
	set.LineIndices:Add(1)

	set.LineIndices:Add(2)
	set.LineIndices:Add(3)

	set.LineIndices:Add(4)
	set.LineIndices:Add(5)

	set.LineIndices:Add(6)
	set.LineIndices:Add(7)

	set.PhysFromVisual = true


	set:ComputeNormals()

	return extrusion
end

local mt =
{
	__call = function(self, ...)
		return lib.Railbed(...)
	end,
}
setmetatable(lib, mt)

return lib