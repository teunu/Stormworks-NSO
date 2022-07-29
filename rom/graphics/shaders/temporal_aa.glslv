in vec3 vertex_position_in;
in vec2 vertex_coord0_in;

out vec2 vertex_coord0_out;

uniform mat4 mat_view_proj;

void main()
{
	vertex_coord0_out = vertex_coord0_in;
	gl_Position =  mat_view_proj * vec4(vertex_position_in, 1);
}
