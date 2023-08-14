in vec3 vertex_position_in;
in vec3 vertex_normal_in;

out vec3 vertex_normal_out;
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;
uniform mat4 mat_world;
uniform mat4 mat_world_prev;
uniform mat4 mat_world_next;

void main()
{
	vertex_normal_out = vertex_normal_in;

	vec3 world_pos = (mat_world * vec4(vertex_position_in, 1.0)).xyz;

	vertex_position_prev_out = mat_view_proj_prev * (mat_world_prev * vec4(vertex_position_in, 1.0));
	vertex_position_next_out = mat_view_proj_next * (mat_world_next * vec4(vertex_position_in, 1.0));

	gl_Position = mat_view_proj * vec4(world_pos, 1);
}
