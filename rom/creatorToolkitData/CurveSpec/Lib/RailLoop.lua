-- Generate a Circle

return function(steps, radius, color)
	-- Create the LoopSet
	-- LoopSet holds a number of Loops (but 1 is fine too)
	local set = LoopSet()
	local loop = Loop()
	set.Loops:Add(loop)

	for i = 0, steps do
		local t = i / steps * math.pi * 2

		local x = math.sin(t)
		local y = math.cos(t)

		local v = VertexRecord()
		v.position = Vector3(x * radius, y * radius, 0)
		v.normal   = Vector3(x, y, 0)
		v.color    = color or Color4.White

		loop.Vertices:Add(v)
	end

	-- Indices reference vertices to create lines
	for i = 0, steps - 1 do
		set.LineIndices:Add(i + 1)
		set.LineIndices:Add(i)
	end
	-- Finish up with a line from the last Vertex to the first.
	set.LineIndices:Add(0)
	set.LineIndices:Add(steps - 1)

	return set
end