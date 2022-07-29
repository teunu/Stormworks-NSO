-- Generate the Embankment

return function(color)
	-- Create the LoopSet
	-- LoopSet holds a number of Loops (but 1 is fine too)
	local set = LoopSet()
	local loop = Loop()
	set.Loops:Add(loop)

	local v1 = VertexRecord()
	v1.position = Vector3(-3, -1, 0)
	v1.normal = Vector3(-3, -1, 0)
	v1.color    = color or Color4.White

	local v2 = VertexRecord()
	v2.position = Vector3(-2, 0, 0)
	v2.normal = Vector3(-2, 0, 0)
	v2.color    = color or Color4.White

	local v3 = VertexRecord()
	v2.position = Vector3(2, 0, 0)
	v2.normal = Vector3(2, 0, 0)
	v2.color    = color or Color4.White

	local v3 = VertexRecord()
	v1.position = Vector3(3, -1, 0)
	v1.normal = Vector3(3, -1, 0)
	v1.color    = color or Color4.White

	--Add vertexes to loopset
	loop.Vertices:Add(v1)
	loop.Vertices:Add(v2)
	loop.Vertices:Add(v3)
	loop.Vertices:Add(v4)

	-- Indices reference vertices to create lines
	for i = 0, 3 do
		set.LineIndices:Add(i + 1)
		set.LineIndices:Add(i)
	end
	-- Leave out the bottom line
	
	return set
end