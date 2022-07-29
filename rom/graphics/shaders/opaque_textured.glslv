#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec2 vertex_coord0_in;
in vec3 vertex_normal_in;

out float log_z;
out vec2 vertex_coord0_out;
out vec3 vertex_normal_out;
out vec3 vertex_world_position_out;
#if VELOCITY_ENABLED == 1
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;
#endif

uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;
uniform mat4 mat_world;
uniform mat4 mat_world_prev;
uniform mat4 mat_world_next;

void main()
{
	vertex_coord0_out = vertex_coord0_in;
	vertex_normal_out = (mat_world * vec4(vertex_normal_in, 0.0)).xyz;

	vec4 world_pos = mat_world * vec4(vertex_position_in, 1.0);
	vertex_world_position_out = world_pos.xyz;

#if VELOCITY_ENABLED == 1
	vertex_position_prev_out = mat_view_proj_prev * (mat_world_prev * vec4(vertex_position_in, 1.0));
	vertex_position_next_out = mat_view_proj_next * (mat_world_next * vec4(vertex_position_in, 1.0));
#endif

	gl_Position =  mat_view_proj * world_pos;
	encode_depth(gl_Position, log_z);
}
