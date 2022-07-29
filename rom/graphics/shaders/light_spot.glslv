#include "depth_utils.glslh"

in vec3 vertex_position_in;

out float log_z;
out vec4 screen_pos_out;
out vec3 world_position_out;

uniform mat4 mat_world;
uniform mat4 mat_view_proj;

void main()
{
	vec4 world_pos = mat_world * vec4(vertex_position_in, 1);
	world_position_out = world_pos.xyz;
	screen_pos_out = mat_view_proj * world_pos;
	gl_Position = screen_pos_out;
	encode_depth(gl_Position, log_z);
}
