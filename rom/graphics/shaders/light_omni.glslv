#include "depth_utils.glslh"

in vec3 vertex_position_in;

out float log_z;
out vec4 screen_pos_out;

uniform mat4 mat_world;
uniform mat4 mat_view_proj;

void main()
{
	screen_pos_out = mat_view_proj * (mat_world * vec4(vertex_position_in, 1.0));
	gl_Position = screen_pos_out;
	encode_depth(gl_Position, log_z);
}
