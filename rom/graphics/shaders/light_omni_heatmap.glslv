in vec3 vertex_position_in;

out vec4 screen_pos_out;
out vec3 vertex_world_position_out;

uniform mat4 mat_world;
uniform mat4 mat_view_proj;

void main()
{
	vertex_world_position_out = (mat_world * vec4(vertex_position_in, 1.0)).xyz;
	screen_pos_out = mat_view_proj * vec4(vertex_world_position_out, 1.0);
	gl_Position = screen_pos_out;
}
