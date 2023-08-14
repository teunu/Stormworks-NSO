in vec3 vertex_position_in;
in vec4 vertex_color_in;

out vec3 vertex_position_out;
out vec4 vertex_color_out;

uniform mat4 mat_world;
uniform mat4 mat_view_proj;

void main()
{
	vertex_color_out = vertex_color_in;

	vec4 world_pos = mat_world * vec4(vertex_position_in, 1);
	vertex_position_out = (mat_world * vec4(vertex_position_in, 0)).xyz;
	gl_Position = mat_view_proj * world_pos; 
}
