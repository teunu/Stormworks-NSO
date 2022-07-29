#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec4 vertex_color_in;

out float log_z;
out vec3 vertex_world_position_out;
out vec4 vertex_color_out;

uniform mat4 mat_world;
uniform mat4 mat_view_proj;
uniform int is_override_color;
uniform vec4 override_color;

void main()
{
	vertex_color_out = vertex_color_in;

    if(is_override_color == 1)
    {
        vertex_color_out.r = pow(override_color.r, 2.2);
        vertex_color_out.g = pow(override_color.g, 2.2);
        vertex_color_out.b = pow(override_color.b, 2.2);
    }

	vec4 world_pos = mat_world * vec4(vertex_position_in, 1);
	vertex_world_position_out = world_pos.xyz;
	gl_Position = mat_view_proj * world_pos;
    encode_depth(gl_Position, log_z);
}
