--- Apply color to all vertices in a Loop

return function(loop, color)
	for i = 0, (loop.Vertices.Count -2) do
		local v = loop.Vertices[i]
		v.color = color
		-- A VertexRecord is a 'value type'
		-- This means that changes to v do not also apply
		-- to loop.Vertices
		-- So we put it back in
		loop.Vertices[i] = v
	end
end