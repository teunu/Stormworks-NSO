local lib = {}

lib.version = "0.1.0"

local AntiZGlitch = 0.0001

local function Color255(R, G, B, A)
	return Color(R / 255, G / 255, B / 255, (A or 255) / 255)
end

lib.Presets =
{
	Gravel =
	{
		Colour			= Color255(84, 77, 75),
		TopWidth		= 3		* 0.5,
		BottomWidth		= 4.8	* 0.5,
		Height			= 0.69,
		CenterGroove	= -0.11,
		YOffset			= -0.20
	},

	-- CONCRETE NEEDS TO LIVE SOMEWHERE ELSE CAUSE ITS NOT ROUND!!


	Concrete =
	{
		Colour			= Color255(168, 168, 166),
		TopWidth		= 4.5	* 0.5,
		BottomWidth		= 5.2	* 0.5,
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

	v.position = Vector3(0, YOffset + CenterGroove, 0)
	loop.Vertices:Add(v)

	v.position = Vector3(TopWidth, YOffset, 0)
	loop.Vertices:Add(v)

	v.position = Vector3(BottomWidth, -Height, 0)
	loop.Vertices:Add(v)

	-- Indices link vertices together with lines.
	set.LineIndices:Add(0)
	set.LineIndices:Add(1)

	set.LineIndices:Add(1)
	set.LineIndices:Add(2)

	set.LineIndices:Add(2)
	set.LineIndices:Add(3)

	set.LineIndices:Add(3)
	set.LineIndices:Add(4)

	-- Slightly optimize physics by making the shape simpler.
	set.PhysFromVisual = false
	set.PhysLineIndices:Add(0)
	set.PhysLineIndices:Add(1)

	set.PhysLineIndices:Add(1)
	set.PhysLineIndices:Add(3)

	set.PhysLineIndices:Add(3)
	set.PhysLineIndices:Add(4)


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