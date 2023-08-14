in vec2 vertex_uv0;
in vec3 vertex_pos;

out vec2 out_uv_coord;

void main()
{
	gl_Position = vec4(vertex_pos.xyz, 1.0);
	out_uv_coord = vertex_uv0;
}
